# Celery Background Tasks Setup

This document explains the Celery setup for background tasks in the Fertility Services Platform.

## Overview

Celery is used for:
- **Appointment Reminders**: Sending 24-hour and 1-hour reminders before appointments
- **Reservation Cleanup**: Automatically canceling expired appointment reservations
- **Future Tasks**: Email sending, report generation, data exports, etc.

## Architecture

```
┌─────────────────┐
│   FastAPI App   │
│                 │
│  (Web Server)   │
└────────┬────────┘
         │
         │ Queues tasks
         ▼
┌─────────────────┐      ┌──────────────┐
│  Redis Broker   │◄────►│ Celery Worker│
│                 │      │              │
│  (Task Queue)   │      │ (Processes)  │
└─────────────────┘      └──────┬───────┘
                                │
                                │ Executes
                                ▼
                         ┌──────────────┐
                         │   Database   │
                         │              │
                         │   (MySQL)    │
                         └──────────────┘
```

## Components

### 1. Celery App (`app/celery_app.py`)
- Configures Celery with Redis as broker and backend
- Defines beat schedule for periodic tasks
- Sets task execution parameters

### 2. Appointment Tasks (`app/tasks/appointment_tasks.py`)
Contains three main tasks:

#### `send_24_hour_reminders`
- **Schedule**: Runs every hour (at minute 0)
- **Purpose**: Sends reminders for appointments happening in 24 hours
- **Logic**: 
  - Queries confirmed appointments between 23-24 hours from now
  - Checks if reminder already sent (prevents duplicates)
  - Creates notification with appointment details
  - Tracks sent reminders and errors

#### `send_1_hour_reminders`
- **Schedule**: Runs every 15 minutes
- **Purpose**: Sends reminders for appointments happening in 1 hour
- **Logic**:
  - Queries confirmed appointments between 45-75 minutes from now
  - Checks if reminder already sent (prevents duplicates)
  - Creates notification with appointment details
  - Tracks sent reminders and errors

#### `cleanup_expired_reservations`
- **Schedule**: Runs every 5 minutes
- **Purpose**: Cancels expired appointment reservations
- **Logic**:
  - Queries pending appointments with expired `reserved_until`
  - Cancels them to free up time slots
  - Sets cancellation reason
  - Tracks cleaned up reservations

## Installation

### Prerequisites
1. **Redis Server**: Must be running
   ```bash
   # Install Redis (Ubuntu/Debian)
   sudo apt-get install redis-server
   
   # Start Redis
   sudo systemctl start redis
   
   # Check Redis status
   redis-cli ping  # Should return "PONG"
   ```

2. **Python Dependencies**: Already in `requirements.txt`
   ```
   celery==5.3.4
   redis==5.0.1
   ```

### Configuration

Add to `.env` file:
```env
# Redis Configuration
REDIS_URL=redis://localhost:6379
```

## Running Celery

### Option 1: Worker + Beat Combined (Development)
```bash
cd python_backend
celery -A app.celery_app worker --beat --loglevel=info
```

Or use the provided script:
```bash
chmod +x start_celery_worker.sh
./start_celery_worker.sh
```

### Option 2: Separate Worker and Beat (Production)

**Terminal 1 - Worker:**
```bash
cd python_backend
celery -A app.celery_app worker --loglevel=info
```

**Terminal 2 - Beat Scheduler:**
```bash
cd python_backend
celery -A app.celery_app beat --loglevel=info
```

Or use the provided scripts:
```bash
chmod +x start_celery_worker.sh start_celery_beat.sh
./start_celery_worker.sh  # Terminal 1
./start_celery_beat.sh    # Terminal 2
```

## Monitoring

### Check Task Status
```bash
# List active tasks
celery -A app.celery_app inspect active

# List scheduled tasks
celery -A app.celery_app inspect scheduled

# List registered tasks
celery -A app.celery_app inspect registered
```

### Celery Flower (Web UI)
Install and run Flower for monitoring:
```bash
pip install flower
celery -A app.celery_app flower
```
Access at: http://localhost:5555

## Task Execution Flow

### 24-Hour Reminder Flow
```
1. Celery Beat triggers task every hour
2. Task queries appointments 23-24 hours away
3. For each appointment:
   - Check if reminder already sent
   - Get user details
   - Create notification in database
   - Track success/failure
4. Return execution summary
```

### 1-Hour Reminder Flow
```
1. Celery Beat triggers task every 15 minutes
2. Task queries appointments 45-75 minutes away
3. For each appointment:
   - Check if reminder already sent
   - Get user details
   - Create notification in database
   - Track success/failure
4. Return execution summary
```

### Reservation Cleanup Flow
```
1. Celery Beat triggers task every 5 minutes
2. Task queries pending appointments with expired reserved_until
3. For each expired reservation:
   - Set status to CANCELLED
   - Set cancellation reason
   - Set cancelled_at timestamp
   - Commit to database
4. Return cleanup summary
```

## Testing Tasks Manually

You can trigger tasks manually for testing:

```python
from app.tasks.appointment_tasks import send_24_hour_reminders, send_1_hour_reminders, cleanup_expired_reservations

# Trigger 24-hour reminders
result = send_24_hour_reminders.delay()
print(result.get())

# Trigger 1-hour reminders
result = send_1_hour_reminders.delay()
print(result.get())

# Trigger cleanup
result = cleanup_expired_reservations.delay()
print(result.get())
```

Or use Celery CLI:
```bash
celery -A app.celery_app call app.tasks.appointment_tasks.send_24_hour_reminders
celery -A app.celery_app call app.tasks.appointment_tasks.send_1_hour_reminders
celery -A app.celery_app call app.tasks.appointment_tasks.cleanup_expired_reservations
```

## Production Deployment

### Using Supervisor (Linux)

Create `/etc/supervisor/conf.d/celery.conf`:
```ini
[program:celery_worker]
command=/path/to/venv/bin/celery -A app.celery_app worker --loglevel=info
directory=/path/to/python_backend
user=www-data
autostart=true
autorestart=true
stderr_logfile=/var/log/celery/worker.err.log
stdout_logfile=/var/log/celery/worker.out.log

[program:celery_beat]
command=/path/to/venv/bin/celery -A app.celery_app beat --loglevel=info
directory=/path/to/python_backend
user=www-data
autostart=true
autorestart=true
stderr_logfile=/var/log/celery/beat.err.log
stdout_logfile=/var/log/celery/beat.out.log
```

Reload supervisor:
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start celery_worker celery_beat
```

### Using Docker

Add to `docker-compose.yml`:
```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
  
  celery_worker:
    build: ./python_backend
    command: celery -A app.celery_app worker --loglevel=info
    depends_on:
      - redis
      - db
    environment:
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=mysql+pymysql://user:pass@db:3306/fertility_services
  
  celery_beat:
    build: ./python_backend
    command: celery -A app.celery_app beat --loglevel=info
    depends_on:
      - redis
      - db
    environment:
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=mysql+pymysql://user:pass@db:3306/fertility_services
```

## Troubleshooting

### Redis Connection Error
```
Error: Error 111 connecting to localhost:6379. Connection refused.
```
**Solution**: Start Redis server
```bash
sudo systemctl start redis
```

### Task Not Found
```
KeyError: 'app.tasks.appointment_tasks.send_24_hour_reminders'
```
**Solution**: Ensure task is imported in `celery_app.py` include list

### Database Connection Issues
**Solution**: Check database credentials in `.env` and ensure MySQL is running

### Tasks Not Executing
**Solution**: 
1. Check Celery worker is running
2. Check Celery beat is running
3. Check Redis is running
4. Check logs for errors

## Requirements Validation

This implementation satisfies:
- ✅ **Requirement 1.10**: Sends reminder notifications 24 hours and 1 hour before appointments
- ✅ **Requirement 4.4**: Sends appointment reminders at scheduled times
- ✅ Uses Celery for background task processing
- ✅ Integrates with notification service (creates Notification records)
- ✅ Prevents duplicate reminders
- ✅ Handles errors gracefully
- ✅ Provides execution summaries
- ✅ Cleans up expired reservations automatically

## Future Enhancements

1. **Email Integration**: Send email notifications in addition to in-app notifications
2. **SMS Integration**: Send SMS reminders via Twilio/Africa's Talking
3. **Push Notifications**: Integrate with FCM for mobile push notifications
4. **Retry Logic**: Add retry mechanism for failed notifications
5. **User Preferences**: Respect user notification preferences
6. **Analytics**: Track reminder delivery rates and effectiveness
7. **Custom Schedules**: Allow hospitals to configure reminder timing
8. **Multi-language**: Support multiple languages for notifications
