#!/bin/bash

# Flutter Production Build Script
# Usage: ./build_flutter_production.sh [environment]

set -e

ENVIRONMENT=${1:-production}
DOMAIN=${2:-yourdomain.com}

echo "🚀 Building Flutter app for $ENVIRONMENT environment"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed!"
    exit 1
fi

# Navigate to Flutter app directory
cd flutter_app

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Set environment-specific variables
if [ "$ENVIRONMENT" = "production" ]; then
    API_BASE_URL="https://api.$DOMAIN/api/v1"
    WEBSOCKET_URL="wss://api.$DOMAIN/ws"
    DEBUG_MODE="false"
    ENABLE_ANALYTICS="true"
    ENABLE_CRASH_REPORTING="true"
elif [ "$ENVIRONMENT" = "staging" ]; then
    API_BASE_URL="https://staging-api.$DOMAIN/api/v1"
    WEBSOCKET_URL="wss://staging-api.$DOMAIN/ws"
    DEBUG_MODE="true"
    ENABLE_ANALYTICS="true"
    ENABLE_CRASH_REPORTING="false"
else
    print_error "Invalid environment: $ENVIRONMENT"
    print_status "Valid environments: production, staging"
    exit 1
fi

print_status "Building for $ENVIRONMENT environment..."
print_status "API Base URL: $API_BASE_URL"
print_status "WebSocket URL: $WEBSOCKET_URL"

# Build Android APK
print_status "Building Android APK..."
flutter build apk \
    --release \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
    --dart-define=DEBUG_MODE=$DEBUG_MODE \
    --dart-define=ENABLE_ANALYTICS=$ENABLE_ANALYTICS \
    --dart-define=ENABLE_CRASH_REPORTING=$ENABLE_CRASH_REPORTING \
    --dart-define=PAYSTACK_PUBLIC_KEY=$PAYSTACK_PUBLIC_KEY \
    --dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY \
    --dart-define=FLUTTERWAVE_PUBLIC_KEY=$FLUTTERWAVE_PUBLIC_KEY

# Build Android App Bundle (for Play Store)
print_status "Building Android App Bundle..."
flutter build appbundle \
    --release \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
    --dart-define=DEBUG_MODE=$DEBUG_MODE \
    --dart-define=ENABLE_ANALYTICS=$ENABLE_ANALYTICS \
    --dart-define=ENABLE_CRASH_REPORTING=$ENABLE_CRASH_REPORTING \
    --dart-define=PAYSTACK_PUBLIC_KEY=$PAYSTACK_PUBLIC_KEY \
    --dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY \
    --dart-define=FLUTTERWAVE_PUBLIC_KEY=$FLUTTERWAVE_PUBLIC_KEY

# Build iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building iOS..."
    flutter build ios \
        --release \
        --dart-define=API_BASE_URL=$API_BASE_URL \
        --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
        --dart-define=DEBUG_MODE=$DEBUG_MODE \
        --dart-define=ENABLE_ANALYTICS=$ENABLE_ANALYTICS \
        --dart-define=ENABLE_CRASH_REPORTING=$ENABLE_CRASH_REPORTING \
        --dart-define=PAYSTACK_PUBLIC_KEY=$PAYSTACK_PUBLIC_KEY \
        --dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY \
        --dart-define=FLUTTERWAVE_PUBLIC_KEY=$FLUTTERWAVE_PUBLIC_KEY
else
    print_warning "Skipping iOS build (not on macOS)"
fi

# Build Web (optional)
print_status "Building Web version..."
flutter build web \
    --release \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
    --dart-define=DEBUG_MODE=$DEBUG_MODE \
    --dart-define=ENABLE_ANALYTICS=$ENABLE_ANALYTICS \
    --dart-define=ENABLE_CRASH_REPORTING=$ENABLE_CRASH_REPORTING \
    --dart-define=PAYSTACK_PUBLIC_KEY=$PAYSTACK_PUBLIC_KEY \
    --dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY \
    --dart-define=FLUTTERWAVE_PUBLIC_KEY=$FLUTTERWAVE_PUBLIC_KEY

# Go back to root directory
cd ..

print_status "Build completed successfully!"
echo ""
echo "📱 Build outputs:"
echo "  - Android APK: flutter_app/build/app/outputs/flutter-apk/app-release.apk"
echo "  - Android Bundle: flutter_app/build/app/outputs/bundle/release/app-release.aab"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  - iOS: flutter_app/build/ios/archive/Runner.xcarchive"
fi
echo "  - Web: flutter_app/build/web/"
echo ""
echo "🚀 Next steps:"
echo "  1. Test the APK on a device"
echo "  2. Upload to Google Play Store (AAB)"
echo "  3. Upload to Apple App Store (iOS)"
echo "  4. Deploy web version to your hosting"
echo ""
