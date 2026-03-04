# Appointment Reminders Implementation

## Overview

This document describes the implementation of Task 1.6: Integrate appointment reminders with notification service.

## Implementation Summary

Successfully implemented a complete Celery-based background task system for appointment reminders that satisfies Requirement 1.10: "THE Appointment_System SHALL send reminder notifications 24 hours and 1 hour before appointments."

## Files Created

### 1. `app/celery_app.py`
**Purpose**: Celery application configuration and beat schedule

**Key Features**:
- Configures Celery with Redis as broker and backend
- Defines three periodic tasks with cron schedules:
  - `send-24-hour-reminders`: Runs every hour
  - `send-1-hour-reminders`: Runs every 15 minutes
  - `cleanup-expired-reservations`: Runs every 5 minutes
- Sets task execution parameters (timeouts, serialization, etc.)

### 2. `app/tasks/__init__.py`
**Purpose**: Package initialization for tasks module

### 3. `app/tasks/appointment_tasks.py`
**Purpose**: Celery tasks for appointment management

**Key Components**:

#### `DatabaseTask` Base Class
- Provides database session management for tasks
- Automatically closes sessions after task completion
- Prevents database connection leaks

#### `create_notification()` Helper Function
- Creates notification records in the database
- Used by reminder tasks to send notifications to users

#### `send_24_hour_reminders()` Task
- **Schedule**: Every hour (crontab: minute=0)
- **Logic**:
  1. Queries confirmed appointments 23-24 hours from now
  2. Checks if 24-hour reminder already sent (prevents duplicates)
  3. Creates notification with appointment details
  4. Returns execution summary with counts and errors
- **Notification Type**: `appointment_reminder_24h`
- **Duplicate Prevention**: Checks for existing notifications with same type and appointment ID

#### `send_1_hour_reminders()` Task
- **Schedule**: Every 15 minutes (crontab: minute="*/15")
- **Logic**:
  1. Queries confirmed appointments 45-75 minutes from now
  2. Checks if 1-hour reminder already sent (prevents duplicates)
  3. Creates notification with appointment details
  4. Returns execution summary with counts and errors
- **Notification Type**: `appointment_reminder_1h`
- **Duplicate Prevention**: Checks for existing notifications with same type and appointment ID

#### `cleanup_expired_reservations()` Task
- **Schedule**: Every 5 minutes (crontab: minute="*/5")
- **Logic**:
  1. Queries pending appointments with expired `reserved_until`
  2. Cancels them to free up time slots
  3. Sets cancellation reason and timestamp
  4. Returns cleanup summary with counts and errors
- **Purpose**: Implements the 10-minute reservation timeout from Requirement 1.2

### 4. `start_celery_worker.sh`
**Purpose**: Shell script to start Celery worker with beat scheduler

**Usage**:
```bash
chmod +x start_celery_worker.sh
./start_celery_worker.sh
```

### 5. `start_celery_beat.sh`
**Purpose**: Shell script to start Celery beat scheduler separately

**Usage** (for production with separate worker and beat):
```bash
chmod +x start_celery_beat.sh
./start_celery_beat.sh
```

### 6. `CELERY_SETUP.md`
**Purpose**: Comprehensive documentation for Celery setup

**Contents**:
- Architecture overview with diagrams
- Component descriptions
- Installation instructions
- Configuration guide
- Running instructions (development and production)
- Monitoring commands
- Task execution flow diagrams
- Manual testing instructions
- Production deployment guides (Supervisor, Docker)
- Troubleshooting section
- Requirements validation
- Future enhancements

### 7. `test_celery_tasks.py`
**Purpose**: Test script to verify Celery tasks work correctly

**Features**:
- Creates test appointments at appropriate times
- Tests 24-hour reminder task
- Tests 1-hour reminder task
- Tests expired reservation cleanup
- Verifies notifications were created
- Provides detailed output and next steps

**Usage**:
```bash
cd python_backend
python test_celery_tasks.py
```

## Technical Details

### Time Windows

#### 24-Hour Reminders
- **Window**: 23-24 hours before appointment
- **Reason**: Provides 1-hour buffer to catch appointments even if task runs slightly late
- **Example**: If task runs at 10:00 AM, it catches appointments between 9:00 AM and 10:00 AM tomorrow

#### 1-Hour Reminders
- **Window**: 45-75 minutes before appointment
- **Reason**: 15-minute buffer on each side to account for task execution every 15 minutes
- **Example**: If task runs at 10:00 AM, it catches appointments between 10:45 AM and 11:15 AM

### Duplicate Prevention

Both reminder tasks check for existing notifications before creating new ones:

```python
existing_notification = db.query(Notification).filter(
    Notification.user_id == appointment.user_id,
    Notification.notification_type == "appointment_reminder_24h",
    Notification.message.like(f"%Appointment ID: {appointment.id}%")
).first()

if existing_notification:
    continue  # Skip if already sent
```

This ensures:
- No duplicate reminders sent to users
- Idempotent task execution (safe to run multiple times)
- Efficient database queries

### Error Handling

All tasks implement robust error handling:
- Try-catch blocks around each appointment processing
- Errors collected in list and returned in summary
- Database rollback on errors
- Continues processing remaining appointments even if one fails

### Database Session Management

Uses custom `DatabaseTask` base class:
- Provides `self.db` property for database access
- Automatically closes session after task completion
- Prevents connection leaks
- Thread-safe session handling

## Integration with Notification Service

The implementation integrates with the existing notification system by:

1. **Creating Notification Records**: Uses the existing `Notification` model
2. **Notification Types**: Defines specific types for tracking:
   - `appointment_reminder_24h`
   - `appointment_reminder_1h`
3. **User Association**: Links notifications to users via `user_id`
4. **Message Format**: Includes user name, appointment date, and appointment ID
5. **Read Status**: Sets `is_read=False` for new notifications

## Requirements Validation

### ✅ Requirement 1.10
"THE Appointment_System SHALL send reminder notifications 24 hours and 1 hour before appointments"

**Implementation**:
- ✅ 24-hour reminders: `send_24_hour_reminders` task runs every hour
- ✅ 1-hour reminders: `send_1_hour_reminders` task runs every 15 minutes
- ✅ Notifications created in database for users to see
- ✅ Duplicate prevention ensures users don't get multiple reminders

### ✅ Task Requirements
"Implement scheduled task for 24-hour reminders"
- ✅ Implemented with Celery beat schedule

"Implement scheduled task for 1-hour reminders"
- ✅ Implemented with Celery beat schedule

"Queue reminder notifications using Celery"
- ✅ Uses Celery with Redis broker for task queuing

## Testing

### Manual Testing

1. **Create Test Appointments**:
   ```bash
   python test_celery_tasks.py
   ```

2. **Start Celery Worker**:
   ```bash
   celery -A app.celery_app worker --beat --loglevel=info
   ```

3. **Verify Notifications**:
   - Check `notifications` table in database
   - Look for `appointment_reminder_24h` and `appointment_reminder_1h` types

### Automated Testing

The `test_celery_tasks.py` script:
- Creates appointments at appropriate times
- Executes tasks manually
- Verifies notifications were created
- Provides detailed output

## Deployment

### Development
```bash
# Start worker with beat in one process
celery -A app.celery_app worker --beat --loglevel=info
```

### Production

**Option 1: Supervisor**
- See `CELERY_SETUP.md` for Supervisor configuration
- Runs worker and beat as separate processes
- Auto-restart on failure

**Option 2: Docker**
- See `CELERY_SETUP.md` for Docker Compose configuration
- Separate containers for worker and beat
- Scales horizontally

## Dependencies

### Required Services
- **Redis**: Task broker and result backend
- **MySQL**: Database for appointments and notifications

### Python Packages
- `celery==5.3.4`: Task queue framework
- `redis==5.0.1`: Redis client

## Configuration

### Environment Variables
```env
# Redis Configuration
REDIS_URL=redis://localhost:6379

# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=fertility_services
DB_USER=root
DB_PASSWORD=your_password
```

## Monitoring

### Celery Commands
```bash
# List active tasks
celery -A app.celery_app inspect active

# List scheduled tasks
celery -A app.celery_app inspect scheduled

# List registered tasks
celery -A app.celery_app inspect registered
```

### Celery Flower
```bash
pip install flower
celery -A app.celery_app flower
# Access at http://localhost:5555
```

## Future Enhancements

1. **Multi-Channel Notifications**:
   - Email notifications via SMTP
   - SMS notifications via Twilio/Africa's Talking
   - Push notifications via FCM

2. **User Preferences**:
   - Allow users to configure reminder timing
   - Opt-out of specific reminder types
   - Choose notification channels

3. **Retry Logic**:
   - Retry failed notifications
   - Exponential backoff
   - Dead letter queue for permanent failures

4. **Analytics**:
   - Track reminder delivery rates
   - Measure effectiveness (appointment show-up rates)
   - A/B test reminder timing

5. **Localization**:
   - Multi-language support
   - Timezone-aware reminders
   - Cultural customization

## Troubleshooting

### Common Issues

1. **Redis Connection Error**
   - Ensure Redis is running: `redis-cli ping`
   - Check REDIS_URL in .env

2. **Tasks Not Executing**
   - Verify Celery worker is running
   - Verify Celery beat is running
   - Check logs for errors

3. **Database Connection Issues**
   - Check database credentials in .env
   - Ensure MySQL is running
   - Verify database exists

4. **No Notifications Created**
   - Check if appointments exist in time window
   - Verify appointments are CONFIRMED status
   - Check task execution logs

## Conclusion

This implementation provides a robust, scalable solution for appointment reminders that:
- ✅ Meets all requirements
- ✅ Prevents duplicate notifications
- ✅ Handles errors gracefully
- ✅ Scales horizontally
- ✅ Provides monitoring capabilities
- ✅ Includes comprehensive documentation
- ✅ Includes testing tools

The system is production-ready and can be extended with additional features as needed.
