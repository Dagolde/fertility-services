"""
Review API Endpoints

Implements review submission, listing, flagging, hospital responses, and admin moderation.
Follows the design specification for Requirements 3.1, 3.6, 3.8, 3.9, 3.10.
"""

from typing import Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
import logging

from ..database import get_db
from ..models import User, Review, UserType
from ..schemas import (
    ReviewCreate, ReviewUpdate, ReviewResponse, ReviewWithUser,
    ReviewFlagRequest, ReviewRespondRequest, ReviewModerateRequest,
    ReviewListResponse
)
from ..auth import get_current_active_user, get_admin_user, get_hospital_user
from ..services.review_service import ReviewService

logger = logging.getLogger(__name__)
router = APIRouter()


def get_review_service(db: Session = Depends(get_db)) -> ReviewService:
    """Dependency to get review service instance."""
    return ReviewService(db)


@router.post("", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
async def submit_review(
    review_data: ReviewCreate,
    current_user: User = Depends(get_current_active_user),
    review_service: ReviewService = Depends(get_review_service)
):
    """
    Submit a review for a hospital after a completed appointment.
    
    Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.7, 3.11
    
    Args:
        review_data: Review submission data
        current_user: Authenticated user
        review_service: Review service instance
        
    Returns:
        Created review
        
    Raises:
        HTTPException: If validation fails or user not authorized
    """
    try:
        review = review_service.submit_review(
            user_id=current_user.id,
            hospital_id=review_data.hospital_id,
            appointment_id=review_data.appointment_id,
            rating=review_data.rating,
            comment=review_data.comment
        )
        
        return ReviewResponse.model_validate(review)
        
    except ValueError as e:
        logger.error(f"Review submission error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error during review submission: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to submit review"
        )


@router.get("", response_model=ReviewListResponse)
async def list_reviews(
    hospital_id: Optional[int] = Query(None, description="Filter by hospital ID"),
    rating: Optional[int] = Query(None, ge=1, le=5, description="Filter by rating"),
    date_from: Optional[datetime] = Query(None, description="Filter from date"),
    date_to: Optional[datetime] = Query(None, description="Filter to date"),
    include_hidden: bool = Query(False, description="Include hidden reviews (admin only)"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=50, description="Items per page"),
    current_user: Optional[User] = Depends(get_current_active_user),
    review_service: ReviewService = Depends(get_review_service)
):
    """
    List reviews with filters.
    
    Requirements: 3.8, 3.9 - List reviews with filtering by rating and date range
    
    Args:
        hospital_id: Optional hospital ID filter
        rating: Optional rating filter (1-5)
        date_from: Optional start date filter
        date_to: Optional end date filter
        include_hidden: Whether to include hidden reviews (admin only)
        page: Page number for pagination
        limit: Items per page
        current_user: Authenticated user (optional)
        review_service: Review service instance
        
    Returns:
        List of reviews with pagination info and rating statistics
        
    Raises:
        HTTPException: If validation fails
    """
    try:
        # Only admins can see hidden reviews
        if include_hidden and (not current_user or current_user.user_type != UserType.ADMIN):
            include_hidden = False
        
        # Hospital ID is required
        if not hospital_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="hospital_id is required"
            )
        
        result = review_service.get_hospital_reviews(
            hospital_id=hospital_id,
            rating_filter=rating,
            date_from=date_from,
            date_to=date_to,
            include_hidden=include_hidden,
            page=page,
            limit=limit
        )
        
        return ReviewListResponse(
            reviews=[ReviewResponse.model_validate(r) for r in result["reviews"]],
            pagination=result["pagination"],
            average_rating=result["average_rating"],
            rating_distribution=result["rating_distribution"]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing reviews: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve reviews"
        )


@router.post("/{review_id}/flag", response_model=ReviewResponse)
async def flag_review(
    review_id: int,
    flag_data: ReviewFlagRequest,
    current_user: User = Depends(get_current_active_user),
    review_service: ReviewService = Depends(get_review_service)
):
    """
    Flag a review for moderation.
    Auto-hides review if flagged by 3+ users.
    
    Requirements: 3.5, 3.10 - Flag review and auto-hide after multiple reports
    
    Args:
        review_id: Review ID to flag
        flag_data: Flag request with optional reason
        current_user: Authenticated user
        review_service: Review service instance
        
    Returns:
        Updated review
        
    Raises:
        HTTPException: If review not found
    """
    try:
        review = review_service.flag_review(
            review_id=review_id,
            reason=flag_data.reason,
            user_id=current_user.id
        )
        
        return ReviewResponse.model_validate(review)
        
    except ValueError as e:
        logger.error(f"Flag review error: {e}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error flagging review: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to flag review"
        )


@router.post("/{review_id}/respond", response_model=ReviewResponse)
async def respond_to_review(
    review_id: int,
    response_data: ReviewRespondRequest,
    current_user: User = Depends(get_hospital_user),
    review_service: ReviewService = Depends(get_review_service),
    db: Session = Depends(get_db)
):
    """
    Allow hospital to respond to a review.
    
    Requirements: 3.6 - Hospital response to reviews within 500 characters
    
    Args:
        review_id: Review ID to respond to
        response_data: Response data
        current_user: Authenticated hospital user
        review_service: Review service instance
        db: Database session
        
    Returns:
        Updated review with hospital response
        
    Raises:
        HTTPException: If review not found or user not authorized
    """
    try:
        # Get hospital ID for the current user
        from ..models import Hospital
        hospital = db.query(Hospital).filter(Hospital.user_id == current_user.id).first()
        
        if not hospital:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User is not associated with a hospital"
            )
        
        review = review_service.respond_to_review(
            review_id=review_id,
            hospital_id=hospital.id,
            response=response_data.response
        )
        
        return ReviewResponse.model_validate(review)
        
    except HTTPException:
        raise
    except ValueError as e:
        logger.error(f"Respond to review error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error responding to review: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to respond to review"
        )


@router.put("/{review_id}/moderate", response_model=ReviewResponse)
async def moderate_review(
    review_id: int,
    moderation_data: ReviewModerateRequest,
    current_user: User = Depends(get_admin_user),
    review_service: ReviewService = Depends(get_review_service)
):
    """
    Moderate a review (admin only).
    
    Requirements: 3.10 - Admin moderation of reviews
    
    Args:
        review_id: Review ID to moderate
        moderation_data: Moderation action and reason
        current_user: Authenticated admin user
        review_service: Review service instance
        
    Returns:
        Updated review
        
    Raises:
        HTTPException: If review not found or invalid action
    """
    try:
        review = review_service.moderate_review(
            review_id=review_id,
            admin_id=current_user.id,
            action=moderation_data.action,
            reason=moderation_data.reason
        )
        
        return ReviewResponse.model_validate(review)
        
    except ValueError as e:
        logger.error(f"Moderate review error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error moderating review: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to moderate review"
        )


@router.put("/{review_id}", response_model=ReviewResponse)
async def update_review(
    review_id: int,
    update_data: ReviewUpdate,
    current_user: User = Depends(get_current_active_user),
    review_service: ReviewService = Depends(get_review_service)
):
    """
    Update a review (only allowed within 48 hours).
    
    Requirements: 3.11 - Review immutability after 48 hours
    
    Args:
        review_id: Review ID to update
        update_data: Updated review data
        current_user: Authenticated user
        review_service: Review service instance
        
    Returns:
        Updated review
        
    Raises:
        HTTPException: If review is immutable or validation fails
    """
    try:
        review = review_service.update_review(
            review_id=review_id,
            user_id=current_user.id,
            rating=update_data.rating,
            comment=update_data.comment
        )
        
        return ReviewResponse.model_validate(review)
        
    except ValueError as e:
        logger.error(f"Update review error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error updating review: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update review"
        )


@router.get("/{review_id}", response_model=ReviewResponse)
async def get_review(
    review_id: int,
    review_service: ReviewService = Depends(get_review_service),
    db: Session = Depends(get_db)
):
    """
    Get a single review by ID.
    
    Args:
        review_id: Review ID
        review_service: Review service instance
        db: Database session
        
    Returns:
        Review details
        
    Raises:
        HTTPException: If review not found
    """
    try:
        review = db.query(Review).filter(Review.id == review_id).first()
        
        if not review:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Review not found"
            )
        
        return ReviewResponse.model_validate(review)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting review: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve review"
        )
