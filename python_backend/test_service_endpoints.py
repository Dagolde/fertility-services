"""
Test script for service catalog API endpoints.

This script tests the service catalog endpoints to ensure they work correctly.
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient
from app.main import app
from app.database import get_db, engine
from app.models import Base, User, Hospital, Service, ServiceCategory, UserType
from sqlalchemy.orm import Session
import json

# Create test client
client = TestClient(app)

def setup_test_data():
    """Create test data for testing."""
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    # Get database session
    db = next(get_db())
    
    try:
        # Create test hospital user
        from app.auth import get_password_hash
        
        hospital_user = User(
            email="hospital@test.com",
            password_hash=get_password_hash("testpass123"),
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
        hospital = Hospital(
            user_id=hospital_user.id,
            name="Test Fertility Center",
            hospital_type="IVF Centers",
            address="123 Test St",
            city="Lagos",
            state="Lagos",
            country="Nigeria",
            is_verified=True
        )
        db.add(hospital)
        db.commit()
        db.refresh(hospital)
        
        # Create test service
        service = Service(
            hospital_id=hospital.id,
            name="IVF Treatment",
            description="Comprehensive IVF treatment",
            price=500000.00,
            duration_minutes=120,
            category=ServiceCategory.IVF,
            is_active=True,
            is_featured=True
        )
        db.add(service)
        db.commit()
        db.refresh(service)
        
        print(f"✓ Created test hospital user (ID: {hospital_user.id})")
        print(f"✓ Created test hospital (ID: {hospital.id})")
        print(f"✓ Created test service (ID: {service.id})")
        
        return hospital_user, hospital, service
        
    except Exception as e:
        print(f"✗ Error setting up test data: {e}")
        db.rollback()
        raise
    finally:
        db.close()


def test_list_services():
    """Test GET /api/v1/services endpoint."""
    print("\n=== Testing GET /api/v1/services ===")
    
    response = client.get("/api/v1/services")
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Retrieved {len(data.get('services', []))} services")
        print(f"  Total: {data.get('total')}")
        print(f"  Page: {data.get('page')}")
        print(f"  Limit: {data.get('limit')}")
        return True
    else:
        print(f"✗ Failed: {response.text}")
        return False


def test_list_services_with_filters():
    """Test GET /api/v1/services with filters."""
    print("\n=== Testing GET /api/v1/services with filters ===")
    
    # Test category filter
    response = client.get("/api/v1/services?category=IVF")
    print(f"Category filter status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Retrieved {len(data.get('services', []))} IVF services")
    else:
        print(f"✗ Failed: {response.text}")
        return False
    
    # Test price range filter
    response = client.get("/api/v1/services?price_min=100000&price_max=1000000")
    print(f"Price range filter status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Retrieved {len(data.get('services', []))} services in price range")
    else:
        print(f"✗ Failed: {response.text}")
        return False
    
    # Test featured filter
    response = client.get("/api/v1/services?is_featured=true")
    print(f"Featured filter status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Retrieved {len(data.get('services', []))} featured services")
        return True
    else:
        print(f"✗ Failed: {response.text}")
        return False


def test_get_service_by_id():
    """Test GET /api/v1/services/{id} endpoint."""
    print("\n=== Testing GET /api/v1/services/{id} ===")
    
    # First get a service ID
    response = client.get("/api/v1/services")
    if response.status_code == 200:
        services = response.json().get('services', [])
        if services:
            service_id = services[0]['id']
            
            # Get service by ID
            response = client.get(f"/api/v1/services/{service_id}")
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                service = response.json()
                print(f"✓ Retrieved service: {service.get('name')}")
                print(f"  Price: {service.get('price')}")
                print(f"  Category: {service.get('category')}")
                print(f"  View count: {service.get('view_count')}")
                return True
            else:
                print(f"✗ Failed: {response.text}")
                return False
    
    print("✗ No services found to test")
    return False


def test_create_service_without_auth():
    """Test POST /api/v1/services without authentication (should fail)."""
    print("\n=== Testing POST /api/v1/services without auth ===")
    
    service_data = {
        "hospital_id": 1,
        "name": "Test Service",
        "description": "Test description",
        "price": 100000.00,
        "duration_minutes": 60,
        "category": "CONSULTATION",
        "is_featured": False
    }
    
    response = client.post("/api/v1/services", json=service_data)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 401 or response.status_code == 403:
        print("✓ Correctly rejected unauthenticated request")
        return True
    else:
        print(f"✗ Unexpected response: {response.text}")
        return False


def test_update_service_without_auth():
    """Test PUT /api/v1/services/{id} without authentication (should fail)."""
    print("\n=== Testing PUT /api/v1/services/{id} without auth ===")
    
    update_data = {
        "name": "Updated Service Name",
        "price": 150000.00
    }
    
    response = client.put("/api/v1/services/1", json=update_data)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 401 or response.status_code == 403:
        print("✓ Correctly rejected unauthenticated request")
        return True
    else:
        print(f"✗ Unexpected response: {response.text}")
        return False


def test_delete_service_without_auth():
    """Test DELETE /api/v1/services/{id} without authentication (should fail)."""
    print("\n=== Testing DELETE /api/v1/services/{id} without auth ===")
    
    response = client.delete("/api/v1/services/1")
    print(f"Status: {response.status_code}")
    
    if response.status_code == 401 or response.status_code == 403:
        print("✓ Correctly rejected unauthenticated request")
        return True
    else:
        print(f"✗ Unexpected response: {response.text}")
        return False


def test_export_services_without_auth():
    """Test GET /api/v1/services/export without authentication (should fail)."""
    print("\n=== Testing GET /api/v1/services/export without auth ===")
    
    response = client.get("/api/v1/services/export")
    print(f"Status: {response.status_code}")
    
    if response.status_code == 401 or response.status_code == 403:
        print("✓ Correctly rejected unauthenticated request")
        return True
    else:
        print(f"✗ Unexpected response: {response.text}")
        return False


def main():
    """Run all tests."""
    print("=" * 60)
    print("Service Catalog API Endpoints Test")
    print("=" * 60)
    
    try:
        # Setup test data
        print("\n--- Setting up test data ---")
        setup_test_data()
        
        # Run tests
        results = []
        results.append(("List services", test_list_services()))
        results.append(("List services with filters", test_list_services_with_filters()))
        results.append(("Get service by ID", test_get_service_by_id()))
        results.append(("Create service without auth", test_create_service_without_auth()))
        results.append(("Update service without auth", test_update_service_without_auth()))
        results.append(("Delete service without auth", test_delete_service_without_auth()))
        results.append(("Export services without auth", test_export_services_without_auth()))
        
        # Print summary
        print("\n" + "=" * 60)
        print("Test Summary")
        print("=" * 60)
        
        passed = sum(1 for _, result in results if result)
        total = len(results)
        
        for test_name, result in results:
            status = "✓ PASS" if result else "✗ FAIL"
            print(f"{status}: {test_name}")
        
        print(f"\nTotal: {passed}/{total} tests passed")
        
        if passed == total:
            print("\n🎉 All tests passed!")
            return 0
        else:
            print(f"\n⚠️  {total - passed} test(s) failed")
            return 1
            
    except Exception as e:
        print(f"\n✗ Test execution failed: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    exit(main())
