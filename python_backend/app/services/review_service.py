"""
Review Service Layer

Handles review submission, validation, profanity detection, rating calculation,
flagging, and hospital responses. Implements review immutability after 48 hours.
"""

from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import and_, func
from decimal import Decimal
import logging
import re

from ..models import (
    Review, Hospital, User, Appointment, AppointmentStatus
)

logger = logging.getLogger(__name__)


class ReviewService:
    """Service for managing reviews and ratings."""
    
    # Simple profanity list for auto-flagging
    PROFANITY_KEYWORDS = [
        "damn", "hell", "crap", "stupid", "idiot", "fool", "dumb",
        "suck", "terrible", "awful", "worst", "horrible", "disgusting",
        # Add more as needed - this is a basic list
    ]
    
    def __init__(self, db: Session):
        """
        Initialize review service.
        
        Args:
            db: Database session
        """
        self.db = db
        self.IMMUTABILITY_HOURS = 48
        self.MAX_COMMENT_LENGTH = 1000
        self.MAX_RESPONSE_LENGTH = 500
        self.MIN_RATING = 1
        self.MAX_RATING = 5
    
    def submit_review(
        self,
        user_id: int,
        hospital_id: int,
        appointment_id: int,
        rating: int,
        comment: Optional[str] = None
    ) -> Review:
        """
        Submit a review for a hospital after a completed appointment.
        
        Args:
            user_id: User ID
            hospital_id: Hospital ID
            appointment_id: Appointment ID
            rating: Rating (1-5)
            comment: Optional review comment (max 1000 chars)
            
        Returns:
            Created review
            
        Raises:
            ValueError: If validation fails or user not authorized
        """
        # Validate rating
        if not self.MIN_RATING <= rating <= self.MAX_RATING:
            raise ValueError(f"Rating must be between {self.MIN_RATING} and {self.MAX_RATING}")
        
        # Validate comment length
        if comment and len(comment) > self.MAX_COMMENT_LENGTH:
            raise ValueError(f"Comment must not exceed {self.MAX_COMMENT_LENGTH} characters")
        
        # Verify user exists
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("User not found")
        
        # Verify hospital exists
        hospital = self.db.query(Hospital).filter(Hospital.id == hospital_id).first()
        if not hospital:
            raise ValueError("Hospital not found")
        
        # Verify appointment exists and belongs to user
        appointment = self.db.query(Appointment).filter(
            and_(
                Appointment.id == appointment_id,
                Appointment.user_id == user_id,
                Appointment.hospital_id == hospital_id
            )
        ).first()
        
        if not appointment:
            raise ValueError("Appointment not found or unauthorized")
        
        # Check if appointment is completed
        if appointment.status != AppointmentStatus.COMPLETED:
            raise ValueError("Can only review completed appointments")
        
        # Check if review already exists for this appointment
        existing_review = self.db.query(Review).filter(
            Review.appointment_id == appointment_id
        ).first()
        
        if existing_review:
            raise ValueError("Review already submitted for this appointment")
        
        # Check for profanity and auto-flag if detected
        is_flagged = False
        if comment:
            is_flagged = self._contains_profanity(comment)
        
        # Calculate immutability timestamp (48 hours from now)
        immutable_after = datetime.now() + timedelta(hours=self.IMMUTABILITY_HOURS)
        
        # Create review
        review = Review(
            user_id=user_id,
            hospital_id=hospital_id,
            appointment_id=appointment_id,
            rating=rating,
            comment=comment,
            is_flagged=is_flagged,
            flag_count=1 if is_flagged else 0,
            immutable_after=immutable_after
        )
        
        try:
            self.db.add(review)
            self.db.flush()  # Flush to get review ID before updating hospital rating
            
            # Update hospital rating
            self._update_hospital_rating(hospital_id)
            
            self.db.commit()
            self.db.refresh(review)
            
            logger.info(
                f"Review {review.id} submitted by user {user_id} for hospital {hospital_id}, "
                f"rating: {rating}, flagged: {is_flagged}"
            )
            
            return review
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error submitting review: {e}")
            raise ValueError("Failed to submit review")
    
    def get_hospital_reviews(
        self,
        hospital_id: int,
        rating_filter: Optional[int] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
        include_hidden: bool = False,
        page: int = 1,
        limit: int = 20
    ) -> Dict[str, Any]:
        """
        Get reviews for a hospital with filtering and pagination.
        
        Args:
            hospital_id: Hospital ID
            rating_filter: Optional rating filter (1-5)
            date_from: Optional start date filter
            date_to: Optional end date filter
            include_hidden: Whether to include hidden reviews (admin only)
            page: Page number (1-indexed)
            limit: Items per page
            
        Returns:
            Dictionary with reviews, pagination info, and rating distribution
        """
        # Build query
        query = self.db.query(Review).filter(Review.hospital_id == hospital_id)
        
        # Apply filters
        if not include_hidden:
            query = query.filter(Review.is_hidden == False)
        
        if rating_filter:
            query = query.filter(Review.rating == rating_filter)
        
        if date_from:
            query = query.filter(Review.created_at >= date_from)
        
        if date_to:
            query = query.filter(Review.created_at <= date_to)
        
        # Get total count
        total = query.count()
        
        # Apply pagination and ordering (reverse chronological)
        reviews = query.order_by(Review.created_at.desc()).offset(
            (page - 1) * limit
        ).limit(limit).all()
        
        # Calculate rating distribution
        rating_distribution = self._get_rating_distribution(hospital_id)
        
        # Get average rating
        hospital = self.db.query(Hospital).filter(Hospital.id == hospital_id).first()
        average_rating = float(hospital.rating) if hospital else 0.0
        
        return {
            "reviews": reviews,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": total,
                "pages": (total + limit - 1) // limit
            },
            "average_rating": average_rating,
            "rating_distribution": rating_distribution
        }
    
    def calculate_hospital_rating(self, hospital_id: int) -> float:
        """
        Calculate average rating for a hospital.
        
        Args:
            hospital_id: Hospital ID
            
        Returns:
            Average rating (0.0 if no reviews)
        """
        result = self.db.query(
            func.avg(Review.rating).label("average"),
            func.count(Review.id).label("count")
        ).filter(
            and_(
                Review.hospital_id == hospital_id,
                Review.is_hidden == False
            )
        ).first()
        
        if result and result.count > 0:
            return round(float(result.average), 2)
        
        return 0.0
    
    def flag_review(
        self,
        review_id: int,
        reason: Optional[str] = None,
        user_id: Optional[int] = None
    ) -> Review:
        """
        Flag a review for moderation.
        Auto-hide if flagged by multiple users (3+ flags).
        
        Args:
            review_id: Review ID
            reason: Optional reason for flagging
            user_id: Optional user ID who flagged
            
        Returns:
            Updated review
            
        Raises:
            ValueError: If review not found
        """
        review = self.db.query(Review).filter(Review.id == review_id).first()
        
        if not review:
            raise ValueError("Review not found")
        
        # Increment flag count
        review.is_flagged = True
        review.flag_count += 1
        
        # Auto-hide if flagged by 3 or more users
        if review.flag_count >= 3:
            review.is_hidden = True
            logger.warning(
                f"Review {review_id} auto-hidden after {review.flag_count} flags"
            )
        
        try:
            self.db.commit()
            self.db.refresh(review)
            
            logger.info(
                f"Review {review_id} flagged by user {user_id}, "
                f"total flags: {review.flag_count}, hidden: {review.is_hidden}"
            )
            
            return review
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error flagging review: {e}")
            raise ValueError("Failed to flag review")
    
    def respond_to_review(
        self,
        review_id: int,
        hospital_id: int,
        response: str
    ) -> Review:
        """
        Allow hospital to respond to a review.
        
        Args:
            review_id: Review ID
            hospital_id: Hospital ID (for authorization)
            response: Hospital response (max 500 chars)
            
        Returns:
            Updated review
            
        Raises:
            ValueError: If validation fails or unauthorized
        """
        # Validate response length
        if len(response) > self.MAX_RESPONSE_LENGTH:
            raise ValueError(f"Response must not exceed {self.MAX_RESPONSE_LENGTH} characters")
        
        # Get review
        review = self.db.query(Review).filter(
            and_(
                Review.id == review_id,
                Review.hospital_id == hospital_id
            )
        ).first()
        
        if not review:
            raise ValueError("Review not found or unauthorized")
        
        # Update response
        review.hospital_response = response
        review.hospital_response_date = datetime.now()
        
        try:
            self.db.commit()
            self.db.refresh(review)
            
            logger.info(f"Hospital {hospital_id} responded to review {review_id}")
            
            return review
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error responding to review: {e}")
            raise ValueError("Failed to respond to review")
    
    def update_review(
        self,
        review_id: int,
        user_id: int,
        rating: Optional[int] = None,
        comment: Optional[str] = None
    ) -> Review:
        """
        Update a review (only allowed within 48 hours of submission).
        
        Args:
            review_id: Review ID
            user_id: User ID (for authorization)
            rating: Optional new rating
            comment: Optional new comment
            
        Returns:
            Updated review
            
        Raises:
            ValueError: If review is immutable or validation fails
        """
        # Get review
        review = self.db.query(Review).filter(
            and_(
                Review.id == review_id,
                Review.user_id == user_id
            )
        ).first()
        
        if not review:
            raise ValueError("Review not found or unauthorized")
        
        # Check immutability
        if review.is_immutable or (review.immutable_after and datetime.now() > review.immutable_after):
            raise ValueError("Review cannot be modified after 48 hours")
        
        # Validate rating if provided
        if rating is not None:
            if not self.MIN_RATING <= rating <= self.MAX_RATING:
                raise ValueError(f"Rating must be between {self.MIN_RATING} and {self.MAX_RATING}")
            review.rating = rating
        
        # Validate comment if provided
        if comment is not None:
            if len(comment) > self.MAX_COMMENT_LENGTH:
                raise ValueError(f"Comment must not exceed {self.MAX_COMMENT_LENGTH} characters")
            
            # Check for profanity
            if self._contains_profanity(comment):
                review.is_flagged = True
                review.flag_count += 1
            
            review.comment = comment
        
        try:
            self.db.commit()
            self.db.refresh(review)
            
            # Update hospital rating if rating changed
            if rating is not None:
                self._update_hospital_rating(review.hospital_id)
            
            logger.info(f"Review {review_id} updated by user {user_id}")
            
            return review
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error updating review: {e}")
            raise ValueError("Failed to update review")
    
    def moderate_review(
        self,
        review_id: int,
        admin_id: int,
        action: str,
        reason: Optional[str] = None
    ) -> Review:
        """
        Moderate a review (admin action).
        
        Args:
            review_id: Review ID
            admin_id: Admin user ID
            action: Action to take ('hide', 'show', 'delete')
            reason: Optional reason for moderation
            
        Returns:
            Updated review
            
        Raises:
            ValueError: If review not found or invalid action
        """
        review = self.db.query(Review).filter(Review.id == review_id).first()
        
        if not review:
            raise ValueError("Review not found")
        
        if action == "hide":
            review.is_hidden = True
        elif action == "show":
            review.is_hidden = False
            review.is_flagged = False
            review.flag_count = 0
        elif action == "delete":
            # Soft delete by hiding and marking
            review.is_hidden = True
            review.is_flagged = True
        else:
            raise ValueError(f"Invalid moderation action: {action}")
        
        try:
            self.db.commit()
            self.db.refresh(review)
            
            logger.info(
                f"Review {review_id} moderated by admin {admin_id}, "
                f"action: {action}, reason: {reason}"
            )
            
            return review
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error moderating review: {e}")
            raise ValueError("Failed to moderate review")
    
    def mark_reviews_immutable(self) -> int:
        """
        Mark reviews as immutable after 48 hours (scheduled task).
        
        Returns:
            Number of reviews marked immutable
        """
        now = datetime.now()
        
        reviews = self.db.query(Review).filter(
            and_(
                Review.is_immutable == False,
                Review.immutable_after <= now
            )
        ).all()
        
        count = 0
        for review in reviews:
            review.is_immutable = True
            count += 1
        
        if count > 0:
            try:
                self.db.commit()
                logger.info(f"Marked {count} reviews as immutable")
            except Exception as e:
                self.db.rollback()
                logger.error(f"Error marking reviews immutable: {e}")
                return 0
        
        return count
    
    def _update_hospital_rating(self, hospital_id: int) -> None:
        """
        Update hospital average rating and total review count.
        
        Args:
            hospital_id: Hospital ID
        """
        # Calculate new average rating
        result = self.db.query(
            func.avg(Review.rating).label("average"),
            func.count(Review.id).label("count")
        ).filter(
            and_(
                Review.hospital_id == hospital_id,
                Review.is_hidden == False
            )
        ).first()
        
        hospital = self.db.query(Hospital).filter(Hospital.id == hospital_id).first()
        
        if hospital:
            if result and result.count > 0:
                hospital.rating = Decimal(str(round(float(result.average), 2)))
                hospital.total_reviews = result.count
            else:
                hospital.rating = Decimal("0.00")
                hospital.total_reviews = 0
            
            logger.info(
                f"Updated hospital {hospital_id} rating: {hospital.rating} "
                f"({hospital.total_reviews} reviews)"
            )
    
    def _get_rating_distribution(self, hospital_id: int) -> Dict[int, int]:
        """
        Get rating distribution for a hospital.
        
        Args:
            hospital_id: Hospital ID
            
        Returns:
            Dictionary mapping rating (1-5) to count
        """
        results = self.db.query(
            Review.rating,
            func.count(Review.id).label("count")
        ).filter(
            and_(
                Review.hospital_id == hospital_id,
                Review.is_hidden == False
            )
        ).group_by(Review.rating).all()
        
        # Initialize all ratings to 0
        distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
        
        # Fill in actual counts
        for rating, count in results:
            distribution[rating] = count
        
        return distribution
    
    def _contains_profanity(self, text: str) -> bool:
        """
        Check if text contains profanity or inappropriate content.
        Uses simple keyword matching (can be enhanced with ML models).
        
        Args:
            text: Text to check
            
        Returns:
            True if profanity detected, False otherwise
        """
        if not text:
            return False
        
        # Convert to lowercase for case-insensitive matching
        text_lower = text.lower()
        
        # Check for profanity keywords
        for keyword in self.PROFANITY_KEYWORDS:
            # Use word boundaries to avoid false positives
            pattern = r'\b' + re.escape(keyword) + r'\b'
            if re.search(pattern, text_lower):
                logger.info(f"Profanity detected: {keyword}")
                return True
        
        return False
