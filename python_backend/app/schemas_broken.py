from pydantic import BaseModel, EmailStr, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

# Enums
class UserTypeEnum(str, Enum):
    PATIENT = "patient"
    SPERM_DONOR = "sperm_donor"
    EGG_DONOR = "egg_donor"
    SURROGATE = "surrogate"
    HOSPITAL = "hospital"
    ADMIN = "admin"

class ServiceTypeEnum(str, Enum):
    SPERM_DONATION = "sperm_donation"
    EGG_DONATION = "egg_donation"
    SURROGACY = "surrogacy"

class AppointmentStatusEnum(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class PaymentStatusEnum(str, Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"

# Base schemas
class UserBase(BaseModel):
    email: EmailStr
    first_name: str
    last_name: str
    phone: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    user_type: UserTypeEnum

class UserCreate(UserBase):
    password: str
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        return v

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    date_of_birth: Optional[datetime] = None

class UserResponse(UserBase):
    id: int
    is_active: bool
    is_verified: bool
    profile_completed: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# User Profile schemas
class UserProfileBase(BaseModel):
    bio: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    zip_code: Optional[str] = None
    medical_history: Optional[Dict[str, Any]] = None
    preferences: Optional[Dict[str, Any]] = None

class UserProfileCreate(UserProfileBase):
    pass

class UserProfileUpdate(UserProfileBase):
    pass

class UserProfileResponse(UserProfileBase):
    id: int
    user_id: int
    profile_image: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Hospital schemas
class HospitalBase(BaseModel):
    name: str
    license_number: str
    address: str
    city: str
    state: str
    country: str
    zip_code: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    website: Optional[str] = None
    description: Optional[str] = None
    services_offered: Optional[List[str]] = None

class HospitalCreate(HospitalBase):
    pass

class HospitalUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    zip_code: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    website: Optional[str] = None
    description: Optional[str] = None
    services_offered: Optional[List[str]] = None

class HospitalResponse(HospitalBase):
    id: int
    user_id: int
    is_verified: bool
    is_active: bool = True
    rating: float
    total_reviews: int = 0
    latitude: float = 0.0
    longitude: float = 0.0
    operating_hours: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
        
    # Add field aliases for Flutter compatibility
    @property
    def postal_code(self):
        return self.zip_code
        
    def dict(self, **kwargs):
        data = super().dict(**kwargs)
        # Map zip_code to postal_code for Flutter compatibility
        if 'zip_code' in data:
            data['postal_code'] = data['zip_code']
        return data

# Service schemas
class ServiceBase(BaseModel):
    name: str
    service_type: ServiceTypeEnum
    description: Optional[str] = None
    base_price: Optional[float] = None

class ServiceCreate(ServiceBase):
    pass

class ServiceUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    base_price: Optional[float] = None
    is_active: Optional[bool] = None

class ServiceResponse(ServiceBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Appointment schemas
class AppointmentBase(BaseModel):
    hospital_id: int
    service_id: int
    appointment_date: datetime
    notes: Optional[str] = None

class AppointmentCreate(AppointmentBase):
    pass

class AppointmentUpdate(BaseModel):
    appointment_date: Optional[datetime] = None
    status: Optional[AppointmentStatusEnum] = None
    notes: Optional[str] = None
    price: Optional[float] = None

class AppointmentResponse(AppointmentBase):
    id: int
    user_id: int
    status: AppointmentStatusEnum
    price: Optional[float] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Message schemas
class MessageBase(BaseModel):
    receiver_id: int
    content: str

class MessageCreate(MessageBase):
    pass

class MessageResponse(MessageBase):
    id: int
    sender_id: int
    is_read: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# Payment schemas
class PaymentBase(BaseModel):
    appointment_id: int
    amount: float
    payment_method: str

class PaymentCreate(PaymentBase):
    pass

class PaymentResponse(PaymentBase):
    id: int
    user_id: int
    transaction_id: Optional[str] = None
    status: PaymentStatusEnum
    payment_date: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Medical Record schemas
class MedicalRecordBase(BaseModel):
    title: str
    description: Optional[str] = None
    is_confidential: bool = True

class MedicalRecordCreate(MedicalRecordBase):
    pass

class MedicalRecordResponse(MedicalRecordBase):
    id: int
    user_id: int
    file_path: Optional[str] = None
    file_type: Optional[str] = None
    uploaded_by: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Notification schemas
class NotificationBase(BaseModel):
    title: str
    message: str
    notification_type: Optional[str] = None

class NotificationCreate(NotificationBase):
    user_id: int

class NotificationResponse(NotificationBase):
    id: int
    user_id: int
    is_read: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# Authentication schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

# Response schemas with relationships
class UserWithProfile(UserResponse):
    profile: Optional[UserProfileResponse] = None

class HospitalWithUser(HospitalResponse):
    user: UserResponse

class AppointmentWithDetails(AppointmentResponse):
    user: UserResponse
    hospital: HospitalResponse
    service: ServiceResponse
    payment: Optional[PaymentResponse] = None

# Search and filter schemas
class HospitalSearchParams(BaseModel):
    city: Optional[str] = None
    state: Optional[str] = None
    service_type: Optional[ServiceTypeEnum] = None
    min_rating: Optional[float] = None

class AppointmentFilterParams(BaseModel):
    status: Optional[AppointmentStatusEnum] = None
    service_type: Optional[ServiceTypeEnum] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
