from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta

from ..database import get_db
from ..models import User, Hospital, MedicalRecord, Appointment, Payment, Notification
from ..auth import get_admin_user
from ..schemas import UserResponse, HospitalResponse, MedicalRecordResponse
from pydantic import BaseModel

router = APIRouter(prefix="/admin", tags=["Enhanced Admin"])

# Pydantic models for requests
class UserUpdateRequest(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    user_type: Optional[str] = None
    is_active: Optional[bool] = None
    is_verified: Optional[bool] = None
    profile_completed: Optional[bool] = None
    bio: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None

class HospitalCreateRequest(BaseModel):
    name: str
    license_number: str
    email: str
    phone: str
    website: Optional[str] = None
    address: str
    city: str
    state: str
    country: str
    postal_code: Optional[str] = None
    description: Optional[str] = None
    specialties: Optional[List[str]] = []
    is_verified: Optional[bool] = False
    rating: Optional[float] = 4.0

class DoctorCreateRequest(BaseModel):
    first_name: str
    last_name: str
    email: str
    phone: str
    specialization: str
    license_number: str
    years_experience: Optional[int] = 0
    rating: Optional[float] = 4.0
    bio: Optional[str] = None

class MedicalRecordVerificationRequest(BaseModel):
    is_verified: bool
    verification_notes: Optional[str] = None

class UserVerificationRequest(BaseModel):
    is_verified: bool

# Dashboard endpoint
@router.get("/dashboard")
async def get_dashboard_data(
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get comprehensive dashboard data"""
    
    # Get date ranges
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    
    # Users statistics
    total_users = db.query(User).count()
    new_users_30_days = db.query(User).filter(User.created_at >= thirty_days_ago).count()
    active_users = db.query(User).filter(User.is_active == True).count()
    
    # User types distribution
    user_types = {}
    for user_type in ['patient', 'sperm_donor', 'egg_donor', 'surrogate', 'hospital']:
        count = db.query(User).filter(User.user_type == user_type).count()
        user_types[user_type] = count
    
    # Hospitals statistics
    total_hospitals = db.query(Hospital).count()
    verified_hospitals = db.query(Hospital).filter(Hospital.is_verified == True).count()
    
    # Appointments statistics
    total_appointments = db.query(Appointment).count()
    new_appointments_30_days = db.query(Appointment).filter(Appointment.created_at >= thirty_days_ago).count()
    pending_appointments = db.query(Appointment).filter(Appointment.status == 'pending').count()
    confirmed_appointments = db.query(Appointment).filter(Appointment.status == 'confirmed').count()
    completed_appointments = db.query(Appointment).filter(Appointment.status == 'completed').count()
    
    # Payments statistics
    total_payments = db.query(Payment).count()
    successful_payments = db.query(Payment).filter(Payment.status == 'completed').count()
    total_revenue = db.query(Payment).filter(Payment.status == 'completed').with_entities(
        db.func.sum(Payment.amount)
    ).scalar() or 0
    success_rate = (successful_payments / total_payments * 100) if total_payments > 0 else 0
    
    return {
        "users": {
            "total": total_users,
            "new_last_30_days": new_users_30_days,
            "active": active_users,
            "by_type": user_types
        },
        "hospitals": {
            "total": total_hospitals,
            "verified": verified_hospitals
        },
        "appointments": {
            "total": total_appointments,
            "new_last_30_days": new_appointments_30_days,
            "pending": pending_appointments,
            "confirmed": confirmed_appointments,
            "completed": completed_appointments
        },
        "payments": {
            "total_revenue": float(total_revenue),
            "success_rate": success_rate,
            "total_transactions": total_payments
        }
    }

# Enhanced User Management
@router.get("/users/{user_id}")
async def get_user_details(
    user_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get detailed user information"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user

@router.put("/users/{user_id}")
async def update_user(
    user_id: int,
    user_data: UserUpdateRequest,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Update user information"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update fields that are provided
    update_data = user_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    
    user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(user)
    
    return {"message": "User updated successfully"}

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Delete user"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Delete related records first (appointments, payments, etc.)
    db.query(Appointment).filter(Appointment.user_id == user_id).delete()
    db.query(Payment).filter(Payment.user_id == user_id).delete()
    db.query(MedicalRecord).filter(MedicalRecord.user_id == user_id).delete()
    db.query(Notification).filter(Notification.user_id == user_id).delete()
    
    # Delete the user
    db.delete(user)
    db.commit()
    
    return {"message": "User deleted successfully"}

@router.post("/users/{user_id}/verify")
async def verify_user(
    user_id: int,
    verification_data: UserVerificationRequest,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Verify or unverify user"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_verified = verification_data.is_verified
    user.updated_at = datetime.utcnow()
    db.commit()
    
    return {"message": f"User {'verified' if verification_data.is_verified else 'unverified'} successfully"}

@router.post("/users/{user_id}/toggle-status")
async def toggle_user_status(
    user_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Toggle user active status"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_active = not user.is_active
    user.updated_at = datetime.utcnow()
    db.commit()
    
    return {"message": f"User status updated to {'active' if user.is_active else 'inactive'}"}

# Medical Records Management
@router.get("/users/{user_id}/medical-records")
async def get_user_medical_records(
    user_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get user's medical records"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    records = db.query(MedicalRecord).filter(MedicalRecord.user_id == user_id).all()
    return records

@router.post("/medical-records/{record_id}/verify")
async def verify_medical_record(
    record_id: int,
    verification_data: MedicalRecordVerificationRequest,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Verify or reject medical record"""
    record = db.query(MedicalRecord).filter(MedicalRecord.id == record_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Medical record not found")
    
    record.is_verified = verification_data.is_verified
    record.verified_by = current_admin.id
    record.verified_at = datetime.utcnow() if verification_data.is_verified else None
    record.verification_notes = verification_data.verification_notes
    record.updated_at = datetime.utcnow()
    
    db.commit()
    
    return {"message": f"Medical record {'verified' if verification_data.is_verified else 'rejected'} successfully"}

# Enhanced Hospital Management
@router.get("/hospitals/")
async def get_hospitals(
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all hospitals"""
    hospitals = db.query(Hospital).all()
    return hospitals

@router.post("/hospitals/")
async def create_hospital(
    hospital_data: HospitalCreateRequest,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Create new hospital"""
    
    # Check if hospital with same license number exists
    existing_hospital = db.query(Hospital).filter(
        Hospital.license_number == hospital_data.license_number
    ).first()
    if existing_hospital:
        raise HTTPException(status_code=400, detail="Hospital with this license number already exists")
    
    # Create new hospital
    hospital = Hospital(
        name=hospital_data.name,
        license_number=hospital_data.license_number,
        email=hospital_data.email,
        phone=hospital_data.phone,
        website=hospital_data.website,
        address=hospital_data.address,
        city=hospital_data.city,
        state=hospital_data.state,
        country=hospital_data.country,
        zip_code=hospital_data.postal_code,  # Map postal_code to zip_code
        description=hospital_data.description,
        services_offered=hospital_data.specialties,  # Map specialties to services_offered
        is_verified=hospital_data.is_verified,
        rating=hospital_data.rating,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    db.add(hospital)
    db.commit()
    db.refresh(hospital)
    
    return {"message": "Hospital created successfully", "hospital_id": hospital.id}

@router.put("/hospitals/{hospital_id}")
async def update_hospital(
    hospital_id: int,
    hospital_data: HospitalCreateRequest,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Update hospital information"""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found")
    
    # Update fields with proper mapping
    update_data = hospital_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        if field == 'postal_code':
            setattr(hospital, 'zip_code', value)  # Map postal_code to zip_code
        elif field == 'specialties':
            setattr(hospital, 'services_offered', value)  # Map specialties to services_offered
        else:
            setattr(hospital, field, value)
    
    hospital.updated_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Hospital updated successfully"}

@router.delete("/hospitals/{hospital_id}")
async def delete_hospital(
    hospital_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Delete hospital"""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found")
    
    # Delete related records first
    db.query(Appointment).filter(Appointment.hospital_id == hospital_id).delete()
    
    # Delete the hospital
    db.delete(hospital)
    db.commit()
    
    return {"message": "Hospital deleted successfully"}

@router.post("/hospitals/{hospital_id}/toggle-verification")
async def toggle_hospital_verification(
    hospital_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Toggle hospital verification status"""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found")
    
    hospital.is_verified = not hospital.is_verified
    hospital.updated_at = datetime.utcnow()
    db.commit()
    
    return {"message": f"Hospital {'verified' if hospital.is_verified else 'unverified'} successfully"}

# Doctor Management (simplified - assuming doctors are users with hospital type)
@router.get("/doctors/")
async def get_all_doctors(
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all doctors"""
    doctors = db.query(User).filter(User.user_type == 'hospital').all()
    return doctors

@router.get("/doctors/{doctor_id}")
async def get_doctor_details(
    doctor_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get detailed doctor information"""
    doctor = db.query(User).filter(User.id == doctor_id, User.user_type == 'hospital').first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    return doctor

@router.put("/doctors/{doctor_id}")
async def update_doctor(
    doctor_id: int,
    doctor_data: DoctorCreateRequest,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Update doctor information"""
    doctor = db.query(User).filter(User.id == doctor_id, User.user_type == 'hospital').first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # Update fields
    doctor.first_name = doctor_data.first_name
    doctor.last_name = doctor_data.last_name
    doctor.email = doctor_data.email
    doctor.phone = doctor_data.phone
    doctor.bio = doctor_data.bio
    doctor.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(doctor)
    
    return {"message": "Doctor updated successfully"}

@router.delete("/doctors/{doctor_id}")
async def delete_doctor(
    doctor_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Delete doctor"""
    doctor = db.query(User).filter(User.id == doctor_id, User.user_type == 'hospital').first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # Delete related records first
    db.query(Appointment).filter(Appointment.user_id == doctor_id).delete()
    db.query(MedicalRecord).filter(MedicalRecord.user_id == doctor_id).delete()
    db.query(Notification).filter(Notification.user_id == doctor_id).delete()
    
    # Delete the doctor
    db.delete(doctor)
    db.commit()
    
    return {"message": "Doctor deleted successfully"}

@router.get("/hospitals/{hospital_id}/doctors")
async def get_hospital_doctors(
    hospital_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get doctors for a specific hospital"""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found")
    
    # For now, return doctors associated with this hospital
    # This would need a proper doctor-hospital relationship table in a real implementation
    doctors = db.query(User).filter(
        User.user_type == 'hospital',
        User.email.like(f"%{hospital.email.split('@')[1]}")  # Simple association by domain
    ).all()
    
    return doctors

@router.post("/hospitals/{hospital_id}/doctors", status_code=201)
async def add_doctor_to_hospital(
    hospital_id: int,
    doctor_data: DoctorCreateRequest,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Add doctor to hospital"""
    from ..auth import get_password_hash
    
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found")
    
    # Check if doctor already exists
    existing_doctor = db.query(User).filter(User.email == doctor_data.email).first()
    if existing_doctor:
        raise HTTPException(status_code=400, detail="Doctor with this email already exists")
    
    # Create doctor as a user with a default password
    default_password = "doctor123"  # In production, generate a secure password and send via email
    doctor = User(
        first_name=doctor_data.first_name,
        last_name=doctor_data.last_name,
        email=doctor_data.email,
        password_hash=get_password_hash(default_password),
        phone=doctor_data.phone,
        user_type='hospital',  # Doctors are hospital type users
        is_active=True,
        is_verified=True,
        profile_completed=True,
        bio=doctor_data.bio,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    db.add(doctor)
    db.commit()
    db.refresh(doctor)
    
    return {"message": "Doctor added successfully", "doctor_id": doctor.id, "default_password": default_password}

@router.delete("/hospitals/{hospital_id}/doctors/{doctor_id}")
async def remove_doctor_from_hospital(
    hospital_id: int,
    doctor_id: int,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Remove doctor from hospital"""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found")
    
    doctor = db.query(User).filter(User.id == doctor_id, User.user_type == 'hospital').first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # In a real implementation, you would remove the association, not delete the user
    # For now, we'll just deactivate the doctor
    doctor.is_active = False
    doctor.updated_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Doctor removed from hospital successfully"}

# Additional endpoints for comprehensive admin functionality
@router.get("/appointments/all")
async def get_all_appointments(
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all appointments for admin view"""
    appointments = db.query(Appointment).all()
    return appointments

@router.get("/payments/all")
async def get_all_payments(
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all payments for admin view"""
    payments = db.query(Payment).all()
    return payments

@router.post("/notifications/broadcast")
async def send_broadcast_notification(
    title: str,
    message: str,
    user_type: Optional[str] = None,
    current_admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Send broadcast notification to users"""
    
    # Get target users
    query = db.query(User)
    if user_type:
        query = query.filter(User.user_type == user_type)
    
    users = query.all()
    
    # Create notifications for each user
    notifications = []
    for user in users:
        notification = Notification(
            user_id=user.id,
            title=title,
            message=message,
            is_read=False,
            created_at=datetime.utcnow()
        )
        notifications.append(notification)
    
    db.add_all(notifications)
    db.commit()
    
    return {"message": f"Broadcast notification sent to {len(users)} users"}
