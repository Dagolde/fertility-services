#!/usr/bin/env python3
"""
Seed script to populate the database with sample data
"""
import asyncio
import sys
import os
from datetime import datetime, timedelta
from passlib.context import CryptContext

# Add the project root to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from python_backend.app.database import get_db, engine
from python_backend.app.models import *
from sqlalchemy.orm import Session

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def seed_database():
    """Seed the database with sample data"""
    print("🌱 Starting database seeding...")
    
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    db = Session(bind=engine)
    
    try:
        # Check if data already exists
        if db.query(User).count() > 1:  # More than just admin
            print("📊 Database already has data, skipping seeding...")
            return
        
        print("👥 Creating sample users...")
        
        # Create sample patients
        patients = [
            User(
                email="patient1@example.com",
                hashed_password=hash_password("password123"),
                first_name="John",
                last_name="Doe",
                phone="+1234567890",
                user_type=UserType.PATIENT,
                is_active=True,
                is_verified=True,
                profile_completed=True,
                date_of_birth=datetime(1990, 5, 15),
                gender="Male"
            ),
            User(
                email="patient2@example.com",
                hashed_password=hash_password("password123"),
                first_name="Jane",
                last_name="Smith",
                phone="+1234567891",
                user_type=UserType.PATIENT,
                is_active=True,
                is_verified=True,
                profile_completed=True,
                date_of_birth=datetime(1988, 8, 22),
                gender="Female"
            )
        ]
        
        # Create sample donors
        donors = [
            User(
                email="donor1@example.com",
                hashed_password=hash_password("password123"),
                first_name="Mike",
                last_name="Johnson",
                phone="+1234567892",
                user_type=UserType.SPERM_DONOR,
                is_active=True,
                is_verified=True,
                profile_completed=True,
                date_of_birth=datetime(1992, 3, 10),
                gender="Male"
            ),
            User(
                email="donor2@example.com",
                hashed_password=hash_password("password123"),
                first_name="Sarah",
                last_name="Wilson",
                phone="+1234567893",
                user_type=UserType.EGG_DONOR,
                is_active=True,
                is_verified=True,
                profile_completed=True,
                date_of_birth=datetime(1994, 7, 18),
                gender="Female"
            )
        ]
        
        # Create sample surrogate
        surrogates = [
            User(
                email="surrogate1@example.com",
                hashed_password=hash_password("password123"),
                first_name="Emily",
                last_name="Brown",
                phone="+1234567894",
                user_type=UserType.SURROGATE,
                is_active=True,
                is_verified=True,
                profile_completed=True,
                date_of_birth=datetime(1989, 12, 5),
                gender="Female"
            )
        ]
        
        # Create sample hospitals
        hospitals = [
            User(
                email="hospital1@example.com",
                hashed_password=hash_password("password123"),
                first_name="City Fertility",
                last_name="Center",
                phone="+1234567895",
                user_type=UserType.HOSPITAL,
                is_active=True,
                is_verified=True,
                profile_completed=True
            ),
            User(
                email="hospital2@example.com",
                hashed_password=hash_password("password123"),
                first_name="Advanced Reproductive",
                last_name="Medicine",
                phone="+1234567896",
                user_type=UserType.HOSPITAL,
                is_active=True,
                is_verified=True,
                profile_completed=True
            )
        ]
        
        all_users = patients + donors + surrogates + hospitals
        
        for user in all_users:
            db.add(user)
        
        db.commit()
        
        print("🏥 Creating sample hospitals...")
        
        # Create hospital profiles
        hospital_profiles = [
            Hospital(
                user_id=hospitals[0].id,
                name="City Fertility Center",
                description="Leading fertility clinic with state-of-the-art facilities",
                address="123 Medical Plaza, Downtown",
                city="New York",
                state="NY",
                zip_code="10001",
                country="USA",
                phone="+1234567895",
                email="info@cityfertility.com",
                website="www.cityfertility.com",
                license_number="LIC001",
                accreditation="ASRM Certified",
                specializations=["IVF", "IUI", "Egg Freezing", "Genetic Testing"],
                is_verified=True
            ),
            Hospital(
                user_id=hospitals[1].id,
                name="Advanced Reproductive Medicine",
                description="Comprehensive reproductive health services",
                address="456 Health Avenue, Midtown",
                city="New York",
                state="NY",
                zip_code="10002",
                country="USA",
                phone="+1234567896",
                email="contact@armedicine.com",
                website="www.armedicine.com",
                license_number="LIC002",
                accreditation="ASRM Certified",
                specializations=["IVF", "ICSI", "Donor Programs", "Surrogacy"],
                is_verified=True
            )
        ]
        
        for hospital in hospital_profiles:
            db.add(hospital)
        
        db.commit()
        
        print("📅 Creating sample appointments...")
        
        # Create sample appointments
        appointments = [
            Appointment(
                patient_id=patients[0].id,
                hospital_id=hospitals[0].id,
                service_type="Initial Consultation",
                appointment_date=datetime.now() + timedelta(days=7),
                status=AppointmentStatus.CONFIRMED,
                notes="First consultation for IVF treatment"
            ),
            Appointment(
                patient_id=patients[1].id,
                hospital_id=hospitals[1].id,
                service_type="Follow-up",
                appointment_date=datetime.now() + timedelta(days=14),
                status=AppointmentStatus.PENDING,
                notes="Follow-up after initial tests"
            )
        ]
        
        for appointment in appointments:
            db.add(appointment)
        
        db.commit()
        
        print("💬 Creating sample messages...")
        
        # Create sample messages
        messages = [
            Message(
                sender_id=patients[0].id,
                receiver_id=hospitals[0].id,
                subject="Question about IVF process",
                content="Hi, I have some questions about the IVF process. Could you please provide more information?",
                is_read=False
            ),
            Message(
                sender_id=hospitals[0].id,
                receiver_id=patients[0].id,
                subject="Re: Question about IVF process",
                content="Hello! We'd be happy to answer your questions. Please schedule a consultation with our team.",
                is_read=True
            )
        ]
        
        for message in messages:
            db.add(message)
        
        db.commit()
        
        print("💳 Creating payment gateway configurations...")
        
        # Create payment gateway configurations
        payment_gateways = [
            PaymentGatewayConfig(
                gateway=PaymentGateway.PAYSTACK,
                is_active=True,
                is_test_mode=True,
                public_key="pk_test_your_paystack_public_key",
                secret_key="sk_test_your_paystack_secret_key",
                webhook_secret="whsec_your_webhook_secret",
                supported_currencies=["NGN", "USD", "EUR"],
                config_data={
                    "callback_url": "http://localhost:3000/payment/callback",
                    "merchant_email": "admin@fertilityservices.com"
                }
            ),
            PaymentGatewayConfig(
                gateway=PaymentGateway.STRIPE,
                is_active=False,
                is_test_mode=True,
                public_key="pk_test_your_stripe_public_key",
                secret_key="sk_test_your_stripe_secret_key",
                webhook_secret="whsec_your_stripe_webhook_secret",
                supported_currencies=["USD", "EUR", "GBP"],
                config_data={
                    "callback_url": "http://localhost:3000/payment/callback"
                }
            ),
            PaymentGatewayConfig(
                gateway=PaymentGateway.FLUTTERWAVE,
                is_active=False,
                is_test_mode=True,
                public_key="FLWPUBK_your_flutterwave_public_key",
                secret_key="FLWSECK_your_flutterwave_secret_key",
                webhook_secret="whsec_your_flutterwave_webhook_secret",
                supported_currencies=["NGN", "USD", "EUR", "GBP"],
                config_data={
                    "callback_url": "http://localhost:3000/payment/callback"
                }
            )
        ]
        
        for gateway in payment_gateways:
            db.add(gateway)
        
        db.commit()
        
        print("🏥 Creating sample services...")
        
        # Create sample services
        services = [
            Service(
                name="Initial Consultation",
                description="Comprehensive initial consultation with fertility specialist",
                price=5000.00,
                duration_minutes=60,
                service_type="consultation",
                is_active=True
            ),
            Service(
                name="IVF Treatment",
                description="In-vitro fertilization treatment cycle",
                price=500000.00,
                duration_minutes=120,
                service_type="treatment",
                is_active=True
            ),
            Service(
                name="IUI Treatment",
                description="Intrauterine insemination treatment",
                price=150000.00,
                duration_minutes=90,
                service_type="treatment",
                is_active=True
            ),
            Service(
                name="Egg Freezing",
                description="Egg cryopreservation service",
                price=300000.00,
                duration_minutes=180,
                service_type="preservation",
                is_active=True
            ),
            Service(
                name="Sperm Donation",
                description="Sperm donation and processing",
                price=25000.00,
                duration_minutes=30,
                service_type="donation",
                is_active=True
            ),
            Service(
                name="Egg Donation",
                description="Egg donation and processing",
                price=200000.00,
                duration_minutes=120,
                service_type="donation",
                is_active=True
            )
        ]
        
        for service in services:
            db.add(service)
        
        db.commit()
        
        print("🎉 Database seeding completed successfully!")
        print(f"Created {len(all_users)} users")
        print(f"Created {len(hospital_profiles)} hospitals")
        print(f"Created {len(appointments)} appointments")
        print(f"Created {len(messages)} messages")
        print(f"Created {len(payment_gateways)} payment gateway configurations")
        print(f"Created {len(services)} services")
        
    except Exception as e:
        print(f"❌ Error seeding database: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
