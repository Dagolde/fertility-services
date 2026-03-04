"""
Service Catalog Service Layer

Handles CRUD operations for services, soft delete (archive), CSV import/export,
and tracking of view counts and booking counts.
"""

from datetime import datetime
from decimal import Decimal
from typing import List, Optional, Dict, Any, BinaryIO
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from sqlalchemy.exc import IntegrityError
import csv
import io
import logging

from ..models import Service, ServiceCategory, Appointment, AppointmentStatus

logger = logging.getLogger(__name__)


class ServiceCatalogService:
    """Service for managing service catalog with CRUD operations and CSV import/export."""
    
    def __init__(self, db: Session):
        """
        Initialize service catalog service.
        
        Args:
            db: Database session
        """
        self.db = db
    
    def create_service(
        self,
        hospital_id: int,
        name: str,
        description: Optional[str],
        price: Decimal,
        duration_minutes: int,
        category: ServiceCategory,
        service_type: Optional[str] = None,
        is_featured: bool = False
    ) -> Service:
        """
        Create a new service.
        
        Args:
            hospital_id: Hospital ID
            name: Service name
            description: Service description
            price: Service price (must be positive)
            duration_minutes: Duration in minutes
            category: Service category
            service_type: Optional service type
            is_featured: Whether service is featured
            
        Returns:
            Created service
            
        Raises:
            ValueError: If validation fails
        """
        # Validate price is positive
        if price <= 0:
            raise ValueError("Service price must be a positive number")
        
        # Create service
        service = Service(
            hospital_id=hospital_id,
            name=name,
            description=description,
            price=price,
            duration_minutes=duration_minutes,
            category=category,
            service_type=service_type,
            is_featured=is_featured,
            is_active=True,
            view_count=0,
            booking_count=0
        )
        
        try:
            self.db.add(service)
            self.db.commit()
            self.db.refresh(service)
            
            logger.info(f"Created service {service.id}: {service.name}")
            return service
            
        except IntegrityError as e:
            self.db.rollback()
            logger.error(f"Database integrity error creating service: {e}")
            raise ValueError("Failed to create service")
    
    def get_service(self, service_id: int) -> Optional[Service]:
        """
        Get a service by ID.
        
        Args:
            service_id: Service ID
            
        Returns:
            Service or None if not found
        """
        return self.db.query(Service).filter(Service.id == service_id).first()
    
    def get_services(
        self,
        hospital_id: Optional[int] = None,
        category: Optional[ServiceCategory] = None,
        is_active: Optional[bool] = None,
        is_featured: Optional[bool] = None,
        price_min: Optional[Decimal] = None,
        price_max: Optional[Decimal] = None,
        skip: int = 0,
        limit: int = 50
    ) -> List[Service]:
        """
        Get services with optional filters.
        
        Args:
            hospital_id: Filter by hospital ID
            category: Filter by category
            is_active: Filter by active status
            is_featured: Filter by featured status
            price_min: Minimum price filter
            price_max: Maximum price filter
            skip: Number of records to skip (pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of services
        """
        query = self.db.query(Service)
        
        if hospital_id is not None:
            query = query.filter(Service.hospital_id == hospital_id)
        
        if category is not None:
            query = query.filter(Service.category == category)
        
        if is_active is not None:
            query = query.filter(Service.is_active == is_active)
        
        if is_featured is not None:
            query = query.filter(Service.is_featured == is_featured)
        
        if price_min is not None:
            query = query.filter(Service.price >= price_min)
        
        if price_max is not None:
            query = query.filter(Service.price <= price_max)
        
        return query.offset(skip).limit(limit).all()
    
    def update_service(
        self,
        service_id: int,
        name: Optional[str] = None,
        description: Optional[str] = None,
        price: Optional[Decimal] = None,
        duration_minutes: Optional[int] = None,
        category: Optional[ServiceCategory] = None,
        service_type: Optional[str] = None,
        is_featured: Optional[bool] = None,
        is_active: Optional[bool] = None
    ) -> Service:
        """
        Update an existing service.
        
        Args:
            service_id: Service ID
            name: New service name
            description: New description
            price: New price (must be positive if provided)
            duration_minutes: New duration
            category: New category
            service_type: New service type
            is_featured: New featured status
            is_active: New active status
            
        Returns:
            Updated service
            
        Raises:
            ValueError: If service not found or validation fails
        """
        service = self.get_service(service_id)
        if not service:
            raise ValueError("Service not found")
        
        # Validate price if provided
        if price is not None and price <= 0:
            raise ValueError("Service price must be a positive number")
        
        # Update fields
        if name is not None:
            service.name = name
        if description is not None:
            service.description = description
        if price is not None:
            service.price = price
        if duration_minutes is not None:
            service.duration_minutes = duration_minutes
        if category is not None:
            service.category = category
        if service_type is not None:
            service.service_type = service_type
        if is_featured is not None:
            service.is_featured = is_featured
        if is_active is not None:
            service.is_active = is_active
        
        try:
            self.db.commit()
            self.db.refresh(service)
            
            logger.info(f"Updated service {service.id}")
            return service
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error updating service: {e}")
            raise ValueError("Failed to update service")
    
    def delete_service(self, service_id: int) -> Dict[str, Any]:
        """
        Soft delete (archive) a service by setting is_active=False.
        Prevents deletion of services with active appointments.
        
        Args:
            service_id: Service ID
            
        Returns:
            Dictionary with deletion status and message
            
        Raises:
            ValueError: If service not found or has active appointments
        """
        service = self.get_service(service_id)
        if not service:
            raise ValueError("Service not found")
        
        # Check for active appointments
        active_appointments = self.db.query(Appointment).filter(
            and_(
                Appointment.service_id == service_id,
                Appointment.status.in_([
                    AppointmentStatus.PENDING,
                    AppointmentStatus.CONFIRMED
                ])
            )
        ).first()
        
        if active_appointments:
            raise ValueError(
                "Cannot delete service with active appointments. "
                "Please cancel or complete all appointments first."
            )
        
        # Soft delete by setting is_active=False
        service.is_active = False
        
        try:
            self.db.commit()
            self.db.refresh(service)
            
            logger.info(f"Archived service {service.id}")
            return {
                "status": "archived",
                "message": f"Service '{service.name}' has been archived",
                "service_id": service.id
            }
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error archiving service: {e}")
            raise ValueError("Failed to archive service")
    
    def increment_view_count(self, service_id: int) -> Service:
        """
        Increment the view count for a service.
        
        Args:
            service_id: Service ID
            
        Returns:
            Updated service
            
        Raises:
            ValueError: If service not found
        """
        service = self.get_service(service_id)
        if not service:
            raise ValueError("Service not found")
        
        service.view_count += 1
        
        try:
            self.db.commit()
            self.db.refresh(service)
            return service
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error incrementing view count: {e}")
            raise ValueError("Failed to update view count")
    
    def increment_booking_count(self, service_id: int) -> Service:
        """
        Increment the booking count for a service.
        
        Args:
            service_id: Service ID
            
        Returns:
            Updated service
            
        Raises:
            ValueError: If service not found
        """
        service = self.get_service(service_id)
        if not service:
            raise ValueError("Service not found")
        
        service.booking_count += 1
        
        try:
            self.db.commit()
            self.db.refresh(service)
            return service
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error incrementing booking count: {e}")
            raise ValueError("Failed to update booking count")
    
    def import_services_from_csv(
        self,
        hospital_id: int,
        csv_file: BinaryIO
    ) -> Dict[str, Any]:
        """
        Import services from CSV file.
        
        CSV format:
        name,description,price,duration_minutes,category,service_type,is_featured
        
        Args:
            hospital_id: Hospital ID for all imported services
            csv_file: CSV file object
            
        Returns:
            Dictionary with import statistics
        """
        imported_count = 0
        error_count = 0
        errors = []
        
        try:
            # Read CSV file
            csv_content = csv_file.read().decode('utf-8')
            csv_reader = csv.DictReader(io.StringIO(csv_content))
            
            for row_num, row in enumerate(csv_reader, start=2):  # Start at 2 (header is row 1)
                try:
                    # Parse row data
                    name = row.get('name', '').strip()
                    description = row.get('description', '').strip() or None
                    price = Decimal(row.get('price', '0').strip())
                    duration_minutes = int(row.get('duration_minutes', '60').strip())
                    category_str = row.get('category', '').strip().upper()
                    service_type = row.get('service_type', '').strip() or None
                    is_featured = row.get('is_featured', 'false').strip().lower() in ['true', '1', 'yes']
                    
                    # Validate required fields
                    if not name:
                        raise ValueError("Name is required")
                    
                    # Parse category
                    try:
                        category = ServiceCategory[category_str]
                    except KeyError:
                        raise ValueError(f"Invalid category: {category_str}")
                    
                    # Create service
                    self.create_service(
                        hospital_id=hospital_id,
                        name=name,
                        description=description,
                        price=price,
                        duration_minutes=duration_minutes,
                        category=category,
                        service_type=service_type,
                        is_featured=is_featured
                    )
                    
                    imported_count += 1
                    
                except Exception as e:
                    error_count += 1
                    errors.append({
                        "row": row_num,
                        "error": str(e),
                        "data": row
                    })
                    logger.warning(f"Error importing row {row_num}: {e}")
            
            logger.info(
                f"CSV import completed: {imported_count} imported, "
                f"{error_count} errors"
            )
            
            return {
                "imported_count": imported_count,
                "error_count": error_count,
                "errors": errors[:10]  # Return first 10 errors
            }
            
        except Exception as e:
            logger.error(f"Error reading CSV file: {e}")
            raise ValueError(f"Failed to read CSV file: {str(e)}")
    
    def export_services_to_csv(
        self,
        hospital_id: Optional[int] = None,
        is_active: Optional[bool] = None
    ) -> str:
        """
        Export services to CSV format.
        
        Args:
            hospital_id: Optional filter by hospital ID
            is_active: Optional filter by active status
            
        Returns:
            CSV string
        """
        # Get services
        services = self.get_services(
            hospital_id=hospital_id,
            is_active=is_active,
            limit=10000  # Large limit for export
        )
        
        # Create CSV
        output = io.StringIO()
        fieldnames = [
            'id',
            'hospital_id',
            'name',
            'description',
            'price',
            'duration_minutes',
            'category',
            'service_type',
            'is_featured',
            'is_active',
            'view_count',
            'booking_count',
            'created_at',
            'updated_at'
        ]
        
        writer = csv.DictWriter(output, fieldnames=fieldnames)
        writer.writeheader()
        
        for service in services:
            writer.writerow({
                'id': service.id,
                'hospital_id': service.hospital_id,
                'name': service.name,
                'description': service.description or '',
                'price': str(service.price),
                'duration_minutes': service.duration_minutes,
                'category': service.category.value if service.category else '',
                'service_type': service.service_type or '',
                'is_featured': service.is_featured,
                'is_active': service.is_active,
                'view_count': service.view_count,
                'booking_count': service.booking_count,
                'created_at': service.created_at.isoformat() if service.created_at else '',
                'updated_at': service.updated_at.isoformat() if service.updated_at else ''
            })
        
        csv_content = output.getvalue()
        output.close()
        
        logger.info(f"Exported {len(services)} services to CSV")
        return csv_content
