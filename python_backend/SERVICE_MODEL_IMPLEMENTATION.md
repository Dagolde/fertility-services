# Service Model Implementation - Task 4.1

## Overview
This document describes the implementation of the Service database model and migrations for the Service Catalog Management feature (Requirements 2.1, 2.2, 2.3, 2.4).

## Changes Made

### 1. Service Model Updates (`app/models.py`)

#### New Enum: ServiceCategory
Added a new enum to support service categories as specified in the requirements:
- `IVF` - In Vitro Fertilization
- `IUI` - Intrauterine Insemination
- `FERTILITY_TESTING` - Fertility Testing
- `CONSULTATION` - Consultation
- `EGG_FREEZING` - Egg Freezing
- `OTHER` - Other services

#### Updated Service Model Fields
The Service model now includes the following fields:

**Required Fields:**
- `id` (Integer, Primary Key) - Unique identifier
- `hospital_id` (Integer, Foreign Key) - Links service to hospital
- `name` (String, 255) - Service name
- `price` (Decimal, 10,2) - Service price (must be positive)
- `category` (Enum) - Service category from ServiceCategory enum

**Optional Fields:**
- `description` (Text) - Detailed service description
- `duration_minutes` (Integer, default: 60) - Service duration
- `is_active` (Boolean, default: True) - Whether service is active
- `is_featured` (Boolean, default: False) - Whether service is featured
- `service_type` (String, 50) - Additional service type classification
- `view_count` (Integer, default: 0) - Number of times service was viewed
- `booking_count` (Integer, default: 0) - Number of times service was booked
- `created_at` (DateTime) - Creation timestamp
- `updated_at` (DateTime) - Last update timestamp

#### Relationships
- `hospital` - Many-to-one relationship with Hospital model
- `appointments` - One-to-many relationship with Appointment model

#### Validation
Added `validate_price()` method that ensures:
- Price is not None
- Price is greater than 0 (positive number)
- Raises `ValueError` if validation fails

### 2. Database Migration (`alembic/versions/20260303170000_update_service_model_for_catalog.py`)

#### Migration Details
- **Revision ID:** 20260303170000
- **Revises:** 20260303162006
- **Created:** 2026-03-03 17:00:00

#### Upgrade Operations
1. **Add hospital_id column** with foreign key constraint to hospitals table
2. **Add category enum column** with ServiceCategory values
3. **Add is_featured column** (Boolean, default: False)
4. **Add view_count column** (Integer, default: 0)
5. **Add booking_count column** (Integer, default: 0)
6. **Create indexes:**
   - `idx_hospital` on hospital_id
   - `idx_category` on category
   - `idx_featured` on is_featured
   - `idx_price` on price
7. **Create full-text search index** on name and description fields
8. **Update existing records** to set default category to 'Other'
9. **Make category NOT NULL** after setting defaults

#### Downgrade Operations
Reverses all changes:
- Drops all indexes
- Drops all new columns
- Removes foreign key constraint

### 3. Indexes Created

The following indexes were created for query performance:

1. **idx_hospital** - For filtering services by hospital
2. **idx_category** - For filtering services by category
3. **idx_featured** - For filtering featured services
4. **idx_price** - For sorting/filtering by price
5. **idx_search** (FULLTEXT) - For full-text search on name and description

### 4. Verification Script (`verify_service_model.py`)

Created a comprehensive test script that verifies:
- Service creation with valid data
- Price validation for positive prices
- Price validation rejection for negative prices
- Price validation rejection for zero prices
- All service categories work correctly
- Default values are properly defined

## Requirements Satisfied

✅ **Requirement 2.1** - Service catalog allows hospitals to create, update, and delete service offerings
- Model supports CRUD operations with proper relationships

✅ **Requirement 2.2** - Service creation requires name, description, price, duration, and category
- All required fields are defined in the model

✅ **Requirement 2.3** - Service prices must be positive numbers
- `validate_price()` method enforces positive price validation

✅ **Requirement 2.4** - Support for service categories (IVF, IUI, Fertility_Testing, Consultation, Egg_Freezing)
- ServiceCategory enum includes all required categories plus OTHER

## Database Schema

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
    FULLTEXT INDEX idx_search (name, description)
);
```

## Usage Example

```python
from app.models import Service, ServiceCategory
from decimal import Decimal

# Create a new service
service = Service(
    hospital_id=1,
    name="IVF Treatment Package",
    description="Comprehensive IVF treatment with consultation",
    price=Decimal("5000.00"),
    duration_minutes=120,
    category=ServiceCategory.IVF,
    is_active=True,
    is_featured=True
)

# Validate price before saving
service.validate_price()  # Raises ValueError if price <= 0

# Save to database
db.add(service)
db.commit()
```

## Next Steps

The following tasks should be completed next:
- **Task 4.2** - Implement service catalog service layer
- **Task 4.3** - Write unit tests for service catalog
- **Task 4.4** - Implement service catalog API endpoints
- **Task 4.5** - Write integration tests for service endpoints

## Testing

Run the verification script to test the model:
```bash
cd python_backend
python verify_service_model.py
```

All tests should pass with output showing:
- ✓ Service creation with valid data
- ✓ Price validation for positive prices
- ✓ Price validation rejection for negative/zero prices
- ✓ All service categories working correctly
- ✓ Default values properly defined

## Migration Commands

To apply the migration:
```bash
cd python_backend
alembic upgrade head
```

To rollback the migration:
```bash
cd python_backend
alembic downgrade -1
```
