#!/usr/bin/env python3
"""
Test script to check if the messages API is working
"""

import requests
import json

def test_messages_api():
    """Test the messages API endpoints"""
    base_url = "http://localhost:8000/api/v1"
    
    # Test conversations endpoint
    print("🧪 Testing messages API...")
    
    # First, let's try to get a valid token by logging in
    login_data = {
        "email": "admin@fertilityservices.com",
        "password": "admin123"
    }
    
    try:
        # Try to login
        login_response = requests.post(f"{base_url}/auth/login", json=login_data)
        print(f"Login response status: {login_response.status_code}")
        
        if login_response.status_code == 200:
            token_data = login_response.json()
            access_token = token_data.get("access_token")
            print(f"✅ Got access token: {access_token[:20]}...")
            
            # Test conversations endpoint with token
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            conversations_response = requests.get(f"{base_url}/messages/conversations", headers=headers)
            print(f"Conversations response status: {conversations_response.status_code}")
            
            if conversations_response.status_code == 200:
                conversations = conversations_response.json()
                print(f"✅ Successfully fetched {len(conversations)} conversations")
                for i, conv in enumerate(conversations[:3]):  # Show first 3
                    user = conv.get('user', {})
                    last_msg = conv.get('last_message', {})
                    print(f"  Conversation {i+1}: {user.get('first_name')} {user.get('last_name')}")
                    print(f"    Last message: {last_msg.get('content', 'No message')[:50]}...")
                    print(f"    Unread: {conv.get('unread_count', 0)}")
            else:
                print(f"❌ Failed to fetch conversations: {conversations_response.text}")
        else:
            print(f"❌ Login failed: {login_response.text}")
            
    except Exception as e:
        print(f"❌ Error testing API: {e}")

if __name__ == "__main__":
    test_messages_api()
