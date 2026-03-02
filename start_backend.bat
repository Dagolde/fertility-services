@echo off
echo Starting Fertility Services Backend Server...
echo.

cd python_backend

echo Installing/updating dependencies...
pip install -r requirements.txt

echo.
echo Starting server at http://192.168.1.106:8000...
echo You can access the API documentation at http://192.168.1.106:8000/docs
echo.

python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

pause
