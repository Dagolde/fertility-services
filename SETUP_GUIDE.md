# 🏥 Fertility Services Setup Guide

## Option 1: Docker Setup (Recommended)

### Prerequisites
1. **Install Docker Desktop for Windows**
   - Download from: https://www.docker.com/products/docker-desktop/
   - Install and restart your computer
   - Make sure Docker Desktop is running (check system tray)

2. **Run Setup**
   ```cmd
   # Option A: PowerShell (Recommended)
   powershell -ExecutionPolicy Bypass -File setup.ps1
   
   # Option B: Command Prompt
   setup.bat
   ```

### After Docker Setup
- Backend API: http://localhost:8000
- API Documentation: http://localhost:8000/docs
- Admin Dashboard: http://localhost:8501
- Database: localhost:3306

---

## Option 2: Manual Setup (Without Docker)

### 1. Setup Python Backend

#### Prerequisites
- Python 3.11 or higher
- MySQL 8.0 or higher

#### Steps
```cmd
# Navigate to backend directory
cd python_backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# For Command Prompt:
venv\Scripts\activate
# For PowerShell:
venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Setup environment
copy .env.example .env
# Edit .env file with your database credentials

# Run the backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Setup MySQL Database

#### Install MySQL
1. Download MySQL 8.0 from: https://dev.mysql.com/downloads/mysql/
2. Install with default settings
3. Remember your root password

#### Create Database
```sql
-- Connect to MySQL as root
mysql -u root -p

-- Create database and user
CREATE DATABASE fertility_services;
CREATE USER 'fertility_user'@'localhost' IDENTIFIED BY 'fertility_password';
GRANT ALL PRIVILEGES ON fertility_services.* TO 'fertility_user'@'localhost';
FLUSH PRIVILEGES;

-- Use the database
USE fertility_services;

-- Run the init script (copy content from database/init.sql)
```

### 3. Setup Admin Dashboard

```cmd
# Navigate to admin directory
cd admin_dashboard

# Create virtual environment
python -m venv venv

# Activate virtual environment
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the admin dashboard
streamlit run main.py --server.port=8501 --server.address=0.0.0.0
```

### 4. Setup Flutter App

#### Prerequisites
- Flutter SDK 3.10+
- Android Studio (for Android development)
- VS Code with Flutter extension

#### Steps
```cmd
# Navigate to Flutter app
cd flutter_app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## Option 3: Quick Test Setup

If you want to test the backend API quickly without full setup:

### 1. Install Python Dependencies Only
```cmd
cd python_backend
pip install fastapi uvicorn sqlalchemy pymysql python-decouple python-jose passlib
```

### 2. Create Simple Test Database
```cmd
# Install SQLite for testing (simpler than MySQL)
pip install sqlite3
```

### 3. Modify Database Configuration
Edit `python_backend/app/database.py` to use SQLite:
```python
DATABASE_URL = "sqlite:///./fertility_services.db"
```

### 4. Run Backend
```cmd
cd python_backend
uvicorn app.main:app --reload
```

### 5. Test API
- Open browser: http://localhost:8000/docs
- Try the API endpoints

---

## Default Credentials

### Admin
- Email: admin@fertilityservices.com
- Password: admin123

### Hospital
- Email: hospital@example.com
- Password: hospital123

### Sample Users
- Patient: patient1@example.com / patient123
- Donor: donor1@example.com / donor123

---

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```cmd
   # Check what's using the port
   netstat -ano | findstr :8000
   # Kill the process
   taskkill /PID <process_id> /F
   ```

2. **Python Virtual Environment Issues**
   ```cmd
   # Make sure you're in the right directory
   # Activate the virtual environment first
   # Install dependencies again
   ```

3. **Database Connection Issues**
   - Make sure MySQL is running
   - Check credentials in .env file
   - Verify database exists

4. **Flutter Issues**
   ```cmd
   # Clean and get dependencies
   flutter clean
   flutter pub get
   ```

### Getting Help
- Check the main README.md for detailed information
- API Documentation: http://localhost:8000/docs (when backend is running)
- Create GitHub issues for bugs

---

## Next Steps After Setup

1. **Test the Backend API**
   - Visit http://localhost:8000/docs
   - Try the authentication endpoints
   - Register a new user

2. **Access Admin Dashboard**
   - Visit http://localhost:8501
   - Login with admin credentials
   - Explore user management features

3. **Setup Flutter App**
   - Configure API endpoints in app_config.dart
   - Run the app on emulator or device
   - Test user registration and login

4. **Customize for Your Needs**
   - Update branding and colors
   - Add additional features
   - Configure payment gateways
   - Setup email notifications

---

**Choose the setup option that works best for your environment!**
