from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import or_

from ..database import get_db
from ..models import User, UserProfile
from ..schemas import (
    UserResponse, UserUpdate, UserWithProfile,
    UserProfileCreate, UserProfileUpdate, UserProfileResponse
)
from ..auth import get_current_active_user, get_admin_user

router = APIRouter()

@router.get("/me", response_model=UserWithProfile)
async def get_current_user_profile(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get current user's profile."""
    user_profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    user_data = UserWithProfile.from_orm(current_user)
    if user_profile:
        user_data.profile = UserProfileResponse.from_orm(user_profile)
    return user_data

@router.put("/me", response_model=UserResponse)
async def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update current user's basic information."""
    for field, value in user_update.dict(exclude_unset=True).items():
        setattr(current_user, field, value)
    
    # Check if profile is complete
    if (current_user.first_name and current_user.last_name and 
        current_user.phone and current_user.date_of_birth and 
        current_user.gender and current_user.bio and 
        current_user.address and current_user.city and 
        current_user.state and current_user.country and 
        current_user.postal_code):
        current_user.profile_completed = True
    
    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/me/profile", response_model=UserProfileResponse)
async def create_user_profile(
    profile_data: UserProfileCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create or update user profile."""
    # Check if profile already exists
    existing_profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    
    if existing_profile:
        # Update existing profile
        for field, value in profile_data.dict(exclude_unset=True).items():
            setattr(existing_profile, field, value)
        db.commit()
        db.refresh(existing_profile)
        return existing_profile
    else:
        # Create new profile
        db_profile = UserProfile(
            user_id=current_user.id,
            **profile_data.dict()
        )
        db.add(db_profile)
        db.commit()
        db.refresh(db_profile)
        
        # Mark profile as completed
        current_user.profile_completed = True
        db.commit()
        
        return db_profile

@router.put("/me/profile", response_model=UserProfileResponse)
async def update_user_profile(
    profile_update: UserProfileUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update user profile."""
    profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    for field, value in profile_update.dict(exclude_unset=True).items():
        setattr(profile, field, value)
    
    db.commit()
    db.refresh(profile)
    return profile

@router.post("/me/profile/image")
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Upload profile image."""
    import os
    import uuid
    from pathlib import Path
    
    # Validate file type
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image"
        )
    
    # Create uploads directory if it doesn't exist
    UPLOAD_DIR = Path("python_backend/uploads")
    PROFILES_DIR = UPLOAD_DIR / "profiles"
    PROFILES_DIR.mkdir(parents=True, exist_ok=True)
    
    # Validate file size (max 5MB for profile images)
    MAX_FILE_SIZE = 5 * 1024 * 1024
    file_content = await file.read()
    if len(file_content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File too large. Maximum size: 5MB"
        )
    
    # Generate unique filename
    file_ext = Path(file.filename).suffix.lower()
    if file_ext not in {'.jpg', '.jpeg', '.png', '.gif'}:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Allowed: jpg, jpeg, png, gif"
        )
    
    unique_filename = f"{current_user.id}_{uuid.uuid4()}{file_ext}"
    file_path = PROFILES_DIR / unique_filename
    
    # Save file
    with open(file_path, "wb") as buffer:
        buffer.write(file_content)
    
    # Get or create profile
    profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)
    
    # Return full URL for the uploaded image
    base_url = "http://192.168.1.106:8000"  # Use the same IP as Flutter app
    image_url = f"{base_url}/uploads/profiles/{unique_filename}"
    
    # Update profile image path with the HTTP URL
    profile.profile_image = image_url
    
    # Also update the user's profile_picture field with the HTTP URL
    current_user.profile_picture = image_url
    
    db.commit()
    db.refresh(profile)
    
    return {"message": "Profile image uploaded successfully", "file_path": image_url}

@router.get("/search", response_model=List[UserResponse])
async def search_users(
    q: str = "",
    user_type: str = None,
    skip: int = 0,
    limit: int = 20,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Search users (for matching purposes)."""
    query = db.query(User).filter(User.is_active == True, User.id != current_user.id)
    
    if q:
        query = query.filter(
            or_(
                User.first_name.contains(q),
                User.last_name.contains(q),
                User.email.contains(q)
            )
        )
    
    if user_type:
        query = query.filter(User.user_type == user_type)
    
    users = query.offset(skip).limit(limit).all()
    return users

@router.get("/{user_id}", response_model=UserWithProfile)
async def get_user_by_id(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get user by ID (with profile)."""
    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user_profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    user_data = UserWithProfile.from_orm(user)
    if user_profile:
        user_data.profile = UserProfileResponse.from_orm(user_profile)
    
    return user_data

# Admin endpoints
@router.get("/", response_model=List[UserResponse])
async def get_all_users(
    skip: int = 0,
    limit: int = 100,
    user_type: str = None,
    is_active: bool = None,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all users (admin only)."""
    query = db.query(User)
    
    if user_type:
        query = query.filter(User.user_type == user_type)
    
    if is_active is not None:
        query = query.filter(User.is_active == is_active)
    
    users = query.offset(skip).limit(limit).all()
    return users

@router.put("/{user_id}/status")
async def update_user_status(
    user_id: int,
    is_active: bool,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Update user status (admin only)."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.is_active = is_active
    db.commit()
    
    return {"message": f"User {'activated' if is_active else 'deactivated'} successfully"}

@router.delete("/{user_id}")
async def delete_user(
    user_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Delete user (admin only)."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Soft delete by deactivating
    user.is_active = False
    db.commit()
    
    return {"message": "User deleted successfully"}
