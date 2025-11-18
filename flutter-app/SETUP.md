# Flutter App Setup Instructions

## Prerequisites

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Ensure you have Android Studio or VS Code with Flutter extensions

## Setup Steps

1. **Install Dependencies**
   ```bash
   cd flutter-app
   flutter pub get
   ```

2. **Update API Configuration**
   - Edit `lib/utils/config.dart`
   - Update `apiBaseUrl` to your server IP:
     ```dart
     static const String apiBaseUrl = 'http://YOUR_SERVER_IP:3000/api/';
     ```

3. **Device Admin Implementation**
   - The app uses device admin features which require native Android code
   - You'll need to implement platform channels for:
     - Device admin activation
     - Device locking
     - Factory reset protection
   - See `android/app/src/main/kotlin/` for native implementation

4. **Build APK**
   ```bash
   flutter build apk --release
   ```
   The APK will be in `build/app/outputs/flutter-apk/app-release.apk`

## Important Notes

- **Device Admin Plugin**: The `device_admin` package in pubspec.yaml is a placeholder. You'll need to create a custom platform channel or use a different approach for device admin functionality.

- **Native Code Required**: For full device admin functionality, you'll need to:
  1. Create Kotlin/Java code in `android/app/src/main/kotlin/`
  2. Implement MethodChannel to communicate between Flutter and Android
  3. Use Android Device Admin API in native code

## Testing

1. Connect your Android device or start an emulator
2. Run: `flutter run`
3. Or install the APK: `flutter install`

## Troubleshooting

- If you get dependency errors, run `flutter pub get` again
- For device admin issues, check AndroidManifest.xml permissions
- Make sure your device/emulator has the required Android version (API 24+)

