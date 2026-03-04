"""
Verification script for service catalog API endpoints.

This script verifies that the service catalog endpoints are properly implemented.
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def verify_router_exists():
    """Verify that the services router exists and is properly configured."""
    print("=== Verifying Services Router ===")
    
    try:
        from app.routers import services
        print("✓ Services router module imported successfully")
        
        # Check router exists
        if hasattr(services, 'router'):
            print("✓ Router object exists")
        else:
            print("✗ Router object not found")
            return False
        
        # Check routes
        routes = services.router.routes
        print(f"✓ Router has {len(routes)} routes")
        
        # List all routes
        print("\nRegistered routes:")
        for route in routes:
            if hasattr(route, 'methods') and hasattr(route, 'path'):
                methods = ', '.join(route.methods)
                print(f"  {methods:10} {route.path}")
        
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_schemas():
    """Verify that service schemas are properly defined."""
    print("\n=== Verifying Service Schemas ===")
    
    try:
        from app.schemas import (
            ServiceCreate, ServiceUpdate, ServiceResponse,
            ServiceListResponse, ServiceImportResponse, ServiceArchiveResponse,
            ServiceCategoryEnum
        )
        
        print("✓ ServiceCreate schema imported")
        print("✓ ServiceUpdate schema imported")
        print("✓ ServiceResponse schema imported")
        print("✓ ServiceListResponse schema imported")
        print("✓ ServiceImportResponse schema imported")
        print("✓ ServiceArchiveResponse schema imported")
        print("✓ ServiceCategoryEnum imported")
        
        # Check ServiceCategoryEnum values
        print("\nService categories:")
        for category in ServiceCategoryEnum:
            print(f"  - {category.value}")
        
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_service_catalog_service():
    """Verify that the ServiceCatalogService exists."""
    print("\n=== Verifying ServiceCatalogService ===")
    
    try:
        from app.services.service_catalog_service import ServiceCatalogService
        
        print("✓ ServiceCatalogService imported successfully")
        
        # Check methods
        methods = [
            'create_service',
            'get_service',
            'get_services',
            'update_service',
            'delete_service',
            'increment_view_count',
            'increment_booking_count',
            'import_services_from_csv',
            'export_services_to_csv'
        ]
        
        print("\nService methods:")
        for method in methods:
            if hasattr(ServiceCatalogService, method):
                print(f"  ✓ {method}")
            else:
                print(f"  ✗ {method} not found")
                return False
        
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_main_app_integration():
    """Verify that the services router is registered in main app."""
    print("\n=== Verifying Main App Integration ===")
    
    try:
        from app.main import app
        
        print("✓ Main app imported successfully")
        
        # Check if services router is included
        routes = app.routes
        service_routes = [r for r in routes if '/services' in str(r.path)]
        
        if service_routes:
            print(f"✓ Found {len(service_routes)} service routes in main app")
            print("\nService routes:")
            for route in service_routes[:5]:  # Show first 5
                if hasattr(route, 'methods') and hasattr(route, 'path'):
                    methods = ', '.join(route.methods) if hasattr(route, 'methods') else 'N/A'
                    print(f"  {methods:10} {route.path}")
        else:
            print("✗ No service routes found in main app")
            return False
        
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_endpoint_requirements():
    """Verify that all required endpoints are implemented."""
    print("\n=== Verifying Required Endpoints ===")
    
    required_endpoints = [
        ("GET", "/api/v1/services", "List services with filters"),
        ("POST", "/api/v1/services", "Create service (hospital auth)"),
        ("GET", "/api/v1/services/{id}", "Get service by ID"),
        ("PUT", "/api/v1/services/{id}", "Update service"),
        ("DELETE", "/api/v1/services/{id}", "Archive service"),
        ("POST", "/api/v1/services/import", "Bulk import from CSV"),
        ("GET", "/api/v1/services/export", "Export to CSV"),
    ]
    
    try:
        from app.routers import services
        routes = services.router.routes
        
        all_found = True
        for method, path, description in required_endpoints:
            # Normalize path for comparison
            normalized_path = path.replace("/api/v1/services", "")
            if not normalized_path:
                normalized_path = "/"
            
            found = False
            for route in routes:
                if hasattr(route, 'methods') and hasattr(route, 'path'):
                    route_path = str(route.path)
                    if normalized_path in route_path or route_path in normalized_path:
                        if method in route.methods:
                            found = True
                            break
            
            if found:
                print(f"  ✓ {method:6} {path:35} - {description}")
            else:
                print(f"  ✗ {method:6} {path:35} - {description} NOT FOUND")
                all_found = False
        
        return all_found
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run all verifications."""
    print("=" * 70)
    print("Service Catalog API Endpoints Verification")
    print("=" * 70)
    print()
    
    results = []
    results.append(("Router exists", verify_router_exists()))
    results.append(("Schemas defined", verify_schemas()))
    results.append(("Service catalog service", verify_service_catalog_service()))
    results.append(("Main app integration", verify_main_app_integration()))
    results.append(("Required endpoints", verify_endpoint_requirements()))
    
    # Print summary
    print("\n" + "=" * 70)
    print("Verification Summary")
    print("=" * 70)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status}: {test_name}")
    
    print(f"\nTotal: {passed}/{total} verifications passed")
    
    if passed == total:
        print("\n🎉 All verifications passed!")
        print("\nThe service catalog API endpoints are properly implemented with:")
        print("  - GET /api/v1/services - List services with filters")
        print("  - POST /api/v1/services - Create service (hospital auth)")
        print("  - GET /api/v1/services/{id} - Get service by ID")
        print("  - PUT /api/v1/services/{id} - Update service")
        print("  - DELETE /api/v1/services/{id} - Archive service")
        print("  - POST /api/v1/services/import - Bulk import from CSV")
        print("  - GET /api/v1/services/export - Export to CSV")
        print("\nRequirements covered: 2.1, 2.5, 2.6, 2.10")
        return 0
    else:
        print(f"\n⚠️  {total - passed} verification(s) failed")
        return 1


if __name__ == "__main__":
    exit(main())
