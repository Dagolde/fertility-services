# Fix: Mobile App "No Internet Connection" Error

## Problem
Mobile app shows "no internet connection" error when trying to access the backend API.

## Root Cause
The app was configured with IP address `192.168.1.106`, but your computer's actual IP is `192.168.1.107`.

## Solution Applied
✅ Updated `flutter_app/lib/core/config/app_config.dart` with correct IP: `192.168.1.107`
✅ Verified backend API is accessible at `http://192.168.1.107:8000`
✅ Confirmed Docker firewall rules are enabled

## Steps to Complete the Fix

### 1. Ensure Same WiFi Network
**CRITICAL**: Your mobile device MUST be on the same WiFi network as your computer.

Check:
- Computer WiFi: Connected to your home/office WiFi
- Mobile device: Connected to the SAME WiFi network

### 2. Test Connection from Mobile Browser
Before running the app, test the connection:

1. Open a web browser on your mobile device
2. Navigate to: `http://192.168.1.107:8000/`
3. You should see:
   ```json
   {"message":"Fertility Services API","version":"1.0.0","status":"healthy"}
   ```

If you DON'T see this message:
- ❌ Devices are not on the same network
- ❌ Windows Firewall is blocking the connection
- ❌ Backend is not running

### 3. Configure Windows Firewall (If Needed)

If the browser test fails, you may need to allow incoming connections:

**Option A: Quick Test (Temporary)**
```powershell
# Run as Administrator
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```
⚠️ Remember to re-enable after testing!

**Option B: Create Specific Rule (Recommended)**
```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "Fertility Services API" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

### 4. Rebuild Flutter App

After confirming the browser test works:

```bash
cd flutter_app
flutter clean
flutter pub get
flutter run
```

Or build APK:
```bash
flutter build apk --release
```

### 5. Install and Test

1. Install the rebuilt app on your device
2. Open the app
3. Try to login or view services
4. Connection should now work!

## Verification Checklist

- [ ] Computer IP is `192.168.1.107` (run `ipconfig` to verify)
- [ ] Backend is running (`docker-compose ps` shows backend as healthy)
- [ ] Mobile device is on same WiFi network
- [ ] Browser test from mobile device succeeds
- [ ] App config updated with correct IP
- [ ] Flutter app rebuilt after config change
- [ ] App installed on device
- [ ] App can connect to backend

## Alternative Solutions

### Using Android Emulator Instead
If you're using Android Emulator (not a physical device), use this IP instead:

```dart
// In flutter_app/lib/core/config/app_config.dart
defaultValue: 'http://10.0.2.2:8000/api/v1'
```

`10.0.2.2` is a special alias that points to the host machine's localhost.

### Using iOS Simulator
For iOS Simulator, use:

```dart
defaultValue: 'http://localhost:8000/api/v1'
```

## Troubleshooting

### Error: "Connection refused"
**Cause**: Backend is not running or wrong port

**Fix**:
```bash
docker-compose ps  # Check if backend is running
docker-compose up -d backend  # Start backend if needed
```

### Error: "Connection timeout"
**Cause**: Firewall blocking or wrong IP

**Fix**:
1. Verify IP: `ipconfig` (look for IPv4 Address)
2. Update app_config.dart with correct IP
3. Check firewall settings
4. Rebuild app

### Error: "Network unreachable"
**Cause**: Devices on different networks

**Fix**:
1. Connect mobile device to same WiFi as computer
2. Verify both devices can ping each other
3. Test browser connection first

### IP Address Changed
If your computer's IP changes (common with DHCP):

1. Check new IP: `ipconfig`
2. Update `app_config.dart`
3. Rebuild app

## Quick Reference

| Component | URL |
|-----------|-----|
| Backend API | http://192.168.1.107:8000/api/v1 |
| Admin Dashboard | http://192.168.1.107:8501 |
| WebSocket | ws://192.168.1.107:8000/ws |
| Health Check | http://192.168.1.107:8000/ |

## Files Modified
- ✅ `flutter_app/lib/core/config/app_config.dart` - Updated IP address

## Test Script
Run `python test_mobile_connection.py` to verify API connectivity.

## Additional Resources
- See `MOBILE_APP_NETWORK_SETUP.md` for detailed network setup guide
- Check Docker logs: `docker-compose logs backend`
- View backend health: http://192.168.1.107:8000/
