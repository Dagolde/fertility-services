# Appointment Booking 404 Error Troubleshooting Guide

## Problem
The Flutter app is getting a 404 error when trying to create appointments, even though the backend server is running.

## Root Cause
The appointments endpoint requires user authentication (`current_user: User = Depends(get_current_active_user)`), but the user may not be properly authenticated.

## Troubleshooting Steps

### 1. Verify Backend Server is Running
- Visit http://192.168.1.106:8000/docs in your browser
- You should see the FastAPI documentation interface
- Look for the `/api/v1/appointments` endpoints

### 2. Test Appointments Router
- Visit http://192.168.1.106:8000/api/v1/appointments/test
- You should see: `{"message": "Appointments router is working", "timestamp": "..."}`
- If this works, the router is properly registered

### 3. Check User Authentication
The 404 error likely means the user is not authenticated. The appointments endpoint requires:
- Valid JWT token in the Authorization header
- User must be logged in through the Flutter app

### 4. Authentication Flow
1. User must first register/login through the Flutter app
2. The app receives a JWT token
3. This token is stored and sent with all API requests
4. Without this token, protected endpoints return 404 (not 401/403)

## Solutions

### Option 1: Ensure User is Logged In
1. Make sure the user has successfully logged in through the Flutter app
2. Check that the auth token is being stored and sent with requests
3. Verify the token hasn't expired

### Option 2: Test with Manual Authentication
1. Go to http://192.168.1.106:8000/docs
2. Use the `/api/v1/auth/login` endpoint to get a token
3. Click "Authorize" and enter the token
4. Try the appointments endpoints

### Option 3: Create Test User (if needed)
If no users exist, create one:
1. Use `/api/v1/auth/register` endpoint
2. Or run the `create_admin.py` script to create an admin user

## Expected Behavior After Fix
Once authenticated, the appointment booking should work with data like:
```json
{
  "hospital_id": 2,
  "service_id": 3,
  "appointment_date": "2025-07-30T11:00:00.000",
  "notes": "TESTING IT OUT"
}
```

## Files Modified
- Added test endpoint in `python_backend/app/routers/appointments.py`
- Created troubleshooting guide
- Backend server startup script: `start_backend.bat`
