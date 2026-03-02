from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
import uuid

from ..database import get_db
from ..models import User, Message
from ..schemas import MessageCreate, MessageResponse
from ..auth import get_current_active_user
from ..services.websocket_service import WebSocketService, manager

router = APIRouter()

@router.post("/", response_model=MessageResponse)
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Send a message to another user."""
    # Verify receiver exists
    receiver = db.query(User).filter(
        User.id == message_data.receiver_id,
        User.is_active == True
    ).first()
    
    if not receiver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receiver not found"
        )
    
    # Prevent sending message to self
    if message_data.receiver_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot send message to yourself"
        )
    
    # Create message
    db_message = Message(
        sender_id=current_user.id,
        receiver_id=message_data.receiver_id,
        content=message_data.content
    )
    
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    
    return db_message

@router.get("/conversations", response_model=List[dict])
async def get_conversations(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get all conversations for the current user."""
    # Get all users who have exchanged messages with current user
    conversations_query = db.query(Message).filter(
        or_(
            Message.sender_id == current_user.id,
            Message.receiver_id == current_user.id
        )
    ).distinct()
    
    # Get unique user IDs from conversations
    user_ids = set()
    messages = conversations_query.all()
    
    for message in messages:
        if message.sender_id != current_user.id:
            user_ids.add(message.sender_id)
        if message.receiver_id != current_user.id:
            user_ids.add(message.receiver_id)
    
    # Get user details and last message for each conversation
    conversations = []
    for user_id in user_ids:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            continue
        
        # Get last message in conversation
        last_message = db.query(Message).filter(
            or_(
                and_(Message.sender_id == current_user.id, Message.receiver_id == user_id),
                and_(Message.sender_id == user_id, Message.receiver_id == current_user.id)
            )
        ).order_by(Message.created_at.desc()).first()
        
        # Count unread messages
        unread_count = db.query(Message).filter(
            Message.sender_id == user_id,
            Message.receiver_id == current_user.id,
            Message.is_read == False
        ).count()
        
        conversations.append({
            "user": {
                "id": user.id,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "email": user.email,
                "user_type": user.user_type.value
            },
            "last_message": {
                "id": last_message.id,
                "content": last_message.content,
                "created_at": last_message.created_at,
                "is_read": last_message.is_read,
                "sender_id": last_message.sender_id
            } if last_message else None,
            "unread_count": unread_count
        })
    
    # Sort by last message time
    conversations.sort(
        key=lambda x: x["last_message"]["created_at"] if x["last_message"] else x["user"]["id"],
        reverse=True
    )
    
    return conversations

@router.get("/conversation/{user_id}", response_model=List[MessageResponse])
async def get_conversation_messages(
    user_id: int,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get messages in a conversation with a specific user."""
    # Verify the other user exists
    other_user = db.query(User).filter(User.id == user_id).first()
    if not other_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Get messages between current user and specified user
    messages = db.query(Message).filter(
        or_(
            and_(Message.sender_id == current_user.id, Message.receiver_id == user_id),
            and_(Message.sender_id == user_id, Message.receiver_id == current_user.id)
        )
    ).order_by(Message.created_at.asc()).offset(skip).limit(limit).all()
    
    # Mark messages as read (messages sent to current user)
    unread_messages = db.query(Message).filter(
        Message.sender_id == user_id,
        Message.receiver_id == current_user.id,
        Message.is_read == False
    ).all()
    
    for message in unread_messages:
        message.is_read = True
    
    if unread_messages:
        db.commit()
    
    return messages

@router.get("/unread-count")
async def get_unread_count(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get total unread message count for current user."""
    unread_count = db.query(Message).filter(
        Message.receiver_id == current_user.id,
        Message.is_read == False
    ).count()
    
    return {"unread_count": unread_count}

@router.put("/{message_id}/read")
async def mark_message_as_read(
    message_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Mark a message as read."""
    message = db.query(Message).filter(Message.id == message_id).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    # Only receiver can mark message as read
    if message.receiver_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to mark this message as read"
        )
    
    message.is_read = True
    db.commit()
    
    return {"message": "Message marked as read"}

@router.put("/conversation/{user_id}/read-all")
async def mark_conversation_as_read(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Mark all messages in a conversation as read."""
    # Verify the other user exists
    other_user = db.query(User).filter(User.id == user_id).first()
    if not other_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Mark all unread messages from this user as read
    unread_messages = db.query(Message).filter(
        Message.sender_id == user_id,
        Message.receiver_id == current_user.id,
        Message.is_read == False
    ).all()
    
    for message in unread_messages:
        message.is_read = True
    
    db.commit()
    
    return {"message": f"Marked {len(unread_messages)} messages as read"}

@router.delete("/{message_id}")
async def delete_message(
    message_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a message (only sender can delete)."""
    message = db.query(Message).filter(Message.id == message_id).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    # Only sender can delete message
    if message.sender_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this message"
        )
    
    db.delete(message)
    db.commit()
    
    return {"message": "Message deleted successfully"}

@router.get("/search")
async def search_messages(
    q: str,
    user_id: int = None,
    skip: int = 0,
    limit: int = 20,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Search messages by content."""
    query = db.query(Message).filter(
        or_(
            Message.sender_id == current_user.id,
            Message.receiver_id == current_user.id
        ),
        Message.content.contains(q)
    )
    
    if user_id:
        query = query.filter(
            or_(
                and_(Message.sender_id == current_user.id, Message.receiver_id == user_id),
                and_(Message.sender_id == user_id, Message.receiver_id == current_user.id)
            )
        )
    
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(limit).all()
    
    return messages

@router.websocket("/ws/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: int,
    token: str
):
    """WebSocket endpoint for real-time messaging"""
    try:
        # Verify user authentication
        # In a real implementation, you'd verify the JWT token here
        # For now, we'll accept the connection
        
        # Generate session ID
        session_id = str(uuid.uuid4())
        
        # Create WebSocket service instance
        db = next(get_db())
        websocket_service = WebSocketService(db)
        
        # Handle the WebSocket connection
        await websocket_service.handle_websocket_connection(websocket, user_id, session_id)
        
    except WebSocketDisconnect:
        print(f"WebSocket disconnected for user {user_id}")
    except Exception as e:
        print(f"WebSocket error for user {user_id}: {e}")

@router.get("/online-status/{user_id}")
async def get_user_online_status(
    user_id: int,
    current_user: User = Depends(get_current_active_user)
):
    """Get online status of a user"""
    is_online = manager.is_user_online(user_id)
    return {"user_id": user_id, "is_online": is_online}

@router.post("/typing")
async def send_typing_indicator(
    receiver_id: int,
    is_typing: bool,
    current_user: User = Depends(get_current_active_user)
):
    """Send typing indicator to a user"""
    if manager.is_user_online(receiver_id):
        message_type = "typing_start" if is_typing else "typing_stop"
        await manager.send_personal_message({
            "type": message_type,
            "user_id": current_user.id,
            "receiver_id": receiver_id
        }, receiver_id)
    
    return {"status": "sent"}
