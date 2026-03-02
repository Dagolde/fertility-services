@echo off
echo Setting up Local Development Environment for Fertility Services...

echo.
echo 1. Setting up Python Backend...
cd python_backend
echo Installing Python dependencies...
pip install -r requirements.txt

echo.
echo 2. Creating database and admin user...
python -c "from app.database import create_tables; create_tables()"
python create_admin.py

echo.
echo 3. Seeding sample data...
cd ..
python seed_data.py

echo.
echo 4. Starting Backend API Server...
cd python_backend
start "Backend API" python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

echo.
echo 5. Setting up Admin Dashboard...
cd ..\admin_dashboard
echo Installing Streamlit dependencies...
pip install -r requirements.txt

echo.
echo 6. Starting Admin Dashboard...
start "Admin Dashboard" streamlit run main.py --server.port 8501

echo.
echo 7. Updating Flutter configuration for local development...
cd ..\flutter_app\lib\core\config
echo Updating app_config.dart for localhost...

echo.
echo ========================================
echo Local Development Setup Complete!
echo ========================================
echo.
echo Services running:
echo - Backend API: http://localhost:8000
echo - API Documentation: http://localhost:8000/docs
echo - Admin Dashboard: http://localhost:8501
echo.
echo Test Accounts:
echo - Admin: admin@fertilityservices.com / admin123
echo - Patient: patient1@example.com / password123
echo - Hospital: hospital1@example.com / password123
echo.
echo Next Steps:
echo 1. Open Flutter project in your IDE
echo 2. Run: flutter pub get
echo 3. Run: flutter run
echo.
echo Press any key to continue...
pause > nul
