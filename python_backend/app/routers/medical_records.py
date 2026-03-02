import os
import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Response
from sqlalchemy.orm import Session
from pathlib import Path

from ..database import get_db
from ..models import User, MedicalRecord, MedicalRecordType
from ..schemas import MedicalRecordResponse, MedicalRecordCreate
from ..auth import get_current_active_user, get_admin_user

router = APIRouter()

# Create uploads directory if it doesn't exist
UPLOAD_DIR = Path("python_backend/uploads")
MEDICAL_RECORDS_DIR = UPLOAD_DIR / "medical_records"
MEDICAL_RECORDS_DIR.mkdir(parents=True, exist_ok=True)

# TODO: Medical record enum validation error has been fixed by:
# 1. Updated database table enum definition to use uppercase values
# 2. Fixed existing database records to use uppercase values
# 3. Updated backend schema to match the actual model fields
# 4. Removed db.refresh() call that was causing enum validation issues

ALLOWED_EXTENSIONS = {'.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB

def validate_file(file: UploadFile) -> None:
    """Validate uploaded file"""
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No file provided"
        )
    
    # Check file extension
    file_ext = Path(file.filename).suffix.lower()
    if file_ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File type not allowed. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"
        )

def save_file(file: UploadFile, user_id: int) -> tuple[str, str, int]:
    """Save uploaded file and return file path, filename, and size"""
    # Generate unique filename
    file_ext = Path(file.filename).suffix.lower()
    unique_filename = f"{user_id}_{uuid.uuid4()}{file_ext}"
    file_path = MEDICAL_RECORDS_DIR / unique_filename
    
    # Save file
    file_size = 0
    with open(file_path, "wb") as buffer:
        content = file.file.read()
        file_size = len(content)
        
        # Check file size
        if file_size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File too large. Maximum size: {MAX_FILE_SIZE // (1024*1024)}MB"
            )
        
        buffer.write(content)
    
    return str(file_path), unique_filename, file_size

@router.get("/", response_model=List[MedicalRecordResponse])
async def get_my_medical_records(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get current user's medical records"""
    try:
        records = db.query(MedicalRecord).filter(
            MedicalRecord.user_id == current_user.id
        ).order_by(MedicalRecord.created_at.desc()).all()
        
        return records
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error: {str(e)}"
        )

@router.post("/", response_model=MedicalRecordResponse)
async def upload_medical_record(
    file: UploadFile = File(...),
    description: str = Form(...),
    record_type: str = Form(...),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Upload a medical record"""
    try:
        # Validate file
        validate_file(file)
        
        # Validate record type
        try:
            record_type_enum = MedicalRecordType(record_type)
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid record type. Valid types: {[e.value for e in MedicalRecordType]}"
            )
        
        # Save file
        file_path, unique_filename, file_size = save_file(file, current_user.id)
        
        # Create database record
        # Generate a title from the record type and file name
        title = f"{record_type_enum.value.replace('_', ' ').title()} - {file.filename}"
        
        db_record = MedicalRecord(
            user_id=current_user.id,
            title=title,
            file_name=file.filename,
            file_path=file_path,
            file_type=Path(file.filename).suffix.lower(),
            file_size=file_size,
            description=description,
            record_type=record_type_enum
        )
        
        db.add(db_record)
        db.commit()
        
        return db_record
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        # Clean up file if it was created
        try:
            if 'file_path' in locals() and os.path.exists(file_path):
                os.remove(file_path)
        except Exception as cleanup_error:
            pass
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error: {str(e)}"
        )

@router.get("/{record_id}", response_model=MedicalRecordResponse)
async def get_medical_record(
    record_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get a specific medical record"""
    record = db.query(MedicalRecord).filter(
        MedicalRecord.id == record_id,
        MedicalRecord.user_id == current_user.id
    ).first()
    
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medical record not found"
        )
    
    return record

@router.delete("/{record_id}")
async def delete_medical_record(
    record_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a medical record"""
    record = db.query(MedicalRecord).filter(
        MedicalRecord.id == record_id,
        MedicalRecord.user_id == current_user.id
    ).first()
    
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medical record not found"
        )
    
    # Delete file from filesystem
    try:
        if os.path.exists(record.file_path):
            os.remove(record.file_path)
    except Exception as e:
        print(f"Error deleting file {record.file_path}: {e}")
    
    # Delete database record
    db.delete(record)
    db.commit()
    
    return {"message": "Medical record deleted successfully"}

# Admin endpoints
@router.get("/admin/all", response_model=List[MedicalRecordResponse])
async def get_all_medical_records(
    skip: int = 0,
    limit: int = 100,
    user_id: int = None,
    is_verified: bool = None,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all medical records (admin only)"""
    query = db.query(MedicalRecord)
    
    if user_id:
        query = query.filter(MedicalRecord.user_id == user_id)
    
    if is_verified is not None:
        query = query.filter(MedicalRecord.is_verified == is_verified)
    
    records = query.offset(skip).limit(limit).all()
    return records

@router.put("/{record_id}/verify")
async def verify_medical_record(
    record_id: int,
    is_verified: bool,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Verify or reject a medical record (admin only)"""
    record = db.query(MedicalRecord).filter(MedicalRecord.id == record_id).first()
    
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medical record not found"
        )
    
    record.is_verified = is_verified
    record.verified_by = admin_user.id
    record.verified_at = db.query(MedicalRecord).filter(MedicalRecord.id == record_id).first().updated_at
    
    db.commit()
    db.refresh(record)
    
    return {"message": f"Medical record {'verified' if is_verified else 'rejected'} successfully"}

@router.get("/admin/users/{user_id}/medical-records", response_model=List[MedicalRecordResponse])
async def get_user_medical_records_admin(
    user_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get medical records for a specific user (admin only)"""
    try:
        records = db.query(MedicalRecord).filter(
            MedicalRecord.user_id == user_id
        ).order_by(MedicalRecord.created_at.desc()).all()
        
        return records
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error: {str(e)}"
        )

@router.get("/{record_id}/file")
async def get_medical_record_file(
    record_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get medical record file (admin only)"""
    record = db.query(MedicalRecord).filter(MedicalRecord.id == record_id).first()
    
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medical record not found"
        )
    
    # Check if file exists
    if not record.file_path or not os.path.exists(record.file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found"
        )
    
    # Determine content type based on file extension
    file_ext = Path(record.file_path).suffix.lower()
    content_type_map = {
        '.pdf': 'application/pdf',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.doc': 'application/msword',
        '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    }
    content_type = content_type_map.get(file_ext, 'application/octet-stream')
    
    # Read and return file
    try:
        with open(record.file_path, 'rb') as file:
            content = file.read()
        
        return Response(
            content=content,
            media_type=content_type,
            headers={
                "Content-Disposition": f"inline; filename={record.file_name}",
                "Cache-Control": "no-cache"
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error reading file: {str(e)}"
        )

@router.delete("/admin/{record_id}")
async def delete_medical_record_admin(
    record_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Delete a medical record (admin only)"""
    record = db.query(MedicalRecord).filter(MedicalRecord.id == record_id).first()
    
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medical record not found"
        )
    
    # Delete file from filesystem
    try:
        if os.path.exists(record.file_path):
            os.remove(record.file_path)
    except Exception as e:
        print(f"Error deleting file {record.file_path}: {e}")
    
    # Delete database record
    db.delete(record)
    db.commit()
    
    return {"message": "Medical record deleted successfully"}
