Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Fertility Services App - Docker Build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose down

Write-Host ""
Write-Host "Cleaning up Docker system..." -ForegroundColor Yellow
docker system prune -f

Write-Host ""
Write-Host "Building containers (this may take a while)..." -ForegroundColor Yellow
docker-compose build --no-cache

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ Build failed! Check the error messages above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "1. Restart Docker Desktop" -ForegroundColor White
    Write-Host "2. Increase Docker memory limit to 4GB+" -ForegroundColor White
    Write-Host "3. Check internet connection" -ForegroundColor White
    Write-Host "4. Run: docker system prune -a" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to continue"
    exit 1
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ Failed to start services!" -ForegroundColor Red
    Write-Host "Check logs with: docker-compose logs" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
    exit 1
}

Write-Host ""
Write-Host "✅ Build completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Services running:" -ForegroundColor Cyan
docker-compose ps

Write-Host ""
Write-Host "Access points:" -ForegroundColor Cyan
Write-Host "- Backend API: http://localhost:8000" -ForegroundColor White
Write-Host "- Admin Dashboard: http://localhost:8501" -ForegroundColor White
Write-Host "- MySQL: localhost:3306" -ForegroundColor White
Write-Host "- Redis: localhost:6379" -ForegroundColor White
Write-Host ""
Write-Host "To view logs: docker-compose logs -f" -ForegroundColor Yellow
Write-Host "To stop: docker-compose down" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to continue"
