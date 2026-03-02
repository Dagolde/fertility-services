from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, Service
from ..schemas import ServiceCreate, ServiceUpdate, ServiceResponse
from ..auth import get_current_active_user, get_admin_user

router = APIRouter()

@router.get("/", response_model=List[ServiceResponse])
async def get_all_services(
    skip: int = 0,
    limit: int = 100,
    service_type: str = None,
    is_active: bool = True,
    db: Session = Depends(get_db)
):
    """Get all available services."""
    query = db.query(Service)
    
    if service_type:
        query = query.filter(Service.service_type == service_type)
    
    if is_active is not None:
        query = query.filter(Service.is_active == is_active)
    
    services = query.offset(skip).limit(limit).all()
    return services

@router.get("/featured", response_model=List[ServiceResponse])
async def get_featured_services(
    skip: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    """Get featured services (most popular or recommended)."""
    # For now, return the first few active services
    # In the future, this could be based on popularity, ratings, etc.
    services = db.query(Service).filter(
        Service.is_active == True
    ).order_by(Service.created_at.desc()).offset(skip).limit(limit).all()
    
    return services

@router.get("/type/{service_type}", response_model=List[ServiceResponse])
async def get_services_by_type(
    service_type: str,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    """Get services by type (sperm_donation, egg_donation, surrogacy)."""
    services = db.query(Service).filter(
        Service.service_type == service_type,
        Service.is_active == True
    ).offset(skip).limit(limit).all()
    
    return services

@router.get("/{service_id}", response_model=ServiceResponse)
async def get_service_by_id(
    service_id: int,
    db: Session = Depends(get_db)
):
    """Get service by ID."""
    service = db.query(Service).filter(
        Service.id == service_id,
        Service.is_active == True
    ).first()
    
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    return service

# Admin endpoints
@router.post("/", response_model=ServiceResponse)
async def create_service(
    service_data: ServiceCreate,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Create a new service (admin only)."""
    # Check if service with same name and type already exists
    existing_service = db.query(Service).filter(
        Service.name == service_data.name,
        Service.service_type == service_data.service_type
    ).first()
    
    if existing_service:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Service with this name and type already exists"
        )
    
    db_service = Service(**service_data.dict())
    db.add(db_service)
    db.commit()
    db.refresh(db_service)
    
    return db_service

@router.put("/{service_id}", response_model=ServiceResponse)
async def update_service(
    service_id: int,
    service_update: ServiceUpdate,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Update service (admin only)."""
    service = db.query(Service).filter(Service.id == service_id).first()
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    for field, value in service_update.dict(exclude_unset=True).items():
        setattr(service, field, value)
    
    db.commit()
    db.refresh(service)
    
    return service

@router.delete("/{service_id}")
async def delete_service(
    service_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Delete service (admin only)."""
    service = db.query(Service).filter(Service.id == service_id).first()
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    # Soft delete by deactivating
    service.is_active = False
    db.commit()
    
    return {"message": "Service deleted successfully"}

@router.get("/admin/all", response_model=List[ServiceResponse])
async def get_all_services_admin(
    skip: int = 0,
    limit: int = 100,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all services including inactive ones (admin only)."""
    services = db.query(Service).offset(skip).limit(limit).all()
    return services

@router.get("/stats/overview")
async def get_service_stats(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get service statistics (admin only)."""
    total_services = db.query(Service).count()
    active_services = db.query(Service).filter(Service.is_active == True).count()
    inactive_services = db.query(Service).filter(Service.is_active == False).count()
    
    # Count by service type
    sperm_donation_count = db.query(Service).filter(
        Service.service_type == "sperm_donation",
        Service.is_active == True
    ).count()
    
    egg_donation_count = db.query(Service).filter(
        Service.service_type == "egg_donation",
        Service.is_active == True
    ).count()
    
    surrogacy_count = db.query(Service).filter(
        Service.service_type == "surrogacy",
        Service.is_active == True
    ).count()
    
    return {
        "total_services": total_services,
        "active_services": active_services,
        "inactive_services": inactive_services,
        "by_type": {
            "sperm_donation": sperm_donation_count,
            "egg_donation": egg_donation_count,
            "surrogacy": surrogacy_count
        }
    }
