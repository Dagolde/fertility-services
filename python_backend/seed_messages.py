#!/usr/bin/env python3
"""
Seed script to add test messages for the messaging system
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from app.database import get_db, engine, SessionLocal
from app.models import User, Message
from datetime import datetime, timedelta

def seed_messages():
    """Seed test messages for the messaging system"""
    db = SessionLocal()
    
    try:
        # Get existing users
        users = db.query(User).filter(User.is_active == True).limit(5).all()
        
        if len(users) < 2:
            print("Need at least 2 users to create messages")
            return
        
        # Clear existing messages
        db.query(Message).delete()
        db.commit()
        
        # Create test messages between users
        test_messages = [
            {
                'sender_id': users[0].id,
                'receiver_id': users[1].id,
                'content': 'Hello! How are you feeling today?',
                'created_at': datetime.now() - timedelta(hours=2)
            },
            {
                'sender_id': users[1].id,
                'receiver_id': users[0].id,
                'content': 'I\'m doing well, thank you for asking!',
                'created_at': datetime.now() - timedelta(hours=1, minutes=30)
            },
            {
                'sender_id': users[0].id,
                'receiver_id': users[1].id,
                'content': 'That\'s great to hear. Do you have any questions about your treatment?',
                'created_at': datetime.now() - timedelta(hours=1)
            },
            {
                'sender_id': users[1].id,
                'receiver_id': users[0].id,
                'content': 'Yes, I was wondering about the next steps in my fertility treatment plan.',
                'created_at': datetime.now() - timedelta(minutes=45)
            },
            {
                'sender_id': users[0].id,
                'receiver_id': users[1].id,
                'content': 'I\'ll review your case and get back to you with a detailed plan.',
                'created_at': datetime.now() - timedelta(minutes=30)
            },
        ]
        
        # Add more conversations if we have more users
        if len(users) >= 3:
            test_messages.extend([
                {
                    'sender_id': users[0].id,
                    'receiver_id': users[2].id,
                    'content': 'Welcome to our fertility services! How can I help you today?',
                    'created_at': datetime.now() - timedelta(days=1)
                },
                {
                    'sender_id': users[2].id,
                    'receiver_id': users[0].id,
                    'content': 'Thank you! I\'m interested in learning more about IVF treatment.',
                    'created_at': datetime.now() - timedelta(hours=23)
                },
                {
                    'sender_id': users[0].id,
                    'receiver_id': users[2].id,
                    'content': 'I\'d be happy to explain the IVF process. Let\'s schedule a consultation.',
                    'created_at': datetime.now() - timedelta(hours=22)
                },
            ])
        
        if len(users) >= 4:
            test_messages.extend([
                {
                    'sender_id': users[1].id,
                    'receiver_id': users[3].id,
                    'content': 'Hi! I\'m your assigned nurse. How are you feeling after your last appointment?',
                    'created_at': datetime.now() - timedelta(days=2)
                },
                {
                    'sender_id': users[3].id,
                    'receiver_id': users[1].id,
                    'content': 'I\'m feeling much better, thank you! The medication is working well.',
                    'created_at': datetime.now() - timedelta(days=1, hours=12)
                },
                {
                    'sender_id': users[1].id,
                    'receiver_id': users[3].id,
                    'content': 'That\'s excellent news! Keep up with your medication schedule.',
                    'created_at': datetime.now() - timedelta(hours=6)
                },
            ])
        
        # Create message objects and add to database
        for msg_data in test_messages:
            message = Message(
                sender_id=msg_data['sender_id'],
                receiver_id=msg_data['receiver_id'],
                content=msg_data['content'],
                created_at=msg_data['created_at']
            )
            db.add(message)
        
        db.commit()
        print(f"✅ Successfully seeded {len(test_messages)} test messages")
        
        # Print conversation summary
        print("\n📋 Conversation Summary:")
        for i, user in enumerate(users[:4]):  # Show first 4 users
            sent_count = db.query(Message).filter(Message.sender_id == user.id).count()
            received_count = db.query(Message).filter(Message.receiver_id == user.id).count()
            print(f"  User {i+1} ({user.first_name} {user.last_name}): {sent_count} sent, {received_count} received")
        
    except Exception as e:
        print(f"❌ Error seeding messages: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("🌱 Seeding test messages...")
    seed_messages()
    print("✅ Message seeding completed!")
