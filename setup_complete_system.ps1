Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fertility Services - Complete Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
try {
    docker --version | Out-Null
    Write-Host "✅ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Python
try {
    python --version | Out-Null
    Write-Host "✅ Python is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.11+ from https://www.python.org/downloads/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Prerequisites check passed" -ForegroundColor Green
Write-Host ""

Write-Host "[2/6] Starting Docker services..." -ForegroundColor Yellow
try {
    docker-compose up -d mysql redis
    Write-Host "✅ Docker services started" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Failed to start Docker services" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Waiting for MySQL to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "[3/6] Running database migration..." -ForegroundColor Yellow
try {
    python migrate_database.py
    Write-Host "✅ Database migration completed" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Database migration failed" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

Write-Host "[4/6] Seeding database with sample data..." -ForegroundColor Yellow
try {
    python seed_data.py
    Write-Host "✅ Database seeding completed" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Database seeding failed" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

Write-Host "[5/6] Starting backend and admin services..." -ForegroundColor Yellow
try {
    docker-compose up -d backend admin
    Write-Host "✅ Backend and admin services started" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Failed to start backend/admin services" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "[6/6] Setting up Flutter app..." -ForegroundColor Yellow
Set-Location flutter_app

Write-Host "Installing Flutter dependencies..." -ForegroundColor Yellow
try {
    flutter pub get
    Write-Host "✅ Flutter dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Failed to install Flutter dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location ..

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services running:" -ForegroundColor White
Write-Host "- MySQL Database: localhost:3307" -ForegroundColor Gray
Write-Host "- Backend API: http://localhost:8000" -ForegroundColor Gray
Write-Host "- Admin Dashboard: http://localhost:8501" -ForegroundColor Gray
Write-Host "- API Documentation: http://localhost:8000/docs" -ForegroundColor Gray
Write-Host ""
Write-Host "Flutter App:" -ForegroundColor White
Write-Host "- Navigate to flutter_app/ directory" -ForegroundColor Gray
Write-Host "- Run: flutter run" -ForegroundColor Gray
Write-Host ""
Write-Host "Default credentials:" -ForegroundColor White
Write-Host "- Admin: admin@fertilityservices.com / admin123" -ForegroundColor Gray
Write-Host "- Patient: patient1@example.com / password123" -ForegroundColor Gray
Write-Host ""
Write-Host "To stop all services: docker-compose down" -ForegroundColor Yellow
Write-Host "To view logs: docker-compose logs -f" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to continue"
