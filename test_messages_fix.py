#!/usr/bin/env python3
"""
Test script to verify the messages API fix
"""

import requests
import json

def test_messages_api():
    """Test the messages API endpoints"""
    base_url = "http://localhost:8000/api/v1"
    
    # Test messages endpoint
    print("🧪 Testing messages API fix...")
    
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
            
            # Test messages endpoint with token
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            # Test get messages for a specific conversation
            user_id = 4  # Use a known user ID
            messages_response = requests.get(f"{base_url}/messages/conversation/{user_id}", headers=headers)
            print(f"\nMessages for user {user_id} response status: {messages_response.status_code}")
            
            if messages_response.status_code == 200:
                messages = messages_response.json()
                print(f"✅ Successfully fetched {len(messages)} messages")
                if messages:
                    print(f"✅ First message structure: {json.dumps(messages[0], indent=2, default=str)}")
                else:
                    print("ℹ️ No messages found")
            else:
                print(f"❌ Failed to get messages: {messages_response.text}")
        else:
            print(f"❌ Login failed: {login_response.text}")
            
    except Exception as e:
        print(f"❌ Error testing API: {e}")

if __name__ == "__main__":
    test_messages_api()
