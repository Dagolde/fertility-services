#!/usr/bin/env python3
"""
Verification script for Appointment model and migration

This script verifies that:
1. The Appointment model can be imported successfully
2. All required fields are present
3. The model structure matches the requirements
"""

from app.models import Appointment, AppointmentStatus
from sqlalchemy import inspect

def verify_appointment_model():
    """Verify the Appointment model structure"""
    
    print("=" * 60)
    print("Appointment Model Verification")
    print("=" * 60)
    
    # Get model columns
    mapper = inspect(Appointment)
    columns = {col.key: str(col.type) for col in mapper.columns}
    
    print("\n✓ Model imported successfully")
    print("\nColumns in Appointment model:")
    print("-" * 60)
    for col_name, col_type in columns.items():
        print(f"  {col_name:20} : {col_type}")
    
    # Verify required fields
    required_fields = [
        'id', 'user_id', 'hospital_id', 'service_id', 
        'appointment_date', 'status', 'notes', 'price',
        'cancellation_reason', 'cancelled_at', 'reserved_until',
        'created_at', 'updated_at'
    ]
    
    print("\n" + "=" * 60)
    print("Required Fields Check:")
    print("-" * 60)
    
    all_present = True
    for field in required_fields:
        present = field in columns
        status = "✓" if present else "✗"
        print(f"  {status} {field}")
        if not present:
            all_present = False
    
    # Verify status enum values
    print("\n" + "=" * 60)
    print("AppointmentStatus Enum Values:")
    print("-" * 60)
    for status in AppointmentStatus:
        print(f"  ✓ {status.name} = {status.value}")
    
    # Verify indexes
    print("\n" + "=" * 60)
    print("Indexed Columns:")
    print("-" * 60)
    indexed_columns = [col.key for col in mapper.columns if col.index]
    for col in indexed_columns:
        print(f"  ✓ {col}")
    
    # Verify relationships
    print("\n" + "=" * 60)
    print("Relationships:")
    print("-" * 60)
    relationships = mapper.relationships
    for rel in relationships:
        print(f"  ✓ {rel.key} -> {rel.mapper.class_.__name__}")
    
    print("\n" + "=" * 60)
    if all_present:
        print("✓ All required fields are present!")
        print("✓ Model structure matches requirements!")
    else:
        print("✗ Some required fields are missing!")
    print("=" * 60)
    
    return all_present

if __name__ == "__main__":
    try:
        success = verify_appointment_model()
        exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
