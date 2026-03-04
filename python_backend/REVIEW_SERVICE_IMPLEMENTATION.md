# Review Service Implementation

## Overview

The Review Service Layer has been successfully implemented in `app/services/review_service.py`. This service handles all review-related operations including submission, validation, profanity detection, rating calculation, flagging, and hospital responses.

## Implementation Details

### Class: `ReviewService`

Location: `python_backend/app/services/review_service.py`

### Key Features

1. **Review Submission**
   - Validates rating (1-5 stars)
   - Validates comment length (max 1000 characters)
   - Verifies user has completed appointment
   - Prevents duplicate reviews for same appointment
   - Auto-flags reviews containing profanity
   - Sets immutability timestamp (48 hours from submission)

2. **Profanity Detection**
   - Simple keyword-based detection
   - Auto-flags reviews containing inappropriate content
   - Case-insensitive matching with word boundaries
   - Extensible keyword list

3. **Rating Calculation**
   - Calculates hospital average rating
   - Updates hospital rating within database transaction
   - Excludes hidden reviews from calculations
   - Maintains total review count

4. **Review Immutability**
   - Reviews become immutable 48 hours after submission
   - Prevents edits after immutability period
   - Scheduled task to mark reviews as immutable

5. **Review Flagging**
   - Users can flag inappropriate reviews
   - Tracks flag count per review
   - Auto-hides reviews after 3+ flags
   - Admin moderation support

6. **Hospital Responses**
   - Hospitals can respond to reviews
   - Response length limited to 500 characters
   - Timestamps response date

### Methods

#### Public Methods

1. **`submit_review(user_id, hospital_id, appointment_id, rating, comment)`**
   - Submit a new review
   - Returns: Created Review object
   - Raises: ValueError for validation failures

2. **`get_hospital_reviews(hospital_id, rating_filter, date_from, date_to, include_hidden, page, limit)`**
   - Get paginated reviews for a hospital
   - Returns: Dictionary with reviews, pagination, average rating, and rating distribution
   - Supports filtering by rating and date range

3. **`calculate_hospital_rating(hospital_id)`**
   - Calculate average rating for a hospital
   - Returns: Float (0.0 if no reviews)

4. **`flag_review(review_id, reason, user_id)`**
   - Flag a review for moderation
   - Auto-hides after 3+ flags
   - Returns: Updated Review object

5. **`respond_to_review(review_id, hospital_id, response)`**
   - Hospital response to review
   - Returns: Updated Review object
   - Raises: ValueError if unauthorized or validation fails

6. **`update_review(review_id, user_id, rating, comment)`**
   - Update review within 48-hour window
   - Returns: Updated Review object
   - Raises: ValueError if immutable or validation fails

7. **`moderate_review(review_id, admin_id, action, reason)`**
   - Admin moderation actions (hide, show, delete)
   - Returns: Updated Review object

8. **`mark_reviews_immutable()`**
   - Scheduled task to mark reviews as immutable after 48 hours
   - Returns: Count of reviews marked immutable

#### Private Methods

1. **`_update_hospital_rating(hospital_id)`**
   - Internal method to update hospital rating and review count
   - Called automatically after review submission/update

2. **`_get_rating_distribution(hospital_id)`**
   - Get rating distribution (1-5 stars with counts)
   - Returns: Dictionary mapping rating to count

3. **`_contains_profanity(text)`**
   - Check text for profanity keywords
   - Returns: Boolean

### Configuration Constants

- `IMMUTABILITY_HOURS = 48` - Hours until review becomes immutable
- `MAX_COMMENT_LENGTH = 1000` - Maximum comment length
- `MAX_RESPONSE_LENGTH = 500` - Maximum hospital response length
- `MIN_RATING = 1` - Minimum rating value
- `MAX_RATING = 5` - Maximum rating value
- `PROFANITY_KEYWORDS` - List of profanity keywords for detection

### Validation Rules

1. **Rating Validation**
   - Must be between 1 and 5 (inclusive)
   - Required field

2. **Comment Validation**
   - Optional field
   - Maximum 1000 characters
   - Auto-flagged if contains profanity

3. **Hospital Response Validation**
   - Maximum 500 characters
   - Only hospital can respond to their reviews

4. **Authorization Checks**
   - User must own appointment to review
   - Appointment must be completed
   - No duplicate reviews per appointment
   - Hospital must own review to respond

5. **Immutability Rules**
   - Reviews can be edited within 48 hours
   - After 48 hours, reviews are immutable
   - Scheduled task marks reviews as immutable

### Auto-Flagging Logic

Reviews are automatically flagged if:
1. Comment contains profanity keywords
2. Review is reported by 3+ users (auto-hidden)

### Rating Calculation

Hospital rating is calculated as:
- Average of all non-hidden review ratings
- Rounded to 2 decimal places
- Updated immediately after review submission/update
- Excludes hidden/flagged reviews

### Database Operations

All operations use database transactions:
- Commit on success
- Rollback on error
- Proper error logging

### Error Handling

All methods raise `ValueError` with descriptive messages for:
- Validation failures
- Authorization failures
- Not found errors
- Business logic violations

## Requirements Coverage

This implementation satisfies the following requirements:

- **Requirement 3.2**: Rating validation (1-5) and comment length (max 1000 chars)
- **Requirement 3.3**: Comment length validation
- **Requirement 3.4**: Hospital rating calculation and updates
- **Requirement 3.5**: Profanity detection and auto-flagging
- **Requirement 3.11**: Review immutability after 48 hours

## Usage Example

```python
from sqlalchemy.orm import Session
from app.services.review_service import ReviewService

# Initialize service
db: Session = get_db()
review_service = ReviewService(db)

# Submit a review
review = review_service.submit_review(
    user_id=1,
    hospital_id=5,
    appointment_id=123,
    rating=5,
    comment="Excellent service and professional staff"
)

# Get hospital reviews
result = review_service.get_hospital_reviews(
    hospital_id=5,
    rating_filter=5,
    page=1,
    limit=20
)

# Hospital responds to review
review = review_service.respond_to_review(
    review_id=review.id,
    hospital_id=5,
    response="Thank you for your feedback!"
)

# Flag a review
review = review_service.flag_review(
    review_id=review.id,
    reason="Inappropriate content",
    user_id=2
)

# Calculate hospital rating
rating = review_service.calculate_hospital_rating(hospital_id=5)
print(f"Hospital rating: {rating}")
```

## Testing

A verification script is provided at `python_backend/verify_review_service.py` that checks:
- All required methods exist
- Configuration constants are correct
- Method signatures are correct
- Profanity detection works
- All requirements are covered

Run verification:
```bash
cd python_backend
python verify_review_service.py
```

## Next Steps

1. Implement review API endpoints (Task 8.4)
2. Write unit tests for review service (Task 8.3)
3. Write integration tests for review endpoints (Task 8.5)
4. Implement review UI in mobile app (Phase 3, Tasks 9.1-9.3)
5. Implement review management in admin dashboard (Task 10.1)

## Notes

- The profanity detection is basic keyword-based. For production, consider:
  - ML-based content moderation (e.g., Perspective API)
  - More comprehensive profanity lists
  - Context-aware detection
  - Multi-language support

- Rating calculation is performed synchronously. For high-volume systems, consider:
  - Async rating updates
  - Cached rating values
  - Batch processing

- Review immutability is enforced at the service layer. Consider:
  - Database constraints for additional safety
  - Audit logging for immutability violations
  - Admin override capability
