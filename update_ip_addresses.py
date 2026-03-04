#!/usr/bin/env python3
"""
Script to update IP addresses in the database when the host IP changes.
This is useful during development when the IP address changes frequently.
"""

import subprocess
import re
import sys

def get_current_ip():
    """Get the current IP address of the host machine"""
    try:
        # Run ipconfig and get IPv4 addresses
        result = subprocess.run(
            ['powershell', '-Command', "ipconfig | Select-String 'IPv4'"],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Parse the output to find the local network IP (192.168.x.x)
        lines = result.stdout.strip().split('\n')
        for line in lines:
            match = re.search(r'192\.168\.\d+\.\d+', line)
            if match:
                return match.group(0)
        
        print("❌ Could not find a 192.168.x.x IP address")
        return None
    except Exception as e:
        print(f"❌ Error getting IP address: {e}")
        return None

def get_old_ip_from_db():
    """Get the old IP address from the database"""
    try:
        result = subprocess.run(
            [
                'docker', 'exec', '-i', 'fertility_mysql',
                'mysql', '-uroot', '-prootpassword', '-e',
                "USE fertility_services; SELECT profile_picture FROM users WHERE profile_picture LIKE 'http://192.168.%' LIMIT 1;"
            ],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Parse the output to find the IP address
        match = re.search(r'192\.168\.\d+\.\d+', result.stdout)
        if match:
            return match.group(0)
        
        print("ℹ️  No old IP addresses found in database")
        return None
    except Exception as e:
        print(f"❌ Error getting old IP from database: {e}")
        return None

def update_database_ips(old_ip, new_ip):
    """Update all IP addresses in the database"""
    print(f"\n🔄 Updating IP addresses in database...")
    print(f"   Old IP: {old_ip}")
    print(f"   New IP: {new_ip}")
    
    tables_and_columns = [
        ('users', 'profile_picture'),
        ('medical_records', 'file_path'),
        ('hospitals', 'logo_url'),
        ('services', 'image_url'),
    ]
    
    updated_count = 0
    
    for table, column in tables_and_columns:
        try:
            # Check if column exists
            check_result = subprocess.run(
                [
                    'docker', 'exec', '-i', 'fertility_mysql',
                    'mysql', '-uroot', '-prootpassword', '-e',
                    f"USE fertility_services; SHOW COLUMNS FROM {table} LIKE '{column}';"
                ],
                capture_output=True,
                text=True
            )
            
            if column not in check_result.stdout:
                print(f"   ⏭️  Skipping {table}.{column} (column doesn't exist)")
                continue
            
            # Update the IP addresses
            result = subprocess.run(
                [
                    'docker', 'exec', '-i', 'fertility_mysql',
                    'mysql', '-uroot', '-prootpassword', '-e',
                    f"USE fertility_services; UPDATE {table} SET {column} = REPLACE({column}, '{old_ip}', '{new_ip}') WHERE {column} LIKE '%{old_ip}%';"
                ],
                capture_output=True,
                text=True,
                check=True
            )
            
            print(f"   ✅ Updated {table}.{column}")
            updated_count += 1
            
        except Exception as e:
            print(f"   ⚠️  Error updating {table}.{column}: {e}")
    
    return updated_count

def update_flutter_config(new_ip):
    """Update the Flutter app configuration with the new IP"""
    config_file = 'flutter_app/lib/core/config/app_config.dart'
    
    try:
        with open(config_file, 'r') as f:
            content = f.read()
        
        # Replace IP addresses in the config
        old_pattern = r'192\.168\.\d+\.\d+'
        new_content = re.sub(old_pattern, new_ip, content)
        
        if content != new_content:
            with open(config_file, 'w') as f:
                f.write(new_content)
            print(f"✅ Updated Flutter config file: {config_file}")
            return True
        else:
            print(f"ℹ️  Flutter config already has correct IP: {new_ip}")
            return False
    except Exception as e:
        print(f"❌ Error updating Flutter config: {e}")
        return False

def main():
    print("=" * 60)
    print("IP Address Update Script")
    print("=" * 60)
    
    # Get current IP
    current_ip = get_current_ip()
    if not current_ip:
        print("\n❌ Failed to get current IP address")
        sys.exit(1)
    
    print(f"\n✅ Current IP address: {current_ip}")
    
    # Get old IP from database
    old_ip = get_old_ip_from_db()
    
    if not old_ip:
        print("\nℹ️  No IP addresses to update in database")
        # Still update Flutter config
        update_flutter_config(current_ip)
        print("\n" + "=" * 60)
        print("✅ Done!")
        print("=" * 60)
        return
    
    if old_ip == current_ip:
        print(f"\nℹ️  IP address hasn't changed ({current_ip})")
        print("\n" + "=" * 60)
        print("✅ No updates needed!")
        print("=" * 60)
        return
    
    # Update database
    updated_count = update_database_ips(old_ip, current_ip)
    
    # Update Flutter config
    config_updated = update_flutter_config(current_ip)
    
    print("\n" + "=" * 60)
    print("✅ Update complete!")
    print("=" * 60)
    print(f"\nSummary:")
    print(f"  - Database tables updated: {updated_count}")
    print(f"  - Flutter config updated: {'Yes' if config_updated else 'No'}")
    print(f"\n📱 You may need to restart the Flutter app to see the changes.")

if __name__ == "__main__":
    main()
