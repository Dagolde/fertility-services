# Review Model Implementation

## Overview

This document describes the implementation of the Review database model and migration for Task 8.1 of the Fertility Services Platform.

## Requirements Addressed

- **Requirement 3.1**: Allow Patients to submit reviews only for hospitals where they have completed appointments
- **Requirement 3.2**: Require a rating between 1 and 5 stars and optional text comment
- **Requirement 3.7**: Prevent Patients from submitting multiple reviews for the same appointment
- **Requirement 3.11**: Maintain review immutability after 48 hours of submission

## Implementation Details

### 1. Review Model (`app/models.py`)

Created a new `Review` model with the following fields:

#### Core Fields
- `id`: Primary key (Integer)
- `user_id`: Foreign key to users table (Integer, NOT NULL)
- `hospital_id`: Foreign key to hospitals table (Integer, NOT NULL, indexed)
- `appointment_id`: Foreign key to appointments table (Integer, NOT NULL)
- `rating`: Review rating 1-5 (Integer, NOT NULL)
- `comment`: Optional review text (Text, max 1000 characters)

#### Moderation Fields
- `is_flagged`: Flag for inappropriate content (Boolean, default False, indexed)
- `flag_count`: Number of times flagged (Integer, default 0)
- `is_hidden`: Hide from public view (Boolean, default False)

#### Hospital Response Fields
- `hospital_response`: Hospital's response to review (Text, max 500 characters)
- `hospital_response_date`: Timestamp of hospital response (DateTime)

#### Immutability Fields
- `is_immutable`: Whether review can be edited (Boolean, default False)
- `immutable_after`: Timestamp when review becomes immutable (DateTime, 48 hours after creation)

#### Timestamps
- `created_at`: Record creation timestamp (DateTime, auto-generated)
- `updated_at`: Record update timestamp (DateTime, auto-updated)

### 2. Validation Methods

The Review model includes three validation methods:

#### `validate_rating()`
Ensures rating is between 1 and 5 (inclusive).
```python
def validate_rating(self):
    if self.rating is not None and (self.rating < 1 or self.rating > 5):
        raise ValueError("Rating must be between 1 and 5")
```

#### `validate_comment_length()`
Ensures comment does not exceed 1000 characters.
```python
def validate_comment_length(self):
    if self.comment is not None and len(self.comment) > 1000:
        raise ValueError("Comment must not exceed 1000 characters")
```

#### `validate_hospital_response_length()`
Ensures hospital response does not exceed 500 characters.
```python
def validate_hospital_response_length(self):
    if self.hospital_response is not None and len(self.hospital_response) > 500:
        raise ValueError("Hospital response must not exceed 500 characters")
```

### 3. Database Constraints

#### Unique Constraint
- `unique_review_per_appointment`: Ensures one review per (user_id, appointment_id) pair
- Prevents duplicate reviews for the same appointment (Requirement 3.7)

#### Check Constraint
- `check_rating_range`: Database-level constraint ensuring rating is between 1 and 5

#### Foreign Keys
- `fk_reviews_user_id`: References users.id
- `fk_reviews_hospital_id`: References hospitals.id
- `fk_reviews_appointment_id`: References appointments.id

### 4. Indexes

Created indexes for query performance:
- `idx_hospital_id`: For filtering reviews by hospital
- `idx_rating`: For filtering reviews by rating
- `idx_is_flagged`: For finding flagged reviews (moderation)

### 5. Relationships

#### Review Model Relationships
- `user`: Many-to-one relationship with User model
- `hospital`: Many-to-one relationship with Hospital model
- `appointment`: One-to-one relationship with Appointment model

#### Updated Related Models
- **User model**: Added `reviews` relationship (one-to-many)
- **Hospital model**: Added `reviews` relationship (one-to-many) and `total_reviews` field
- **Appointment model**: Added `review` relationship (one-to-one)

### 6. Migration (`alembic/versions/20260303180000_create_reviews_table.py`)

The migration script:
1. Creates the `reviews` table with all fields
2. Adds foreign key constraints
3. Creates the unique constraint on (user_id, appointment_id)
4. Creates performance indexes
5. Adds check constraint for rating range
6. Adds `total_reviews` column to hospitals table if not exists

#### Running the Migration

```bash
# Upgrade to latest version
alembic upgrade head

# Rollback if needed
alembic downgrade -1
```

## Verification

A verification script (`verify_review_model.py`) is provided to test:

### Model Verification
- ✓ All required fields present (15 fields)
- ✓ All validation methods exist
- ✓ Rating validation (1-5 accepted, others rejected)
- ✓ Comment length validation (max 1000 characters)
- ✓ Hospital response length validation (max 500 characters)

### Database Schema Verification (optional)
- ✓ Reviews table exists
- ✓ All columns present
- ✓ Indexes created
- ✓ Foreign keys configured
- ✓ Unique constraints applied
- ✓ total_reviews column added to hospitals table

### Running Verification

```bash
cd python_backend
python verify_review_model.py
```

## Next Steps

To complete the Review System implementation:

1. **Task 8.2**: Implement ReviewService layer
   - `submit_review()` - Create new review with validation
   - `get_hospital_reviews()` - Retrieve reviews with filters
   - `calculate_rating()` - Update hospital average rating
   - `flag_review()` - Flag inappropriate content
   - `respond_to_review()` - Hospital response functionality

2. **Task 8.3**: Write unit tests
   - Test rating calculation accuracy
   - Test duplicate review prevention
   - Test character limit validation
   - Test immutability enforcement after 48 hours

3. **Task 8.4**: Implement API endpoints
   - POST /api/v1/reviews - Submit review
   - GET /api/v1/reviews - List reviews with filters
   - POST /api/v1/reviews/{id}/flag - Flag review
   - POST /api/v1/reviews/{id}/respond - Hospital response
   - PUT /api/v1/reviews/{id}/moderate - Admin moderation

4. **Task 8.5**: Write integration tests
   - Test complete review submission flow
   - Test filtering by rating and date range
   - Test auto-hide after multiple reports
   - Test rating update within 5 seconds

## Design Decisions

### 1. Immutability Implementation
- Used `immutable_after` timestamp field (set to created_at + 48 hours)
- `is_immutable` boolean flag for quick checks
- Business logic will enforce immutability in ReviewService

### 2. Moderation Fields
- `is_flagged` for quick filtering of flagged content
- `flag_count` to track number of flags (auto-hide threshold)
- `is_hidden` to hide reviews pending moderation

### 3. Hospital Response
- Separate field for hospital responses (max 500 chars)
- Timestamp to track when response was added
- Allows hospitals to engage with patient feedback

### 4. Unique Constraint
- Prevents duplicate reviews per appointment
- Ensures data integrity at database level
- Supports Requirement 3.7

## Database Schema

```sql
CREATE TABLE reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    hospital_id INT NOT NULL,
    appointment_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_flagged BOOLEAN DEFAULT FALSE,
    flag_count INT DEFAULT 0,
    is_hidden BOOLEAN DEFAULT FALSE,
    hospital_response TEXT,
    hospital_response_date DATETIME,
    is_immutable BOOLEAN DEFAULT FALSE,
    immutable_after DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id),
    FOREIGN KEY (appointment_id) REFERENCES appointments(id),
    UNIQUE KEY unique_review_per_appointment (user_id, appointment_id),
    INDEX idx_hospital_id (hospital_id),
    INDEX idx_rating (rating),
    INDEX idx_is_flagged (is_flagged)
);
```

## Files Modified/Created

### Created
- `python_backend/alembic/versions/20260303180000_create_reviews_table.py` - Migration script
- `python_backend/verify_review_model.py` - Verification script
- `python_backend/REVIEW_MODEL_IMPLEMENTATION.md` - This documentation

### Modified
- `python_backend/app/models.py` - Added Review model and updated relationships

## Testing

The verification script confirms:
- ✓ Model structure is correct
- ✓ All validation methods work as expected
- ✓ Rating validation enforces 1-5 range
- ✓ Comment length validation enforces 1000 char limit
- ✓ Hospital response validation enforces 500 char limit

## Compliance

This implementation satisfies:
- ✓ Requirement 3.1 - Reviews linked to completed appointments
- ✓ Requirement 3.2 - Rating 1-5 with optional comment
- ✓ Requirement 3.7 - Unique constraint prevents duplicate reviews
- ✓ Requirement 3.11 - Immutability fields for 48-hour rule

## Status

**Task 8.1: COMPLETE** ✓

The Review database model and migration have been successfully implemented with:
- Complete model definition with all required fields
- Validation methods for rating, comment, and hospital response
- Database migration script with proper constraints and indexes
- Verification script confirming correct implementation
- Comprehensive documentation

Ready for Task 8.2 (ReviewService implementation).
