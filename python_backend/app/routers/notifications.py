"""
Notification API Endpoints

Provides endpoints for managing user notifications and preferences.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field

from app.database import get_db
from app.auth import get_current_user
from app.models import (
    User, Notification, NotificationPreferences,
    NotificationChannel, NotificationType, NotificationStatus
)
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/api/v1/notifications", tags=["notifications"])


# Pydantic schemas
class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    notification_type: str
    channel: str
    status: str
    is_read: bool
    read_at: Optional[datetime]
    created_at: datetime
    data: Optional[dict]
    
    class Config:
        from_attributes = True


class NotificationPreferenceResponse(BaseModel):
    id: int
    channel: str
    notification_type: str
    enabled: bool
    
    class Config:
        from_attributes = True


class UpdatePreferenceRequest(BaseModel):
    channel: NotificationChannel
    notification_type: NotificationType
    enabled: bool


class SendTestNotificationRequest(BaseModel):
    user_id: int
    notification_type: NotificationType
    channel: NotificationChannel
    title: str
    message: str


@router.get("", response_model=List[NotificationResponse])
async def list_notifications(
    skip: int = 0,
    limit: int = 50,
    unread_only: bool = False,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get list of user notifications
    
    - **skip**: Number of records to skip (pagination)
    - **limit**: Maximum number of records to return
    - **unread_only**: Filter to show only unread notifications
    """
    query = db.query(Notification).filter(Notification.user_id == current_user.id)
    
    if unread_only:
        query = query.filter(Notification.is_read == False)
    
    notifications = query.order_by(Notification.created_at.desc()).offset(skip).limit(limit).all()
    
    return notifications


@router.get("/unread-count")
async def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get count of unread notifications"""
    count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).count()
    
    return {"unread_count": count}


@router.put("/{notification_id}/read")
async def mark_as_read(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a notification as read"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    
    notification.is_read = True
    notification.read_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Notification marked as read"}


@router.put("/mark-all-read")
async def mark_all_as_read(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark all notifications as read"""
    db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).update({
        "is_read": True,
        "read_at": datetime.utcnow()
    })
    db.commit()
    
    return {"message": "All notifications marked as read"}


@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a notification"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    
    db.delete(notification)
    db.commit()
    
    return {"message": "Notification deleted"}


@router.get("/preferences", response_model=List[NotificationPreferenceResponse])
async def get_preferences(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's notification preferences"""
    service = NotificationService(db)
    preferences = service.get_user_preferences(current_user.id)
    return preferences


@router.put("/preferences")
async def update_preferences(
    request: UpdatePreferenceRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update notification preference for a specific channel and type"""
    service = NotificationService(db)
    
    preference = service.update_preferences(
        user_id=current_user.id,
        channel=request.channel,
        notification_type=request.notification_type,
        enabled=request.enabled
    )
    
    return {
        "message": "Preference updated successfully",
        "preference": {
            "channel": preference.channel.value,
            "notification_type": preference.notification_type.value,
            "enabled": preference.enabled
        }
    }


@router.post("/test")
async def send_test_notification(
    request: SendTestNotificationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Send a test notification (admin only)
    
    This endpoint is for testing notification delivery.
    """
    # Check if user is admin
    if current_user.user_type.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can send test notifications"
        )
    
    service = NotificationService(db)
    
    notification = await service.send_notification(
        user_id=request.user_id,
        notification_type=request.notification_type,
        channel=request.channel,
        title=request.title,
        message=request.message
    )
    
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to send notification (user may have disabled this notification type)"
        )
    
    return {
        "message": "Test notification sent",
        "notification_id": notification.id,
        "status": notification.status.value
    }
