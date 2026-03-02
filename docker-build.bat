@echo off
echo ========================================
echo  Fertility Services App - Docker Build
echo ========================================
echo.

echo Stopping existing containers...
docker-compose down

echo.
echo Cleaning up Docker system...
docker system prune -f

echo.
echo Building containers (this may take a while)...
docker-compose build --no-cache

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Build failed! Check the error messages above.
    echo.
    echo Common solutions:
    echo 1. Restart Docker Desktop
    echo 2. Increase Docker memory limit to 4GB+
    echo 3. Check internet connection
    echo 4. Run: docker system prune -a
    echo.
    pause
    exit /b 1
)

echo.
echo Starting services...
docker-compose up -d

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Failed to start services!
    echo Check logs with: docker-compose logs
    pause
    exit /b 1
)

echo.
echo ✅ Build completed successfully!
echo.
echo Services running:
docker-compose ps

echo.
echo Access points:
echo - Backend API: http://localhost:8000
echo - Admin Dashboard: http://localhost:8501
echo - MySQL: localhost:3306
echo - Redis: localhost:6379
echo.
echo To view logs: docker-compose logs -f
echo To stop: docker-compose down
echo.
pause
