# ZarFinance Flutter App

Flutter application for mobile phone financing in Nigeria with device admin capabilities.

## Features

- Device Admin integration for payment enforcement
- Payment processing via Paystack/Flutterwave
- Location tracking
- Payment reminders and notifications
- Device locking on overdue payments
- Payment schedule viewing

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Update API URL in `lib/utils/config.dart`:
```dart
static const String apiBaseUrl = 'http://YOUR_SERVER_IP:3000/api/';
```

3. For Android, add device admin permissions in `android/app/src/main/AndroidManifest.xml`

4. Run the app:
```bash
flutter run
```

## Building APK

```bash
flutter build apk --release
```

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`

## Configuration

- Update `lib/utils/config.dart` for API URLs and intervals
- Configure device admin in Android settings
- Set up payment gateway credentials in admin panel

