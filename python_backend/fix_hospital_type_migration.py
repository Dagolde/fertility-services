"""
Fix database migration to update hospital_type field enum values
"""
from sqlalchemy import create_engine, text
from app.database import DATABASE_URL

def fix_hospital_type_column():
    """Fix hospital_type column enum values to match Python enum names"""
    
    # Create engine using the DATABASE_URL from database.py
    engine = create_engine(DATABASE_URL)
    
    try:
        with engine.connect() as connection:
            print("Dropping existing hospital_type column...")
            
            # Drop the existing column
            connection.execute(text("ALTER TABLE hospitals DROP COLUMN hospital_type"))
            
            print("Adding new hospital_type column with correct enum values...")
            
            # Add the hospital_type column with correct enum names
            connection.execute(text("""
                ALTER TABLE hospitals 
                ADD COLUMN hospital_type ENUM(
                    'IVF_CENTERS',
                    'FERTILITY_CLINICS', 
                    'SPERM_BANKS',
                    'SURROGACY_CENTERS',
                    'GENERAL_HOSPITAL'
                ) DEFAULT 'GENERAL_HOSPITAL'
            """))
            
            # Update existing records to have a default type
            connection.execute(text("""
                UPDATE hospitals 
                SET hospital_type = 'GENERAL_HOSPITAL' 
                WHERE hospital_type IS NULL
            """))
            
            connection.commit()
            print("✅ Successfully fixed hospital_type column")
                
    except Exception as e:
        print(f"❌ Error fixing hospital_type column: {e}")
        raise

if __name__ == "__main__":
    fix_hospital_type_column()
