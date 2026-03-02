from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from ..database import get_db
from ..models import User, Hospital
from ..schemas import (
    HospitalCreate, HospitalUpdate, HospitalResponse, 
    HospitalWithUser, HospitalSearchParams
)
from ..auth import get_current_active_user, get_admin_user, get_hospital_user

router = APIRouter()

@router.post("/register", response_model=HospitalResponse)
async def register_hospital(
    hospital_data: HospitalCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Register a new hospital."""
    # Check if user is hospital type
    if current_user.user_type.value != "hospital":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only hospital users can register hospitals"
        )
    
    # Check if hospital already exists for this user
    existing_hospital = db.query(Hospital).filter(Hospital.user_id == current_user.id).first()
    if existing_hospital:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Hospital already registered for this user"
        )
    
    # Check if license number is unique
    existing_license = db.query(Hospital).filter(Hospital.license_number == hospital_data.license_number).first()
    if existing_license:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="License number already registered"
        )
    
    # Create hospital
    db_hospital = Hospital(
        user_id=current_user.id,
        **hospital_data.dict()
    )
    
    db.add(db_hospital)
    db.commit()
    db.refresh(db_hospital)
    
    return db_hospital

@router.get("/my-hospital", response_model=HospitalResponse)
async def get_my_hospital(
    current_user: User = Depends(get_hospital_user),
    db: Session = Depends(get_db)
):
    """Get current user's hospital."""
    hospital = db.query(Hospital).filter(Hospital.user_id == current_user.id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    return hospital

@router.put("/my-hospital", response_model=HospitalResponse)
async def update_my_hospital(
    hospital_update: HospitalUpdate,
    current_user: User = Depends(get_hospital_user),
    db: Session = Depends(get_db)
):
    """Update current user's hospital."""
    hospital = db.query(Hospital).filter(Hospital.user_id == current_user.id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    for field, value in hospital_update.dict(exclude_unset=True).items():
        setattr(hospital, field, value)
    
    db.commit()
    db.refresh(hospital)
    
    return hospital

@router.get("/search", response_model=List[HospitalResponse])
async def search_hospitals(
    city: str = None,
    state: str = None,
    service_type: str = None,
    min_rating: float = None,
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """Search hospitals with filters."""
    query = db.query(Hospital).filter(Hospital.is_verified == True)
    
    if city:
        query = query.filter(Hospital.city.ilike(f"%{city}%"))
    
    if state:
        query = query.filter(Hospital.state.ilike(f"%{state}%"))
    
    if service_type:
        # Search in services_offered JSON field
        query = query.filter(Hospital.services_offered.contains([service_type]))
    
    if min_rating:
        query = query.filter(Hospital.rating >= min_rating)
    
    hospitals = query.offset(skip).limit(limit).all()
    return hospitals

@router.get("/nearby")
async def get_nearby_hospitals(
    latitude: float,
    longitude: float,
    radius_km: float = 50.0,  # km
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """Get nearby hospitals (placeholder - requires geospatial implementation)."""
    # TODO: Implement geospatial search using PostGIS or similar
    # For now, return all verified hospitals
    hospitals = db.query(Hospital).filter(Hospital.is_verified == True).limit(limit).all()
    return hospitals

@router.get("/{hospital_id}/services")
async def get_hospital_services(
    hospital_id: int,
    db: Session = Depends(get_db)
):
    """Get services offered by a hospital."""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    # Return services_offered as a list
    services = hospital.services_offered if hospital.services_offered else []
    return services

@router.get("/{hospital_id}/doctors")
async def get_hospital_doctors(
    hospital_id: int,
    db: Session = Depends(get_db)
):
    """Get doctors working at a hospital."""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    # Get doctors associated with this hospital (simplified - using email domain matching)
    doctors = db.query(User).filter(
        User.user_type == 'hospital',
        User.email.like(f"%{hospital.email.split('@')[1]}")
    ).all()
    
    return doctors

@router.get("/{hospital_id}/reviews")
async def get_hospital_reviews(
    hospital_id: int,
    db: Session = Depends(get_db)
):
    """Get reviews for a hospital."""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    # For now, return empty list (in a real app, you'd have a reviews table)
    return []

@router.get("/{hospital_id}", response_model=HospitalWithUser)
async def get_hospital_by_id(
    hospital_id: int,
    db: Session = Depends(get_db)
):
    """Get hospital by ID with user details."""
    hospital = db.query(Hospital).filter(
        Hospital.id == hospital_id,
        Hospital.is_verified == True
    ).first()
    
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    # Get hospital user details
    user = db.query(User).filter(User.id == hospital.user_id).first()
    
    hospital_data = HospitalWithUser.from_orm(hospital)
    if user:
        hospital_data.user = user
    
    return hospital_data

@router.post("/{hospital_id}/rate")
async def rate_hospital(
    hospital_id: int,
    rating: float,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Rate a hospital (1-5 stars)."""
    if not (1 <= rating <= 5):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5"
        )
    
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    # TODO: Implement proper rating system with user tracking
    # For now, just update the average rating (simplified)
    # In production, you'd want to store individual ratings and calculate averages
    
    return {"message": "Rating submitted successfully"}

# Admin endpoints
@router.get("/", response_model=List[HospitalWithUser])
async def get_all_hospitals(
    skip: int = 0,
    limit: int = 100,
    is_verified: bool = None,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all hospitals (admin only)."""
    query = db.query(Hospital)
    
    if is_verified is not None:
        query = query.filter(Hospital.is_verified == is_verified)
    
    hospitals = query.offset(skip).limit(limit).all()
    
    # Include user details
    result = []
    for hospital in hospitals:
        user = db.query(User).filter(User.id == hospital.user_id).first()
        hospital_data = HospitalWithUser.from_orm(hospital)
        if user:
            hospital_data.user = user
        result.append(hospital_data)
    
    return result

@router.put("/{hospital_id}/verify")
async def verify_hospital(
    hospital_id: int,
    is_verified: bool,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Verify/unverify hospital (admin only)."""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    hospital.is_verified = is_verified
    db.commit()
    
    return {"message": f"Hospital {'verified' if is_verified else 'unverified'} successfully"}

@router.delete("/{hospital_id}")
async def delete_hospital(
    hospital_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Delete hospital (admin only)."""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    db.delete(hospital)
    db.commit()
    
    return {"message": "Hospital deleted successfully"}

@router.get("/stats/overview")
async def get_hospital_stats(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get hospital statistics (admin only)."""
    total_hospitals = db.query(Hospital).count()
    verified_hospitals = db.query(Hospital).filter(Hospital.is_verified == True).count()
    pending_hospitals = db.query(Hospital).filter(Hospital.is_verified == False).count()
    
    return {
        "total_hospitals": total_hospitals,
        "verified_hospitals": verified_hospitals,
        "pending_hospitals": pending_hospitals,
        "verification_rate": (verified_hospitals / total_hospitals * 100) if total_hospitals > 0 else 0
    }
