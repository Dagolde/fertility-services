"""
Database migration to add hospital_type field to hospitals table
"""
from sqlalchemy import create_engine, text
from app.database import DATABASE_URL

def add_hospital_type_column():
    """Add hospital_type column to hospitals table"""
    
    # Create engine using the DATABASE_URL from database.py
    engine = create_engine(DATABASE_URL)
    
    try:
        with engine.connect() as connection:
            # Check if column already exists
            result = connection.execute(text("""
                SELECT COUNT(*) as count 
                FROM information_schema.columns 
                WHERE table_name = 'hospitals' 
                AND column_name = 'hospital_type'
            """))
            
            column_exists = result.fetchone()[0] > 0
            
            if not column_exists:
                print("Adding hospital_type column to hospitals table...")
                
                # Add the hospital_type column
                connection.execute(text("""
                    ALTER TABLE hospitals 
                    ADD COLUMN hospital_type ENUM(
                        'IVF Centers',
                        'Fertility Clinics', 
                        'Sperm Banks',
                        'Surrogacy Centers',
                        'General Hospital'
                    ) DEFAULT 'General Hospital'
                """))
                
                # Update existing records to have a default type
                connection.execute(text("""
                    UPDATE hospitals 
                    SET hospital_type = 'General Hospital' 
                    WHERE hospital_type IS NULL
                """))
                
                connection.commit()
                print("✅ Successfully added hospital_type column")
            else:
                print("ℹ️  hospital_type column already exists")
                
    except Exception as e:
        print(f"❌ Error adding hospital_type column: {e}")
        raise

if __name__ == "__main__":
    add_hospital_type_column()
