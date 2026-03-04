import requests
import json

# Admin login
login_response = requests.post(
    "http://localhost:8000/api/v1/auth/login",
    json={"email": "admin@fertilityservices.com", "password": "admin123"}
)

print("Login response:", login_response.status_code)
if login_response.status_code == 200:
    token = login_response.json()["access_token"]
    print("Token obtained successfully")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Get medical records first
    records_response = requests.get(
        "http://localhost:8000/api/v1/medical-records/admin/all",
        headers=headers
    )
    print("\nGet records response:", records_response.status_code)
    
    if records_response.status_code == 200:
        records = records_response.json()
        print(f"Found {len(records)} records")
        
        # Group records by type
        by_type = {}
        for record in records:
            record_type = record.get('record_type', 'unknown')
            if record_type not in by_type:
                by_type[record_type] = []
            by_type[record_type].append(record)
        
        print("\nRecords by type:")
        for record_type, recs in by_type.items():
            verified_count = sum(1 for r in recs if r.get('is_verified'))
            print(f"  {record_type}: {len(recs)} total, {verified_count} verified")
        
        # Try to verify one record of each type
        print("\n\nTrying to verify one record of each type:")
        for record_type, recs in by_type.items():
            unverified = [r for r in recs if not r.get('is_verified')]
            if unverified:
                record = unverified[0]
                record_id = record['id']
                print(f"\n{record_type} (ID {record_id}):")
                
                verify_response = requests.post(
                    f"http://localhost:8000/api/v1/admin/medical-records/{record_id}/verify",
                    json={"is_verified": True, "verification_notes": f"Test verification for {record_type}"},
                    headers=headers
                )
                
                print(f"  Status: {verify_response.status_code}")
                print(f"  Response: {verify_response.text}")
            else:
                print(f"\n{record_type}: All records already verified")
    else:
        print("Failed to get records:", records_response.text)
else:
    print("Login failed:", login_response.text)
