#!/usr/bin/env python3
"""
Test script to verify mobile app can connect to backend API
Run this on your computer to test the connection
"""

import requests
import socket
import sys

def get_local_ip():
    """Get the local IP address"""
    try:
        # Create a socket to get the local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception as e:
        print(f"Error getting local IP: {e}")
        return None

def test_api_connection(ip_address, port=8000):
    """Test if the API is accessible"""
    base_url = f"http://{ip_address}:{port}"
    
    print(f"\n{'='*60}")
    print(f"Testing API Connection")
    print(f"{'='*60}")
    print(f"Base URL: {base_url}")
    print(f"{'='*60}\n")
    
    # Test 1: Root endpoint
    print("Test 1: Root endpoint")
    try:
        response = requests.get(f"{base_url}/", timeout=5)
        if response.status_code == 200:
            print(f"✅ SUCCESS: {response.json()}")
        else:
            print(f"❌ FAILED: Status {response.status_code}")
    except Exception as e:
        print(f"❌ ERROR: {e}")
    
    print()
    
    # Test 2: API v1 endpoint
    print("Test 2: API v1 hospitals endpoint (should require auth)")
    try:
        response = requests.get(f"{base_url}/api/v1/hospitals", timeout=5)
        if response.status_code == 401:
            print(f"✅ SUCCESS: API is accessible (authentication required)")
        elif response.status_code == 200:
            print(f"✅ SUCCESS: {response.json()}")
        else:
            print(f"⚠️  UNEXPECTED: Status {response.status_code}")
    except Exception as e:
        print(f"❌ ERROR: {e}")
    
    print()
    
    # Test 3: Services endpoint (public)
    print("Test 3: Services endpoint")
    try:
        response = requests.get(f"{base_url}/api/v1/services", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ SUCCESS: Found {data.get('total', 0)} services")
        else:
            print(f"❌ FAILED: Status {response.status_code}")
    except Exception as e:
        print(f"❌ ERROR: {e}")
    
    print()
    print(f"{'='*60}")
    print("Connection Test Complete")
    print(f"{'='*60}\n")
    
    print("Next Steps:")
    print(f"1. Update flutter_app/lib/core/config/app_config.dart")
    print(f"   Change baseUrl to: 'http://{ip_address}:{port}/api/v1'")
    print(f"2. Ensure your mobile device is on the same WiFi network")
    print(f"3. Test from mobile browser: http://{ip_address}:{port}/")
    print(f"4. Rebuild Flutter app: flutter clean && flutter run")
    print()

if __name__ == "__main__":
    local_ip = get_local_ip()
    
    if local_ip:
        print(f"\n🖥️  Your computer's local IP: {local_ip}")
        test_api_connection(local_ip)
    else:
        print("❌ Could not determine local IP address")
        sys.exit(1)
