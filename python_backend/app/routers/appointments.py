from typing import List
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from ..database import get_db
from ..models import User, Appointment, Hospital, Service, Notification
from ..schemas import (
    AppointmentCreate, AppointmentUpdate, AppointmentResponse,
    AppointmentWithDetails, AppointmentFilterParams
)
from ..auth import get_current_active_user, get_admin_user, get_hospital_user

router = APIRouter()

@router.get("/test")
async def test_appointments_endpoint():
    """Test endpoint to verify appointments router is working."""
    return {"message": "Appointments router is working", "timestamp": datetime.now().isoformat()}

@router.post("/", response_model=AppointmentResponse)
async def create_appointment(
    appointment_data: AppointmentCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new appointment."""
    # Verify hospital exists and is verified
    hospital = db.query(Hospital).filter(
        Hospital.id == appointment_data.hospital_id,
        Hospital.is_verified == True
    ).first()
    
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found or not verified"
        )
    
    # Verify service exists and is active
    service = db.query(Service).filter(
        Service.id == appointment_data.service_id,
        Service.is_active == True
    ).first()
    
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found or not active"
        )
    
    # Check if appointment date is in the future
    if appointment_data.appointment_date <= datetime.now():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Appointment date must be in the future"
        )
    
    # Check for conflicting appointments (same user, same time)
    existing_appointment = db.query(Appointment).filter(
        Appointment.user_id == current_user.id,
        Appointment.appointment_date == appointment_data.appointment_date,
        Appointment.status.in_(["pending", "confirmed"])
    ).first()
    
    if existing_appointment:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have an appointment at this time"
        )
    
    # Create appointment
    db_appointment = Appointment(
        user_id=current_user.id,
        hospital_id=appointment_data.hospital_id,
        service_id=appointment_data.service_id,
        appointment_date=appointment_data.appointment_date,
        notes=appointment_data.notes,
        price=service.base_price
    )
    
    db.add(db_appointment)
    db.commit()
    db.refresh(db_appointment)
    
    # Create notification for hospital
    notification = Notification(
        user_id=hospital.user_id,
        title="New Appointment Request",
        message=f"New appointment request from {current_user.first_name} {current_user.last_name}",
        notification_type="appointment_request"
    )
    db.add(notification)
    db.commit()
    
    return db_appointment

@router.get("/my-appointments", response_model=List[AppointmentWithDetails])
async def get_my_appointments(
    status: str = None,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get current user's appointments."""
    try:
        query = db.query(Appointment).filter(Appointment.user_id == current_user.id)
        
        if status:
            query = query.filter(Appointment.status == status)
        
        appointments = query.order_by(Appointment.appointment_date.desc()).offset(skip).limit(limit).all()
        
        # Include related data
        result = []
        for appointment in appointments:
            try:
                hospital = db.query(Hospital).filter(Hospital.id == appointment.hospital_id).first()
                service = db.query(Service).filter(Service.id == appointment.service_id).first()
                user = db.query(User).filter(User.id == appointment.user_id).first()
                
                appointment_data = AppointmentWithDetails.model_validate(appointment)
                if hospital:
                    appointment_data.hospital = hospital
                if service:
                    appointment_data.service = service
                if user:
                    appointment_data.user = user
                    
                result.append(appointment_data)
            except Exception as e:
                print(f"Error processing appointment {appointment.id}: {str(e)}")
                # Skip this appointment if there's an error
                continue
        
        return result
    except Exception as e:
        print(f"Error in get_my_appointments: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch appointments: {str(e)}"
        )

@router.get("/hospital-appointments", response_model=List[AppointmentWithDetails])
async def get_hospital_appointments(
    status: str = None,
    date_from: datetime = None,
    date_to: datetime = None,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_hospital_user),
    db: Session = Depends(get_db)
):
    """Get appointments for current hospital."""
    # Get hospital for current user
    hospital = db.query(Hospital).filter(Hospital.user_id == current_user.id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    query = db.query(Appointment).filter(Appointment.hospital_id == hospital.id)
    
    if status:
        query = query.filter(Appointment.status == status)
    
    if date_from:
        query = query.filter(Appointment.appointment_date >= date_from)
    
    if date_to:
        query = query.filter(Appointment.appointment_date <= date_to)
    
    appointments = query.order_by(Appointment.appointment_date.asc()).offset(skip).limit(limit).all()
    
    # Include related data
    result = []
    for appointment in appointments:
        service = db.query(Service).filter(Service.id == appointment.service_id).first()
        user = db.query(User).filter(User.id == appointment.user_id).first()
        
        appointment_data = AppointmentWithDetails.model_validate(appointment)
        appointment_data.hospital = hospital
        if service:
            appointment_data.service = service
        if user:
            appointment_data.user = user
            
        result.append(appointment_data)
    
    return result

@router.get("/{appointment_id}", response_model=AppointmentWithDetails)
async def get_appointment_by_id(
    appointment_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get appointment by ID."""
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found"
        )
    
    # Check if user has access to this appointment
    hospital = db.query(Hospital).filter(Hospital.user_id == current_user.id).first()
    has_access = (
        appointment.user_id == current_user.id or  # User's own appointment
        (hospital and appointment.hospital_id == hospital.id) or  # Hospital's appointment
        current_user.user_type.value == "admin"  # Admin access
    )
    
    if not has_access:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this appointment"
        )
    
    # Get related data
    hospital_data = db.query(Hospital).filter(Hospital.id == appointment.hospital_id).first()
    service = db.query(Service).filter(Service.id == appointment.service_id).first()
    user = db.query(User).filter(User.id == appointment.user_id).first()
    
    appointment_data = AppointmentWithDetails.model_validate(appointment)
    if hospital_data:
        appointment_data.hospital = hospital_data
    if service:
        appointment_data.service = service
    if user:
        appointment_data.user = user
    
    return appointment_data

@router.put("/{appointment_id}", response_model=AppointmentResponse)
async def update_appointment(
    appointment_id: int,
    appointment_update: AppointmentUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update appointment."""
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found"
        )
    
    # Check permissions
    hospital = db.query(Hospital).filter(Hospital.user_id == current_user.id).first()
    can_update = (
        appointment.user_id == current_user.id or  # User's own appointment
        (hospital and appointment.hospital_id == hospital.id) or  # Hospital's appointment
        current_user.user_type.value == "admin"  # Admin access
    )
    
    if not can_update:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this appointment"
        )
    
    # Update appointment
    for field, value in appointment_update.dict(exclude_unset=True).items():
        setattr(appointment, field, value)
    
    db.commit()
    db.refresh(appointment)
    
    # Create notification based on status change
    if appointment_update.status:
        if appointment_update.status == "confirmed":
            notification = Notification(
                user_id=appointment.user_id,
                title="Appointment Confirmed",
                message="Your appointment has been confirmed",
                notification_type="appointment_confirmed"
            )
        elif appointment_update.status == "cancelled":
            notification = Notification(
                user_id=appointment.user_id,
                title="Appointment Cancelled",
                message="Your appointment has been cancelled",
                notification_type="appointment_cancelled"
            )
        else:
            notification = None
        
        if notification:
            db.add(notification)
            db.commit()
    
    return appointment

@router.delete("/{appointment_id}")
async def cancel_appointment(
    appointment_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Cancel appointment."""
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found"
        )
    
    # Check if user can cancel this appointment
    if appointment.user_id != current_user.id and current_user.user_type.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to cancel this appointment"
        )
    
    # Check if appointment can be cancelled (not in the past or already completed)
    if appointment.status in ["completed", "cancelled"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot cancel completed or already cancelled appointment"
        )
    
    appointment.status = "cancelled"
    db.commit()
    
    return {"message": "Appointment cancelled successfully"}

# Admin endpoints
@router.get("/admin/all", response_model=List[AppointmentWithDetails])
async def get_all_appointments(
    skip: int = 0,
    limit: int = 100,
    status: str = None,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all appointments (admin only)."""
    query = db.query(Appointment)
    
    if status:
        query = query.filter(Appointment.status == status)
    
    appointments = query.order_by(Appointment.created_at.desc()).offset(skip).limit(limit).all()
    
    # Include related data
    result = []
    for appointment in appointments:
        hospital = db.query(Hospital).filter(Hospital.id == appointment.hospital_id).first()
        service = db.query(Service).filter(Service.id == appointment.service_id).first()
        user = db.query(User).filter(User.id == appointment.user_id).first()
        
        appointment_data = AppointmentWithDetails.model_validate(appointment)
        if hospital:
            appointment_data.hospital = hospital
        if service:
            appointment_data.service = service
        if user:
            appointment_data.user = user
            
        result.append(appointment_data)
    
    return result

@router.get("/stats/overview")
async def get_appointment_stats(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get appointment statistics (admin only)."""
    total_appointments = db.query(Appointment).count()
    pending_appointments = db.query(Appointment).filter(Appointment.status == "pending").count()
    confirmed_appointments = db.query(Appointment).filter(Appointment.status == "confirmed").count()
    completed_appointments = db.query(Appointment).filter(Appointment.status == "completed").count()
    cancelled_appointments = db.query(Appointment).filter(Appointment.status == "cancelled").count()
    
    # Today's appointments
    today = datetime.now().date()
    today_appointments = db.query(Appointment).filter(
        Appointment.appointment_date >= today,
        Appointment.appointment_date < today + timedelta(days=1)
    ).count()
    
    return {
        "total_appointments": total_appointments,
        "pending_appointments": pending_appointments,
        "confirmed_appointments": confirmed_appointments,
        "completed_appointments": completed_appointments,
        "cancelled_appointments": cancelled_appointments,
        "today_appointments": today_appointments
    }
