# Alembic Migrations

This directory contains database migration scripts for the Fertility Services Platform.

## Migration: 20260303162006_add_appointment_reservation_fields

### Purpose
Adds appointment reservation functionality to support the 10-minute time slot hold feature.

### Changes
1. **New Fields Added to `appointments` table:**
   - `reserved_until` (DateTime): Timestamp when the reservation expires (10 minutes from creation)
   - `cancellation_reason` (Text): Reason provided when an appointment is cancelled
   - `cancelled_at` (DateTime): Timestamp when the appointment was cancelled

2. **Status Enum Update:**
   - Added `no_show` status to the AppointmentStatus enum

3. **Indexes Created:**
   - `idx_user` on `user_id` - For fast user appointment lookups
   - `idx_hospital` on `hospital_id` - For fast hospital appointment lookups
   - `idx_date` on `appointment_date` - For date-based queries
   - `idx_status` on `status` - For filtering by appointment status
   - `idx_reserved` on `reserved_until` - For finding expired reservations

### How to Apply Migration

1. **Ensure database is running:**
   ```bash
   docker-compose up -d mysql
   ```

2. **Apply the migration:**
   ```bash
   cd python_backend
   alembic upgrade head
   ```

3. **Verify migration:**
   ```bash
   alembic current
   ```

### How to Rollback

If you need to rollback this migration:
```bash
alembic downgrade -1
```

### Requirements Addressed
- Requirement 1.1: Display available time slots
- Requirement 1.2: Reserve slot for 10 minutes
- Requirement 1.5: Prevent double-booking
- Requirement 1.11: Round-trip property for appointment serialization
