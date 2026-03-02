#!/usr/bin/env python3
"""
Database migration script to add new fields to the users table
for camera and file upload functionality.
"""

import mysql.connector
import os
from datetime import datetime

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'port': 3307,
    'user': 'fertility_user',
    'password': 'fertility_password',
    'database': 'fertility_services'
}

def run_migration():
    """Run the database migration to add new columns to users table."""
    
    print("🔄 Starting database migration...")
    print(f"⏰ Migration started at: {datetime.now()}")
    
    try:
        # Connect to database
        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()
        
        print("✅ Connected to database successfully")
        
        # Check if columns already exist
        cursor.execute("DESCRIBE users")
        existing_columns = [column[0] for column in cursor.fetchall()]
        
        # List of new columns to add
        new_columns = [
            ('profile_picture', 'VARCHAR(255) NULL'),
            ('bio', 'TEXT NULL'),
            ('address', 'TEXT NULL'),
            ('city', 'VARCHAR(100) NULL'),
            ('state', 'VARCHAR(100) NULL'),
            ('country', 'VARCHAR(100) NULL'),
            ('postal_code', 'VARCHAR(20) NULL'),
            ('latitude', 'DECIMAL(10,8) NULL'),
            ('longitude', 'DECIMAL(11,8) NULL'),
            ('gender', "ENUM('Male','Female','Other') NULL")
        ]
        
        # Add missing columns
        columns_added = 0
        for column_name, column_definition in new_columns:
            if column_name not in existing_columns:
                alter_query = f"ALTER TABLE users ADD COLUMN {column_name} {column_definition}"
                cursor.execute(alter_query)
                print(f"✅ Added column: {column_name}")
                columns_added += 1
            else:
                print(f"⚠️  Column already exists: {column_name}")
        
        # Add wallet_balance column to users table if not exists
        if 'wallet_balance' not in existing_columns:
            try:
                cursor.execute("ALTER TABLE users ADD COLUMN wallet_balance DECIMAL(12,2) DEFAULT 0.0")
                print("✅ Added column: wallet_balance")
                columns_added += 1
            except Exception as e:
                print(f"❌ Error adding column wallet_balance: {e}")
        else:
            print("⚠️  Column already exists: wallet_balance")
        
        # Create payment_gateway_configs table if not exists
        print("\n🔄 Creating payment_gateway_configs table...")
        try:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS payment_gateway_configs (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    gateway VARCHAR(50) UNIQUE NOT NULL,
                    is_active BOOLEAN DEFAULT FALSE,
                    is_test_mode BOOLEAN DEFAULT TRUE,
                    public_key VARCHAR(255),
                    secret_key VARCHAR(255),
                    webhook_secret VARCHAR(255),
                    supported_currencies JSON DEFAULT '["NGN"]',
                    config_data JSON,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                )
            """)
            print("✅ Created payment_gateway_configs table")
        except Exception as e:
            print(f"⚠️  Payment gateway configs table creation: {e}")
        
        # Create services table if not exists
        print("\n🔄 Creating services table...")
        try:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS services (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    description TEXT,
                    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                    duration_minutes INT DEFAULT 60,
                    is_active BOOLEAN DEFAULT TRUE,
                    service_type ENUM('sperm_donation', 'egg_donation', 'surrogacy'),
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                )
            """)
            print("✅ Created services table")
        except Exception as e:
            print(f"⚠️  Services table creation: {e}")
        
        # Update services table structure if needed
        print("\n🔄 Updating services table structure...")
        cursor.execute("DESCRIBE services")
        services_columns = [column[0] for column in cursor.fetchall()]
        
        # Add missing columns
        if 'price' not in services_columns:
            cursor.execute("ALTER TABLE services ADD COLUMN price DECIMAL(10,2) DEFAULT 0.00")
            print("✅ Added price column to services")
        
        if 'duration_minutes' not in services_columns:
            cursor.execute("ALTER TABLE services ADD COLUMN duration_minutes INT DEFAULT 60")
            print("✅ Added duration_minutes column to services")
        
        # Remove old columns if they exist
        if 'base_price' in services_columns:
            cursor.execute("ALTER TABLE services DROP COLUMN base_price")
            print("✅ Removed base_price column from services")
        
        if 'is_featured' in services_columns:
            cursor.execute("ALTER TABLE services DROP COLUMN is_featured")
            print("✅ Removed is_featured column from services")
        
        # Update medical_records table structure
        print("\n🔄 Updating medical_records table...")
        
        # Check current medical_records table structure
        cursor.execute("DESCRIBE medical_records")
        medical_columns = [column[0] for column in cursor.fetchall()]
        
        # New medical records columns
        medical_new_columns = [
            ('file_name', 'VARCHAR(255) NOT NULL'),
            ('file_size', 'INT NOT NULL DEFAULT 0'),
            ('record_type', "ENUM('license','certification','diploma','identification','medical_history','lab_results','other') NOT NULL DEFAULT 'other'"),
            ('is_verified', 'BOOLEAN DEFAULT FALSE'),
            ('verified_by', 'INT NULL'),
            ('verified_at', 'DATETIME NULL'),
            ('updated_at', 'DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP')
        ]
        
        # Add missing medical records columns
        for column_name, column_definition in medical_new_columns:
            if column_name not in medical_columns:
                alter_query = f"ALTER TABLE medical_records ADD COLUMN {column_name} {column_definition}"
                cursor.execute(alter_query)
                print(f"✅ Added medical_records column: {column_name}")
                columns_added += 1
            else:
                print(f"⚠️  Medical records column already exists: {column_name}")
        
        # Add foreign key constraint for verified_by if it doesn't exist
        try:
            cursor.execute("""
                ALTER TABLE medical_records 
                ADD CONSTRAINT fk_medical_records_verified_by 
                FOREIGN KEY (verified_by) REFERENCES users(id)
            """)
            print("✅ Added foreign key constraint for verified_by")
        except mysql.connector.Error as e:
            if "Duplicate key name" in str(e):
                print("⚠️  Foreign key constraint already exists")
            else:
                print(f"⚠️  Could not add foreign key constraint: {e}")
        
        # Update payments table structure
        print("\n🔄 Updating payments table...")
        cursor.execute("DESCRIBE payments")
        payments_columns = [column[0] for column in cursor.fetchall()]
        payments_new_columns = [
            ('currency', "VARCHAR(3) DEFAULT 'NGN'"),
            ('payment_gateway', "VARCHAR(50) DEFAULT 'paystack'"),
            ('gateway_reference', 'VARCHAR(255)'),
            ('gateway_transaction_id', 'VARCHAR(255)'),
            ('authorization_code', 'VARCHAR(255)'),
            ('gateway_response', 'JSON'),
            ('payment_date', 'DATETIME NULL'),
        ]
        for column_name, column_definition in payments_new_columns:
            if column_name not in payments_columns:
                alter_query = f"ALTER TABLE payments ADD COLUMN {column_name} {column_definition}"
                try:
                    cursor.execute(alter_query)
                    print(f"✅ Added payments column: {column_name}")
                    columns_added += 1
                except Exception as e:
                    print(f"❌ Error adding column {column_name}: {e}")
            else:
                print(f"⚠️  Payments column already exists: {column_name}")
        
        # Commit changes
        connection.commit()
        
        print(f"\n🎉 Migration completed successfully!")
        print(f"📊 Total columns added: {columns_added}")
        print(f"⏰ Migration finished at: {datetime.now()}")
        
    except mysql.connector.Error as e:
        print(f"❌ Database error: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False
    finally:
        if 'connection' in locals() and connection.is_connected():
            cursor.close()
            connection.close()
            print("🔌 Database connection closed")
    
    return True

def verify_migration():
    """Verify that the migration was successful."""
    
    print("\n🔍 Verifying migration...")
    
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()
        
        # Check users table structure
        cursor.execute("DESCRIBE users")
        users_columns = [column[0] for column in cursor.fetchall()]
        
        required_columns = [
            'profile_picture', 'bio', 'address', 'city', 'state', 
            'country', 'postal_code', 'latitude', 'longitude'
        ]
        
        missing_columns = [col for col in required_columns if col not in users_columns]
        
        if missing_columns:
            print(f"❌ Missing columns in users table: {missing_columns}")
            return False
        else:
            print("✅ All required columns present in users table")
        
        # Check medical_records table structure
        cursor.execute("DESCRIBE medical_records")
        medical_columns = [column[0] for column in cursor.fetchall()]
        
        required_medical_columns = [
            'file_name', 'file_size', 'record_type', 'is_verified', 
            'verified_by', 'verified_at', 'updated_at'
        ]
        
        missing_medical_columns = [col for col in required_medical_columns if col not in medical_columns]
        
        if missing_medical_columns:
            print(f"❌ Missing columns in medical_records table: {missing_medical_columns}")
            return False
        else:
            print("✅ All required columns present in medical_records table")
        
        print("🎉 Migration verification successful!")
        return True
        
    except mysql.connector.Error as e:
        print(f"❌ Verification failed: {e}")
        return False
    finally:
        if 'connection' in locals() and connection.is_connected():
            cursor.close()
            connection.close()

def clean_bad_payments():
    """Clean up bad payment data in the payments table."""
    print("\n🔄 Cleaning up bad payment data...")
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        cursor = connection.cursor()

        # 1. Remove payments with NULL or empty status/payment_method
        cursor.execute("DELETE FROM payments WHERE status IS NULL OR status = ''")
        removed_status_null = cursor.rowcount
        cursor.execute("DELETE FROM payments WHERE payment_method IS NULL OR payment_method = ''")
        removed_method_null = cursor.rowcount

        # 2. Remove payments with required fields NULL
        cursor.execute("DELETE FROM payments WHERE amount IS NULL OR appointment_id IS NULL OR user_id IS NULL")
        removed_required_null = cursor.rowcount

        # 3. Remove payments with invalid status
        valid_statuses = ("pending", "completed", "failed", "refunded", "cancelled")
        cursor.execute(f"DELETE FROM payments WHERE status NOT IN {valid_statuses}")
        removed_invalid_status = cursor.rowcount

        # 4. Optionally, remove payments with invalid payment_method (if you know the allowed values)
        # valid_methods = ("paystack", "stripe", "flutterwave", "manual")
        # cursor.execute(f"DELETE FROM payments WHERE payment_method NOT IN {valid_methods}")
        # removed_invalid_method = cursor.rowcount

        connection.commit()
        print(f"✅ Removed {removed_status_null} payments with NULL/empty status.")
        print(f"✅ Removed {removed_method_null} payments with NULL/empty payment_method.")
        print(f"✅ Removed {removed_required_null} payments with NULL required fields.")
        print(f"✅ Removed {removed_invalid_status} payments with invalid status.")
        # print(f"✅ Removed {removed_invalid_method} payments with invalid payment_method.")
        print("🎉 Payment data cleanup complete!\n")
    except Exception as e:
        print(f"❌ Error during payment data cleanup: {e}")
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'connection' in locals():
            connection.close()

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "clean_payments":
        clean_bad_payments()
    else:
        print("🚀 Database Migration Tool")
        print("=" * 50)
        
        # Run migration
        success = run_migration()
        
        if success:
            # Verify migration
            verify_migration()
            print("\n✅ Database migration completed successfully!")
            print("🔄 Please restart the backend service to apply changes.")
        else:
            print("\n❌ Migration failed. Please check the errors above.")
            exit(1)
