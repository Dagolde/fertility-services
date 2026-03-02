#!/usr/bin/env python3
"""
Database migration script to add is_featured column to services table
and set some services as featured.
"""

import sys
import os

from sqlalchemy import create_engine, text
from app.database import DATABASE_URL
from app.models import Base, Service
from sqlalchemy.orm import sessionmaker

def run_migration():
    """Run the migration to add is_featured column and update existing services."""
    
    # Create engine and session
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = SessionLocal()
    
    try:
        print("Starting migration: Adding is_featured column to services table...")
        
        # Add the is_featured column to services table
        print("Adding is_featured column...")
        session.execute(text("""
            ALTER TABLE services 
            ADD COLUMN is_featured BOOLEAN DEFAULT FALSE
        """))
        
        # Update some existing services to be featured
        print("Setting some services as featured...")
        
        # Get existing services and mark the first one of each type as featured
        sperm_donation_service = session.execute(text("""
            SELECT id FROM services 
            WHERE service_type = 'sperm_donation' AND is_active = TRUE 
            LIMIT 1
        """)).fetchone()
        
        egg_donation_service = session.execute(text("""
            SELECT id FROM services 
            WHERE service_type = 'egg_donation' AND is_active = TRUE 
            LIMIT 1
        """)).fetchone()
        
        surrogacy_service = session.execute(text("""
            SELECT id FROM services 
            WHERE service_type = 'surrogacy' AND is_active = TRUE 
            LIMIT 1
        """)).fetchone()
        
        # Mark these services as featured
        featured_service_ids = []
        if sperm_donation_service:
            featured_service_ids.append(sperm_donation_service[0])
        if egg_donation_service:
            featured_service_ids.append(egg_donation_service[0])
        if surrogacy_service:
            featured_service_ids.append(surrogacy_service[0])
        
        if featured_service_ids:
            for service_id in featured_service_ids:
                session.execute(text("""
                    UPDATE services 
                    SET is_featured = TRUE 
                    WHERE id = :service_id
                """), {"service_id": service_id})
                print(f"Marked service ID {service_id} as featured")
        else:
            print("No existing services found to mark as featured")
        
        # Commit the changes
        session.commit()
        print("Migration completed successfully!")
        
        # Verify the changes
        featured_count = session.execute(text("""
            SELECT COUNT(*) FROM services WHERE is_featured = TRUE
        """)).fetchone()[0]
        
        print(f"Total featured services: {featured_count}")
        
    except Exception as e:
        print(f"Migration failed: {e}")
        session.rollback()
        raise
    finally:
        session.close()

if __name__ == "__main__":
    run_migration()
