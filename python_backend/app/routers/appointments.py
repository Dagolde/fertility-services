"""
Appointment API Endpoints

Implements appointment booking, reservation, confirmation, rescheduling, and cancellation.
Follows the design specification for Requirements 1.1, 1.2, 1.3, 1.7.
"""

from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, Appointment, Hospital, Service, AppointmentStatus
from ..schemas import (
    AppointmentReserveRequest, AppointmentReserveResponse,
    AppointmentConfirmRequest, AppointmentConfirmResponse,
    AppointmentResponse, AppointmentWithDetails,
    AppointmentRescheduleRequest, AppointmentCancelRequest,
    AppointmentCancelResponse, AvailabilityResponse, TimeSlot
)
from ..auth import get_current_active_user, get_admin_user, get_hospital_user
from ..services.appointment_service import AppointmentService, get_redis_client
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


def get_appointment_service(db: Session = Depends(get_db)) -> AppointmentService:
    """Dependency to get appointment service instance."""
    redis_client = get_redis_client()
    return AppointmentService(db, redis_client)


@router.post("/reserve", response_model=AppointmentReserveResponse, status_code=status.HTTP_201_CREATED)
async def reserve_appointment(
    request: AppointmentReserveRequest,
    current_user: User = Depends(get_current_active_user),
    appointment_service: AppointmentService = Depends(get_appointment_service)
):
    """
    Reserve a time slot for 10 minutes.
    
    Requirements: 1.2 - Reserve slot for 10 minutes
    
    Args:
        request: Reservation request with hospital_id, service_id, appointment_date
        current_user: Authenticated user
        appointment_service: Appointment service instance
        
    Returns:
        Reservation details with expiration time
        
    Raises:
        HTTPException: If slot is unavailable or validation fails
    """
    try:
        appointment = appointment_service.reserve_slot(
            user_id=current_user.id,
            hospital_id=request.hospital_id,
            service_id=request.service_id,
            appointment_date=request.appointment_date,
            notes=request.notes
        )
        
        return AppointmentReserveResponse(
            reservation_id=f"res_{appointment.id}",
            expires_at=appointment.reserved_until,
            appointment=AppointmentResponse.model_validate(appointment)
        )
        
    except ValueError as e:
        logger.error(f"Reservation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error during reservation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to reserve appointment"
        )


@router.post("/confirm", response_model=AppointmentConfirmResponse)
async def confirm_appointment(
    request: AppointmentConfirmRequest,
    current_user: User = Depends(get_current_active_user),
    appointment_service: AppointmentService = Depends(get_appointment_service),
    db: Session = Depends(get_db)
):
    """
    Confirm appointment with payment.
    
    Requirements: 1.3, 1.4 - Confirm appointment and process payment
    
    Args:
        request: Confirmation request with reservation_id and payment_method
        current_user: Authenticated user
        appointment_service: Appointment service instance
        db: Database session
        
    Returns:
        Confirmed appointment with payment details
        
    Raises:
        HTTPException: If reservation expired or payment fails
    """
    try:
        # Extract appointment ID from reservation_id
        if not request.reservation_id.startswith("res_"):
            raise ValueError("Invalid reservation ID format")
        
        appointment_id = int(request.reservation_id.replace("res_", ""))
        
        # Get appointment
        appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
        if not appointment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reservation not found"
            )
        
        # Verify ownership
        if appointment.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to confirm this reservation"
            )
        
        # For now, create a mock payment (actual payment integration would happen here)
        # In production, this would call the payment service
        from ..models import Payment, PaymentStatus, PaymentGateway
        
        payment = Payment(
            user_id=current_user.id,
            appointment_id=appointment.id,
            amount=appointment.price,
            currency="NGN",
            payment_gateway=PaymentGateway.PAYSTACK,
            payment_method=request.payment_method,
            transaction_id=f"txn_{appointment.id}_{datetime.now().timestamp()}",
            status=PaymentStatus.COMPLETED,
            payment_date=datetime.now()
        )
        
        db.add(payment)
        db.commit()
        db.refresh(payment)
        
        # Confirm appointment
        confirmed_appointment = appointment_service.confirm_appointment(
            appointment_id=appointment.id,
            payment_id=payment.id
        )
        
        # Generate payment URL (mock for now)
        payment_url = f"https://checkout.paystack.com/mock_{payment.transaction_id}"
        
        return AppointmentConfirmResponse(
            appointment=AppointmentResponse.model_validate(confirmed_appointment),
            payment={
                "payment_url": payment_url,
                "reference": payment.transaction_id,
                "payment_id": payment.id,
                "amount": float(payment.amount),
                "currency": payment.currency
            }
        )
        
    except ValueError as e:
        logger.error(f"Confirmation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error during confirmation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to confirm appointment"
        )


@router.get("", response_model=List[AppointmentResponse])
async def list_user_appointments(
    status_filter: Optional[str] = Query(None, alias="status"),
    current_user: User = Depends(get_current_active_user),
    appointment_service: AppointmentService = Depends(get_appointment_service)
):
    """
    List user appointments with optional status filter.
    
    Requirements: 1.7 - View appointments
    
    Args:
        status_filter: Optional status filter (pending, confirmed, completed, cancelled)
        current_user: Authenticated user
        appointment_service: Appointment service instance
        
    Returns:
        List of user appointments
    """
    try:
        # Parse status if provided
        appointment_status = None
        if status_filter:
            try:
                appointment_status = AppointmentStatus[status_filter.upper()]
            except KeyError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid status: {status_filter}"
                )
        
        appointments = appointment_service.get_user_appointments(
            user_id=current_user.id,
            status=appointment_status,
            include_past=True
        )
        
        return [AppointmentResponse.model_validate(apt) for apt in appointments]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing appointments: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve appointments"
        )


@router.put("/{id}/reschedule", response_model=AppointmentResponse)
async def reschedule_appointment(
    id: int,
    request: AppointmentRescheduleRequest,
    current_user: User = Depends(get_current_active_user),
    appointment_service: AppointmentService = Depends(get_appointment_service)
):
    """
    Reschedule an existing appointment.
    
    Requirements: 1.7 - Reschedule appointments
    
    Args:
        id: Appointment ID
        request: Reschedule request with new_date
        current_user: Authenticated user
        appointment_service: Appointment service instance
        
    Returns:
        Updated appointment
        
    Raises:
        HTTPException: If appointment not found or new slot unavailable
    """
    try:
        appointment = appointment_service.reschedule_appointment(
            appointment_id=id,
            new_date=request.new_date,
            user_id=current_user.id
        )
        
        return AppointmentResponse.model_validate(appointment)
        
    except ValueError as e:
        logger.error(f"Reschedule error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error during rescheduling: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to reschedule appointment"
        )


@router.delete("/{id}", response_model=AppointmentCancelResponse)
async def cancel_appointment(
    id: int,
    request: AppointmentCancelRequest,
    current_user: User = Depends(get_current_active_user),
    appointment_service: AppointmentService = Depends(get_appointment_service)
):
    """
    Cancel an appointment with refund calculation.
    
    Requirements: 1.7, 1.8, 1.9 - Cancel appointments with refund
    - 100% refund if cancelled >24 hours in advance
    - 50% refund if cancelled <24 hours in advance
    
    Args:
        id: Appointment ID
        request: Cancellation request with optional reason
        current_user: Authenticated user
        appointment_service: Appointment service instance
        
    Returns:
        Cancellation confirmation with refund details
        
    Raises:
        HTTPException: If appointment not found or already cancelled
    """
    try:
        result = appointment_service.cancel_appointment(
            appointment_id=id,
            user_id=current_user.id,
            reason=request.reason
        )
        
        return AppointmentCancelResponse(
            message="Appointment cancelled successfully",
            refund=result["refund"]
        )
        
    except ValueError as e:
        logger.error(f"Cancellation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error during cancellation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to cancel appointment"
        )


@router.get("/hospitals/{id}/availability", response_model=AvailabilityResponse)
async def get_hospital_availability(
    id: int,
    date: str = Query(..., description="Date in YYYY-MM-DD format"),
    service_id: Optional[int] = Query(None, description="Optional service ID"),
    appointment_service: AppointmentService = Depends(get_appointment_service),
    db: Session = Depends(get_db)
):
    """
    Get available time slots for a hospital on a specific date.
    
    Requirements: 1.1 - Display available time slots
    
    Args:
        id: Hospital ID
        date: Date in YYYY-MM-DD format
        service_id: Optional service ID to filter by duration
        appointment_service: Appointment service instance
        db: Database session
        
    Returns:
        Available time slots for the date
        
    Raises:
        HTTPException: If hospital not found or date invalid
    """
    try:
        # Verify hospital exists
        hospital = db.query(Hospital).filter(Hospital.id == id).first()
        if not hospital:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hospital not found"
            )
        
        # Parse date
        try:
            date_obj = datetime.strptime(date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid date format. Use YYYY-MM-DD"
            )
        
        # Get availability
        slots = appointment_service.get_availability(
            hospital_id=id,
            date=date_obj,
            service_id=service_id
        )
        
        return AvailabilityResponse(
            date=date,
            slots=[TimeSlot(**slot) for slot in slots]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting availability: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve availability"
        )


# Additional endpoints for compatibility with existing code

@router.get("/my-appointments", response_model=List[AppointmentWithDetails])
async def get_my_appointments(
    status_filter: Optional[str] = Query(None, alias="status"),
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get current user's appointments with full details (legacy endpoint)."""
    try:
        query = db.query(Appointment).filter(Appointment.user_id == current_user.id)
        
        if status_filter:
            query = query.filter(Appointment.status == status_filter)
        
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
                logger.warning(f"Error processing appointment {appointment.id}: {e}")
                continue
        
        return result
    except Exception as e:
        logger.error(f"Error in get_my_appointments: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch appointments: {str(e)}"
        )


@router.get("/{appointment_id}", response_model=AppointmentWithDetails)
async def get_appointment_by_id(
    appointment_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get appointment by ID with authorization check."""
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found"
        )
    
    # Check if user has access to this appointment
    hospital = db.query(Hospital).filter(Hospital.user_id == current_user.id).first()
    has_access = (
        appointment.user_id == current_user.id or
        (hospital and appointment.hospital_id == hospital.id) or
        current_user.user_type.value == "admin"
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


# Admin endpoints

@router.get("/admin/all", response_model=List[AppointmentWithDetails])
async def get_all_appointments(
    skip: int = 0,
    limit: int = 100,
    status_filter: Optional[str] = Query(None, alias="status"),
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all appointments (admin only)."""
    query = db.query(Appointment)
    
    if status_filter:
        query = query.filter(Appointment.status == status_filter)
    
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
    from datetime import timedelta
    
    total_appointments = db.query(Appointment).count()
    pending_appointments = db.query(Appointment).filter(Appointment.status == AppointmentStatus.PENDING).count()
    confirmed_appointments = db.query(Appointment).filter(Appointment.status == AppointmentStatus.CONFIRMED).count()
    completed_appointments = db.query(Appointment).filter(Appointment.status == AppointmentStatus.COMPLETED).count()
    cancelled_appointments = db.query(Appointment).filter(Appointment.status == AppointmentStatus.CANCELLED).count()
    
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
