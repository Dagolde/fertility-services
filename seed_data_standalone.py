#!/usr/bin/env python3
"""
Standalone seed script to populate the database with sample data
"""

import sys
import os
from datetime import datetime, timedelta
from passlib.context import CryptContext
import mysql.connector
from sqlalchemy import create_engine, Column, Integer, String, Text, Boolean, DateTime, DECIMAL, ForeignKey, Enum, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import enum

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'port': 3307,
    'user': 'fertility_user',
    'password': 'fertility_password',
    'database': 'fertility_services'
}

# Create SQLAlchemy engine
DATABASE_URL = f"mysql+pymysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_recycle=300)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class
Base = declarative_base()

# Enums
class UserType(enum.Enum):
    PATIENT = "patient"
    SPERM_DONOR = "sperm_donor"
    EGG_DONOR = "egg_donor"
    SURROGATE = "surrogate"
    HOSPITAL = "hospital"
    ADMIN = "admin"

class PaymentGateway(enum.Enum):
    PAYSTACK = "paystack"
    STRIPE = "stripe"
    FLUTTERWAVE = "flutterwave"

class PaymentStatus(enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"
    CANCELLED = "cancelled"

class AppointmentStatus(enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

# Models
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    phone = Column(String(20))
    user_type = Column(Enum(UserType), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    profile_completed = Column(Boolean, default=False)
    date_of_birth = Column(DateTime)
    gender = Column(String(10))  # Male, Female, Other
    wallet_balance = Column(DECIMAL(12, 2), default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Hospital(Base):
    __tablename__ = "hospitals"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    name = Column(String(255), nullable=False)
    license_number = Column(String(100))
    address = Column(Text, nullable=False)
    city = Column(String(100), nullable=False)
    state = Column(String(100), nullable=False)
    country = Column(String(100), nullable=False)
    zip_code = Column(String(20))
    phone = Column(String(20))
    email = Column(String(255))
    website = Column(String(255))
    description = Column(Text)
    services_offered = Column(JSON)
    is_verified = Column(Boolean, default=False)
    rating = Column(DECIMAL(3, 2))
    hospital_type = Column(String(50), default="GENERAL_HOSPITAL")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Service(Base):
    __tablename__ = "services"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    price = Column(DECIMAL(10, 2), nullable=False, default=0.00)
    duration_minutes = Column(Integer, default=60)
    is_active = Column(Boolean, default=True)
    service_type = Column(String(50))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Appointment(Base):
    __tablename__ = "appointments"
    
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id"))
    hospital_id = Column(Integer, ForeignKey("users.id"))
    service_type = Column(String(100))
    appointment_date = Column(DateTime, nullable=False)
    status = Column(Enum(AppointmentStatus), default=AppointmentStatus.PENDING)
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Payment(Base):
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    appointment_id = Column(Integer, ForeignKey("appointments.id"))
    amount = Column(DECIMAL(10, 2), nullable=False)
    currency = Column(String(3), default="NGN")
    payment_gateway = Column(Enum(PaymentGateway), default=PaymentGateway.PAYSTACK)
    payment_method = Column(String(50))
    transaction_id = Column(String(255))
    gateway_reference = Column(String(255))
    gateway_transaction_id = Column(String(255))
    authorization_code = Column(String(255))
    status = Column(Enum(PaymentStatus), default=PaymentStatus.PENDING)
    gateway_response = Column(JSON)
    payment_date = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"))
    receiver_id = Column(Integer, ForeignKey("users.id"))
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class PaymentGatewayConfig(Base):
    __tablename__ = "payment_gateway_configs"
    
    id = Column(Integer, primary_key=True, index=True)
    gateway = Column(Enum(PaymentGateway), unique=True, nullable=False)
    is_active = Column(Boolean, default=False)
    is_test_mode = Column(Boolean, default=True)
    public_key = Column(String(255))
    secret_key = Column(String(255))
    webhook_secret = Column(String(255))
    supported_currencies = Column(JSON)
    config_data = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def seed_database():
    """Seed the database with sample data"""
    print("🌱 Starting database seeding...")
    
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
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
                password_hash=hash_password("password123"),
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
                password_hash=hash_password("password123"),
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
                password_hash=hash_password("password123"),
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
                password_hash=hash_password("password123"),
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
                password_hash=hash_password("password123"),
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
                password_hash=hash_password("password123"),
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
                password_hash=hash_password("password123"),
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
                license_number="LIC001",
                address="123 Medical Plaza, Downtown",
                city="New York",
                state="NY",
                country="USA",
                zip_code="10001",
                phone="+1234567895",
                email="info@cityfertility.com",
                website="www.cityfertility.com",
                description="Leading fertility clinic with state-of-the-art facilities",
                services_offered=["IVF", "IUI", "Egg Freezing", "Genetic Testing"],
                is_verified=True,
                rating=4.8,
                hospital_type="IVF_CENTERS"
            ),
            Hospital(
                user_id=hospitals[1].id,
                name="Advanced Reproductive Medicine",
                license_number="LIC002",
                address="456 Health Avenue, Midtown",
                city="New York",
                state="NY",
                country="USA",
                zip_code="10002",
                phone="+1234567896",
                email="contact@armedicine.com",
                website="www.armedicine.com",
                description="Comprehensive reproductive health services",
                services_offered=["IVF", "ICSI", "Donor Programs", "Surrogacy"],
                is_verified=True,
                rating=4.9,
                hospital_type="FERTILITY_CLINICS"
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
                content="Hi, I have some questions about the IVF process. Could you please provide more information?",
                is_read=False
            ),
            Message(
                sender_id=hospitals[0].id,
                receiver_id=patients[0].id,
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
