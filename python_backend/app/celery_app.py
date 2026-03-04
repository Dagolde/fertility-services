"""
Celery application configuration for background tasks.
"""
from celery import Celery
from celery.schedules import crontab
from decouple import config

# Get Redis URL from environment
REDIS_URL = config("REDIS_URL", default="redis://localhost:6379")

# Create Celery app
celery_app = Celery(
    "fertility_services",
    broker=REDIS_URL,
    backend=REDIS_URL,
    include=["app.tasks.appointment_tasks"]
)

# Celery configuration
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 minutes
    task_soft_time_limit=25 * 60,  # 25 minutes
    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,
)

# Celery Beat schedule for periodic tasks
celery_app.conf.beat_schedule = {
    # Check for appointments needing 24-hour reminders every hour
    "send-24-hour-reminders": {
        "task": "app.tasks.appointment_tasks.send_24_hour_reminders",
        "schedule": crontab(minute=0),  # Every hour at minute 0
    },
    # Check for appointments needing 1-hour reminders every 15 minutes
    "send-1-hour-reminders": {
        "task": "app.tasks.appointment_tasks.send_1_hour_reminders",
        "schedule": crontab(minute="*/15"),  # Every 15 minutes
    },
    # Clean up expired reservations every 5 minutes
    "cleanup-expired-reservations": {
        "task": "app.tasks.appointment_tasks.cleanup_expired_reservations",
        "schedule": crontab(minute="*/5"),  # Every 5 minutes
    },
}
