# Service Catalog Service Implementation

## Overview

The `ServiceCatalogService` provides a comprehensive service layer for managing the service catalog in the Fertility Services Platform. It implements CRUD operations, soft delete (archive), CSV import/export, and tracking of view counts and booking counts.

## Features

### 1. CRUD Operations

#### Create Service
```python
service = service_catalog.create_service(
    hospital_id=1,
    name="IVF Treatment",
    description="In-vitro fertilization treatment",
    price=Decimal("500000.00"),
    duration_minutes=120,
    category=ServiceCategory.IVF,
    service_type="fertility",
    is_featured=True
)
```

**Validation:**
- Price must be a positive number (> 0)
- All required fields must be provided

#### Read Service
```python
# Get single service
service = service_catalog.get_service(service_id=1)

# Get services with filters
services = service_catalog.get_services(
    hospital_id=1,
    category=ServiceCategory.IVF,
    is_active=True,
    is_featured=True,
    price_min=Decimal("10000.00"),
    price_max=Decimal("1000000.00"),
    skip=0,
    limit=50
)
```

**Available Filters:**
- `hospital_id`: Filter by hospital
- `category`: Filter by service category (IVF, IUI, CONSULTATION, etc.)
- `is_active`: Filter by active status
- `is_featured`: Filter by featured status
- `price_min`: Minimum price
- `price_max`: Maximum price
- `skip`: Pagination offset
- `limit`: Maximum results (default: 50)

#### Update Service
```python
updated_service = service_catalog.update_service(
    service_id=1,
    name="Updated IVF Treatment",
    price=Decimal("550000.00"),
    is_featured=False
)
```

**Updatable Fields:**
- `name`: Service name
- `description`: Service description
- `price`: Service price (must be positive)
- `duration_minutes`: Duration in minutes
- `category`: Service category
- `service_type`: Service type
- `is_featured`: Featured status
- `is_active`: Active status

#### Delete Service (Soft Delete)
```python
result = service_catalog.delete_service(service_id=1)
# Returns: {
#     "status": "archived",
#     "message": "Service 'IVF Treatment' has been archived",
#     "service_id": 1
# }
```

**Soft Delete Behavior:**
- Sets `is_active=False` instead of deleting the record
- Preserves historical data and relationships
- Prevents deletion if service has active appointments (PENDING or CONFIRMED)

### 2. View Count and Booking Count Tracking

#### Increment View Count
```python
service = service_catalog.increment_view_count(service_id=1)
# service.view_count is now incremented by 1
```

**Use Case:** Track when users view service details

#### Increment Booking Count
```python
service = service_catalog.increment_booking_count(service_id=1)
# service.booking_count is now incremented by 1
```

**Use Case:** Track when users book appointments for this service

### 3. CSV Import

#### Import Services from CSV
```python
with open('services.csv', 'rb') as csv_file:
    result = service_catalog.import_services_from_csv(
        hospital_id=1,
        csv_file=csv_file
    )

# Returns: {
#     "imported_count": 10,
#     "error_count": 2,
#     "errors": [
#         {"row": 5, "error": "Invalid category: INVALID", "data": {...}},
#         {"row": 8, "error": "Name is required", "data": {...}}
#     ]
# }
```

**CSV Format:**
```csv
name,description,price,duration_minutes,category,service_type,is_featured
IVF Treatment,In-vitro fertilization,500000.00,120,IVF,fertility,true
Fertility Consultation,Initial consultation,25000.00,60,CONSULTATION,consultation,false
IUI Treatment,Intrauterine insemination,150000.00,90,IUI,fertility,false
```

**Required Fields:**
- `name`: Service name (required)
- `price`: Service price (required, must be positive)
- `category`: Service category (required, must be valid enum value)

**Optional Fields:**
- `description`: Service description
- `duration_minutes`: Duration in minutes (default: 60)
- `service_type`: Service type
- `is_featured`: Featured status (true/false, default: false)

**Valid Categories:**
- `IVF`: In-vitro fertilization
- `IUI`: Intrauterine insemination
- `FERTILITY_TESTING`: Fertility testing
- `CONSULTATION`: Consultation
- `EGG_FREEZING`: Egg freezing
- `OTHER`: Other services

**Error Handling:**
- Continues processing even if some rows fail
- Returns detailed error information for failed rows
- Returns first 10 errors in response

### 4. CSV Export

#### Export Services to CSV
```python
csv_content = service_catalog.export_services_to_csv(
    hospital_id=1,
    is_active=True
)

# Save to file
with open('exported_services.csv', 'w') as f:
    f.write(csv_content)
```

**Export Format:**
```csv
id,hospital_id,name,description,price,duration_minutes,category,service_type,is_featured,is_active,view_count,booking_count,created_at,updated_at
1,1,IVF Treatment,In-vitro fertilization,500000.00,120,IVF,fertility,true,true,25,10,2024-01-15T10:00:00,2024-01-15T10:00:00
```

**Export Options:**
- `hospital_id`: Filter by hospital (optional)
- `is_active`: Filter by active status (optional)
- Exports up to 10,000 services

## Requirements Mapping

This implementation satisfies the following requirements from the spec:

### Requirement 2.1
✓ **THE Service_Catalog SHALL allow Hospitals to create, update, and delete service offerings**
- Implemented via `create_service()`, `update_service()`, and `delete_service()` methods

### Requirement 2.8
✓ **WHEN a service is deleted, THE Service_Catalog SHALL archive the service rather than permanently delete it**
- Implemented via soft delete in `delete_service()` method (sets `is_active=False`)

### Requirement 2.9
✓ **THE Service_Catalog SHALL prevent deletion of services with active appointments**
- Implemented in `delete_service()` method with check for PENDING or CONFIRMED appointments

### Requirement 2.10
✓ **THE Service_Catalog SHALL support bulk import of services via CSV format**
- Implemented via `import_services_from_csv()` method

### Requirement 2.11
✓ **THE Service_Catalog_Parser SHALL parse CSV service data into Service objects**
- Implemented in `import_services_from_csv()` method using Python's csv module

### Requirement 2.12
✓ **THE Service_Catalog_Printer SHALL format Service objects back into valid CSV format**
- Implemented via `export_services_to_csv()` method

## Usage Examples

### Example 1: Hospital Creates Services
```python
from app.services.service_catalog_service import ServiceCatalogService
from app.models import ServiceCategory
from decimal import Decimal

# Initialize service
db = get_db()
service_catalog = ServiceCatalogService(db)

# Create IVF service
ivf_service = service_catalog.create_service(
    hospital_id=hospital.id,
    name="IVF Treatment Package",
    description="Complete IVF treatment with monitoring",
    price=Decimal("500000.00"),
    duration_minutes=120,
    category=ServiceCategory.IVF,
    is_featured=True
)

# Create consultation service
consultation = service_catalog.create_service(
    hospital_id=hospital.id,
    name="Initial Fertility Consultation",
    description="Meet with our fertility specialist",
    price=Decimal("25000.00"),
    duration_minutes=60,
    category=ServiceCategory.CONSULTATION
)
```

### Example 2: Search and Filter Services
```python
# Get all active IVF services
ivf_services = service_catalog.get_services(
    category=ServiceCategory.IVF,
    is_active=True
)

# Get featured services under 100,000
affordable_featured = service_catalog.get_services(
    is_featured=True,
    price_max=Decimal("100000.00")
)

# Get services for specific hospital
hospital_services = service_catalog.get_services(
    hospital_id=1,
    is_active=True,
    skip=0,
    limit=20
)
```

### Example 3: Track Service Analytics
```python
# When user views service details
service_catalog.increment_view_count(service_id=1)

# When user books appointment
service_catalog.increment_booking_count(service_id=1)

# Get service with updated counts
service = service_catalog.get_service(service_id=1)
conversion_rate = (service.booking_count / service.view_count * 100) if service.view_count > 0 else 0
print(f"Conversion rate: {conversion_rate:.2f}%")
```

### Example 4: Bulk Import Services
```python
# Prepare CSV file
csv_data = """name,description,price,duration_minutes,category,service_type,is_featured
IVF Treatment,In-vitro fertilization,500000.00,120,IVF,fertility,true
IUI Treatment,Intrauterine insemination,150000.00,90,IUI,fertility,false
Fertility Testing,Comprehensive tests,50000.00,45,FERTILITY_TESTING,testing,false
Egg Freezing,Oocyte cryopreservation,300000.00,90,EGG_FREEZING,fertility,true
Consultation,Initial consultation,25000.00,60,CONSULTATION,consultation,false"""

# Import services
import io
csv_file = io.BytesIO(csv_data.encode('utf-8'))
result = service_catalog.import_services_from_csv(
    hospital_id=1,
    csv_file=csv_file
)

print(f"Imported: {result['imported_count']}")
print(f"Errors: {result['error_count']}")
```

### Example 5: Export Services for Backup
```python
# Export all active services for a hospital
csv_content = service_catalog.export_services_to_csv(
    hospital_id=1,
    is_active=True
)

# Save to file
with open(f'services_backup_{datetime.now().strftime("%Y%m%d")}.csv', 'w') as f:
    f.write(csv_content)
```

### Example 6: Archive Old Services
```python
# Archive a service (soft delete)
try:
    result = service_catalog.delete_service(service_id=5)
    print(result['message'])
except ValueError as e:
    print(f"Cannot archive: {e}")
    # Service might have active appointments
```

## Error Handling

The service raises `ValueError` exceptions for validation errors:

```python
try:
    service = service_catalog.create_service(
        hospital_id=1,
        name="Test Service",
        price=Decimal("-100.00"),  # Invalid: negative price
        duration_minutes=60,
        category=ServiceCategory.IVF
    )
except ValueError as e:
    print(f"Validation error: {e}")
    # Output: "Service price must be a positive number"
```

Common error scenarios:
- **Negative or zero price**: "Service price must be a positive number"
- **Service not found**: "Service not found"
- **Delete with active appointments**: "Cannot delete service with active appointments..."
- **CSV import errors**: Returns error details in response

## Testing

Run the test suite:
```bash
cd python_backend
python test_service_catalog_service.py
```

The test suite covers:
1. ✓ Create service with validation
2. ✓ Price validation (reject negative prices)
3. ✓ Get service by ID
4. ✓ Update service
5. ✓ Get services with filters
6. ✓ Increment view count
7. ✓ Increment booking count
8. ✓ Soft delete (archive)
9. ✓ Prevent deletion with active appointments
10. ✓ CSV export
11. ✓ CSV import with validation

## Integration with Other Services

### With Appointment Service
```python
# When appointment is confirmed, increment booking count
appointment_service.confirm_appointment(appointment_id, payment_id)
service_catalog.increment_booking_count(appointment.service_id)
```

### With Search Service
```python
# Track views when service appears in search results
search_results = search_service.search("IVF")
for result in search_results:
    if result.type == "service":
        service_catalog.increment_view_count(result.id)
```

## Database Schema

The service uses the `services` table:

```sql
CREATE TABLE services (
    id INT PRIMARY KEY AUTO_INCREMENT,
    hospital_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    duration_minutes INT DEFAULT 60,
    category ENUM('IVF', 'IUI', 'Fertility_Testing', 'Consultation', 'Egg_Freezing', 'Other') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    service_type VARCHAR(50),
    view_count INT DEFAULT 0,
    booking_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id),
    INDEX idx_hospital (hospital_id),
    INDEX idx_category (category),
    INDEX idx_featured (is_featured),
    INDEX idx_price (price),
    FULLTEXT idx_search (name, description)
);
```

## Performance Considerations

1. **Pagination**: Use `skip` and `limit` parameters for large result sets
2. **Indexes**: Database indexes on `hospital_id`, `category`, `is_featured`, and `price` for fast filtering
3. **Bulk Operations**: CSV import processes rows sequentially; consider batching for very large files
4. **Soft Delete**: Archived services remain in database; consider periodic cleanup of very old archived services

## Future Enhancements

Potential improvements for future iterations:
1. Add caching for frequently accessed services (similar to appointment service)
2. Implement full-text search on service name and description
3. Add service versioning for price history
4. Implement service availability schedules
5. Add service images and media support
6. Implement service bundles/packages
7. Add service reviews and ratings integration

## Conclusion

The `ServiceCatalogService` provides a robust, production-ready implementation for managing the service catalog with all required features including CRUD operations, soft delete, CSV import/export, and analytics tracking.
