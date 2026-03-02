#!/usr/bin/env python3
"""
Generate password hash for admin user
Usage: python generate_hash.py
"""

import getpass
from passlib.context import CryptContext

def main():
    print("=== Admin Password Hash Generator ===")
    print()
    
    # Create password context
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    
    while True:
        try:
            # Get password from user
            password = getpass.getpass("Enter admin password: ")
            if len(password) < 8:
                print("❌ Password must be at least 8 characters long!")
                continue
                
            confirm_password = getpass.getpass("Confirm password: ")
            if password != confirm_password:
                print("❌ Passwords don't match!")
                continue
                
            # Generate hash
            password_hash = pwd_context.hash(password)
            
            print()
            print("✅ Password hash generated successfully!")
            print()
            print("Copy this hash to your environment variables:")
            print("-" * 50)
            print(f"ADMIN_PASSWORD_HASH={password_hash}")
            print("-" * 50)
            print()
            print("Add this to your .env file or docker-compose.yml environment section")
            break
            
        except KeyboardInterrupt:
            print("\n\n❌ Operation cancelled by user")
            break
        except Exception as e:
            print(f"❌ Error: {e}")
            break

if __name__ == "__main__":
    main()
