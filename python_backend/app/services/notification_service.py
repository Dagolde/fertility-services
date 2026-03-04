"""
Notification Service Layer

Handles multi-channel notification delivery (Push, Email, SMS),
notification templating, retry logic, and user preference management.
"""

from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_
import logging
from abc import ABC, abstractmethod

from app.models import (
    Notification, NotificationPreferences, NotificationStatus,
    NotificationChannel, NotificationType, User
)

logger = logging.getLogger(__name__)


class NotificationChannelAdapter(ABC):
    """Abstract base class for notification channel adapters"""
    
    @abstractmethod
    async def send(self, recipient: str, title: str, message: str, metadata: Dict[str, Any]) -> bool:
        """Send notification through this channel"""
        pass
    
    @abstractmethod
    def supports_rich_content(self) -> bool:
        """Check if channel supports rich content (images, buttons, etc.)"""
        pass


class PushNotificationChannel(NotificationChannelAdapter):
    """FCM Push Notification Channel"""
    
    def __init__(self):
        # TODO: Initialize FCM client
        pass
    
    async def send(self, recipient: str, title: str, message: str, metadata: Dict[str, Any]) -> bool:
        """Send push notification via FCM"""
        try:
            # TODO: Implement FCM push notification
            logger.info(f"Sending push notification to {recipient}: {title}")
            return True
        except Exception as e:
            logger.error(f"Failed to send push notification: {str(e)}")
            return False
    
    def supports_rich_content(self) -> bool:
        return True


class EmailChannel(NotificationChannelAdapter):
    """Email Notification Channel"""
    
    def __init__(self):
        # TODO: Initialize SMTP/SendGrid client
        pass
    
    async def send(self, recipient: str, title: str, message: str, metadata: Dict[str, Any]) -> bool:
        """Send email notification"""
        try:
            # TODO: Implement email sending
            logger.info(f"Sending email to {recipient}: {title}")
            return True
        except Exception as e:
            logger.error(f"Failed to send email: {str(e)}")
            return False
    
    def supports_rich_content(self) -> bool:
        return True


class SMSChannel(NotificationChannelAdapter):
    """SMS Notification Channel"""
    
    def __init__(self):
        # TODO: Initialize Twilio/Africa's Talking client
        pass
    
    async def send(self, recipient: str, title: str, message: str, metadata: Dict[str, Any]) -> bool:
        """Send SMS notification"""
        try:
            # TODO: Implement SMS sending
            logger.info(f"Sending SMS to {recipient}: {message}")
            return True
        except Exception as e:
            logger.error(f"Failed to send SMS: {str(e)}")
            return False
    
    def supports_rich_content(self) -> bool:
        return False


class NotificationTemplate:
    """Notification templates for common events"""
    
    TEMPLATES = {
        NotificationType.APPOINTMENT_CONFIRMATION: {
            "title": "Appointment Confirmed",
            "message": "Your appointment at {hospital_name} on {appointment_date} has been confirmed."
        },
        NotificationType.APPOINTMENT_REMINDER: {
            "title": "Appointment Reminder",
            "message": "Reminder: You have an appointment at {hospital_name} on {appointment_date}."
        },
        NotificationType.APPOINTMENT_CANCELLED: {
            "title": "Appointment Cancelled",
            "message": "Your appointment at {hospital_name} on {appointment_date} has been cancelled."
        },
        NotificationType.APPOINTMENT_RESCHEDULED: {
            "title": "Appointment Rescheduled",
            "message": "Your appointment has been rescheduled to {appointment_date} at {hospital_name}."
        },
        NotificationType.PAYMENT_CONFIRMATION: {
            "title": "Payment Confirmed",
            "message": "Your payment of {amount} {currency} has been confirmed."
        },
        NotificationType.PAYMENT_REFUND: {
            "title": "Refund Processed",
            "message": "A refund of {amount} {currency} has been processed to your account."
        },
        NotificationType.MESSAGE_RECEIVED: {
            "title": "New Message",
            "message": "You have a new message from {sender_name}."
        },
        NotificationType.REVIEW_RESPONSE: {
            "title": "Hospital Responded to Your Review",
            "message": "{hospital_name} has responded to your review."
        },
    }
    
    @classmethod
    def render(cls, notification_type: NotificationType, context: Dict[str, Any]) -> Dict[str, str]:
        """Render notification template with context data"""
        template = cls.TEMPLATES.get(notification_type)
        if not template:
            return {"title": "Notification", "message": "You have a new notification"}
        
        try:
            return {
                "title": template["title"].format(**context),
                "message": template["message"].format(**context)
            }
        except KeyError as e:
            logger.error(f"Missing template context key: {e}")
            return template


class NotificationService:
    """Service for managing notifications"""
    
    def __init__(self, db: Session):
        self.db = db
        self.channels = {
            NotificationChannel.PUSH: PushNotificationChannel(),
            NotificationChannel.EMAIL: EmailChannel(),
            NotificationChannel.SMS: SMSChannel(),
        }
    
    async def send_notification(
        self,
        user_id: int,
        notification_type: NotificationType,
        channel: NotificationChannel,
        context: Optional[Dict[str, Any]] = None,
        title: Optional[str] = None,
        message: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Notification:
        """
        Send a notification to a user through specified channel
        
        Args:
            user_id: ID of the user to notify
            notification_type: Type of notification
            channel: Delivery channel (push, email, sms)
            context: Template context data
            title: Custom title (overrides template)
            message: Custom message (overrides template)
            metadata: Additional metadata to store
        
        Returns:
            Notification object
        """
        # Check user preferences
        if not self._check_user_preference(user_id, notification_type, channel):
            logger.info(f"User {user_id} has disabled {notification_type} notifications on {channel}")
            return None
        
        # Get user details
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError(f"User {user_id} not found")
        
        # Render template if title/message not provided
        if not title or not message:
            rendered = NotificationTemplate.render(notification_type, context or {})
            title = title or rendered["title"]
            message = message or rendered["message"]
        
        # Create notification record
        notification = Notification(
            user_id=user_id,
            title=title,
            message=message,
            notification_type=notification_type,
            channel=channel,
            status=NotificationStatus.PENDING,
            data=metadata or {}
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        
        # Send notification
        success = await self._deliver_notification(notification, user)
        
        return notification
    
    async def send_bulk_notifications(
        self,
        user_ids: List[int],
        notification_type: NotificationType,
        channel: NotificationChannel,
        context: Optional[Dict[str, Any]] = None,
        title: Optional[str] = None,
        message: Optional[str] = None
    ) -> List[Notification]:
        """Send notifications to multiple users"""
        notifications = []
        for user_id in user_ids:
            try:
                notification = await self.send_notification(
                    user_id=user_id,
                    notification_type=notification_type,
                    channel=channel,
                    context=context,
                    title=title,
                    message=message
                )
                if notification:
                    notifications.append(notification)
            except Exception as e:
                logger.error(f"Failed to send notification to user {user_id}: {str(e)}")
        
        return notifications
    
    def schedule_notification(
        self,
        user_id: int,
        notification_type: NotificationType,
        channel: NotificationChannel,
        send_at: datetime,
        context: Optional[Dict[str, Any]] = None,
        title: Optional[str] = None,
        message: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Notification:
        """Schedule a notification to be sent at a specific time"""
        # Render template if title/message not provided
        if not title or not message:
            rendered = NotificationTemplate.render(notification_type, context or {})
            title = title or rendered["title"]
            message = message or rendered["message"]
        
        # Create scheduled notification
        notification = Notification(
            user_id=user_id,
            title=title,
            message=message,
            notification_type=notification_type,
            channel=channel,
            status=NotificationStatus.PENDING,
            scheduled_at=send_at,
            data=metadata or {}
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        
        return notification
    
    def get_user_preferences(self, user_id: int) -> List[NotificationPreferences]:
        """Get user's notification preferences"""
        return self.db.query(NotificationPreferences).filter(
            NotificationPreferences.user_id == user_id
        ).all()
    
    def update_preferences(
        self,
        user_id: int,
        channel: NotificationChannel,
        notification_type: NotificationType,
        enabled: bool
    ) -> NotificationPreferences:
        """Update user's notification preference for a specific channel and type"""
        # Check if preference exists
        preference = self.db.query(NotificationPreferences).filter(
            and_(
                NotificationPreferences.user_id == user_id,
                NotificationPreferences.channel == channel,
                NotificationPreferences.notification_type == notification_type
            )
        ).first()
        
        if preference:
            preference.enabled = enabled
            preference.updated_at = datetime.utcnow()
        else:
            preference = NotificationPreferences(
                user_id=user_id,
                channel=channel,
                notification_type=notification_type,
                enabled=enabled
            )
            self.db.add(preference)
        
        self.db.commit()
        self.db.refresh(preference)
        return preference
    
    async def retry_failed_notifications(self, max_retries: int = 3) -> int:
        """Retry failed notifications with exponential backoff"""
        failed_notifications = self.db.query(Notification).filter(
            and_(
                Notification.status == NotificationStatus.FAILED,
                Notification.retry_count < max_retries
            )
        ).all()
        
        retry_count = 0
        for notification in failed_notifications:
            # Calculate backoff delay (exponential: 1min, 2min, 4min)
            backoff_minutes = 2 ** notification.retry_count
            next_retry = notification.updated_at + timedelta(minutes=backoff_minutes)
            
            if datetime.utcnow() >= next_retry:
                user = self.db.query(User).filter(User.id == notification.user_id).first()
                if user:
                    success = await self._deliver_notification(notification, user)
                    if success:
                        retry_count += 1
        
        return retry_count
    
    def _check_user_preference(
        self,
        user_id: int,
        notification_type: NotificationType,
        channel: NotificationChannel
    ) -> bool:
        """Check if user has enabled this notification type on this channel"""
        preference = self.db.query(NotificationPreferences).filter(
            and_(
                NotificationPreferences.user_id == user_id,
                NotificationPreferences.channel == channel,
                NotificationPreferences.notification_type == notification_type
            )
        ).first()
        
        # If no preference set, default to enabled (except marketing)
        if not preference:
            return notification_type != NotificationType.MARKETING
        
        return preference.enabled
    
    async def _deliver_notification(self, notification: Notification, user: User) -> bool:
        """Deliver notification through the appropriate channel"""
        channel_adapter = self.channels.get(notification.channel)
        if not channel_adapter:
            logger.error(f"Unknown notification channel: {notification.channel}")
            notification.status = NotificationStatus.FAILED
            notification.failed_reason = f"Unknown channel: {notification.channel}"
            self.db.commit()
            return False
        
        # Determine recipient based on channel
        recipient = self._get_recipient(user, notification.channel)
        if not recipient:
            logger.error(f"No recipient found for user {user.id} on channel {notification.channel}")
            notification.status = NotificationStatus.FAILED
            notification.failed_reason = f"No recipient for channel {notification.channel}"
            self.db.commit()
            return False
        
        # Send notification
        try:
            success = await channel_adapter.send(
                recipient=recipient,
                title=notification.title,
                message=notification.message,
                metadata=notification.data or {}
            )
            
            if success:
                notification.status = NotificationStatus.SENT
                notification.sent_at = datetime.utcnow()
            else:
                notification.status = NotificationStatus.FAILED
                notification.retry_count += 1
                notification.failed_reason = "Channel delivery failed"
            
            self.db.commit()
            return success
            
        except Exception as e:
            logger.error(f"Error delivering notification {notification.id}: {str(e)}")
            notification.status = NotificationStatus.FAILED
            notification.retry_count += 1
            notification.failed_reason = str(e)
            self.db.commit()
            return False
    
    def _get_recipient(self, user: User, channel: NotificationChannel) -> Optional[str]:
        """Get recipient identifier based on channel"""
        if channel == NotificationChannel.EMAIL:
            return user.email
        elif channel == NotificationChannel.SMS:
            return user.phone
        elif channel == NotificationChannel.PUSH:
            # TODO: Get FCM token from user profile or separate table
            return f"fcm_token_{user.id}"  # Placeholder
        return None
