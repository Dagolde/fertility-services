@echo off
echo ========================================
echo Flutter App Setup Script
echo ========================================

echo.
echo Checking Flutter installation...
flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo.
echo Checking Flutter doctor...
flutter doctor

echo.
echo Getting Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get Flutter dependencies
    pause
    exit /b 1
)

echo.
echo Running code generation...
flutter packages pub run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo WARNING: Code generation failed, but continuing...
)

echo.
echo Cleaning Flutter project...
flutter clean

echo.
echo Getting dependencies again after clean...
flutter pub get

echo.
echo Analyzing Flutter code...
flutter analyze

echo.
echo Checking for connected devices...
flutter devices

echo.
echo ========================================
echo Setup completed successfully!
echo ========================================
echo.
echo Available commands:
echo   flutter run                    - Run in debug mode
echo   flutter run --release          - Run in release mode
echo   flutter build apk              - Build APK
echo   flutter build apk --release    - Build release APK
echo   flutter build appbundle        - Build App Bundle for Play Store
echo.
echo To run the app:
echo   flutter run
echo.
pause
