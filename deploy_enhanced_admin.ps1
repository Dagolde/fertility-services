Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Deploying Enhanced Admin Dashboard" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "[1/6] Backing up current files..." -ForegroundColor Yellow

if (Test-Path "python_backend\app\main_backup.py") {
    Write-Host "Backend backup already exists" -ForegroundColor Green
} else {
    Copy-Item "python_backend\app\main.py" "python_backend\app\main_backup.py"
    Write-Host "Backend main.py backed up" -ForegroundColor Green
}

if (Test-Path "admin_dashboard\main_backup.py") {
    Write-Host "Admin dashboard backup already exists" -ForegroundColor Green
} else {
    Copy-Item "admin_dashboard\main.py" "admin_dashboard\main_backup.py"
    Write-Host "Admin dashboard main.py backed up" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/6] Updating backend with enhanced admin routes..." -ForegroundColor Yellow
Copy-Item "python_backend\app\main_updated.py" "python_backend\app\main.py"
Write-Host "Backend updated with enhanced admin routes" -ForegroundColor Green

Write-Host ""
Write-Host "[3/6] Updating admin dashboard with complete implementation..." -ForegroundColor Yellow
Copy-Item "admin_dashboard\complete_main.py" "admin_dashboard\main.py"
Write-Host "Admin dashboard updated with enhanced features" -ForegroundColor Green

Write-Host ""
Write-Host "[4/6] Stopping current services..." -ForegroundColor Yellow
docker-compose down

Write-Host ""
Write-Host "[5/6] Rebuilding and starting services..." -ForegroundColor Yellow
docker-compose up --build -d

Write-Host ""
Write-Host "[6/6] Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Enhanced Admin Dashboard Deployed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Services Status:" -ForegroundColor White
docker-compose ps

Write-Host ""
Write-Host "Access Points:" -ForegroundColor White
Write-Host "- Admin Dashboard: http://localhost:8501" -ForegroundColor Green
Write-Host "- Backend API: http://localhost:8000" -ForegroundColor Green
Write-Host "- API Documentation: http://localhost:8000/docs" -ForegroundColor Green

Write-Host ""
Write-Host "Default Admin Credentials:" -ForegroundColor White
Write-Host "- Email: admin@fertilityservices.com" -ForegroundColor Yellow
Write-Host "- Password: admin123" -ForegroundColor Yellow

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
