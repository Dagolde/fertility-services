# Fertility Services App Setup Script (PowerShell)
Write-Host "🏥 Setting up Fertility Services Application..." -ForegroundColor Cyan

# Check if Docker is installed
try {
    docker --version | Out-Null
    Write-Host "✅ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not installed. Please install Docker Desktop first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Docker Compose is available
try {
    docker-compose --version | Out-Null
    Write-Host "✅ Docker Compose is available" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose is not available. Please ensure Docker Desktop is running." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create necessary directories
Write-Host "📁 Creating directories..." -ForegroundColor Yellow
$directories = @(
    "python_backend\uploads",
    "admin_dashboard\logs", 
    "database\backups",
    "nginx\ssl"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Gray
    }
}

# Copy environment file
Write-Host "⚙️ Setting up environment..." -ForegroundColor Yellow
if (!(Test-Path "python_backend\.env")) {
    Copy-Item "python_backend\.env.example" "python_backend\.env"
    Write-Host "✅ Environment file created. Please update python_backend\.env with your settings." -ForegroundColor Green
} else {
    Write-Host "✅ Environment file already exists." -ForegroundColor Green
}

# Build and start services
Write-Host "🐳 Building and starting Docker containers..." -ForegroundColor Cyan
docker-compose up -d --build

# Wait for services to be ready
Write-Host "⏳ Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check if services are running
Write-Host "🔍 Checking service status..." -ForegroundColor Yellow
docker-compose ps

# Display access information
Write-Host ""
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Service Access Information:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🔗 Backend API: http://localhost:8000" -ForegroundColor White
Write-Host "📚 API Documentation: http://localhost:8000/docs" -ForegroundColor White
Write-Host "🔧 Admin Dashboard: http://localhost:8501" -ForegroundColor White
Write-Host "🗄️ MySQL Database: localhost:3306" -ForegroundColor White
Write-Host "🔴 Redis Cache: localhost:6379" -ForegroundColor White
Write-Host ""
Write-Host "👤 Default Admin Credentials:" -ForegroundColor Yellow
Write-Host "Email: admin@fertilityservices.com" -ForegroundColor White
Write-Host "Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "🏥 Sample Hospital Credentials:" -ForegroundColor Yellow
Write-Host "Email: hospital@example.com" -ForegroundColor White
Write-Host "Password: hospital123" -ForegroundColor White
Write-Host ""
Write-Host "👥 Sample User Credentials:" -ForegroundColor Yellow
Write-Host "Patient: patient1@example.com / patient123" -ForegroundColor White
Write-Host "Donor: donor1@example.com / donor123" -ForegroundColor White
Write-Host ""
Write-Host "📱 Flutter App Setup:" -ForegroundColor Magenta
Write-Host "1. Navigate to flutter_app directory" -ForegroundColor White
Write-Host "2. Run: flutter pub get" -ForegroundColor White
Write-Host "3. Run: flutter run" -ForegroundColor White
Write-Host ""
Write-Host "🛠️ Development Commands:" -ForegroundColor Cyan
Write-Host "- View logs: docker-compose logs -f [service_name]" -ForegroundColor White
Write-Host "- Stop services: docker-compose down" -ForegroundColor White
Write-Host "- Restart services: docker-compose restart" -ForegroundColor White
Write-Host "- Update services: docker-compose up -d --build" -ForegroundColor White
Write-Host ""
Write-Host "📖 For more information, check the README.md file" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to continue"
