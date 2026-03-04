"""
Test script for notification endpoints.

This script tests the notification API endpoints to ensure they're working correctly.
"""

import requests
import json
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8000/api/v1"
TEST_EMAIL = "admin@fertilityservices.com"
TEST_PASSWORD = "admin123"

def print_response(response, title="Response"):
    """Print formatted response"""
    print(f"\n{'='*60}")
    print(f"{title}")
    print(f"{'='*60}")
    print(f"Status Code: {response.status_code}")
    try:
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except:
        print(f"Response: {response.text}")
    print(f"{'='*60}\n")

def test_notification_endpoints():
    """Test notification endpoints"""
    
    print("Starting Notification Endpoints Test...")
    print(f"Base URL: {BASE_URL}")
    print(f"Test Time: {datetime.now()}\n")
    
    # Step 1: Login to get auth token
    print("Step 1: Logging in...")
    login_response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "email": TEST_EMAIL,
            "password": TEST_PASSWORD
        }
    )
    
    if login_response.status_code != 200:
        print("❌ Login failed. Please ensure test user exists.")
        print_response(login_response, "Login Failed")
        return
    
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("✅ Login successful")
    
    # Step 2: Get notifications list
    print("\nStep 2: Getting notifications list...")
    notifications_response = requests.get(
        f"{BASE_URL}/notifications",
        headers=headers
    )
    print_response(notifications_response, "Notifications List")
    
    if notifications_response.status_code == 200:
        print("✅ Successfully retrieved notifications")
    else:
        print("❌ Failed to retrieve notifications")
    
    # Step 3: Get unread count
    print("\nStep 3: Getting unread count...")
    unread_response = requests.get(
        f"{BASE_URL}/notifications/unread-count",
        headers=headers
    )
    print_response(unread_response, "Unread Count")
    
    if unread_response.status_code == 200:
        print("✅ Successfully retrieved unread count")
    else:
        print("❌ Failed to retrieve unread count")
    
    # Step 4: Get notification preferences
    print("\nStep 4: Getting notification preferences...")
    preferences_response = requests.get(
        f"{BASE_URL}/notifications/preferences",
        headers=headers
    )
    print_response(preferences_response, "Notification Preferences")
    
    if preferences_response.status_code == 200:
        print("✅ Successfully retrieved preferences")
    else:
        print("❌ Failed to retrieve preferences")
    
    # Step 5: Update notification preference
    print("\nStep 5: Updating notification preference...")
    update_pref_response = requests.put(
        f"{BASE_URL}/notifications/preferences",
        headers=headers,
        json={
            "channel": "push",
            "notification_type": "appointment_reminder",
            "enabled": True
        }
    )
    print_response(update_pref_response, "Update Preference")
    
    if update_pref_response.status_code == 200:
        print("✅ Successfully updated preference")
    else:
        print("❌ Failed to update preference")
    
    # Step 6: Mark all as read (if there are notifications)
    if notifications_response.status_code == 200:
        notifications = notifications_response.json()
        if notifications:
            print("\nStep 6: Marking all notifications as read...")
            mark_read_response = requests.put(
                f"{BASE_URL}/notifications/mark-all-read",
                headers=headers
            )
            print_response(mark_read_response, "Mark All Read")
            
            if mark_read_response.status_code == 200:
                print("✅ Successfully marked all as read")
            else:
                print("❌ Failed to mark all as read")
    
    print("\n" + "="*60)
    print("Notification Endpoints Test Complete!")
    print("="*60)

if __name__ == "__main__":
    try:
        test_notification_endpoints()
    except Exception as e:
        print(f"\n❌ Test failed with error: {str(e)}")
        import traceback
        traceback.print_exc()
