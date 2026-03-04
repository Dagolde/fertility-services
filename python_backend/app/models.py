from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey, Enum, JSON
from sqlalchemy.types import DECIMAL
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from datetime import datetime

Base = declarative_base()

class UserType(enum.Enum):
    PATIENT = "patient"
    SPERM_DONOR = "sperm_donor"
    EGG_DONOR = "egg_donor"
    SURROGATE = "surrogate"
    HOSPITAL = "hospital"
    ADMIN = "admin"

class ServiceCategory(enum.Enum):
    IVF = "IVF"
    IUI = "IUI"
    FERTILITY_TESTING = "Fertility_Testing"
    CONSULTATION = "Consultation"
    EGG_FREEZING = "Egg_Freezing"
    OTHER = "Other"

class Service(Base):
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id"), index=True, nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    price = Column(DECIMAL(10, 2), nullable=False, default=0.00)
    duration_minutes = Column(Integer, default=60)
    category = Column(Enum(ServiceCategory), nullable=False)
    is_active = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False, index=True)
    service_type = Column(String(50))
    view_count = Column(Integer, default=0)
    booking_count = Column(Integer, default=0)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relationships
    hospital = relationship("Hospital", back_populates="services")
    appointments = relationship("Appointment", back_populates="service")
    
    def validate_price(self):
        """Validate that price is a positive number"""
        if self.price is not None and self.price <= 0:
            raise ValueError("Service price must be a positive number")


class AppointmentStatus(enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    NO_SHOW = "no_show"

class PaymentStatus(enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"
    CANCELLED = "cancelled"

class PaymentGateway(enum.Enum):
    PAYSTACK = "paystack"
    STRIPE = "stripe"
    FLUTTERWAVE = "flutterwave"
    MANUAL = "manual"

class HospitalType(enum.Enum):
    IVF_CENTERS = "IVF Centers"
    FERTILITY_CLINICS = "Fertility Clinics"
    SPERM_BANKS = "Sperm Banks"
    SURROGACY_CENTERS = "Surrogacy Centers"
    GENERAL_HOSPITAL = "General Hospital"

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    phone = Column(String(20))
    date_of_birth = Column(DateTime)
    gender = Column(String(10))  # Male, Female, Other
    user_type = Column(Enum(UserType), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    profile_completed = Column(Boolean, default=False)
    profile_picture = Column(String(255))  # Added profile picture field
    bio = Column(Text)
    address = Column(Text)
    city = Column(String(100))
    state = Column(String(100))
    country = Column(String(100))
    postal_code = Column(String(20))
    latitude = Column(DECIMAL(10, 8))
    longitude = Column(DECIMAL(11, 8))
    wallet_balance = Column(DECIMAL(12, 2), default=0.0)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    profile = relationship("UserProfile", back_populates="user", uselist=False)
    appointments = relationship("Appointment", foreign_keys="Appointment.user_id", back_populates="user")
    sent_messages = relationship("Message", foreign_keys="Message.sender_id", back_populates="sender")
    received_messages = relationship("Message", foreign_keys="Message.receiver_id", back_populates="receiver")
    payments = relationship("Payment", back_populates="user")
    medical_records = relationship("MedicalRecord", foreign_keys="MedicalRecord.user_id", back_populates="user")
    wallet_transactions = relationship("WalletTransaction", back_populates="user")
    reviews = relationship("Review", back_populates="user")

class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    bio = Column(Text)
    address = Column(Text)
    city = Column(String(100))
    state = Column(String(100))
    country = Column(String(100))
    zip_code = Column(String(20))
    profile_image = Column(String(255))
    medical_history = Column(JSON)
    preferences = Column(JSON)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="profile")

class Hospital(Base):
    __tablename__ = "hospitals"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String(255), nullable=False)
    license_number = Column(String(100), unique=True)
    hospital_type = Column(Enum(HospitalType), default=HospitalType.GENERAL_HOSPITAL)
    address = Column(Text, nullable=False)
    city = Column(String(100), nullable=False)
    state = Column(String(100), nullable=False)
    country = Column(String(100), nullable=False)
    zip_code = Column(String(20))
    phone = Column(String(20))
    email = Column(String(255))
    website = Column(String(255))
    description = Column(Text)
    services_offered = Column(JSON)  # List of services
    is_verified = Column(Boolean, default=False)
    rating = Column(DECIMAL(3, 2), default=0.0)
    total_reviews = Column(Integer, default=0)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User")
    appointments = relationship("Appointment", back_populates="hospital")
    services = relationship("Service", back_populates="hospital")
    reviews = relationship("Review", back_populates="hospital")

class Appointment(Base):
    __tablename__ = "appointments"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id"), index=True)
    service_id = Column(Integer, ForeignKey("services.id"))
    appointment_date = Column(DateTime, nullable=False, index=True)
    status = Column(Enum(AppointmentStatus), default=AppointmentStatus.PENDING, index=True)
    notes = Column(Text)
    price = Column(DECIMAL(10, 2))
    cancellation_reason = Column(Text)
    cancelled_at = Column(DateTime)
    reserved_until = Column(DateTime, index=True)  # For 10-minute reservation hold
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id], back_populates="appointments")
    hospital = relationship("Hospital", back_populates="appointments")
    service = relationship("Service", back_populates="appointments")
    payment = relationship("Payment", back_populates="appointment", uselist=False)
    review = relationship("Review", back_populates="appointment", uselist=False)

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"))
    receiver_id = Column(Integer, ForeignKey("users.id"))
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    sender = relationship("User", foreign_keys=[sender_id], back_populates="sent_messages")
    receiver = relationship("User", foreign_keys=[receiver_id], back_populates="received_messages")

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
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="payments")
    appointment = relationship("Appointment", back_populates="payment")

class MedicalRecordType(enum.Enum):
    LICENSE = "LICENSE"
    CERTIFICATION = "CERTIFICATION"
    DIPLOMA = "DIPLOMA"
    IDENTIFICATION = "IDENTIFICATION"
    MEDICAL_HISTORY = "MEDICAL_HISTORY"
    LAB_RESULTS = "LAB_RESULTS"
    OTHER = "OTHER"

class MedicalRecord(Base):
    __tablename__ = "medical_records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String(255), nullable=False)
    file_name = Column(String(255), nullable=False)
    file_path = Column(String(255), nullable=False)
    file_type = Column(String(50), nullable=False)
    file_size = Column(Integer, nullable=False)
    description = Column(Text)
    record_type = Column(Enum(MedicalRecordType), nullable=False)
    is_verified = Column(Boolean, default=False)
    verified_by = Column(Integer, ForeignKey("users.id"))
    verified_at = Column(DateTime)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id], back_populates="medical_records")
    verifier = relationship("User", foreign_keys=[verified_by])

class WalletTransactionType(enum.Enum):
    FUND = "fund"
    PAYMENT = "payment"
    REFUND = "refund"
    WITHDRAWAL = "withdrawal"

class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    transaction_type = Column(Enum(WalletTransactionType), nullable=False)
    amount = Column(DECIMAL(10, 2), nullable=False)
    currency = Column(String(3), default="NGN")
    description = Column(Text)
    reference = Column(String(255), unique=True, index=True)
    payment_gateway = Column(Enum(PaymentGateway))
    gateway_reference = Column(String(255))
    gateway_transaction_id = Column(String(255))
    status = Column(Enum(PaymentStatus), default=PaymentStatus.PENDING)
    gateway_response = Column(JSON)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="wallet_transactions")

class PaymentGatewayConfig(Base):
    __tablename__ = "payment_gateway_configs"
    
    id = Column(Integer, primary_key=True, index=True)
    gateway = Column(Enum(PaymentGateway), unique=True, nullable=False)
    is_active = Column(Boolean, default=False)
    is_test_mode = Column(Boolean, default=True)
    public_key = Column(String(255))
    secret_key = Column(String(255))
    webhook_secret = Column(String(255))
    supported_currencies = Column(JSON, default=["NGN"])
    config_data = Column(JSON)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    notification_type = Column(String(50))
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    user = relationship("User")

class Review(Base):
    __tablename__ = "reviews"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    hospital_id = Column(Integer, ForeignKey("hospitals.id"), nullable=False, index=True)
    appointment_id = Column(Integer, ForeignKey("appointments.id"), nullable=False)
    rating = Column(Integer, nullable=False)
    comment = Column(Text)
    is_flagged = Column(Boolean, default=False, index=True)
    flag_count = Column(Integer, default=0)
    is_hidden = Column(Boolean, default=False)
    hospital_response = Column(Text)
    hospital_response_date = Column(DateTime)
    is_immutable = Column(Boolean, default=False)
    immutable_after = Column(DateTime)  # 48 hours after creation
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User")
    hospital = relationship("Hospital")
    appointment = relationship("Appointment")
    
    def validate_rating(self):
        """Validate that rating is between 1 and 5"""
        if self.rating is not None and (self.rating < 1 or self.rating > 5):
            raise ValueError("Rating must be between 1 and 5")
    
    def validate_comment_length(self):
        """Validate that comment does not exceed 1000 characters"""
        if self.comment is not None and len(self.comment) > 1000:
            raise ValueError("Comment must not exceed 1000 characters")
    
    def validate_hospital_response_length(self):
        """Validate that hospital response does not exceed 500 characters"""
        if self.hospital_response is not None and len(self.hospital_response) > 500:
            raise ValueError("Hospital response must not exceed 500 characters")
