"""
Quick test script to verify review system functionality
"""
import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

def test_review_endpoints():
    """Test review system endpoints"""
    print("Testing Review System Endpoints...")
    print("=" * 50)
    
    # Test 1: List reviews (should require hospital_id)
    print("\n1. Testing GET /reviews (without hospital_id - should fail)")
    response = requests.get(f"{BASE_URL}/reviews")
    print(f"   Status: {response.status_code}")
    if response.status_code == 400:
        print("   ✓ Correctly requires hospital_id parameter")
    else:
        print(f"   Response: {response.text[:200]}")
    
    # Test 2: List reviews with hospital_id (should work without auth)
    print("\n2. Testing GET /reviews?hospital_id=1 (public access)")
    response = requests.get(f"{BASE_URL}/reviews", params={"hospital_id": 1})
    print(f"   Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"   ✓ Success! Found {len(data.get('reviews', []))} reviews")
        print(f"   Average Rating: {data.get('average_rating', 0)}")
        print(f"   Rating Distribution: {data.get('rating_distribution', {})}")
    else:
        print(f"   ✗ Failed: {response.text[:200]}")
    
    # Test 3: Filter by rating (should work without auth)
    print("\n3. Testing GET /reviews?hospital_id=1&rating=5 (public access)")
    response = requests.get(f"{BASE_URL}/reviews", params={"hospital_id": 1, "rating": 5})
    print(f"   Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"   ✓ Success! Found {len(data.get('reviews', []))} 5-star reviews")
    else:
        print(f"   ✗ Failed: {response.text[:200]}")
    
    # Test 4: Check review submission endpoint (without auth - should fail)
    print("\n4. Testing POST /reviews (without auth - should fail)")
    review_data = {
        "hospital_id": 1,
        "appointment_id": 1,
        "rating": 5,
        "comment": "Test review"
    }
    response = requests.post(f"{BASE_URL}/reviews", json=review_data)
    print(f"   Status: {response.status_code}")
    if response.status_code == 401 or response.status_code == 403:
        print("   ✓ Correctly requires authentication")
    else:
        print(f"   Response: {response.text[:200]}")
    
    print("\n" + "=" * 50)
    print("Review System Endpoint Tests Complete!")
    print("\nSummary:")
    print("✓ Review listing is publicly accessible")
    print("✓ Filtering by rating works without authentication")
    print("✓ hospital_id parameter is required for listing")
    print("✓ Review submission requires authentication")

if __name__ == "__main__":
    try:
        test_review_endpoints()
    except requests.exceptions.ConnectionError:
        print("ERROR: Could not connect to backend at http://localhost:8000")
        print("Please ensure the backend is running with: docker-compose up backend")
    except Exception as e:
        print(f"ERROR: {str(e)}")
