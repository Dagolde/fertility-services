import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from app.database import DATABASE_URL

def add_wallet_transactions_table():
    """Add wallet_transactions table to the database"""
    
    # Get database URL
    database_url = DATABASE_URL
    engine = create_engine(database_url)
    
    # Create session
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        # Check if table already exists
        result = db.execute(text("""
            SELECT COUNT(*) 
            FROM information_schema.tables 
            WHERE table_schema = 'fertility_services' 
            AND table_name = 'wallet_transactions'
        """))
        
        table_exists = result.scalar() > 0
        
        if table_exists:
            print("✅ wallet_transactions table already exists")
            return
        
        # Create wallet_transactions table
        db.execute(text("""
            CREATE TABLE wallet_transactions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                transaction_type VARCHAR(20) NOT NULL,
                amount DECIMAL(10,2) NOT NULL,
                currency VARCHAR(3) DEFAULT 'NGN',
                description TEXT,
                reference VARCHAR(255) UNIQUE NOT NULL,
                payment_gateway VARCHAR(20),
                gateway_reference VARCHAR(255),
                gateway_transaction_id VARCHAR(255),
                status VARCHAR(20) DEFAULT 'pending',
                gateway_response JSON,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            );
        """))
        
        # Create indexes
        db.execute(text("CREATE INDEX idx_wallet_transactions_user_id ON wallet_transactions(user_id);"))
        db.execute(text("CREATE INDEX idx_wallet_transactions_reference ON wallet_transactions(reference);"))
        db.execute(text("CREATE INDEX idx_wallet_transactions_status ON wallet_transactions(status);"))
        db.execute(text("CREATE INDEX idx_wallet_transactions_created_at ON wallet_transactions(created_at);"))
        
        db.commit()
        print("✅ wallet_transactions table created successfully")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error creating wallet_transactions table: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    add_wallet_transactions_table()
