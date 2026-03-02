@echo off
echo 🏥 Setting up Fertility Services Application...

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

REM Check if Docker Compose is available
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose is not available. Please ensure Docker Desktop is running.
    pause
    exit /b 1
)

REM Create necessary directories
echo 📁 Creating directories...
if not exist "python_backend\uploads" mkdir python_backend\uploads
if not exist "admin_dashboard\logs" mkdir admin_dashboard\logs
if not exist "database\backups" mkdir database\backups
if not exist "nginx\ssl" mkdir nginx\ssl

REM Copy environment file
echo ⚙️ Setting up environment...
if not exist "python_backend\.env" (
    copy "python_backend\.env.example" "python_backend\.env"
    echo ✅ Environment file created. Please update python_backend\.env with your settings.
) else (
    echo ✅ Environment file already exists.
)

REM Build and start services
echo 🐳 Building and starting Docker containers...
docker-compose up -d --build

REM Wait for services to be ready
echo ⏳ Waiting for services to start...
timeout /t 30 /nobreak >nul

REM Check if services are running
echo 🔍 Checking service status...
docker-compose ps

REM Display access information
echo.
echo 🎉 Setup completed successfully!
echo.
echo 📋 Service Access Information:
echo ================================
echo 🔗 Backend API: http://localhost:8000
echo 📚 API Documentation: http://localhost:8000/docs
echo 🔧 Admin Dashboard: http://localhost:8501
echo 🗄️ MySQL Database: localhost:3306
echo 🔴 Redis Cache: localhost:6379
echo.
echo 👤 Default Admin Credentials:
echo Email: admin@fertilityservices.com
echo Password: admin123
echo.
echo 🏥 Sample Hospital Credentials:
echo Email: hospital@example.com
echo Password: hospital123
echo.
echo 👥 Sample User Credentials:
echo Patient: patient1@example.com / patient123
echo Donor: donor1@example.com / donor123
echo.
echo 📱 Flutter App Setup:
echo 1. Navigate to flutter_app directory
echo 2. Run: flutter pub get
echo 3. Run: flutter run
echo.
echo 🛠️ Development Commands:
echo - View logs: docker-compose logs -f [service_name]
echo - Stop services: docker-compose down
echo - Restart services: docker-compose restart
echo - Update services: docker-compose up -d --build
echo.
echo 📖 For more information, check the README.md file
echo.
pause
