@echo off
echo ========================================
echo   Deploying Enhanced Admin Dashboard
echo ========================================

echo.
echo [1/6] Backing up current files...
if exist python_backend\app\main_backup.py (
    echo Backend backup already exists
) else (
    copy python_backend\app\main.py python_backend\app\main_backup.py
    echo Backend main.py backed up
)

if exist admin_dashboard\main_backup.py (
    echo Admin dashboard backup already exists
) else (
    copy admin_dashboard\main.py admin_dashboard\main_backup.py
    echo Admin dashboard main.py backed up
)

echo.
echo [2/6] Updating backend with enhanced admin routes...
copy python_backend\app\main_updated.py python_backend\app\main.py
echo Backend updated with enhanced admin routes

echo.
echo [3/6] Updating admin dashboard with complete implementation...
copy admin_dashboard\complete_main.py admin_dashboard\main.py
echo Admin dashboard updated with enhanced features

echo.
echo [4/6] Stopping current services...
docker-compose down

echo.
echo [5/6] Rebuilding and starting services...
docker-compose up --build -d

echo.
echo [6/6] Waiting for services to start...
timeout /t 10 /nobreak > nul

echo.
echo ========================================
echo   Enhanced Admin Dashboard Deployed!
echo ========================================
echo.
echo Services Status:
docker-compose ps

echo.
echo Access Points:
echo - Admin Dashboard: http://localhost:8501
echo - Backend API: http://localhost:8000
echo - API Documentation: http://localhost:8000/docs
echo.
echo Default Admin Credentials:
echo - Email: admin@fertilityservices.com
echo - Password: admin123
echo.
echo ========================================
echo   Deployment Complete!
echo ========================================

pause
