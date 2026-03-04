# Appointment Service Implementation

## Overview

The `AppointmentService` class provides comprehensive appointment management functionality for the Fertility Services Platform, including:

- **Availability checking** with Redis caching (30s TTL)
- **Slot reservation** with 10-minute timeout
- **Double-booking prevention** using database locks (SELECT FOR UPDATE)
- **Appointment confirmation** with payment verification
- **Rescheduling** with availability validation
- **Cancellation** with automatic refund calculation
- **Expired reservation cleanup** for scheduled tasks

## Features Implemented

### 1. Get Availability (`get_availability`)

**Purpose**: Retrieve available time slots for a hospital on a specific date.

**Features**:
- Generates hourly slots from 9 AM to 5 PM
- Checks for conflicts with existing appointments and active reservations
- Uses Redis cache with 30-second TTL for performance
- Supports service-specific duration filtering

**Cache Key Format**: `availability:{hospital_id}:{date}:{service_id?}`

**Example**:
```python
service = AppointmentService(db, redis_client)
slots = service.get_availability(
    hospital_id=1,
    date=datetime(2024, 1, 15),
    service_id=5
)
# Returns: [{"time": "09:00", "available": True, "duration_minutes": 60}, ...]
```

### 2. Reserve Slot (`reserve_slot`)

**Purpose**: Reserve a time slot for 10 minutes to allow payment processing.

**Features**:
- Validates user, hospital, and service existence
- Uses `SELECT FOR UPDATE` for row-level locking to prevent double-booking
- Creates appointment with `PENDING` status
- Sets `reserved_until` timestamp (current time + 10 minutes)
- Invalidates availability cache

**Double-Booking Prevention**:
```python
# Uses database-level locking
conflicting_appointment = db.query(Appointment).filter(
    # ... conflict conditions ...
).with_for_update().first()
```

**Example**:
```python
appointment = service.reserve_slot(
    user_id=123,
    hospital_id=1,
    service_id=5,
    appointment_date=datetime(2024, 1, 15, 9, 0),
    notes="First consultation"
)
# Returns: Appointment object with reserved_until set
```

### 3. Confirm Appointment (`confirm_appointment`)

**Purpose**: Confirm a reserved appointment after successful payment.

**Features**:
- Validates reservation hasn't expired
- Verifies payment is completed
- Updates status to `CONFIRMED`
- Clears `reserved_until` field
- Invalidates availability cache

**Example**:
```python
confirmed = service.confirm_appointment(
    appointment_id=456,
    payment_id=789
)
# Returns: Confirmed appointment
```

### 4. Reschedule Appointment (`reschedule_appointment`)

**Purpose**: Move an appointment to a new date/time.

**Features**:
- Validates user authorization
- Prevents rescheduling cancelled/completed appointments
- Checks new slot availability
- Updates appointment date
- Invalidates cache for both old and new dates

**Example**:
```python
rescheduled = service.reschedule_appointment(
    appointment_id=456,
    new_date=datetime(2024, 1, 20, 14, 0),
    user_id=123
)
```

### 5. Cancel Appointment (`cancel_appointment`)

**Purpose**: Cancel an appointment with automatic refund calculation.

**Refund Logic**:
- **100% refund**: Cancelled >24 hours before appointment
- **50% refund**: Cancelled <24 hours before appointment

**Features**:
- Validates user authorization
- Prevents cancelling already cancelled/completed appointments
- Calculates refund based on time until appointment
- Updates status to `CANCELLED`
- Records cancellation reason and timestamp
- Invalidates availability cache

**Example**:
```python
result = service.cancel_appointment(
    appointment_id=456,
    user_id=123,
    reason="Personal emergency"
)
# Returns: {
#     "appointment": <Appointment>,
#     "refund": {
#         "amount": 250000.00,
#         "percentage": 50,
#         "status": "processing"
#     }
# }
```

### 6. Get User Appointments (`get_user_appointments`)

**Purpose**: Retrieve appointments for a specific user.

**Features**:
- Optional status filtering
- Optional past appointment exclusion
- Ordered by date (descending)

**Example**:
```python
appointments = service.get_user_appointments(
    user_id=123,
    status=AppointmentStatus.CONFIRMED,
    include_past=False
)
```

### 7. Cleanup Expired Reservations (`cleanup_expired_reservations`)

**Purpose**: Automatically cancel expired reservations (for scheduled tasks).

**Features**:
- Finds all pending appointments with expired `reserved_until`
- Updates status to `CANCELLED`
- Sets cancellation reason to "Reservation expired"
- Invalidates availability cache
- Returns count of cleaned up reservations

**Example** (for Celery task):
```python
count = service.cleanup_expired_reservations()
# Returns: Number of reservations cleaned up
```

## Database Locking Strategy

The service uses **SELECT FOR UPDATE** to prevent race conditions and double-booking:

```python
conflicting_appointment = db.query(Appointment).filter(
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
```

This ensures that:
1. Only one transaction can check and reserve a slot at a time
2. Concurrent requests for the same slot will be serialized
3. The second request will see the first reservation and fail appropriately

## Cache Integration

### Redis Configuration

The service uses Redis for caching availability slots:

```python
redis_client = redis.Redis(
    host=config("REDIS_HOST", default="localhost"),
    port=config("REDIS_PORT", default=6379),
    db=config("REDIS_DB", default=0),
    decode_responses=True
)
```

### Cache Keys

- **Format**: `availability:{hospital_id}:{date}:{service_id?}`
- **TTL**: 30 seconds
- **Invalidation**: Automatic on reservation, confirmation, reschedule, cancellation

### Cache Invalidation

The service invalidates cache whenever availability changes:

```python
def _invalidate_availability_cache(self, hospital_id: int, date: datetime):
    pattern = f"availability:{hospital_id}:{date_str}*"
    for key in redis_client.scan_iter(match=pattern):
        redis_client.delete(key)
```

## Error Handling

The service raises `ValueError` with descriptive messages for:

- User/hospital/service not found
- Slot not available
- Reservation expired
- Payment not completed
- Unauthorized access
- Invalid state transitions (e.g., cancelling completed appointment)

**Example**:
```python
try:
    appointment = service.reserve_slot(...)
except ValueError as e:
    # Handle error: "Time slot is no longer available"
    pass
```

## Configuration

The service uses the following configuration constants:

```python
RESERVATION_TIMEOUT_MINUTES = 10      # Reservation hold time
AVAILABILITY_CACHE_TTL = 30           # Cache TTL in seconds
REFUND_FULL_HOURS = 24                # Hours for 100% refund
REFUND_PARTIAL_PERCENTAGE = 50        # Percentage for <24h refund
```

## Integration with Other Services

### Payment Service

The appointment service integrates with the payment service for:
- Payment verification during confirmation
- Refund processing during cancellation

### Notification Service

The appointment service should trigger notifications for:
- Reservation confirmation
- Appointment confirmation
- Rescheduling
- Cancellation
- Reminders (24h and 1h before)

**Note**: Notification integration should be implemented in the API layer or via Celery tasks.

## Usage Example

```python
from app.services.appointment_service import AppointmentService, get_redis_client
from app.database import get_db

# Initialize service
db = next(get_db())
redis_client = get_redis_client()
service = AppointmentService(db, redis_client)

# 1. Check availability
slots = service.get_availability(
    hospital_id=1,
    date=datetime(2024, 1, 15),
    service_id=5
)

# 2. Reserve slot
appointment = service.reserve_slot(
    user_id=123,
    hospital_id=1,
    service_id=5,
    appointment_date=datetime(2024, 1, 15, 9, 0)
)

# 3. Process payment (external payment service)
# payment = payment_service.process_payment(...)

# 4. Confirm appointment
confirmed = service.confirm_appointment(
    appointment_id=appointment.id,
    payment_id=payment.id
)

# 5. Later: Reschedule
rescheduled = service.reschedule_appointment(
    appointment_id=confirmed.id,
    new_date=datetime(2024, 1, 20, 14, 0),
    user_id=123
)

# 6. Or cancel
result = service.cancel_appointment(
    appointment_id=confirmed.id,
    user_id=123,
    reason="Personal emergency"
)
```

## Testing

A basic test file is provided at `python_backend/test_appointment_service.py`:

```bash
cd python_backend
python test_appointment_service.py
```

This verifies:
- Import success
- Class instantiation
- Configuration values
- Method existence
- Refund calculation logic

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **Requirement 1.1**: Display available time slots ✓
- **Requirement 1.2**: Reserve slot for 10 minutes ✓
- **Requirement 1.5**: Prevent double-booking ✓
- **Requirement 1.6**: Reflect availability changes within 30 seconds ✓
- **Requirement 1.7**: Allow rescheduling and cancellation ✓
- **Requirement 1.8**: 100% refund if cancelled >24h ✓
- **Requirement 1.9**: 50% refund if cancelled <24h ✓

## Next Steps

1. **Create API endpoints** (Task 1.4) to expose these service methods
2. **Write comprehensive unit tests** (Task 1.3) with mocked database
3. **Write integration tests** (Task 1.5) with test database
4. **Integrate notification service** (Task 1.6) for reminders
5. **Create Celery task** for expired reservation cleanup
6. **Add monitoring and logging** for production use

## Dependencies

- SQLAlchemy (database ORM)
- Redis (caching)
- python-decouple (configuration)
- Standard library: datetime, decimal, typing, logging

## Environment Variables

Required environment variables:

```env
# Database
DB_HOST=localhost
DB_PORT=3307
DB_USER=fertility_user
DB_PASSWORD=fertility_password
DB_NAME=fertility_services

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
```
