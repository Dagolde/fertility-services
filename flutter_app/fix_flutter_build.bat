@echo off
echo ========================================
echo  Flutter Build Fix - Android v2 Embedding
echo ========================================
echo.

echo Step 1: Cleaning Flutter project...
cd /d "%~dp0"
flutter clean

echo.
echo Step 2: Removing build directories...
if exist "build" rmdir /s /q "build"
if exist "android\.gradle" rmdir /s /q "android\.gradle"
if exist "android\app\build" rmdir /s /q "android\app\build"
if exist "android\build" rmdir /s /q "android\build"

echo.
echo Step 3: Getting Flutter packages...
flutter pub get

echo.
echo Step 4: Upgrading Flutter packages...
flutter pub upgrade

echo.
echo Step 5: Running Flutter doctor...
flutter doctor

echo.
echo Step 6: Building for Android (debug)...
flutter build apk --debug

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Build failed! 
    echo.
    echo Common solutions:
    echo 1. Make sure Flutter SDK is up to date: flutter upgrade
    echo 2. Check Android SDK installation
    echo 3. Restart Android Studio/VS Code
    echo 4. Clear Flutter cache: flutter pub cache clean
    echo.
    pause
    exit /b 1
)

echo.
echo ✅ Build completed successfully!
echo.
echo You can now run:
echo - flutter run (for development)
echo - flutter build apk --release (for production)
echo.
pause
