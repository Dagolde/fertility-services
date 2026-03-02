#!/usr/bin/env python3
"""
Script to update Paystack API keys to live mode
"""

import mysql.connector
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'port': 3307,
    'user': 'fertility_user',
    'password': 'fertility_password',
    'database': 'fertility_services'
}

def update_paystack_keys():
    """Update Paystack API keys to live mode"""
    
    # Get live API keys from environment or user input
    live_public_key = os.getenv('PAYSTACK_LIVE_PUBLIC_KEY')
    live_secret_key = os.getenv('PAYSTACK_LIVE_SECRET_KEY')
    
    if not live_public_key:
        live_public_key = input("Enter your Paystack Live Public Key: ").strip()
    
    if not live_secret_key:
        live_secret_key = input("Enter your Paystack Live Secret Key: ").strip()
    
    if not live_public_key or not live_secret_key:
        print("❌ Error: Live API keys are required!")
        return False
    
    try:
        # Connect to database
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Update Paystack configuration
        update_query = """
        UPDATE payment_gateway_configs 
        SET public_key = %s, secret_key = %s, is_test_mode = 0
        WHERE gateway = 'PAYSTACK'
        """
        
        cursor.execute(update_query, (live_public_key, live_secret_key))
        conn.commit()
        
        # Verify the update
        cursor.execute("SELECT public_key, secret_key, is_test_mode FROM payment_gateway_configs WHERE gateway = 'PAYSTACK'")
        result = cursor.fetchone()
        
        if result:
            print("✅ Paystack configuration updated successfully!")
            print(f"Public Key: {result[0][:20]}...")
            print(f"Secret Key: {result[1][:20]}...")
            print(f"Test Mode: {'No' if result[2] == 0 else 'Yes'}")
        else:
            print("❌ Error: Paystack configuration not found!")
            return False
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error updating Paystack keys: {str(e)}")
        return False

if __name__ == "__main__":
    print("🚀 Updating Paystack to Live Mode...")
    print("=" * 50)
    
    success = update_paystack_keys()
    
    if success:
        print("\n✅ Paystack is now configured for live mode!")
        print("🔧 Next steps:")
        print("1. Restart the backend: docker restart fertility_backend")
        print("2. Test wallet funding and appointment booking")
        print("3. Update callback URLs to your production domain")
    else:
        print("\n❌ Failed to update Paystack configuration!")
