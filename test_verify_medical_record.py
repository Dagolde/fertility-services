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
        
        if records:
            # Try to verify the first unverified record
            for record in records:
                if not record.get('is_verified'):
                    record_id = record['id']
                    print(f"\nTrying to verify record {record_id}")
                    
                    # Test the endpoint
                    verify_response = requests.post(
                        f"http://localhost:8000/api/v1/admin/medical-records/{record_id}/verify",
                        json={"is_verified": True, "verification_notes": "Test verification"},
                        headers=headers
                    )
                    
                    print(f"Verify response status: {verify_response.status_code}")
                    print(f"Verify response body: {verify_response.text}")
                    break
            else:
                print("No unverified records found")
    else:
        print("Failed to get records:", records_response.text)
else:
    print("Login failed:", login_response.text)
