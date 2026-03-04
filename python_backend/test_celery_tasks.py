"""
Test script for Celery appointment reminder tasks.
Run this after starting Celery worker to verify tasks execute correctly.
"""
from datetime import datetime, timedelta
from app.database import SessionLocal
from app.models import Appointment, AppointmentStatus, User, Hospital, Service, Notification
from app.tasks.appointment_tasks import (
    send_24_hour_reminders,
    send_1_hour_reminders,
    cleanup_expired_reservations
)


def create_test_appointments():
    """Create test appointments for reminder testing."""
    db = SessionLocal()
    
    try:
        # Get or create test user
        test_user = db.query(User).filter(User.email == "test@example.com").first()
        if not test_user:
            print("❌ Test user not found. Please create a user with email 'test@example.com'")
            return False
        
        # Get first hospital and service
        hospital = db.query(Hospital).first()
        service = db.query(Service).first()
        
        if not hospital or not service:
            print("❌ No hospital or service found. Please create test data first.")
            return False
        
        now = datetime.utcnow()
        
        # Create appointment for 24-hour reminder (23.5 hours from now)
        appt_24h = Appointment(
            user_id=test_user.id,
            hospital_id=hospital.id,
            service_id=service.id,
            appointment_date=now + timedelta(hours=23, minutes=30),
            status=AppointmentStatus.CONFIRMED,
            price=service.price,
            notes="Test appointment for 24-hour reminder"
        )
        db.add(appt_24h)
        
        # Create appointment for 1-hour reminder (55 minutes from now)
        appt_1h = Appointment(
            user_id=test_user.id,
            hospital_id=hospital.id,
            service_id=service.id,
            appointment_date=now + timedelta(minutes=55),
            status=AppointmentStatus.CONFIRMED,
            price=service.price,
            notes="Test appointment for 1-hour reminder"
        )
        db.add(appt_1h)
        
        # Create expired reservation (reserved 15 minutes ago, expired 5 minutes ago)
        appt_expired = Appointment(
            user_id=test_user.id,
            hospital_id=hospital.id,
            service_id=service.id,
            appointment_date=now + timedelta(days=1),
            status=AppointmentStatus.PENDING,
            reserved_until=now - timedelta(minutes=5),
            price=service.price,
            notes="Test expired reservation"
        )
        db.add(appt_expired)
        
        db.commit()
        
        print("✅ Created test appointments:")
        print(f"   - 24-hour reminder appointment (ID: {appt_24h.id})")
        print(f"   - 1-hour reminder appointment (ID: {appt_1h.id})")
        print(f"   - Expired reservation (ID: {appt_expired.id})")
        
        return True
        
    except Exception as e:
        print(f"❌ Error creating test appointments: {e}")
        db.rollback()
        return False
    finally:
        db.close()


def test_24_hour_reminders():
    """Test 24-hour reminder task."""
    print("\n" + "="*60)
    print("Testing 24-hour reminder task...")
    print("="*60)
    
    try:
        result = send_24_hour_reminders()
        print(f"✅ Task executed successfully:")
        print(f"   - Appointments checked: {result['appointments_checked']}")
        print(f"   - Reminders sent: {result['reminders_sent']}")
        if result['errors']:
            print(f"   - Errors: {result['errors']}")
        return True
    except Exception as e:
        print(f"❌ Task failed: {e}")
        return False


def test_1_hour_reminders():
    """Test 1-hour reminder task."""
    print("\n" + "="*60)
    print("Testing 1-hour reminder task...")
    print("="*60)
    
    try:
        result = send_1_hour_reminders()
        print(f"✅ Task executed successfully:")
        print(f"   - Appointments checked: {result['appointments_checked']}")
        print(f"   - Reminders sent: {result['reminders_sent']}")
        if result['errors']:
            print(f"   - Errors: {result['errors']}")
        return True
    except Exception as e:
        print(f"❌ Task failed: {e}")
        return False


def test_cleanup_expired_reservations():
    """Test expired reservation cleanup task."""
    print("\n" + "="*60)
    print("Testing expired reservation cleanup task...")
    print("="*60)
    
    try:
        result = cleanup_expired_reservations()
        print(f"✅ Task executed successfully:")
        print(f"   - Reservations checked: {result['reservations_checked']}")
        print(f"   - Cleaned up: {result['cleaned_up']}")
        if result['errors']:
            print(f"   - Errors: {result['errors']}")
        return True
    except Exception as e:
        print(f"❌ Task failed: {e}")
        return False


def verify_notifications():
    """Verify notifications were created."""
    print("\n" + "="*60)
    print("Verifying notifications...")
    print("="*60)
    
    db = SessionLocal()
    try:
        # Count notifications by type
        reminder_24h = db.query(Notification).filter(
            Notification.notification_type == "appointment_reminder_24h"
        ).count()
        
        reminder_1h = db.query(Notification).filter(
            Notification.notification_type == "appointment_reminder_1h"
        ).count()
        
        print(f"✅ Notifications in database:")
        print(f"   - 24-hour reminders: {reminder_24h}")
        print(f"   - 1-hour reminders: {reminder_1h}")
        
        # Show recent notifications
        recent = db.query(Notification).order_by(
            Notification.created_at.desc()
        ).limit(5).all()
        
        if recent:
            print(f"\n   Recent notifications:")
            for notif in recent:
                print(f"   - [{notif.notification_type}] {notif.title}")
        
        return True
    except Exception as e:
        print(f"❌ Error verifying notifications: {e}")
        return False
    finally:
        db.close()


def main():
    """Run all tests."""
    print("\n" + "="*60)
    print("CELERY APPOINTMENT TASKS TEST SUITE")
    print("="*60)
    
    # Step 1: Create test data
    print("\nStep 1: Creating test appointments...")
    if not create_test_appointments():
        print("\n❌ Failed to create test appointments. Exiting.")
        return
    
    # Step 2: Test 24-hour reminders
    print("\nStep 2: Testing 24-hour reminders...")
    test_24_hour_reminders()
    
    # Step 3: Test 1-hour reminders
    print("\nStep 3: Testing 1-hour reminders...")
    test_1_hour_reminders()
    
    # Step 4: Test cleanup
    print("\nStep 4: Testing expired reservation cleanup...")
    test_cleanup_expired_reservations()
    
    # Step 5: Verify notifications
    print("\nStep 5: Verifying notifications...")
    verify_notifications()
    
    print("\n" + "="*60)
    print("TEST SUITE COMPLETED")
    print("="*60)
    print("\nNext steps:")
    print("1. Check the notifications table in your database")
    print("2. Verify the expired reservation was cancelled")
    print("3. Start Celery worker to test scheduled execution:")
    print("   celery -A app.celery_app worker --beat --loglevel=info")
    print("="*60 + "\n")


if __name__ == "__main__":
    main()
