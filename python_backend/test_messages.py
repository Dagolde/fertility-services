#!/usr/bin/env python3
"""
Test script to verify messages are working correctly
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import User, Message
from datetime import datetime

def test_messages():
    """Test that messages are working correctly"""
    db = SessionLocal()
    
    try:
        # Check if messages exist
        message_count = db.query(Message).count()
        print(f"📊 Total messages in database: {message_count}")
        
        if message_count == 0:
            print("❌ No messages found in database")
            return
        
        # Get all users
        users = db.query(User).filter(User.is_active == True).all()
        print(f"👥 Total active users: {len(users)}")
        
        # Show message distribution
        for user in users:
            sent_count = db.query(Message).filter(Message.sender_id == user.id).count()
            received_count = db.query(Message).filter(Message.receiver_id == user.id).count()
            print(f"  {user.first_name} {user.last_name}: {sent_count} sent, {received_count} received")
        
        # Show recent messages
        print("\n📝 Recent messages:")
        recent_messages = db.query(Message).order_by(Message.created_at.desc()).limit(5).all()
        for msg in recent_messages:
            sender = db.query(User).filter(User.id == msg.sender_id).first()
            receiver = db.query(User).filter(User.id == msg.receiver_id).first()
            print(f"  {sender.first_name} → {receiver.first_name}: {msg.content[:50]}...")
        
        # Test conversation structure
        print("\n💬 Testing conversation structure:")
        if users:
            test_user = users[0]
            conversations_query = db.query(Message).filter(
                (Message.sender_id == test_user.id) | (Message.receiver_id == test_user.id)
            ).distinct()
            
            user_ids = set()
            messages = conversations_query.all()
            
            for message in messages:
                if message.sender_id != test_user.id:
                    user_ids.add(message.sender_id)
                if message.receiver_id != test_user.id:
                    user_ids.add(message.receiver_id)
            
            print(f"  {test_user.first_name} has conversations with {len(user_ids)} users")
            
            for user_id in user_ids:
                other_user = db.query(User).filter(User.id == user_id).first()
                if other_user:
                    last_message = db.query(Message).filter(
                        ((Message.sender_id == test_user.id) & (Message.receiver_id == user_id)) |
                        ((Message.sender_id == user_id) & (Message.receiver_id == test_user.id))
                    ).order_by(Message.created_at.desc()).first()
                    
                    unread_count = db.query(Message).filter(
                        Message.sender_id == user_id,
                        Message.receiver_id == test_user.id,
                        Message.is_read == False
                    ).count()
                    
                    print(f"    Conversation with {other_user.first_name}: {unread_count} unread")
        
        print("\n✅ Message system test completed successfully!")
        
    except Exception as e:
        print(f"❌ Error testing messages: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    print("🧪 Testing message system...")
    test_messages()
