#!/usr/bin/env python3
"""
Test script to check if the user search API is working
"""

import requests
import json

def test_user_search_api():
    """Test the user search API endpoints"""
    base_url = "http://localhost:8000/api/v1"
    
    # Test user search endpoint
    print("🧪 Testing user search API...")
    
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
            
            # Test user search endpoint with token
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            # Test search with no query (should return all users)
            search_response = requests.get(f"{base_url}/users/search", headers=headers)
            print(f"User search response status: {search_response.status_code}")
            
            if search_response.status_code == 200:
                users = search_response.json()
                print(f"✅ Successfully fetched {len(users)} users")
                for i, user in enumerate(users[:5]):  # Show first 5
                    print(f"  User {i+1}: {user.get('first_name')} {user.get('last_name')} ({user.get('user_type')})")
                
                # Test search with query
                search_response2 = requests.get(
                    f"{base_url}/users/search?q=john", 
                    headers=headers
                )
                print(f"\nSearch for 'john' response status: {search_response2.status_code}")
                
                if search_response2.status_code == 200:
                    users2 = search_response2.json()
                    print(f"✅ Found {len(users2)} users matching 'john'")
                    for user in users2:
                        print(f"  Match: {user.get('first_name')} {user.get('last_name')} ({user.get('user_type')})")
                
                # Test search by user type
                search_response3 = requests.get(
                    f"{base_url}/users/search?user_type=admin", 
                    headers=headers
                )
                print(f"\nSearch for admins response status: {search_response3.status_code}")
                
                if search_response3.status_code == 200:
                    users3 = search_response3.json()
                    print(f"✅ Found {len(users3)} admin users")
                    for user in users3:
                        print(f"  Admin: {user.get('first_name')} {user.get('last_name')} ({user.get('user_type')})")
            else:
                print(f"❌ Failed to search users: {search_response.text}")
        else:
            print(f"❌ Login failed: {login_response.text}")
            
    except Exception as e:
        print(f"❌ Error testing API: {e}")

if __name__ == "__main__":
    test_user_search_api()
