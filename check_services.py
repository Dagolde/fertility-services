#!/usr/bin/env python3
"""
Service health check script for Fertility Services Platform
"""

import requests
import mysql.connector
import redis
import time
from datetime import datetime

# Configuration
SERVICES = {
    'backend': {
        'url': 'http://localhost:8000/health',
        'name': 'Backend API',
        'port': 8000
    },
    'admin': {
        'url': 'http://localhost:8501',
        'name': 'Admin Dashboard',
        'port': 8501
    },
    'mysql': {
        'host': 'localhost',
        'port': 3307,
        'user': 'fertility_user',
        'password': 'fertility_password',
        'database': 'fertility_services',
        'name': 'MySQL Database'
    },
    'redis': {
        'host': 'localhost',
        'port': 6379,
        'name': 'Redis Cache'
    }
}

def check_http_service(url, name, timeout=5):
    """Check if an HTTP service is responding"""
    try:
        response = requests.get(url, timeout=timeout)
        if response.status_code == 200:
            return True, f"✅ {name} is running (Status: {response.status_code})"
        else:
            return False, f"❌ {name} returned status {response.status_code}"
    except requests.exceptions.ConnectionError:
        return False, f"❌ {name} is not accessible (Connection refused)"
    except requests.exceptions.Timeout:
        return False, f"❌ {name} is not responding (Timeout)"
    except Exception as e:
        return False, f"❌ {name} error: {str(e)}"

def check_mysql_service(config, name):
    """Check if MySQL service is accessible"""
    try:
        connection = mysql.connector.connect(
            host=config['host'],
            port=config['port'],
            user=config['user'],
            password=config['password'],
            database=config['database']
        )
        cursor = connection.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        connection.close()
        return True, f"✅ {name} is running and accessible"
    except mysql.connector.Error as e:
        return False, f"❌ {name} error: {str(e)}"
    except Exception as e:
        return False, f"❌ {name} error: {str(e)}"

def check_redis_service(config, name):
    """Check if Redis service is accessible"""
    try:
        r = redis.Redis(
            host=config['host'],
            port=config['port'],
            socket_connect_timeout=5
        )
        r.ping()
        return True, f"✅ {name} is running and accessible"
    except redis.ConnectionError:
        return False, f"❌ {name} is not accessible (Connection refused)"
    except Exception as e:
        return False, f"❌ {name} error: {str(e)}"

def check_docker_containers():
    """Check if Docker containers are running"""
    import subprocess
    try:
        result = subprocess.run(
            ['docker-compose', 'ps'],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            return True, f"✅ Docker containers status:\n{result.stdout}"
        else:
            return False, f"❌ Docker command failed: {result.stderr}"
    except FileNotFoundError:
        return False, "❌ Docker Compose not found"
    except subprocess.TimeoutExpired:
        return False, "❌ Docker command timed out"
    except Exception as e:
        return False, f"❌ Docker error: {str(e)}"

def main():
    """Main health check function"""
    print("🏥 Fertility Services Platform - Health Check")
    print("=" * 50)
    print(f"⏰ Check time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    all_healthy = True
    results = []
    
    # Check Docker containers
    print("🐳 Checking Docker containers...")
    docker_ok, docker_msg = check_docker_containers()
    results.append(('Docker', docker_ok, docker_msg))
    print(docker_msg)
    print()
    
    # Check HTTP services
    print("🌐 Checking HTTP services...")
    for service_id, config in SERVICES.items():
        if 'url' in config:
            ok, msg = check_http_service(config['url'], config['name'])
            results.append((config['name'], ok, msg))
            print(msg)
            if not ok:
                all_healthy = False
        elif 'database' in config:  # MySQL
            ok, msg = check_mysql_service(config, config['name'])
            results.append((config['name'], ok, msg))
            print(msg)
            if not ok:
                all_healthy = False
        elif 'port' in config and 'host' in config:  # Redis
            ok, msg = check_redis_service(config, config['name'])
            results.append((config['name'], ok, msg))
            print(msg)
            if not ok:
                all_healthy = False
    
    print()
    print("📊 Summary:")
    print("-" * 30)
    
    healthy_count = sum(1 for _, ok, _ in results if ok)
    total_count = len(results)
    
    for name, ok, msg in results:
        status = "✅" if ok else "❌"
        print(f"{status} {name}")
    
    print()
    print(f"Overall Status: {'🟢 All services healthy' if all_healthy else '🔴 Some services unhealthy'}")
    print(f"Health Score: {healthy_count}/{total_count} ({healthy_count/total_count*100:.1f}%)")
    
    if all_healthy:
        print()
        print("🎉 All services are running properly!")
        print("You can now:")
        print("- Access the API at: http://localhost:8000")
        print("- View API docs at: http://localhost:8000/docs")
        print("- Access admin dashboard at: http://localhost:8501")
        print("- Run the Flutter app: cd flutter_app && flutter run")
    else:
        print()
        print("⚠️  Some services are not running properly.")
        print("Troubleshooting tips:")
        print("1. Check if Docker is running: docker --version")
        print("2. Start services: docker-compose up -d")
        print("3. View logs: docker-compose logs")
        print("4. Check this script again after starting services")
    
    return all_healthy

if __name__ == "__main__":
    try:
        success = main()
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⏹️  Health check interrupted by user")
        exit(1)
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        exit(1)
