#!/usr/bin/env python3
"""
Verification script for Review model and migration.
Tests that the Review model is properly defined with all required fields and constraints.
"""

import sys
from datetime import datetime, timedelta
from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import sessionmaker
from app.models import Base, Review, User, Hospital, Appointment, Service, UserType, HospitalType, ServiceCategory, AppointmentStatus

def verify_review_model():
    """Verify Review model structure and validation methods"""
    print("=" * 60)
    print("REVIEW MODEL VERIFICATION")
    print("=" * 60)
    
    # Check Review model attributes
    print("\n1. Checking Review model attributes...")
    required_fields = [
        'id', 'user_id', 'hospital_id', 'appointment_id', 'rating', 'comment',
        'is_flagged', 'flag_count', 'is_hidden', 'hospital_response',
        'hospital_response_date', 'is_immutable', 'immutable_after',
        'created_at', 'updated_at'
    ]
    
    review_columns = [col.name for col in Review.__table__.columns]
    missing_fields = [field for field in required_fields if field not in review_columns]
    
    if missing_fields:
        print(f"   ❌ Missing fields: {missing_fields}")
        return False
    else:
        print(f"   ✓ All required fields present: {len(required_fields)} fields")
    
    # Check validation methods
    print("\n2. Checking validation methods...")
    validation_methods = ['validate_rating', 'validate_comment_length', 'validate_hospital_response_length']
    for method in validation_methods:
        if hasattr(Review, method):
            print(f"   ✓ {method} exists")
        else:
            print(f"   ❌ {method} missing")
            return False
    
    # Test rating validation
    print("\n3. Testing rating validation...")
    review = Review()
    
    # Test valid ratings
    for rating in [1, 2, 3, 4, 5]:
        review.rating = rating
        try:
            review.validate_rating()
            print(f"   ✓ Rating {rating} is valid")
        except ValueError as e:
            print(f"   ❌ Rating {rating} failed: {e}")
            return False
    
    # Test invalid ratings
    for rating in [0, 6, -1, 10]:
        review.rating = rating
        try:
            review.validate_rating()
            print(f"   ❌ Rating {rating} should have failed but didn't")
            return False
        except ValueError:
            print(f"   ✓ Rating {rating} correctly rejected")
    
    # Test comment length validation
    print("\n4. Testing comment length validation...")
    review.comment = "A" * 1000
    try:
        review.validate_comment_length()
        print(f"   ✓ Comment with 1000 characters is valid")
    except ValueError as e:
        print(f"   ❌ Comment with 1000 characters failed: {e}")
        return False
    
    review.comment = "A" * 1001
    try:
        review.validate_comment_length()
        print(f"   ❌ Comment with 1001 characters should have failed")
        return False
    except ValueError:
        print(f"   ✓ Comment with 1001 characters correctly rejected")
    
    # Test hospital response length validation
    print("\n5. Testing hospital response length validation...")
    review.hospital_response = "A" * 500
    try:
        review.validate_hospital_response_length()
        print(f"   ✓ Hospital response with 500 characters is valid")
    except ValueError as e:
        print(f"   ❌ Hospital response with 500 characters failed: {e}")
        return False
    
    review.hospital_response = "A" * 501
    try:
        review.validate_hospital_response_length()
        print(f"   ❌ Hospital response with 501 characters should have failed")
        return False
    except ValueError:
        print(f"   ✓ Hospital response with 501 characters correctly rejected")
    
    print("\n" + "=" * 60)
    print("✓ ALL REVIEW MODEL CHECKS PASSED")
    print("=" * 60)
    return True


def verify_database_schema(db_url: str):
    """Verify database schema after migration"""
    print("\n" + "=" * 60)
    print("DATABASE SCHEMA VERIFICATION")
    print("=" * 60)
    
    try:
        engine = create_engine(db_url)
        inspector = inspect(engine)
        
        # Check if reviews table exists
        print("\n1. Checking if reviews table exists...")
        tables = inspector.get_table_names()
        if 'reviews' not in tables:
            print("   ❌ Reviews table does not exist")
            print("   Run: alembic upgrade head")
            return False
        print("   ✓ Reviews table exists")
        
        # Check columns
        print("\n2. Checking reviews table columns...")
        columns = inspector.get_columns('reviews')
        column_names = [col['name'] for col in columns]
        
        required_columns = [
            'id', 'user_id', 'hospital_id', 'appointment_id', 'rating', 'comment',
            'is_flagged', 'flag_count', 'is_hidden', 'hospital_response',
            'hospital_response_date', 'is_immutable', 'immutable_after',
            'created_at', 'updated_at'
        ]
        
        missing_columns = [col for col in required_columns if col not in column_names]
        if missing_columns:
            print(f"   ❌ Missing columns: {missing_columns}")
            return False
        print(f"   ✓ All required columns present: {len(required_columns)} columns")
        
        # Check indexes
        print("\n3. Checking indexes...")
        indexes = inspector.get_indexes('reviews')
        index_names = [idx['name'] for idx in indexes]
        
        required_indexes = ['idx_hospital_id', 'idx_rating', 'idx_is_flagged']
        missing_indexes = [idx for idx in required_indexes if idx not in index_names]
        
        if missing_indexes:
            print(f"   ⚠ Missing indexes: {missing_indexes}")
        else:
            print(f"   ✓ All required indexes present: {len(required_indexes)} indexes")
        
        # Check foreign keys
        print("\n4. Checking foreign keys...")
        foreign_keys = inspector.get_foreign_keys('reviews')
        fk_columns = [fk['constrained_columns'][0] for fk in foreign_keys]
        
        required_fks = ['user_id', 'hospital_id', 'appointment_id']
        missing_fks = [fk for fk in required_fks if fk not in fk_columns]
        
        if missing_fks:
            print(f"   ❌ Missing foreign keys: {missing_fks}")
            return False
        print(f"   ✓ All required foreign keys present: {len(required_fks)} foreign keys")
        
        # Check unique constraints
        print("\n5. Checking unique constraints...")
        unique_constraints = inspector.get_unique_constraints('reviews')
        
        # Look for the unique constraint on (user_id, appointment_id)
        has_unique_constraint = False
        for constraint in unique_constraints:
            if set(constraint['column_names']) == {'user_id', 'appointment_id'}:
                has_unique_constraint = True
                break
        
        if has_unique_constraint:
            print("   ✓ Unique constraint on (user_id, appointment_id) exists")
        else:
            print("   ⚠ Unique constraint on (user_id, appointment_id) not found")
        
        # Check hospitals table for total_reviews column
        print("\n6. Checking hospitals table for total_reviews column...")
        hospital_columns = inspector.get_columns('hospitals')
        hospital_column_names = [col['name'] for col in hospital_columns]
        
        if 'total_reviews' in hospital_column_names:
            print("   ✓ total_reviews column exists in hospitals table")
        else:
            print("   ❌ total_reviews column missing from hospitals table")
            return False
        
        print("\n" + "=" * 60)
        print("✓ ALL DATABASE SCHEMA CHECKS PASSED")
        print("=" * 60)
        return True
        
    except Exception as e:
        print(f"\n❌ Error connecting to database: {e}")
        print("Make sure the database is running and the connection string is correct")
        return False


def main():
    """Main verification function"""
    print("\n" + "=" * 60)
    print("REVIEW MODEL AND MIGRATION VERIFICATION SCRIPT")
    print("=" * 60)
    
    # Verify model structure
    model_ok = verify_review_model()
    
    if not model_ok:
        print("\n❌ Model verification failed!")
        sys.exit(1)
    
    # Ask user if they want to verify database schema
    print("\n" + "=" * 60)
    print("DATABASE VERIFICATION")
    print("=" * 60)
    print("\nTo verify the database schema, you need to:")
    print("1. Ensure MySQL is running")
    print("2. Run the migration: alembic upgrade head")
    print("3. Provide the database connection string")
    print("\nExample: mysql+pymysql://user:password@localhost/fertility_db")
    
    db_url = input("\nEnter database URL (or press Enter to skip): ").strip()
    
    if db_url:
        db_ok = verify_database_schema(db_url)
        if not db_ok:
            print("\n❌ Database verification failed!")
            sys.exit(1)
    else:
        print("\nSkipping database verification.")
    
    print("\n" + "=" * 60)
    print("✓ VERIFICATION COMPLETE")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Run migration: alembic upgrade head")
    print("2. Implement ReviewService in app/services/review_service.py")
    print("3. Create API endpoints in app/routers/reviews.py")
    print("4. Write unit tests for the Review model")
    print("=" * 60)


if __name__ == "__main__":
    main()
