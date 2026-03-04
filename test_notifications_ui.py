import requests
import json

# Configuration
BASE_URL = "http://localhost:8000/api/v1"
ADMIN_EMAIL = "admin@fertilityservices.com"
ADMIN_PASSWORD = "admin123"

def login():
    """Login and get token"""
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD}
    )
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Login successful")
        return data["access_token"]
    else:
        print(f"❌ Login failed: {response.status_code}")
        print(response.text)
        return None

def get_headers(token):
    """Get headers with auth token"""
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

def get_current_user_id(token):
    """Get current user ID"""
    headers = get_headers(token)
    
    response = requests.get(
        f"{BASE_URL}/users/me",
        headers=headers
    )
    
    if response.status_code == 200:
        user = response.json()
        print(f"✅ Current user: {user.get('email')} (ID: {user.get('id')})")
        return user.get('id')
    else:
        print(f"❌ Failed to get current user: {response.status_code}")
        return None

def create_test_notifications(token, user_id):
    """Create some test notifications"""
    headers = get_headers(token)
    
    test_notifications = [
        {
            "user_id": user_id,
            "channel": "push",
            "notification_type": "appointment_confirmation",
            "title": "Appointment Confirmed",
            "message": "Your appointment has been confirmed for tomorrow at 10:00 AM"
        },
        {
            "user_id": user_id,
            "channel": "email",
            "notification_type": "appointment_reminder",
            "title": "Appointment Reminder",
            "message": "You have an appointment in 1 hour"
        },
        {
            "user_id": user_id,
            "channel": "push",
            "notification_type": "payment_confirmation",
            "title": "Payment Successful",
            "message": "Your payment of $100 has been processed successfully"
        },
        {
            "user_id": user_id,
            "channel": "sms",
            "notification_type": "payment_refund",
            "title": "Payment Refund",
            "message": "Your refund has been processed"
        },
        {
            "user_id": user_id,
            "channel": "push",
            "notification_type": "system",
            "title": "Welcome!",
            "message": "Welcome to Fertility Services Platform"
        }
    ]
    
    print("\n📤 Creating test notifications...")
    for notif in test_notifications:
        response = requests.post(
            f"{BASE_URL}/notifications/test",
            headers=headers,
            json=notif
        )
        if response.status_code == 200:
            print(f"✅ Created: {notif['title']}")
        else:
            print(f"❌ Failed to create: {notif['title']} - {response.status_code}")
            print(f"   Error: {response.text}")

def get_notifications(token):
    """Get all notifications"""
    headers = get_headers(token)
    
    print("\n📥 Fetching notifications...")
    response = requests.get(
        f"{BASE_URL}/notifications",
        headers=headers
    )
    
    if response.status_code == 200:
        notifications = response.json()
        print(f"✅ Found {len(notifications)} notifications")
        for notif in notifications[:5]:  # Show first 5
            print(f"  - {notif['title']} ({notif['channel']}) - Status: {notif['status']}")
        return notifications
    else:
        print(f"❌ Failed to fetch notifications: {response.status_code}")
        return []

def get_unread_count(token):
    """Get unread notification count"""
    headers = get_headers(token)
    
    print("\n🔔 Fetching unread count...")
    response = requests.get(
        f"{BASE_URL}/notifications/unread-count",
        headers=headers
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Unread notifications: {data['unread_count']}")
        return data['unread_count']
    else:
        print(f"❌ Failed to fetch unread count: {response.status_code}")
        return 0

def main():
    print("=" * 60)
    print("Testing Notification System UI")
    print("=" * 60)
    
    # Login
    token = login()
    if not token:
        return
    
    # Get current user ID
    user_id = get_current_user_id(token)
    if not user_id:
        return
    
    # Create test notifications
    create_test_notifications(token, user_id)
    
    # Get notifications
    notifications = get_notifications(token)
    
    # Get unread count
    unread_count = get_unread_count(token)
    
    print("\n" + "=" * 60)
    print("✅ Notification system is ready!")
    print("=" * 60)
    print("\n📱 You can now:")
    print("  1. Open admin dashboard at http://localhost:8501")
    print("  2. Navigate to 'Notifications' menu")
    print("  3. View all notifications, send test notifications, and see statistics")
    print("\n📱 For mobile app:")
    print("  1. Run the Flutter app")
    print("  2. Tap the notification bell icon in the home screen")
    print("  3. View notifications and manage preferences")

if __name__ == "__main__":
    main()
