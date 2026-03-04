# Mobile App Network Setup Guide

## Current Configuration
- **Computer IP**: 192.168.1.107
- **Backend API**: http://192.168.1.107:8000/api/v1
- **Admin Dashboard**: http://192.168.1.107:8501

## Steps to Connect Mobile App to Backend

### 1. Ensure Same Network
Make sure your mobile device is connected to the **same WiFi network** as your computer.

### 2. Check Windows Firewall
Windows Firewall might be blocking incoming connections. To allow access:

#### Option A: Allow Docker Desktop through Firewall (Recommended)
1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Find "Docker Desktop" and ensure both Private and Public are checked
4. Click OK

#### Option B: Create Firewall Rule for Port 8000
Run this command in PowerShell as Administrator:
```powershell
New-NetFirewallRule -DisplayName "Fertility Services API" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

### 3. Test Connection from Mobile Device
1. Open a web browser on your mobile device
2. Navigate to: `http://192.168.1.107:8000/`
3. You should see: `{"message":"Fertility Services API","version":"1.0.0","status":"healthy"}`

If you see this message, the connection is working!

### 4. Rebuild Flutter App
After updating the IP address in `app_config.dart`, rebuild the app:

```bash
cd flutter_app
flutter clean
flutter pub get
flutter run
```

Or for release build:
```bash
flutter build apk --release
```

### 5. Alternative: Use Android Emulator
If you're using Android Emulator, use `10.0.2.2` instead of `192.168.1.107`:
- This is a special alias that points to the host machine's localhost

Update `flutter_app/lib/core/config/app_config.dart`:
```dart
defaultValue: 'http://10.0.2.2:8000/api/v1'
```

## Troubleshooting

### Issue: "No internet connection" error
**Cause**: Mobile device can't reach the backend API

**Solutions**:
1. Verify both devices are on the same WiFi network
2. Check Windows Firewall settings
3. Verify backend is running: `docker-compose ps`
4. Test API from mobile browser: `http://192.168.1.107:8000/`

### Issue: Connection timeout
**Cause**: Firewall blocking or wrong IP address

**Solutions**:
1. Disable Windows Firewall temporarily to test
2. Verify your computer's IP hasn't changed: `ipconfig`
3. Update `app_config.dart` with the correct IP

### Issue: API returns 404
**Cause**: Wrong endpoint path

**Solutions**:
1. Ensure you're using `/api/v1/` prefix
2. Check backend logs: `docker-compose logs backend`

## Network Configuration for Different Scenarios

### Development on Physical Device
```dart
defaultValue: 'http://192.168.1.107:8000/api/v1'
```

### Development on Android Emulator
```dart
defaultValue: 'http://10.0.2.2:8000/api/v1'
```

### Development on iOS Simulator
```dart
defaultValue: 'http://localhost:8000/api/v1'
```

### Production
```dart
defaultValue: 'https://api.yourdomain.com/api/v1'
```

## Current Status
✅ Backend API is running and accessible at http://192.168.1.107:8000
✅ App configuration updated to use correct IP address
⚠️ May need to configure Windows Firewall
⚠️ Ensure mobile device is on same WiFi network

## Next Steps
1. Check if mobile device is on same WiFi
2. Configure Windows Firewall if needed
3. Rebuild Flutter app
4. Test connection from mobile browser first
5. Launch app and verify connectivity
