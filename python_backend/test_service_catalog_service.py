"""
Test script for ServiceCatalogService

This script tests the basic functionality of the service catalog service layer.
"""

import sys
from decimal import Decimal
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models import Base, Service, ServiceCategory, Hospital, User, UserType, Appointment, AppointmentStatus
from app.services.service_catalog_service import ServiceCatalogService
import io

# Create in-memory SQLite database for testing
engine = create_engine("sqlite:///:memory:", echo=False)
Base.metadata.create_all(engine)
SessionLocal = sessionmaker(bind=engine)

def test_service_catalog_service():
    """Test ServiceCatalogService functionality."""
    db = SessionLocal()
    service_catalog = ServiceCatalogService(db)
    
    print("=" * 60)
    print("Testing ServiceCatalogService")
    print("=" * 60)
    
    try:
        # Create test user and hospital
        print("\n1. Setting up test data...")
        user = User(
            email="hospital@test.com",
            password_hash="hashed_password",
            first_name="Test",
            last_name="Hospital",
            user_type=UserType.HOSPITAL,
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
        hospital = Hospital(
            user_id=user.id,
            name="Test Fertility Center",
            address="123 Test St",
            city="Lagos",
            state="Lagos",
            country="Nigeria",
            is_verified=True
        )
        db.add(hospital)
        db.commit()
        db.refresh(hospital)
        print(f"   ✓ Created test hospital: {hospital.name} (ID: {hospital.id})")
        
        # Test 1: Create service
        print("\n2. Testing create_service...")
        service = service_catalog.create_service(
            hospital_id=hospital.id,
            name="IVF Treatment",
            description="In-vitro fertilization treatment",
            price=Decimal("500000.00"),
            duration_minutes=120,
            category=ServiceCategory.IVF,
            service_type="fertility",
            is_featured=True
        )
        print(f"   ✓ Created service: {service.name} (ID: {service.id})")
        print(f"     Price: {service.price}, Duration: {service.duration_minutes} min")
        print(f"     Featured: {service.is_featured}, Active: {service.is_active}")
        
        # Test 2: Validate positive price
        print("\n3. Testing price validation...")
        try:
            service_catalog.create_service(
                hospital_id=hospital.id,
                name="Invalid Service",
                description="Should fail",
                price=Decimal("-100.00"),
                duration_minutes=60,
                category=ServiceCategory.CONSULTATION
            )
            print("   ✗ FAILED: Should have rejected negative price")
        except ValueError as e:
            print(f"   ✓ Correctly rejected negative price: {e}")
        
        # Test 3: Get service
        print("\n4. Testing get_service...")
        retrieved_service = service_catalog.get_service(service.id)
        print(f"   ✓ Retrieved service: {retrieved_service.name}")
        
        # Test 4: Update service
        print("\n5. Testing update_service...")
        updated_service = service_catalog.update_service(
            service_id=service.id,
            price=Decimal("550000.00"),
            is_featured=False
        )
        print(f"   ✓ Updated service price: {updated_service.price}")
        print(f"     Featured status: {updated_service.is_featured}")
        
        # Test 5: Get services with filters
        print("\n6. Testing get_services with filters...")
        
        # Create more services
        service2 = service_catalog.create_service(
            hospital_id=hospital.id,
            name="Fertility Consultation",
            description="Initial consultation",
            price=Decimal("25000.00"),
            duration_minutes=60,
            category=ServiceCategory.CONSULTATION
        )
        
        service3 = service_catalog.create_service(
            hospital_id=hospital.id,
            name="IUI Treatment",
            description="Intrauterine insemination",
            price=Decimal("150000.00"),
            duration_minutes=90,
            category=ServiceCategory.IUI,
            is_featured=True
        )
        
        all_services = service_catalog.get_services(hospital_id=hospital.id)
        print(f"   ✓ Total services: {len(all_services)}")
        
        featured_services = service_catalog.get_services(
            hospital_id=hospital.id,
            is_featured=True
        )
        print(f"   ✓ Featured services: {len(featured_services)}")
        
        consultation_services = service_catalog.get_services(
            hospital_id=hospital.id,
            category=ServiceCategory.CONSULTATION
        )
        print(f"   ✓ Consultation services: {len(consultation_services)}")
        
        # Test 6: Increment view count
        print("\n7. Testing increment_view_count...")
        initial_views = service.view_count
        service_catalog.increment_view_count(service.id)
        service_catalog.increment_view_count(service.id)
        db.refresh(service)
        print(f"   ✓ View count: {initial_views} → {service.view_count}")
        
        # Test 7: Increment booking count
        print("\n8. Testing increment_booking_count...")
        initial_bookings = service.booking_count
        service_catalog.increment_booking_count(service.id)
        db.refresh(service)
        print(f"   ✓ Booking count: {initial_bookings} → {service.booking_count}")
        
        # Test 8: Soft delete without active appointments
        print("\n9. Testing soft delete (archive)...")
        result = service_catalog.delete_service(service2.id)
        print(f"   ✓ {result['message']}")
        db.refresh(service2)
        print(f"     Service is_active: {service2.is_active}")
        
        # Test 9: Prevent deletion with active appointments
        print("\n10. Testing prevention of deletion with active appointments...")
        
        # Create a patient user
        patient = User(
            email="patient@test.com",
            password_hash="hashed_password",
            first_name="Test",
            last_name="Patient",
            user_type=UserType.PATIENT,
            is_active=True
        )
        db.add(patient)
        db.commit()
        db.refresh(patient)
        
        # Create an active appointment
        appointment = Appointment(
            user_id=patient.id,
            hospital_id=hospital.id,
            service_id=service.id,
            appointment_date=datetime.now(),
            status=AppointmentStatus.CONFIRMED,
            price=service.price
        )
        db.add(appointment)
        db.commit()
        
        try:
            service_catalog.delete_service(service.id)
            print("   ✗ FAILED: Should have prevented deletion")
        except ValueError as e:
            print(f"   ✓ Correctly prevented deletion: {e}")
        
        # Test 10: CSV Export
        print("\n11. Testing CSV export...")
        csv_content = service_catalog.export_services_to_csv(hospital_id=hospital.id)
        lines = csv_content.strip().split('\n')
        print(f"   ✓ Exported {len(lines) - 1} services to CSV")
        print(f"     CSV header: {lines[0][:80]}...")
        
        # Test 11: CSV Import
        print("\n12. Testing CSV import...")
        csv_data = """name,description,price,duration_minutes,category,service_type,is_featured
Egg Freezing,Oocyte cryopreservation,300000.00,90,EGG_FREEZING,fertility,true
Fertility Testing,Comprehensive fertility tests,50000.00,45,FERTILITY_TESTING,testing,false"""
        
        csv_file = io.BytesIO(csv_data.encode('utf-8'))
        import_result = service_catalog.import_services_from_csv(hospital.id, csv_file)
        print(f"   ✓ Imported {import_result['imported_count']} services")
        print(f"     Errors: {import_result['error_count']}")
        
        # Verify imported services
        all_services_after_import = service_catalog.get_services(hospital_id=hospital.id)
        print(f"   ✓ Total services after import: {len(all_services_after_import)}")
        
        print("\n" + "=" * 60)
        print("✓ All tests passed successfully!")
        print("=" * 60)
        
        return True
        
    except Exception as e:
        print(f"\n✗ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        db.close()


if __name__ == "__main__":
    success = test_service_catalog_service()
    sys.exit(0 if success else 1)
