import json
import asyncio
from typing import Dict, Set, Optional
from fastapi import WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from ..models import User, Message
from ..database import get_db

class ConnectionManager:
    def __init__(self):
        # Store active connections: {user_id: WebSocket}
        self.active_connections: Dict[int, WebSocket] = {}
        # Store user sessions: {user_id: Set[session_id]}
        self.user_sessions: Dict[int, Set[str]] = {}
        
    async def connect(self, websocket: WebSocket, user_id: int, session_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        
        if user_id not in self.user_sessions:
            self.user_sessions[user_id] = set()
        self.user_sessions[user_id].add(session_id)
        
        # Send connection confirmation
        await self.send_personal_message({
            "type": "connection_established",
            "user_id": user_id,
            "message": "Connected to real-time messaging"
        }, user_id)
        
        print(f"User {user_id} connected with session {session_id}")
    
    def disconnect(self, user_id: int, session_id: str):
        if user_id in self.user_sessions:
            self.user_sessions[user_id].discard(session_id)
            
            # If no more sessions for this user, remove the connection
            if not self.user_sessions[user_id]:
                self.active_connections.pop(user_id, None)
                del self.user_sessions[user_id]
        
        print(f"User {user_id} disconnected from session {session_id}")
    
    async def send_personal_message(self, message: dict, user_id: int):
        """Send message to a specific user"""
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_text(json.dumps(message))
            except Exception as e:
                print(f"Error sending message to user {user_id}: {e}")
                # Remove failed connection
                self.active_connections.pop(user_id, None)
    
    async def broadcast(self, message: dict, exclude_user_id: Optional[int] = None):
        """Broadcast message to all connected users except specified user"""
        disconnected_users = []
        
        for user_id, connection in self.active_connections.items():
            if user_id != exclude_user_id:
                try:
                    await connection.send_text(json.dumps(message))
                except Exception as e:
                    print(f"Error broadcasting to user {user_id}: {e}")
                    disconnected_users.append(user_id)
        
        # Clean up disconnected users
        for user_id in disconnected_users:
            self.active_connections.pop(user_id, None)
            self.user_sessions.pop(user_id, None)
    
    async def send_to_users(self, message: dict, user_ids: list):
        """Send message to specific users"""
        for user_id in user_ids:
            await self.send_personal_message(message, user_id)
    
    def is_user_online(self, user_id: int) -> bool:
        """Check if a user is currently online"""
        return user_id in self.active_connections

# Global connection manager instance
manager = ConnectionManager()

class WebSocketService:
    def __init__(self, db: Session):
        self.db = db
    
    async def handle_websocket_connection(self, websocket: WebSocket, user_id: int, session_id: str):
        """Handle WebSocket connection for a user"""
        await manager.connect(websocket, user_id, session_id)
        
        try:
            while True:
                # Wait for messages from the client
                data = await websocket.receive_text()
                message_data = json.loads(data)
                
                # Handle different message types
                await self.handle_message(user_id, message_data)
                
        except WebSocketDisconnect:
            manager.disconnect(user_id, session_id)
        except Exception as e:
            print(f"WebSocket error for user {user_id}: {e}")
            manager.disconnect(user_id, session_id)
    
    async def handle_message(self, user_id: int, message_data: dict):
        """Handle incoming WebSocket messages"""
        message_type = message_data.get("type")
        
        if message_type == "typing_start":
            await self.handle_typing_start(user_id, message_data)
        elif message_type == "typing_stop":
            await self.handle_typing_stop(user_id, message_data)
        elif message_type == "message":
            await self.handle_new_message(user_id, message_data)
        elif message_type == "read_receipt":
            await self.handle_read_receipt(user_id, message_data)
        elif message_type == "ping":
            await self.handle_ping(user_id)
    
    async def handle_typing_start(self, user_id: int, message_data: dict):
        """Handle typing indicator start"""
        receiver_id = message_data.get("receiver_id")
        if receiver_id:
            await manager.send_personal_message({
                "type": "typing_start",
                "user_id": user_id,
                "receiver_id": receiver_id
            }, receiver_id)
    
    async def handle_typing_stop(self, user_id: int, message_data: dict):
        """Handle typing indicator stop"""
        receiver_id = message_data.get("receiver_id")
        if receiver_id:
            await manager.send_personal_message({
                "type": "typing_stop",
                "user_id": user_id,
                "receiver_id": receiver_id
            }, receiver_id)
    
    async def handle_new_message(self, user_id: int, message_data: dict):
        """Handle new message from WebSocket"""
        receiver_id = message_data.get("receiver_id")
        content = message_data.get("content")
        
        if receiver_id and content:
            # Save message to database
            db_message = Message(
                sender_id=user_id,
                receiver_id=receiver_id,
                content=content
            )
            
            self.db.add(db_message)
            self.db.commit()
            self.db.refresh(db_message)
            
            # Send message to receiver if online
            if manager.is_user_online(receiver_id):
                await manager.send_personal_message({
                    "type": "new_message",
                    "message": {
                        "id": db_message.id,
                        "sender_id": db_message.sender_id,
                        "receiver_id": db_message.receiver_id,
                        "content": db_message.content,
                        "created_at": db_message.created_at.isoformat(),
                        "is_read": db_message.is_read
                    }
                }, receiver_id)
            
            # Send confirmation to sender
            await manager.send_personal_message({
                "type": "message_sent",
                "message_id": db_message.id,
                "status": "sent"
            }, user_id)
    
    async def handle_read_receipt(self, user_id: int, message_data: dict):
        """Handle read receipt"""
        message_id = message_data.get("message_id")
        sender_id = message_data.get("sender_id")
        
        if message_id and sender_id:
            # Update message as read in database
            message = self.db.query(Message).filter(
                Message.id == message_id,
                Message.receiver_id == user_id
            ).first()
            
            if message and not message.is_read:
                message.is_read = True
                self.db.commit()
                
                # Send read receipt to sender
                if manager.is_user_online(sender_id):
                    await manager.send_personal_message({
                        "type": "read_receipt",
                        "message_id": message_id,
                        "read_by": user_id
                    }, sender_id)
    
    async def handle_ping(self, user_id: int):
        """Handle ping message"""
        await manager.send_personal_message({
            "type": "pong",
            "timestamp": asyncio.get_event_loop().time()
        }, user_id)
    
    async def send_message_notification(self, message: Message):
        """Send message notification to receiver"""
        if manager.is_user_online(message.receiver_id):
            await manager.send_personal_message({
                "type": "new_message",
                "message": {
                    "id": message.id,
                    "sender_id": message.sender_id,
                    "receiver_id": message.receiver_id,
                    "content": message.content,
                    "created_at": message.created_at.isoformat(),
                    "is_read": message.is_read
                }
            }, message.receiver_id)
    
    async def send_online_status(self, user_id: int, is_online: bool):
        """Send online status to user's contacts"""
        # Get user's contacts (people they've messaged with)
        contacts_query = self.db.query(Message).filter(
            (Message.sender_id == user_id) | (Message.receiver_id == user_id)
        ).distinct()
        
        contact_ids = set()
        for message in contacts_query.all():
            if message.sender_id != user_id:
                contact_ids.add(message.sender_id)
            if message.receiver_id != user_id:
                contact_ids.add(message.receiver_id)
        
        # Send online status to contacts
        for contact_id in contact_ids:
            if manager.is_user_online(contact_id):
                await manager.send_personal_message({
                    "type": "user_status",
                    "user_id": user_id,
                    "is_online": is_online
                }, contact_id)
