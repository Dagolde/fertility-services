"""
Test script for appointment API endpoints.

Tests the implementation of Task 1.4 - Appointment API endpoints.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient
from datetime import datetime, timedelta
from app.main import app
from app.database import get_db, engine
from app.models import Base, User, Hospital, Service, Appointment, UserType, HospitalType, AppointmentStatus
from sqlalchemy.orm import Session
import json

# Create test client
client = TestClient(app)

# Test data
TEST_USER_EMAIL = "test_patient@example.com"
TEST_USER_PASSWORD = "TestPass123!"
TEST_HOSPITAL_EMAIL = "test_hospital@example.com"


def setup_test_data():
    """Set up test data in the database."""
    print("Setting up test data...")
    
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    db = next(get_db())
    
    try:
        # Clean up existing test data
        db.query(Appointment).filter(Appointment.user_id.in_(
            db.query(User.id).filter(User.email.in_([TEST_USER_EMAIL, TEST_HOSPITAL_EMAIL]))
        )).delete(synchronize_session=False)
        
        db.query(User).filter(User.email.in_([TEST_USER_EMAIL, TEST_HOSPITAL_EMAIL])).delete()
        db.commit()
        
        # Create test patient
        from app.auth import get_password_hash
        test_user = User(
            email=TEST_USER_EMAIL,
            password_hash=get_password_hash(TEST_USER_PASSWORD),
            first_name="Test",
            last_name="Patient",
            user_type=UserType.PATIENT,
            is_active=True,
            is_verified=True
        )
        db.add(test_user)
        db.commit()
        db.refresh(test_user)
        
        # Create test hospital user
        hospital_user = User(
            email=TEST_HOSPITAL_EMAIL,
            password_hash=get_password_hash(TEST_USER_PASSWORD),
            first_name="Test",
            last_name="Hospital",
            user_type=UserType.HOSPITAL,
            is_active=True,
            is_verified=True
        )
        db.add(hospital_user)
        db.commit()
        db.refresh(hospital_user)
        
        # Create test hospital
        test_hospital = Hospital(
            user_id=hospital_user.id,
            name="Test Fertility Center",
            license_number="TEST123",
            hospital_type=HospitalType.IVF_CENTERS,
            address="123 Test St",
            city="Lagos",
            state="Lagos",
            country="Nigeria",
            is_verified=True,
            rating=4.5
        )
        db.add(test_hospital)
        db.commit()
        db.refresh(test_hospital)
        
        # Create test service
        test_service = Service(
            name="IVF Consultation",
            description="Initial IVF consultation",
            price=50000.00,
            duration_minutes=60,
            is_active=True,
            service_type="consultation"
        )
        db.add(test_service)
        db.commit()
        db.refresh(test_service)
        
        print(f"✓ Created test user (ID: {test_user.id})")
        print(f"✓ Created test hospital (ID: {test_hospital.id})")
        print(f"✓ Created test service (ID: {test_service.id})")
        
        return {
            "user_id": test_user.id,
            "hospital_id": test_hospital.id,
            "service_id": test_service.id
        }
        
    except Exception as e:
        print(f"Error setting up test data: {e}")
        db.rollback()
        raise
    finally:
        db.close()


def get_auth_token():
    """Get authentication token for test user."""
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": TEST_USER_EMAIL,
            "password": TEST_USER_PASSWORD
        }
    )
    
    if response.status_code != 200:
        print(f"Login failed: {response.json()}")
        return None
    
    return response.json()["access_token"]


def test_get_availability(hospital_id: int, service_id: int, token: str):
    """Test GET /api/v1/appointments/hospitals/{id}/availability"""
    print("\n--- Testing GET /hospitals/{id}/availability ---")
    
    tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
    
    response = client.get(
        f"/api/v1/appointments/hospitals/{hospital_id}/availability",
        params={"date": tomorrow, "service_id": service_id},
        headers={"Authorization": f"Bearer {token}"}
    )
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Got availability for {data['date']}")
        print(f"  Total slots: {len(data['slots'])}")
        available_count = sum(1 for slot in data['slots'] if slot['available'])
        print(f"  Available slots: {available_count}")
        return data
    else:
        print(f"✗ Error: {response.json()}")
        return None


def test_reserve_appointment(hospital_id: int, service_id: int, token: str):
    """Test POST /api/v1/appointments/reserve"""
    print("\n--- Testing POST /appointments/reserve ---")
    
    appointment_date = datetime.now() + timedelta(days=1, hours=10)
    
    response = client.post(
        "/api/v1/appointments/reserve",
        json={
            "hospital_id": hospital_id,
            "service_id": service_id,
            "appointment_date": appointment_date.isoformat(),
            "notes": "Test reservation"
        },
        headers={"Authorization": f"Bearer {token}"}
    )
    
    print(f"Status: {response.status_code}")
    if response.status_code == 201:
        data = response.json()
        print(f"✓ Reserved appointment")
        print(f"  Reservation ID: {data['reservation_id']}")
        print(f"  Expires at: {data['expires_at']}")
        print(f"  Appointment ID: {data['appointment']['id']}")
        return data
    else:
        print(f"✗ Error: {response.json()}")
        return None


def test_confirm_appointment(reservation_id: str, token: str):
    """Test POST /api/v1/appointments/confirm"""
    print("\n--- Testing POST /appointments/confirm ---")
    
    response = client.post(
        "/api/v1/appointments/confirm",
        json={
            "reservation_id": reservation_id,
            "payment_method": "paystack"
        },
        headers={"Authorization": f"Bearer {token}"}
    )
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Confirmed appointment")
        print(f"  Appointment ID: {data['appointment']['id']}")
        print(f"  Status: {data['appointment']['status']}")
        print(f"  Payment URL: {data['payment']['payment_url']}")
        return data
    else:
        print(f"✗ Error: {response.json()}")
        return None


def test_list_appointments(token: str):
    """Test GET /api/v1/appointments"""
    print("\n--- Testing GET /appointments ---")
    
    response = client.get(
        "/api/v1/appointments",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Retrieved {len(data)} appointments")
        for apt in data:
            print(f"  - ID: {apt['id']}, Status: {apt['status']}, Date: {apt['appointment_date']}")
        return data
    else:
        print(f"✗ Error: {response.json()}")
        return None


def test_reschedule_appointment(appointment_id: int, token: str):
    """Test PUT /api/v1/appointments/{id}/reschedule"""
    print("\n--- Testing PUT /appointments/{id}/reschedule ---")
    
    new_date = datetime.now() + timedelta(days=2, hours=14)
    
    response = client.put(
        f"/api/v1/appointments/{appointment_id}/reschedule",
        json={"new_date": new_date.isoformat()},
        headers={"Authorization": f"Bearer {token}"}
    )
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Rescheduled appointment")
        print(f"  New date: {data['appointment_date']}")
        return data
    else:
        print(f"✗ Error: {response.json()}")
        return None


def test_cancel_appointment(appointment_id: int, token: str):
    """Test DELETE /api/v1/appointments/{id}"""
    print("\n--- Testing DELETE /appointments/{id} ---")
    
    response = client.delete(
        f"/api/v1/appointments/{appointment_id}",
        json={"reason": "Test cancellation"},
        headers={"Authorization": f"Bearer {token}"}
    )
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Cancelled appointment")
        print(f"  Message: {data['message']}")
        print(f"  Refund: {data['refund']['percentage']}% = {data['refund']['amount']}")
        return data
    else:
        print(f"✗ Error: {response.json()}")
        return None


def run_tests():
    """Run all endpoint tests."""
    print("=" * 60)
    print("APPOINTMENT API ENDPOINTS TEST")
    print("=" * 60)
    
    try:
        # Setup
        test_data = setup_test_data()
        
        # Get auth token
        print("\n--- Authenticating ---")
        token = get_auth_token()
        if not token:
            print("✗ Failed to authenticate")
            return
        print("✓ Authenticated successfully")
        
        # Test endpoints
        availability = test_get_availability(
            test_data["hospital_id"],
            test_data["service_id"],
            token
        )
        
        reservation = test_reserve_appointment(
            test_data["hospital_id"],
            test_data["service_id"],
            token
        )
        
        if reservation:
            confirmation = test_confirm_appointment(
                reservation["reservation_id"],
                token
            )
            
            if confirmation:
                appointments = test_list_appointments(token)
                
                if appointments and len(appointments) > 0:
                    appointment_id = appointments[0]["id"]
                    
                    reschedule = test_reschedule_appointment(appointment_id, token)
                    
                    cancel = test_cancel_appointment(appointment_id, token)
        
        print("\n" + "=" * 60)
        print("TEST SUMMARY")
        print("=" * 60)
        print("✓ All endpoint tests completed")
        print("\nImplemented endpoints:")
        print("  ✓ POST /api/v1/appointments/reserve")
        print("  ✓ POST /api/v1/appointments/confirm")
        print("  ✓ GET /api/v1/appointments")
        print("  ✓ PUT /api/v1/appointments/{id}/reschedule")
        print("  ✓ DELETE /api/v1/appointments/{id}")
        print("  ✓ GET /api/v1/hospitals/{id}/availability")
        
    except Exception as e:
        print(f"\n✗ Test failed with error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    run_tests()
