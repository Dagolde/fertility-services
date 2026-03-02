from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, UserProfile
from ..schemas import UserCreate, UserResponse, Token, LoginRequest
from ..auth import (
    authenticate_user,
    create_access_token,
    get_password_hash,
    ACCESS_TOKEN_EXPIRE_MINUTES
)

router = APIRouter()

@router.post("/register")
async def register(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user and return access token with user data."""
    # Check if user already exists
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        password_hash=hashed_password,
        first_name=user.first_name,
        last_name=user.last_name,
        phone=user.phone,
        date_of_birth=user.date_of_birth,
        gender=user.gender,
        user_type=user.user_type
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Create user profile
    user_profile = UserProfile(user_id=db_user.id)
    db.add(user_profile)
    db.commit()
    
    # Create access token for the new user
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": db_user.email}, expires_delta=access_token_expires
    )
    
    # Convert user to dict format expected by Flutter
    user_data = {
        "id": db_user.id,
        "email": db_user.email,
        "first_name": db_user.first_name,
        "last_name": db_user.last_name,
        "phone": db_user.phone,
        "date_of_birth": db_user.date_of_birth.isoformat() if db_user.date_of_birth else None,
        "gender": db_user.gender,
        "user_type": db_user.user_type.value,
        "is_active": db_user.is_active,
        "is_verified": db_user.is_verified,
        "profile_completed": db_user.profile_completed,
        "profile_picture": db_user.profile_picture,
        "bio": db_user.bio,
        "address": db_user.address,
        "city": db_user.city,
        "state": db_user.state,
        "country": db_user.country,
        "postal_code": db_user.postal_code,
        "latitude": db_user.latitude,
        "longitude": db_user.longitude,
        "created_at": db_user.created_at.isoformat(),
        "updated_at": db_user.updated_at.isoformat(),
    }
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "refresh_token": None,
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "user": user_data
    }

@router.post("/login")
async def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """Authenticate user and return access token with user data."""
    user = authenticate_user(db, login_data.email, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    # Convert user to dict format expected by Flutter
    user_data = {
        "id": user.id,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "phone": user.phone,
        "date_of_birth": user.date_of_birth.isoformat() if user.date_of_birth else None,
        "user_type": user.user_type.value,
        "is_active": user.is_active,
        "is_verified": user.is_verified,
        "profile_completed": user.profile_completed,
        "profile_picture": user.profile_picture,
        "bio": user.bio,
        "address": user.address,
        "city": user.city,
        "state": user.state,
        "country": user.country,
        "postal_code": user.postal_code,
        "latitude": user.latitude,
        "longitude": user.longitude,
        "created_at": user.created_at.isoformat(),
        "updated_at": user.updated_at.isoformat(),
    }
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "refresh_token": None,
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "user": user_data
    }

@router.post("/token", response_model=Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """OAuth2 compatible token login."""
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/verify-email/{user_id}")
async def verify_email(user_id: int, db: Session = Depends(get_db)):
    """Verify user email (simplified version)."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.is_verified = True
    db.commit()
    
    return {"message": "Email verified successfully"}

@router.post("/forgot-password")
async def forgot_password(email: str, db: Session = Depends(get_db)):
    """Send password reset email (placeholder)."""
    user = db.query(User).filter(User.email == email).first()
    if not user:
        # Don't reveal if email exists or not
        return {"message": "If the email exists, a reset link has been sent"}
    
    # TODO: Implement email sending logic
    return {"message": "Password reset email sent"}

@router.post("/reset-password")
async def reset_password(
    token: str,
    new_password: str,
    db: Session = Depends(get_db)
):
    """Reset user password (placeholder)."""
    # TODO: Implement token verification and password reset
    return {"message": "Password reset successfully"}
