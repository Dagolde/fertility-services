"""
Celery tasks for notification management.
Handles scheduled notifications, retry logic, and notification cleanup.
"""
from datetime import datetime, timedelta
from typing import List
from celery import Task
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.celery_app import celery_app
from app.database import SessionLocal
from app.models import (
    Notification, NotificationStatus, NotificationChannel,
    NotificationType, User
)
from app.services.notification_service import NotificationService


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


@celery_app.task(base=DatabaseTask, bind=True, name="app.tasks.notification_tasks.send_scheduled_notifications")
def send_scheduled_notifications(self) -> dict:
    """
    Send notifications that are scheduled to be sent now.
    
    This task runs every minute and checks for notifications that:
    - Have status PENDING
    - Have scheduled_at <= current time
    - Haven't exceeded retry limit
    
    Returns:
        Dictionary with task execution results
    """
    db = self.db
    now = datetime.utcnow()
    
    # Query scheduled notifications that are due
    scheduled_notifications = db.query(Notification).filter(
        Notification.status == NotificationStatus.PENDING,
        Notification.scheduled_at.isnot(None),
        Notification.scheduled_at <= now,
        Notification.retry_count < 3
    ).all()
    
    sent_count = 0
    failed_count = 0
    errors = []
    
    service = NotificationService(db)
    
    for notification in scheduled_notifications:
        try:
            # Get user
            user = db.query(User).filter(User.id == notification.user_id).first()
            if not user:
                errors.append(f"User not found for notification {notification.id}")
                notification.status = NotificationStatus.FAILED
                notification.failed_reason = "User not found"
                db.commit()
                failed_count += 1
                continue
            
            # Deliver notification
            import asyncio
            success = asyncio.run(service._deliver_notification(notification, user))
            
            if success:
                sent_count += 1
            else:
                failed_count += 1
                
        except Exception as e:
            errors.append(f"Error sending notification {notification.id}: {str(e)}")
            notification.status = NotificationStatus.FAILED
            notification.failed_reason = str(e)
            notification.retry_count += 1
            db.commit()
            failed_count += 1
            continue
    
    return {
        "task": "send_scheduled_notifications",
        "executed_at": now.isoformat(),
        "notifications_checked": len(scheduled_notifications),
        "sent": sent_count,
        "failed": failed_count,
        "errors": errors
    }


@celery_app.task(base=DatabaseTask, bind=True, name="app.tasks.notification_tasks.retry_failed_notifications")
def retry_failed_notifications(self) -> dict:
    """
    Retry failed notifications with exponential backoff.
    
    This task runs every 5 minutes and retries notifications that:
    - Have status FAILED
    - Haven't exceeded max retry count (3)
    - Have waited the appropriate backoff period
    
    Backoff schedule:
    - 1st retry: 1 minute after failure
    - 2nd retry: 2 minutes after failure
    - 3rd retry: 4 minutes after failure
    
    Returns:
        Dictionary with task execution results
    """
    db = self.db
    now = datetime.utcnow()
    
    # Query failed notifications eligible for retry
    failed_notifications = db.query(Notification).filter(
        Notification.status == NotificationStatus.FAILED,
        Notification.retry_count < 3
    ).all()
    
    retried_count = 0
    success_count = 0
    still_failed_count = 0
    errors = []
    
    service = NotificationService(db)
    
    for notification in failed_notifications:
        try:
            # Calculate backoff delay (exponential: 1min, 2min, 4min)
            backoff_minutes = 2 ** notification.retry_count
            next_retry = notification.updated_at + timedelta(minutes=backoff_minutes)
            
            # Skip if not ready for retry yet
            if now < next_retry:
                continue
            
            # Get user
            user = db.query(User).filter(User.id == notification.user_id).first()
            if not user:
                errors.append(f"User not found for notification {notification.id}")
                continue
            
            # Retry delivery
            import asyncio
            success = asyncio.run(service._deliver_notification(notification, user))
            
            retried_count += 1
            if success:
                success_count += 1
            else:
                still_failed_count += 1
                
        except Exception as e:
            errors.append(f"Error retrying notification {notification.id}: {str(e)}")
            notification.retry_count += 1
            db.commit()
            still_failed_count += 1
            continue
    
    return {
        "task": "retry_failed_notifications",
        "executed_at": now.isoformat(),
        "notifications_checked": len(failed_notifications),
        "retried": retried_count,
        "succeeded": success_count,
        "still_failed": still_failed_count,
        "errors": errors
    }


@celery_app.task(base=DatabaseTask, bind=True, name="app.tasks.notification_tasks.cleanup_old_notifications")
def cleanup_old_notifications(self) -> dict:
    """
    Clean up old read notifications to prevent database bloat.
    
    This task runs daily and deletes notifications that:
    - Have been read
    - Are older than 30 days
    
    Returns:
        Dictionary with task execution results
    """
    db = self.db
    now = datetime.utcnow()
    cutoff_date = now - timedelta(days=30)
    
    # Query old read notifications
    old_notifications = db.query(Notification).filter(
        Notification.is_read == True,
        Notification.created_at < cutoff_date
    ).all()
    
    deleted_count = 0
    errors = []
    
    for notification in old_notifications:
        try:
            db.delete(notification)
            deleted_count += 1
        except Exception as e:
            errors.append(f"Error deleting notification {notification.id}: {str(e)}")
            db.rollback()
            continue
    
    if deleted_count > 0:
        db.commit()
    
    return {
        "task": "cleanup_old_notifications",
        "executed_at": now.isoformat(),
        "notifications_checked": len(old_notifications),
        "deleted": deleted_count,
        "errors": errors
    }


@celery_app.task(base=DatabaseTask, bind=True, name="app.tasks.notification_tasks.send_appointment_reminder")
def send_appointment_reminder(self, appointment_id: int, reminder_type: str) -> dict:
    """
    Send appointment reminder notification.
    
    This is a helper task that can be called to send reminders for specific appointments.
    
    Args:
        appointment_id: ID of the appointment
        reminder_type: Type of reminder ('24h' or '1h')
    
    Returns:
        Dictionary with task execution results
    """
    from app.models import Appointment, Hospital
    
    db = self.db
    
    # Get appointment
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment:
        return {
            "success": False,
            "error": f"Appointment {appointment_id} not found"
        }
    
    # Get user
    user = db.query(User).filter(User.id == appointment.user_id).first()
    if not user:
        return {
            "success": False,
            "error": f"User {appointment.user_id} not found"
        }
    
    # Get hospital
    hospital = db.query(Hospital).filter(Hospital.id == appointment.hospital_id).first()
    hospital_name = hospital.name if hospital else "the hospital"
    
    # Determine notification type and context
    if reminder_type == "24h":
        notification_type = NotificationType.APPOINTMENT_REMINDER
        context = {
            "hospital_name": hospital_name,
            "appointment_date": appointment.appointment_date.strftime("%B %d, %Y at %I:%M %p")
        }
    elif reminder_type == "1h":
        notification_type = NotificationType.APPOINTMENT_REMINDER
        context = {
            "hospital_name": hospital_name,
            "appointment_date": appointment.appointment_date.strftime("%I:%M %p")
        }
    else:
        return {
            "success": False,
            "error": f"Invalid reminder type: {reminder_type}"
        }
    
    # Send notification via all enabled channels
    service = NotificationService(db)
    notifications_sent = []
    
    for channel in [NotificationChannel.PUSH, NotificationChannel.EMAIL, NotificationChannel.SMS]:
        try:
            import asyncio
            notification = asyncio.run(service.send_notification(
                user_id=user.id,
                notification_type=notification_type,
                channel=channel,
                context=context,
                metadata={"appointment_id": appointment_id, "reminder_type": reminder_type}
            ))
            if notification:
                notifications_sent.append({
                    "channel": channel.value,
                    "notification_id": notification.id,
                    "status": notification.status.value
                })
        except Exception as e:
            notifications_sent.append({
                "channel": channel.value,
                "error": str(e)
            })
    
    return {
        "success": True,
        "appointment_id": appointment_id,
        "reminder_type": reminder_type,
        "notifications_sent": notifications_sent
    }
