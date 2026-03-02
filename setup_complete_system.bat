@echo off
echo ========================================
echo Fertility Services - Complete Setup
echo ========================================
echo.

echo [1/6] Checking prerequisites...
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Docker is not installed or not in PATH
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.11+ from https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Prerequisites check passed
echo.

echo [2/6] Starting Docker services...
docker-compose up -d mysql redis
if %errorlevel% neq 0 (
    echo ERROR: Failed to start Docker services
    pause
    exit /b 1
)

echo ✅ Docker services started
echo Waiting for MySQL to be ready...
timeout /t 10 /nobreak >nul

echo [3/6] Running database migration...
python migrate_database.py
if %errorlevel% neq 0 (
    echo ERROR: Database migration failed
    pause
    exit /b 1
)

echo ✅ Database migration completed
echo.

echo [4/6] Seeding database with sample data...
python seed_data.py
if %errorlevel% neq 0 (
    echo ERROR: Database seeding failed
    pause
    exit /b 1
)

echo ✅ Database seeding completed
echo.

echo [5/6] Starting backend and admin services...
docker-compose up -d backend admin
if %errorlevel% neq 0 (
    echo ERROR: Failed to start backend/admin services
    pause
    exit /b 1
)

echo ✅ Backend and admin services started
echo Waiting for services to be ready...
timeout /t 15 /nobreak >nul

echo [6/6] Setting up Flutter app...
cd flutter_app

echo Installing Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to install Flutter dependencies
    pause
    exit /b 1
)

echo ✅ Flutter dependencies installed
echo.

cd ..

echo ========================================
echo 🎉 Setup completed successfully!
echo ========================================
echo.
echo Services running:
echo - MySQL Database: localhost:3307
echo - Backend API: http://localhost:8000
echo - Admin Dashboard: http://localhost:8501
echo - API Documentation: http://localhost:8000/docs
echo.
echo Flutter App:
echo - Navigate to flutter_app/ directory
echo - Run: flutter run
echo.
echo Default credentials:
echo - Admin: admin@fertilityservices.com / admin123
echo - Patient: patient1@example.com / password123
echo.
echo To stop all services: docker-compose down
echo To view logs: docker-compose logs -f
echo.
pause
