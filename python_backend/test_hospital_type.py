from app.database import SessionLocal
from app.models import Hospital, HospitalType
from sqlalchemy import text

db = SessionLocal()
try:
    # Test inserting a hospital with hospital_type
    hospital = Hospital(
        name='Test Hospital Type',
        license_number='TEST456',
        hospital_type=HospitalType.IVF_CENTERS,
        address='123 Test St',
        city='Test City',
        state='Test State',
        country='Test Country',
        zip_code='12345',
        phone='555-0123',
        email='test@hospital.com',
        description='Test hospital for type validation'
    )
    db.add(hospital)
    db.commit()
    print('✅ Hospital created successfully with hospital_type:', hospital.hospital_type.value)
    
    # Query to verify
    result = db.execute(text('SELECT name, hospital_type FROM hospitals WHERE license_number = :license'), {'license': 'TEST456'})
    row = result.fetchone()
    if row:
        print('✅ Database verification - Name:', row[0], 'Type:', row[1])
    else:
        print('❌ Hospital not found in database')
        
except Exception as e:
    print('❌ Error:', str(e))
    db.rollback()
finally:
    db.close()
