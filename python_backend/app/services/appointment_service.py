"""
Appointment Service Layer

Handles appointment booking, reservation, confirmation, rescheduling, and cancellation.
Implements 10-minute reservation timeout, double-booking prevention, and cache integration.
"""

from datetime import datetime, timedelta
from decimal import Decimal
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from sqlalchemy.exc import IntegrityError
import redis
import json
import logging

from ..models import (
    Appointment, AppointmentStatus, Service, Hospital, User, Payment, PaymentStatus
)
from ..database import get_db

logger = logging.getLogger(__name__)


class AppointmentService:
    """Service for managing appointments with reservation and caching."""
    
    def __init__(self, db: Session, redis_client: Optional[redis.Redis] = None):
        """
        Initialize appointment service.
        
        Args:
            db: Database session
            redis_client: Redis client for caching (optional)
        """
        self.db = db
        self.redis_client = redis_client
        self.RESERVATION_TIMEOUT_MINUTES = 10
        self.AVAILABILITY_CACHE_TTL = 30  # 30 seconds
        self.REFUND_FULL_HOURS = 24
        self.REFUND_PARTIAL_PERCENTAGE = 50
    
    def get_availability(
        self, 
        hospital_id: int, 
        date: datetime, 
        service_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Get available time slots for a hospital on a specific date.
        Uses Redis cache with 30-second TTL.
        
        Args:
            hospital_id: Hospital ID
            date: Date to check availability
            service_id: Optional service ID to filter by duration
            
        Returns:
            List of available time slots with format:
            [{"time": "09:00", "available": True, "duration_minutes": 60}, ...]
        """
        # Generate cache key
        date_str = date.strftime("%Y-%m-%d")
        cache_key = f"availability:{hospital_id}:{date_str}"
        if service_id:
            cache_key += f":{service_id}"
        
        # Try to get from cache
        if self.redis_client:
            try:
                cached_data = self.redis_client.get(cache_key)
                if cached_data:
                    logger.info(f"Cache hit for availability: {cache_key}")
                    return json.loads(cached_data)
            except Exception as e:
                logger.warning(f"Redis cache read error: {e}")
        
        # Get service duration if specified
        duration_minutes = 60  # Default
        if service_id:
            service = self.db.query(Service).filter(Service.id == service_id).first()
            if service:
                duration_minutes = service.duration_minutes
        
        # Generate time slots (9 AM to 5 PM, hourly)
        slots = []
        start_time = datetime.combine(date.date(), datetime.min.time().replace(hour=9))
        end_time = datetime.combine(date.date(), datetime.min.time().replace(hour=17))
        
        current_time = start_time
        while current_time < end_time:
            slot_time = current_time.strftime("%H:%M")
            
            # Check if slot is available (not booked or reserved)
            is_available = self._is_slot_available(
                hospital_id, current_time, duration_minutes
            )
            
            slots.append({
                "time": slot_time,
                "available": is_available,
                "duration_minutes": duration_minutes
            })
            
            current_time += timedelta(hours=1)
        
        # Cache the results
        if self.redis_client:
            try:
                self.redis_client.setex(
                    cache_key,
                    self.AVAILABILITY_CACHE_TTL,
                    json.dumps(slots)
                )
                logger.info(f"Cached availability: {cache_key}")
            except Exception as e:
                logger.warning(f"Redis cache write error: {e}")
        
        return slots
    
    def _is_slot_available(
        self, 
        hospital_id: int, 
        slot_time: datetime, 
        duration_minutes: int
    ) -> bool:
        """
        Check if a time slot is available (not booked or reserved).
        
        Args:
            hospital_id: Hospital ID
            slot_time: Start time of the slot
            duration_minutes: Duration of the appointment
            
        Returns:
            True if available, False otherwise
        """
        slot_end = slot_time + timedelta(minutes=duration_minutes)
        now = datetime.now()
        
        # Check for overlapping appointments
        overlapping = self.db.query(Appointment).filter(
            and_(
                Appointment.hospital_id == hospital_id,
                Appointment.appointment_date < slot_end,
                Appointment.appointment_date >= slot_time,
                or_(
                    # Confirmed or pending appointments
                    Appointment.status.in_([
                        AppointmentStatus.CONFIRMED,
                        AppointmentStatus.PENDING
                    ]),
                    # Active reservations (not expired)
                    and_(
                        Appointment.status == AppointmentStatus.PENDING,
                        Appointment.reserved_until > now
                    )
                )
            )
        ).first()
        
        return overlapping is None
    
    def reserve_slot(
        self,
        user_id: int,
        hospital_id: int,
        service_id: int,
        appointment_date: datetime,
        notes: Optional[str] = None
    ) -> Appointment:
        """
        Reserve a time slot for 10 minutes.
        Implements double-booking prevention using database locks.
        
        Args:
            user_id: User ID
            hospital_id: Hospital ID
            service_id: Service ID
            appointment_date: Appointment date and time
            notes: Optional notes
            
        Returns:
            Created appointment with reservation
            
        Raises:
            ValueError: If slot is not available or validation fails
        """
        # Validate inputs
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("User not found")
        
        hospital = self.db.query(Hospital).filter(Hospital.id == hospital_id).first()
        if not hospital:
            raise ValueError("Hospital not found")
        
        service = self.db.query(Service).filter(Service.id == service_id).first()
        if not service:
            raise ValueError("Service not found")
        
        # Use SELECT FOR UPDATE to prevent double-booking
        # Lock the time slot by checking for conflicts
        slot_end = appointment_date + timedelta(minutes=service.duration_minutes)
        now = datetime.now()
        
        # Check for conflicts with row-level locking
        conflicting_appointment = self.db.query(Appointment).filter(
            and_(
                Appointment.hospital_id == hospital_id,
                Appointment.appointment_date < slot_end,
                Appointment.appointment_date >= appointment_date,
                or_(
                    Appointment.status.in_([
                        AppointmentStatus.CONFIRMED,
                        AppointmentStatus.PENDING
                    ]),
                    and_(
                        Appointment.status == AppointmentStatus.PENDING,
                        Appointment.reserved_until > now
                    )
                )
            )
        ).with_for_update().first()
        
        if conflicting_appointment:
            raise ValueError("Time slot is no longer available")
        
        # Create reservation
        reserved_until = now + timedelta(minutes=self.RESERVATION_TIMEOUT_MINUTES)
        
        appointment = Appointment(
            user_id=user_id,
            hospital_id=hospital_id,
            service_id=service_id,
            appointment_date=appointment_date,
            status=AppointmentStatus.PENDING,
            notes=notes,
            price=service.price,
            reserved_until=reserved_until
        )
        
        try:
            self.db.add(appointment)
            self.db.commit()
            self.db.refresh(appointment)
            
            # Invalidate availability cache
            self._invalidate_availability_cache(hospital_id, appointment_date)
            
            logger.info(f"Reserved appointment {appointment.id} until {reserved_until}")
            return appointment
            
        except IntegrityError as e:
            self.db.rollback()
            logger.error(f"Database integrity error during reservation: {e}")
            raise ValueError("Failed to reserve slot due to conflict")
    
    def confirm_appointment(
        self,
        appointment_id: int,
        payment_id: int
    ) -> Appointment:
        """
        Confirm an appointment after successful payment.
        
        Args:
            appointment_id: Appointment ID
            payment_id: Payment ID
            
        Returns:
            Confirmed appointment
            
        Raises:
            ValueError: If appointment or payment is invalid
        """
        appointment = self.db.query(Appointment).filter(
            Appointment.id == appointment_id
        ).first()
        
        if not appointment:
            raise ValueError("Appointment not found")
        
        # Check if reservation is still valid
        if appointment.reserved_until and datetime.now() > appointment.reserved_until:
            raise ValueError("Reservation has expired")
        
        # Verify payment
        payment = self.db.query(Payment).filter(Payment.id == payment_id).first()
        if not payment or payment.status != PaymentStatus.COMPLETED:
            raise ValueError("Payment not completed")
        
        # Confirm appointment
        appointment.status = AppointmentStatus.CONFIRMED
        appointment.reserved_until = None  # Clear reservation
        
        try:
            self.db.commit()
            self.db.refresh(appointment)
            
            # Invalidate availability cache
            self._invalidate_availability_cache(
                appointment.hospital_id, 
                appointment.appointment_date
            )
            
            logger.info(f"Confirmed appointment {appointment.id}")
            return appointment
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error confirming appointment: {e}")
            raise ValueError("Failed to confirm appointment")
    
    def reschedule_appointment(
        self,
        appointment_id: int,
        new_date: datetime,
        user_id: int
    ) -> Appointment:
        """
        Reschedule an existing appointment.
        
        Args:
            appointment_id: Appointment ID
            new_date: New appointment date and time
            user_id: User ID (for authorization)
            
        Returns:
            Rescheduled appointment
            
        Raises:
            ValueError: If appointment not found or new slot unavailable
        """
        appointment = self.db.query(Appointment).filter(
            Appointment.id == appointment_id,
            Appointment.user_id == user_id
        ).first()
        
        if not appointment:
            raise ValueError("Appointment not found or unauthorized")
        
        if appointment.status == AppointmentStatus.CANCELLED:
            raise ValueError("Cannot reschedule cancelled appointment")
        
        if appointment.status == AppointmentStatus.COMPLETED:
            raise ValueError("Cannot reschedule completed appointment")
        
        # Get service for duration
        service = self.db.query(Service).filter(
            Service.id == appointment.service_id
        ).first()
        
        if not service:
            raise ValueError("Service not found")
        
        # Check if new slot is available
        if not self._is_slot_available(
            appointment.hospital_id, 
            new_date, 
            service.duration_minutes
        ):
            raise ValueError("New time slot is not available")
        
        # Update appointment
        old_date = appointment.appointment_date
        appointment.appointment_date = new_date
        
        try:
            self.db.commit()
            self.db.refresh(appointment)
            
            # Invalidate cache for both old and new dates
            self._invalidate_availability_cache(appointment.hospital_id, old_date)
            self._invalidate_availability_cache(appointment.hospital_id, new_date)
            
            logger.info(f"Rescheduled appointment {appointment.id} to {new_date}")
            return appointment
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error rescheduling appointment: {e}")
            raise ValueError("Failed to reschedule appointment")
    
    def cancel_appointment(
        self,
        appointment_id: int,
        user_id: int,
        reason: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Cancel an appointment and calculate refund.
        - 100% refund if cancelled >24 hours in advance
        - 50% refund if cancelled <24 hours in advance
        
        Args:
            appointment_id: Appointment ID
            user_id: User ID (for authorization)
            reason: Cancellation reason
            
        Returns:
            Dictionary with appointment and refund information
            
        Raises:
            ValueError: If appointment not found or already cancelled
        """
        appointment = self.db.query(Appointment).filter(
            Appointment.id == appointment_id,
            Appointment.user_id == user_id
        ).first()
        
        if not appointment:
            raise ValueError("Appointment not found or unauthorized")
        
        if appointment.status == AppointmentStatus.CANCELLED:
            raise ValueError("Appointment already cancelled")
        
        if appointment.status == AppointmentStatus.COMPLETED:
            raise ValueError("Cannot cancel completed appointment")
        
        # Calculate refund
        now = datetime.now()
        hours_until_appointment = (appointment.appointment_date - now).total_seconds() / 3600
        
        refund_percentage = 100 if hours_until_appointment > self.REFUND_FULL_HOURS else self.REFUND_PARTIAL_PERCENTAGE
        refund_amount = (appointment.price * Decimal(refund_percentage)) / Decimal(100)
        
        # Update appointment
        appointment.status = AppointmentStatus.CANCELLED
        appointment.cancellation_reason = reason
        appointment.cancelled_at = now
        
        try:
            self.db.commit()
            self.db.refresh(appointment)
            
            # Invalidate availability cache
            self._invalidate_availability_cache(
                appointment.hospital_id, 
                appointment.appointment_date
            )
            
            logger.info(
                f"Cancelled appointment {appointment.id}, "
                f"refund: {refund_percentage}% = {refund_amount}"
            )
            
            return {
                "appointment": appointment,
                "refund": {
                    "amount": float(refund_amount),
                    "percentage": refund_percentage,
                    "status": "processing"
                }
            }
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error cancelling appointment: {e}")
            raise ValueError("Failed to cancel appointment")
    
    def get_user_appointments(
        self,
        user_id: int,
        status: Optional[AppointmentStatus] = None,
        include_past: bool = True
    ) -> List[Appointment]:
        """
        Get appointments for a user.
        
        Args:
            user_id: User ID
            status: Optional status filter
            include_past: Whether to include past appointments
            
        Returns:
            List of appointments
        """
        query = self.db.query(Appointment).filter(Appointment.user_id == user_id)
        
        if status:
            query = query.filter(Appointment.status == status)
        
        if not include_past:
            query = query.filter(Appointment.appointment_date >= datetime.now())
        
        return query.order_by(Appointment.appointment_date.desc()).all()
    
    def cleanup_expired_reservations(self) -> int:
        """
        Clean up expired reservations (for scheduled task).
        
        Returns:
            Number of reservations cleaned up
        """
        now = datetime.now()
        
        expired_appointments = self.db.query(Appointment).filter(
            and_(
                Appointment.status == AppointmentStatus.PENDING,
                Appointment.reserved_until < now
            )
        ).all()
        
        count = 0
        for appointment in expired_appointments:
            appointment.status = AppointmentStatus.CANCELLED
            appointment.cancellation_reason = "Reservation expired"
            appointment.cancelled_at = now
            count += 1
            
            # Invalidate cache
            self._invalidate_availability_cache(
                appointment.hospital_id,
                appointment.appointment_date
            )
        
        if count > 0:
            try:
                self.db.commit()
                logger.info(f"Cleaned up {count} expired reservations")
            except Exception as e:
                self.db.rollback()
                logger.error(f"Error cleaning up reservations: {e}")
                return 0
        
        return count
    
    def _invalidate_availability_cache(self, hospital_id: int, date: datetime) -> None:
        """
        Invalidate availability cache for a hospital and date.
        
        Args:
            hospital_id: Hospital ID
            date: Date to invalidate
        """
        if not self.redis_client:
            return
        
        try:
            date_str = date.strftime("%Y-%m-%d")
            # Delete all cache keys for this hospital and date
            pattern = f"availability:{hospital_id}:{date_str}*"
            
            # Use scan_iter to find and delete matching keys
            for key in self.redis_client.scan_iter(match=pattern):
                self.redis_client.delete(key)
            
            logger.info(f"Invalidated availability cache for hospital {hospital_id} on {date_str}")
            
        except Exception as e:
            logger.warning(f"Error invalidating cache: {e}")


def get_redis_client() -> Optional[redis.Redis]:
    """
    Get Redis client for caching.
    
    Returns:
        Redis client or None if connection fails
    """
    try:
        from decouple import config
        
        redis_host = config("REDIS_HOST", default="localhost")
        redis_port = config("REDIS_PORT", default=6379, cast=int)
        redis_db = config("REDIS_DB", default=0, cast=int)
        
        client = redis.Redis(
            host=redis_host,
            port=redis_port,
            db=redis_db,
            decode_responses=True,
            socket_connect_timeout=5
        )
        
        # Test connection
        client.ping()
        logger.info("Redis connection established")
        return client
        
    except Exception as e:
        logger.warning(f"Redis connection failed: {e}. Continuing without cache.")
        return None
