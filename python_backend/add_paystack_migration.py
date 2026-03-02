#!/usr/bin/env python3
"""
Migration script to add Paystack payment gateway support
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from app.database import engine
from app.models import PaymentGateway

def run_migration():
    """Run the migration to add payment gateway support"""
    
    # Create session
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = SessionLocal()
    
    try:
        print("Starting Paystack payment gateway migration...")
        
        # Add new columns to payments table
        migration_queries = [
            # Add new columns to payments table
            """
            ALTER TABLE payments 
            ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'NGN',
            ADD COLUMN IF NOT EXISTS payment_gateway ENUM('paystack', 'stripe', 'flutterwave', 'manual') DEFAULT 'paystack',
            ADD COLUMN IF NOT EXISTS gateway_reference VARCHAR(255),
            ADD COLUMN IF NOT EXISTS gateway_transaction_id VARCHAR(255),
            ADD COLUMN IF NOT EXISTS authorization_code VARCHAR(255),
            ADD COLUMN IF NOT EXISTS gateway_response JSON;
            """,
            
            # Create payment_gateway_configs table
            """
            CREATE TABLE IF NOT EXISTS payment_gateway_configs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                gateway ENUM('paystack', 'stripe', 'flutterwave', 'manual') UNIQUE NOT NULL,
                is_active BOOLEAN DEFAULT FALSE,
                is_test_mode BOOLEAN DEFAULT TRUE,
                public_key VARCHAR(255),
                secret_key VARCHAR(255),
                webhook_secret VARCHAR(255),
                supported_currencies JSON DEFAULT ('["NGN"]'),
                config_data JSON,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            );
            """,
            
            # Update payment status enum to include cancelled
            """
            ALTER TABLE payments 
            MODIFY COLUMN status ENUM('pending', 'completed', 'failed', 'refunded', 'cancelled') DEFAULT 'pending';
            """

            """
            ALTER TABLE payments ADD COLUMN currency VARCHAR(3) DEFAULT 'NGN';
            """	
        ]
        
        # Execute migration queries
        for query in migration_queries:
            try:
                session.execute(text(query))
                session.commit()
                print(f"✓ Executed migration query successfully")
            except Exception as e:
                print(f"⚠ Query execution note: {e}")
                session.rollback()
                # Continue with other queries
        
        # Insert default Paystack configuration (inactive by default)
        try:
            insert_config_query = """
            INSERT IGNORE INTO payment_gateway_configs 
            (gateway, is_active, is_test_mode, supported_currencies, config_data) 
            VALUES 
            ('paystack', FALSE, TRUE, '["NGN", "USD", "GHS", "ZAR"]', '{}'),
            ('stripe', FALSE, TRUE, '["USD", "EUR", "GBP"]', '{}'),
            ('flutterwave', FALSE, TRUE, '["NGN", "USD", "GHS", "KES"]', '{}'),
            ('manual', TRUE, FALSE, '["NGN", "USD"]', '{}');
            """
            
            session.execute(text(insert_config_query))
            session.commit()
            print("✓ Inserted default payment gateway configurations")
            
        except Exception as e:
            print(f"⚠ Default config insertion note: {e}")
            session.rollback()
        
        print("✅ Paystack payment gateway migration completed successfully!")
        
        # Display next steps
        print("\n" + "="*60)
        print("NEXT STEPS:")
        print("="*60)
        print("1. Configure Paystack API keys in admin dashboard")
        print("2. Test payment gateway connection")
        print("3. Activate Paystack gateway when ready")
        print("4. Update Flutter app to use new payment endpoints")
        print("="*60)
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        session.rollback()
        return False
    finally:
        session.close()
    
    return True

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
