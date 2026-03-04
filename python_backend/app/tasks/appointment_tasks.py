"""
Celery tasks for appointment management.
Handles appointment reminders and reservation cleanup.
"""
from datetime import datetime, timedelta
from typing import List
from celery import Task
from sqlalchemy.orm import Session

from app.celery_app import celery_app
from app.database import SessionLocal
from app.models import Appointment, AppointmentStatus, Notification, User


class DatabaseTask(Task):
    """Base task class that provides database session management."""
    
    _db: Session = None
    
    @property
    def db(self) -> Session:
        if self._db is None:
            self._db = SessionLocal()
        return self._db
    
    def after_return(self, *args, **kwargs):
        """Close database session after task completion."""
        if self._db is not None:
            self._db.close()
            self._db = None


def create_notification(db: Session, user_id: int, title: str, message: str, notification_type: str) -> Notification:
    """
    Create a notification for a user.
    
    Args:
        db: Database session
        user_id: User ID to send notification to
        title: Notification title
        message: Notification message
        notification_type: Type of notification
    
    Returns:
        Created Notification object
    """
    notification = Notification(
        user_id=user_id,
        title=title,
        message=message,
        notification_type=notification_type,
        is_read=False
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification


@celery_app.task(base=DatabaseTask, bind=True, name="app.tasks.appointment_tasks.send_24_hour_reminders")
def send_24_hour_reminders(self) -> dict:
    """
    Send reminder notifications for appointments happening in 24 hours.
    
    This task runs every hour and checks for appointments that:
    - Are confirmed
    - Have appointment_date between 23 and 24 hours from now
    - Haven't been sent a 24-hour reminder yet
    
    Returns:
        Dictionary with task execution results
    """
    db = self.db
    
    # Calculate time window: 23-24 hours from now
    now = datetime.utcnow()
    reminder_start = now + timedelta(hours=23)
    reminder_end = now + timedelta(hours=24)
    
    # Query appointments needing 24-hour reminders
    appointments = db.query(Appointment).filter(
        Appointment.status == AppointmentStatus.CONFIRMED,
        Appointment.appointment_date >= reminder_start,
        Appointment.appointment_date < reminder_end
    ).all()
    
    reminders_sent = 0
    errors = []
    
    for appointment in appointments:
        try:
            # Check if 24-hour reminder already sent
            existing_notification = db.query(Notification).filter(
                Notification.user_id == appointment.user_id,
                Notification.notification_type == "appointment_reminder_24h",
                Notification.message.like(f"%Appointment ID: {appointment.id}%")
            ).first()
            
            if existing_notification:
                continue  # Skip if already sent
            
            # Get user details
            user = db.query(User).filter(User.id == appointment.user_id).first()
            if not user:
                errors.append(f"User not found for appointment {appointment.id}")
                continue
            
            # Format appointment date
            appt_date = appointment.appointment_date.strftime("%B %d, %Y at %I:%M %p")
            
            # Create notification
            title = "Appointment Reminder - Tomorrow"
            message = (
                f"Hi {user.first_name}, this is a reminder that you have an appointment "
                f"tomorrow on {appt_date}. "
                f"Appointment ID: {appointment.id}"
            )
            
            create_notification(
                db=db,
                user_id=appointment.user_id,
                title=title,
                message=message,
                notification_type="appointment_reminder_24h"
            )
            
            reminders_sent += 1
            
        except Exception as e:
            errors.append(f"Error processing appointment {appointment.id}: {str(e)}")
            continue
    
    return {
        "task": "send_24_hour_reminders",
        "executed_at": now.isoformat(),
        "appointments_checked": len(appointments),
        "reminders_sent": reminders_sent,
        "errors": errors
    }


@celery_app.task(base=DatabaseTask, bind=True, name="app.tasks.appointment_tasks.send_1_hour_reminders")
def send_1_hour_reminders(self) -> dict:
    """
    Send reminder notifications for appointments happening in 1 hour.
    
    This task runs every 15 minutes and checks for appointments that:
    - Are confirmed
    - Have appointment_date between 45 minutes and 1 hour 15 minutes from now
    - Haven't been sent a 1-hour reminder yet
    
    Returns:
        Dictionary with task execution results
    """
    db = self.db
    
    # Calculate time window: 45 minutes to 1 hour 15 minutes from now
    now = datetime.utcnow()
    reminder_start = now + timedelta(minutes=45)
    reminder_end = now + timedelta(minutes=75)
    
    # Query appointments needing 1-hour reminders
    appointments = db.query(Appointment).filter(
        Appointment.status == AppointmentStatus.CONFIRMED,
        Appointment.appointment_date >= reminder_start,
        Appointment.appointment_date < reminder_end
    ).all()
    
    reminders_sent = 0
    errors = []
    
    for appointment in appointments:
        try:
            # Check if 1-hour reminder already sent
            existing_notification = db.query(Notification).filter(
                Notification.user_id == appointment.user_id,
                Notification.notification_type == "appointment_reminder_1h",
                Notification.message.like(f"%Appointment ID: {appointment.id}%")
            ).first()
            
            if existing_notification:
                continue  # Skip if already sent
            
            # Get user details
            user = db.query(User).filter(User.id == appointment.user_id).first()
            if not user:
                errors.append(f"User not found for appointment {appointment.id}")
                continue
            
            # Format appointment date
            appt_date = appointment.appointment_date.strftime("%B %d, %Y at %I:%M %p")
            
            # Create notification
            title = "Appointment Reminder - In 1 Hour"
            message = (
                f"Hi {user.first_name}, your appointment is coming up soon on {appt_date}. "
                f"Please make sure to arrive on time. "
                f"Appointment ID: {appointment.id}"
            )
            
            create_notification(
                db=db,
                user_id=appointment.user_id,
                title=title,
                message=message,
                notification_type="appointment_reminder_1h"
            )
            
            reminders_sent += 1
            
        except Exception as e:
            errors.append(f"Error processing appointment {appointment.id}: {str(e)}")
            continue
    
    return {
        "task": "send_1_hour_reminders",
        "executed_at": now.isoformat(),
        "appointments_checked": len(appointments),
        "reminders_sent": reminders_sent,
        "errors": errors
    }


@celery_app.task(base=DatabaseTask, bind=True, name="app.tasks.appointment_tasks.cleanup_expired_reservations")
def cleanup_expired_reservations(self) -> dict:
    """
    Clean up expired appointment reservations.
    
    This task runs every 5 minutes and:
    - Finds appointments with status PENDING and expired reserved_until
    - Cancels them to free up the time slots
    
    Returns:
        Dictionary with task execution results
    """
    db = self.db
    
    now = datetime.utcnow()
    
    # Query expired reservations
    expired_reservations = db.query(Appointment).filter(
        Appointment.status == AppointmentStatus.PENDING,
        Appointment.reserved_until.isnot(None),
        Appointment.reserved_until < now
    ).all()
    
    cleaned_up = 0
    errors = []
    
    for appointment in expired_reservations:
        try:
            # Cancel the expired reservation
            appointment.status = AppointmentStatus.CANCELLED
            appointment.cancellation_reason = "Reservation expired - not confirmed within 10 minutes"
            appointment.cancelled_at = now
            
            db.commit()
            cleaned_up += 1
            
        except Exception as e:
            db.rollback()
            errors.append(f"Error cleaning up appointment {appointment.id}: {str(e)}")
            continue
    
    return {
        "task": "cleanup_expired_reservations",
        "executed_at": now.isoformat(),
        "reservations_checked": len(expired_reservations),
        "cleaned_up": cleaned_up,
        "errors": errors
    }
