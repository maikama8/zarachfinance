# Quick Start Guide

## 🚀 Start Web Portal

```bash
cd admin-panel
npm install  # First time only
node server.js
```

Or use the script:
```bash
./START_SERVER.sh
```

**Access**: http://localhost:3000

## 📱 Build Mobile App APK

```bash
cd flutter-app
flutter clean
flutter pub get
flutter build apk --release
```

Or use the script:
```bash
./BUILD_APK.sh
```

**APK Location**: `flutter-app/build/app/outputs/flutter-apk/app-release.apk`

## 🔒 Flashing Protection Features

The app now includes protection against:
- ✅ USB flashing tools (Odin, SP Flash Tool, etc.)
- ✅ Download mode / Fastboot detection
- ✅ ADB connection monitoring
- ✅ Bootloader unlock detection
- ✅ Root detection
- ✅ Custom recovery detection
- ✅ Factory reset detection
- ✅ System integrity checks

## 🧪 Testing

### Web Portal
1. Open http://localhost:3000
2. Login with admin credentials
3. Test dashboard, devices, customers, payments

### Mobile App
1. Install APK on device
2. Grant device admin privileges
3. Test payment flow
4. Test flashing protection (connect USB with debugging)

## 📝 Notes

- Server must be running for mobile app to work
- Update API URL in `flutter-app/lib/utils/config.dart` if needed
- Flashing protection starts automatically when app launches

