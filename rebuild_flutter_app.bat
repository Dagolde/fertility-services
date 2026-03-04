@echo off
echo ============================================================
echo Rebuilding Flutter App with Updated Network Configuration
echo ============================================================
echo.

cd flutter_app

echo Step 1: Cleaning Flutter build cache...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)
echo ✅ Clean complete
echo.

echo Step 2: Getting Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)
echo ✅ Dependencies installed
echo.

echo Step 3: Building APK (Release)...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: Flutter build failed
    pause
    exit /b 1
)
echo ✅ Build complete
echo.

echo ============================================================
echo Build Complete!
echo ============================================================
echo.
echo APK Location: flutter_app\build\app\outputs\flutter-apk\app-release.apk
echo.
echo Next Steps:
echo 1. Transfer the APK to your mobile device
echo 2. Install the APK on your device
echo 3. Ensure device is on same WiFi network (192.168.1.x)
echo 4. Open the app and test connectivity
echo.
echo To run on connected device instead:
echo   flutter run --release
echo.
pause
