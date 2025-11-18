#!/bin/bash

# Build ZarFinance Flutter APK

cd "$(dirname "$0")/flutter-app"

echo "Building ZarFinance Flutter APK..."
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build APK
echo "🔨 Building release APK..."
flutter build apk --release

# Check if build succeeded
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo ""
    echo "✅ APK built successfully!"
    echo "📱 APK Location: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
    echo "📊 APK Size: $APK_SIZE"
    echo ""
    echo "To install on device:"
    echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
else
    echo "❌ APK build failed. Check errors above."
    exit 1
fi

