#!/usr/bin/env python3
"""
Script to check and fix medical records with invalid enum values
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal
from app.models import MedicalRecord, MedicalRecordType
from sqlalchemy import text

def check_and_fix_medical_records():
    """Check for medical records with invalid enum values and fix them"""
    db = SessionLocal()
    
    try:
        # Check for any medical records
        records = db.query(MedicalRecord).all()
        print(f"Found {len(records)} medical records in database")
        
        if not records:
            print("No medical records found. Database is clean.")
            return
        
        # Check each record's enum value
        invalid_records = []
        for record in records:
            try:
                # Try to access the enum value
                enum_value = record.record_type.value
                print(f"Record {record.id}: {enum_value} (valid)")
            except Exception as e:
                print(f"Record {record.id}: INVALID - {e}")
                invalid_records.append(record)
        
        if invalid_records:
            print(f"\nFound {len(invalid_records)} invalid records. Attempting to fix...")
            
            # Try to fix by updating to a default value
            for record in invalid_records:
                try:
                    # Set to OTHER as default
                    record.record_type = MedicalRecordType.OTHER
                    print(f"Fixed record {record.id}: set to OTHER")
                except Exception as e:
                    print(f"Failed to fix record {record.id}: {e}")
            
            # Commit changes
            try:
                db.commit()
                print("Successfully fixed invalid records")
            except Exception as e:
                print(f"Failed to commit fixes: {e}")
                db.rollback()
        else:
            print("All medical records have valid enum values.")
            
    except Exception as e:
        print(f"Error checking medical records: {e}")
        db.rollback()
    finally:
        db.close()

def check_enum_values():
    """Check what enum values are available"""
    print("Available MedicalRecordType enum values:")
    for enum_value in MedicalRecordType:
        print(f"  {enum_value.value}")
    print()

if __name__ == "__main__":
    print("=== Medical Records Enum Check and Fix ===")
    print()
    
    check_enum_values()
    check_and_fix_medical_records()
    
    print("\n=== Done ===")
