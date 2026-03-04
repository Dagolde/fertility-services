"""
Service Catalog API Endpoints

Implements service catalog management including CRUD operations,
filtering, CSV import/export, and service archiving.
Follows the design specification for Requirements 2.1, 2.5, 2.6, 2.10.
"""

from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from fastapi.responses import Response
from sqlalchemy.orm import Session
from decimal import Decimal
import logging

from ..database import get_db
from ..models import User, Service, ServiceCategory
from ..schemas import (
    ServiceCreate, ServiceUpdate, ServiceResponse,
    ServiceListResponse, ServiceImportResponse, ServiceArchiveResponse
)
from ..auth import get_current_active_user, get_hospital_user
from ..services.service_catalog_service import ServiceCatalogService

logger = logging.getLogger(__name__)
router = APIRouter()


def get_service_catalog_service(db: Session = Depends(get_db)) -> ServiceCatalogService:
    """Dependency to get service catalog service instance."""
    return ServiceCatalogService(db)


@router.get("", response_model=ServiceListResponse)
async def list_services(
    hospital_id: Optional[int] = Query(None, description="Filter by hospital ID"),
    category: Optional[str] = Query(None, description="Filter by category"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    is_featured: Optional[bool] = Query(None, description="Filter by featured status"),
    price_min: Optional[float] = Query(None, description="Minimum price filter"),
    price_max: Optional[float] = Query(None, description="Maximum price filter"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=50, description="Items per page"),
    service_catalog: ServiceCatalogService = Depends(get_service_catalog_service),
    db: Session = Depends(get_db)
):
    """
    List services with filters.
    
    Requirements: 2.1, 2.5 - List services with filters and search within 500ms
    
    Args:
        hospital_id: Optional hospital ID filter
        category: Optional category filter
        is_active: Optional active status filter
        is_featured: Optional featured status filter
        price_min: Optional minimum price filter
        price_max: Optional maximum price filter
        page: Page number for pagination
        limit: Items per page
        service_catalog: Service catalog service instance
        db: Database session
        
    Returns:
        List of services with pagination info
        
    Raises:
        HTTPException: If validation fails
    """
    try:
        # Parse category if provided
        category_enum = None
        if category:
            try:
                category_enum = ServiceCategory[category.upper()]
            except KeyError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid category: {category}. Valid categories: {[c.value for c in ServiceCategory]}"
                )
        
        # Convert price to Decimal if provided
        price_min_decimal = Decimal(str(price_min)) if price_min is not None else None
        price_max_decimal = Decimal(str(price_max)) if price_max is not None else None
        
        # Calculate skip for pagination
        skip = (page - 1) * limit
        
        # Get services
        services = service_catalog.get_services(
            hospital_id=hospital_id,
            category=category_enum,
            is_active=is_active,
            is_featured=is_featured,
            price_min=price_min_decimal,
            price_max=price_max_decimal,
            skip=skip,
            limit=limit
        )
        
        # Get total count for pagination
        total = db.query(Service).count()
        
        return ServiceListResponse(
            services=[ServiceResponse.model_validate(s) for s in services],
            total=total,
            page=page,
            limit=limit
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing services: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve services"
        )


@router.get("/featured", response_model=List[ServiceResponse])
async def get_featured_services(
    limit: int = Query(10, ge=1, le=50, description="Number of featured services to return"),
    service_catalog: ServiceCatalogService = Depends(get_service_catalog_service)
):
    """
    Get featured services.
    
    Args:
        limit: Maximum number of featured services to return
        service_catalog: Service catalog service instance
        
    Returns:
        List of featured services
        
    Raises:
        HTTPException: If retrieval fails
    """
    try:
        services = service_catalog.get_services(
            is_active=True,
            is_featured=True,
            skip=0,
            limit=limit
        )
        
        return [ServiceResponse.model_validate(s) for s in services]
        
    except Exception as e:
        logger.error(f"Error retrieving featured services: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve featured services"
        )


@router.post("", response_model=ServiceResponse, status_code=status.HTTP_201_CREATED)
async def create_service(
    service_data: ServiceCreate,
    current_user: User = Depends(get_hospital_user),
    service_catalog: ServiceCatalogService = Depends(get_service_catalog_service),
    db: Session = Depends(get_db)
):
    """
    Create a new service (hospital authentication required).
    
    Requirements: 2.1, 2.2, 2.3 - Create service with validation
    
    Args:
        service_data: Service creation data
        current_user: Authenticated hospital user
        service_catalog: Service catalog service instance
        db: Database session
        
    Returns:
        Created service
        
    Raises:
        HTTPException: If validation fails or user not authorized
    """
    try:
        # Verify hospital ownership
        from ..models import Hospital
        hospital = db.query(Hospital).filter(Hospital.id == service_data.hospital_id).first()
        
        if not hospital:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hospital not found"
            )
        
        if hospital.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to create services for this hospital"
            )
        
        # Parse category
        try:
            category_enum = ServiceCategory[service_data.category.value.upper()]
        except (KeyError, AttributeError):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid category: {service_data.category}"
            )
        
        # Create service
        service = service_catalog.create_service(
            hospital_id=service_data.hospital_id,
            name=service_data.name,
            description=service_data.description,
            price=Decimal(str(service_data.price)),
            duration_minutes=service_data.duration_minutes,
            category=category_enum,
            service_type=service_data.service_type,
            is_featured=service_data.is_featured
        )
        
        return ServiceResponse.model_validate(service)
        
    except ValueError as e:
        logger.error(f"Service creation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error creating service: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create service"
        )


@router.get("/{id}", response_model=ServiceResponse)
async def get_service(
    id: int,
    service_catalog: ServiceCatalogService = Depends(get_service_catalog_service)
):
    """
    Get a service by ID.
    
    Args:
        id: Service ID
        service_catalog: Service catalog service instance
        
    Returns:
        Service details
        
    Raises:
        HTTPException: If service not found
    """
    service = service_catalog.get_service(id)
    
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    # Increment view count
    try:
        service_catalog.increment_view_count(id)
    except Exception as e:
        logger.warning(f"Failed to increment view count: {e}")
    
    return ServiceResponse.model_validate(service)


@router.put("/{id}", response_model=ServiceResponse)
async def update_service(
    id: int,
    service_data: ServiceUpdate,
    current_user: User = Depends(get_hospital_user),
    service_catalog: ServiceCatalogService = Depends(get_service_catalog_service),
    db: Session = Depends(get_db)
):
    """
    Update an existing service (hospital authentication required).
    
    Requirements: 2.1 - Update service
    
    Args:
        id: Service ID
        service_data: Service update data
        current_user: Authenticated hospital user
        service_catalog: Service catalog service instance
        db: Database session
        
    Returns:
        Updated service
        
    Raises:
        HTTPException: If service not found or user not authorized
    """
    try:
        # Get service
        service = service_catalog.get_service(id)
        if not service:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Service not found"
            )
        
        # Verify hospital ownership
        from ..models import Hospital
        hospital = db.query(Hospital).filter(Hospital.id == service.hospital_id).first()
        
        if not hospital or hospital.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this service"
            )
        
        # Parse category if provided
        category_enum = None
        if service_data.category:
            try:
                category_enum = ServiceCategory[service_data.category.value.upper()]
            except (KeyError, AttributeError):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid category: {service_data.category}"
                )
        
        # Convert price to Decimal if provided
        price_decimal = Decimal(str(service_data.price)) if service_data.price is not None else None
        
        # Update service
        updated_service = service_catalog.update_service(
            service_id=id,
            name=service_data.name,
            description=service_data.description,
            price=price_decimal,
            duration_minutes=service_data.duration_minutes,
            category=category_enum,
            service_type=service_data.service_type,
            is_featured=service_data.is_featured,
            is_active=service_data.is_active
        )
        
        return ServiceResponse.model_validate(updated_service)
        
    except ValueError as e:
        logger.error(f"Service update error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error updating service: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update service"
        )


@router.delete("/{id}", response_model=ServiceArchiveResponse)
async def delete_service(
    id: int,
    current_user: User = Depends(get_hospital_user),
    service_catalog: ServiceCatalogService = Depends(get_service_catalog_service),
    db: Session = Depends(get_db)
):
    """
    Archive a service (soft delete).
    
    Requirements: 2.8, 2.9 - Archive service, prevent deletion with active appointments
    
    Args:
        id: Service ID
        current_user: Authenticated hospital user
        service_catalog: Service catalog service instance
        db: Database session
        
    Returns:
        Archive confirmation
        
    Raises:
        HTTPException: If service not found, has active appointments, or user not authorized
    """
    try:
        # Get service
        service = service_catalog.get_service(id)
        if not service:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Service not found"
            )
        
        # Verify hospital ownership
        from ..models import Hospital
        hospital = db.query(Hospital).filter(Hospital.id == service.hospital_id).first()
        
        if not hospital or hospital.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this service"
            )
        
        # Delete (archive) service
        result = service_catalog.delete_service(id)
        
        return ServiceArchiveResponse(**result)
        
    except ValueError as e:
        logger.error(f"Service deletion error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error deleting service: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete service"
        )


@router.post("/import", response_model=ServiceImportResponse)
async def import_services(
    file: UploadFile = File(..., description="CSV file with services"),
    hospital_id: int = Query(..., description="Hospital ID for imported services"),
    current_user: User = Depends(get_hospital_user),
    service_catalog: ServiceCatalogService = Depends(get_service_catalog_service),
    db: Session = Depends(get_db)
):
    """
    Bulk import services from CSV file.
    
    Requirements: 2.10, 2.11 - Bulk import from CSV
    
    CSV format:
    name,description,price,duration_minutes,category,service_type,is_featured
    
    Args:
        file: CSV file upload
        hospital_id: Hospital ID for all imported services
        current_user: Authenticated hospital user
        service_catalog: Service catalog service instance
        db: Database session
        
    Returns:
        Import statistics
        
    Raises:
        HTTPException: If file invalid or user not authorized
    """
    try:
        # Verify hospital ownership
        from ..models import Hospital
        hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
        
        if not hospital:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hospital not found"
            )
        
        if hospital.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to import services for this hospital"
            )
        
        # Validate file type
        if not file.filename.endswith('.csv'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be a CSV file"
            )
        
        # Import services
        result = service_catalog.import_services_from_csv(
            hospital_id=hospital_id,
            csv_file=file.file
        )
        
        return ServiceImportResponse(**result)
        
    except ValueError as e:
        logger.error(f"Service import error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error importing services: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to import services"
        )


@router.get("/export", response_class=Response)
async def export_services(
    hospital_id: Optional[int] = Query(None, description="Filter by hospital ID"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    current_user: User = Depends(get_hospital_user),
    service_catalog: ServiceCatalogService = Depends(get_service_catalog_service),
    db: Session = Depends(get_db)
):
    """
    Export services to CSV file.
    
    Requirements: 2.10, 2.12 - Export to CSV
    
    Args:
        hospital_id: Optional hospital ID filter
        is_active: Optional active status filter
        current_user: Authenticated hospital user
        service_catalog: Service catalog service instance
        db: Database session
        
    Returns:
        CSV file download
        
    Raises:
        HTTPException: If user not authorized
    """
    try:
        # If hospital_id provided, verify ownership
        if hospital_id:
            from ..models import Hospital
            hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
            
            if not hospital:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Hospital not found"
                )
            
            if hospital.user_id != current_user.id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Not authorized to export services for this hospital"
                )
        else:
            # If no hospital_id, export only current user's hospital services
            from ..models import Hospital
            hospital = db.query(Hospital).filter(Hospital.user_id == current_user.id).first()
            
            if hospital:
                hospital_id = hospital.id
        
        # Export services
        csv_content = service_catalog.export_services_to_csv(
            hospital_id=hospital_id,
            is_active=is_active
        )
        
        # Return CSV file
        return Response(
            content=csv_content,
            media_type="text/csv",
            headers={
                "Content-Disposition": f"attachment; filename=services_export_{hospital_id or 'all'}.csv"
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error exporting services: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to export services"
        )
