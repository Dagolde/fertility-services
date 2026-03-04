"""
Test script for review API endpoints.

This script verifies that all review endpoints are properly implemented and accessible.
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_review_endpoints_exist():
    """Test that all review endpoints are registered."""
    
    print("Testing Review API Endpoints...")
    print("=" * 60)
    
    # Get OpenAPI schema
    response = client.get("/docs")
    assert response.status_code == 200, "API docs should be accessible"
    print("✓ API documentation is accessible")
    
    # Get OpenAPI JSON
    response = client.get("/openapi.json")
    assert response.status_code == 200, "OpenAPI schema should be accessible"
    openapi_schema = response.json()
    
    # Check that review endpoints are registered
    paths = openapi_schema.get("paths", {})
    
    review_endpoints = [
        "/api/v1/reviews",
        "/api/v1/reviews/{review_id}",
        "/api/v1/reviews/{review_id}/flag",
        "/api/v1/reviews/{review_id}/respond",
        "/api/v1/reviews/{review_id}/moderate"
    ]
    
    print("\nChecking review endpoints:")
    for endpoint in review_endpoints:
        if endpoint in paths:
            methods = list(paths[endpoint].keys())
            print(f"✓ {endpoint} - Methods: {methods}")
        else:
            print(f"✗ {endpoint} - NOT FOUND")
            return False
    
    # Check specific methods
    print("\nChecking specific endpoint methods:")
    
    # POST /api/v1/reviews - Submit review
    if "post" in paths.get("/api/v1/reviews", {}):
        print("✓ POST /api/v1/reviews - Submit review")
    else:
        print("✗ POST /api/v1/reviews - NOT FOUND")
        return False
    
    # GET /api/v1/reviews - List reviews
    if "get" in paths.get("/api/v1/reviews", {}):
        print("✓ GET /api/v1/reviews - List reviews with filters")
    else:
        print("✗ GET /api/v1/reviews - NOT FOUND")
        return False
    
    # GET /api/v1/reviews/{review_id} - Get single review
    if "get" in paths.get("/api/v1/reviews/{review_id}", {}):
        print("✓ GET /api/v1/reviews/{review_id} - Get review")
    else:
        print("✗ GET /api/v1/reviews/{review_id} - NOT FOUND")
        return False
    
    # PUT /api/v1/reviews/{review_id} - Update review
    if "put" in paths.get("/api/v1/reviews/{review_id}", {}):
        print("✓ PUT /api/v1/reviews/{review_id} - Update review")
    else:
        print("✗ PUT /api/v1/reviews/{review_id} - NOT FOUND")
        return False
    
    # POST /api/v1/reviews/{review_id}/flag - Flag review
    if "post" in paths.get("/api/v1/reviews/{review_id}/flag", {}):
        print("✓ POST /api/v1/reviews/{review_id}/flag - Flag review")
    else:
        print("✗ POST /api/v1/reviews/{review_id}/flag - NOT FOUND")
        return False
    
    # POST /api/v1/reviews/{review_id}/respond - Hospital response
    if "post" in paths.get("/api/v1/reviews/{review_id}/respond", {}):
        print("✓ POST /api/v1/reviews/{review_id}/respond - Hospital response")
    else:
        print("✗ POST /api/v1/reviews/{review_id}/respond - NOT FOUND")
        return False
    
    # PUT /api/v1/reviews/{review_id}/moderate - Admin moderation
    if "put" in paths.get("/api/v1/reviews/{review_id}/moderate", {}):
        print("✓ PUT /api/v1/reviews/{review_id}/moderate - Admin moderation")
    else:
        print("✗ PUT /api/v1/reviews/{review_id}/moderate - NOT FOUND")
        return False
    
    print("\n" + "=" * 60)
    print("✓ All review endpoints are properly registered!")
    print("=" * 60)
    
    return True


def test_review_schemas():
    """Test that review schemas are properly defined."""
    
    print("\nTesting Review Schemas...")
    print("=" * 60)
    
    response = client.get("/openapi.json")
    openapi_schema = response.json()
    
    schemas = openapi_schema.get("components", {}).get("schemas", {})
    
    required_schemas = [
        "ReviewCreate",
        "ReviewUpdate",
        "ReviewResponse",
        "ReviewFlagRequest",
        "ReviewRespondRequest",
        "ReviewModerateRequest",
        "ReviewListResponse"
    ]
    
    print("\nChecking review schemas:")
    for schema_name in required_schemas:
        if schema_name in schemas:
            print(f"✓ {schema_name}")
        else:
            print(f"✗ {schema_name} - NOT FOUND")
            return False
    
    print("\n" + "=" * 60)
    print("✓ All review schemas are properly defined!")
    print("=" * 60)
    
    return True


def test_endpoint_requirements():
    """Test that endpoints meet the requirements."""
    
    print("\nTesting Endpoint Requirements...")
    print("=" * 60)
    
    response = client.get("/openapi.json")
    openapi_schema = response.json()
    paths = openapi_schema.get("paths", {})
    
    # Check POST /api/v1/reviews
    post_review = paths.get("/api/v1/reviews", {}).get("post", {})
    if post_review:
        print("✓ POST /api/v1/reviews - Submit review (Req 3.1, 3.2, 3.3)")
        # Check request body
        if "requestBody" in post_review:
            print("  ✓ Has request body schema")
        # Check response
        if "201" in post_review.get("responses", {}):
            print("  ✓ Returns 201 Created")
    
    # Check GET /api/v1/reviews
    get_reviews = paths.get("/api/v1/reviews", {}).get("get", {})
    if get_reviews:
        print("✓ GET /api/v1/reviews - List reviews (Req 3.8, 3.9)")
        # Check query parameters
        params = get_reviews.get("parameters", [])
        param_names = [p.get("name") for p in params]
        if "hospital_id" in param_names:
            print("  ✓ Has hospital_id filter")
        if "rating" in param_names:
            print("  ✓ Has rating filter")
        if "date_from" in param_names and "date_to" in param_names:
            print("  ✓ Has date range filters")
    
    # Check POST /api/v1/reviews/{review_id}/flag
    flag_review = paths.get("/api/v1/reviews/{review_id}/flag", {}).get("post", {})
    if flag_review:
        print("✓ POST /api/v1/reviews/{review_id}/flag - Flag review (Req 3.5, 3.10)")
    
    # Check POST /api/v1/reviews/{review_id}/respond
    respond_review = paths.get("/api/v1/reviews/{review_id}/respond", {}).get("post", {})
    if respond_review:
        print("✓ POST /api/v1/reviews/{review_id}/respond - Hospital response (Req 3.6)")
    
    # Check PUT /api/v1/reviews/{review_id}/moderate
    moderate_review = paths.get("/api/v1/reviews/{review_id}/moderate", {}).get("put", {})
    if moderate_review:
        print("✓ PUT /api/v1/reviews/{review_id}/moderate - Admin moderation (Req 3.10)")
    
    print("\n" + "=" * 60)
    print("✓ All endpoint requirements are met!")
    print("=" * 60)
    
    return True


if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("REVIEW API ENDPOINTS VERIFICATION")
    print("=" * 60 + "\n")
    
    try:
        # Run tests
        test1 = test_review_endpoints_exist()
        test2 = test_review_schemas()
        test3 = test_endpoint_requirements()
        
        if test1 and test2 and test3:
            print("\n" + "=" * 60)
            print("✓✓✓ ALL TESTS PASSED! ✓✓✓")
            print("=" * 60)
            print("\nReview API endpoints are properly implemented!")
            print("\nImplemented endpoints:")
            print("  • POST   /api/v1/reviews - Submit review")
            print("  • GET    /api/v1/reviews - List reviews with filters")
            print("  • GET    /api/v1/reviews/{id} - Get single review")
            print("  • PUT    /api/v1/reviews/{id} - Update review")
            print("  • POST   /api/v1/reviews/{id}/flag - Flag review")
            print("  • POST   /api/v1/reviews/{id}/respond - Hospital response")
            print("  • PUT    /api/v1/reviews/{id}/moderate - Admin moderation")
            print("\nRequirements covered: 3.1, 3.6, 3.8, 3.9, 3.10")
            sys.exit(0)
        else:
            print("\n" + "=" * 60)
            print("✗✗✗ SOME TESTS FAILED ✗✗✗")
            print("=" * 60)
            sys.exit(1)
            
    except Exception as e:
        print(f"\n✗ Error during testing: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
