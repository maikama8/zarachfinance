# Building the Flutter App

## Prerequisites

1. **Install Flutter**: https://flutter.dev/docs/get-started/install
2. **Install Android Studio** or ensure Android SDK is installed
3. **Set up Android device** or emulator (API 24+)

## Setup Steps

### 1. Install Dependencies

```bash
cd flutter-app
flutter pub get
```

### 2. Configure API URL

Edit `lib/utils/config.dart` and update:
```dart
static const String apiBaseUrl = 'http://YOUR_SERVER_IP:3000/api/';
```

### 3. Generate Device ID (First Run)

The app will automatically generate a device ID on first launch using Android's Secure.ANDROID_ID.

### 4. Build APK

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

The APK will be located at:
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

### 5. Install on Device

**Via ADB:**
```bash
flutter install
# or
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Manual:**
- Transfer APK to device
- Enable "Install from Unknown Sources"
- Install APK

## Testing

### Run on Connected Device/Emulator

```bash
flutter run
```

### Check Logs

```bash
flutter logs
# or
adb logcat | grep -i flutter
```

## Device Admin Setup

1. **First Launch**: App will prompt for device admin privileges
2. **Enable**: Tap "Enable" in the dialog
3. **System Settings**: You'll be taken to Android settings to activate
4. **Verify**: App will check if device admin is active

## Troubleshooting

### Build Errors

- **Gradle issues**: Run `cd android && ./gradlew clean`
- **Dependency issues**: Run `flutter clean && flutter pub get`
- **Kotlin version**: Ensure Kotlin 1.9.0+ is installed

### Runtime Issues

- **Device Admin not working**: Check AndroidManifest.xml permissions
- **API connection failed**: Verify server is running and IP is correct
- **Location not working**: Grant location permissions in device settings

### Common Issues

1. **"Device Admin not active"**: Enable in Android Settings > Security > Device Admin Apps
2. **"API connection timeout"**: Check server IP and firewall settings
3. **"Location permission denied"**: Grant in device settings

## Production Build

For production, you'll need to:

1. **Sign the APK**: Create a keystore and sign the release APK
2. **Update version**: Update version in `pubspec.yaml`
3. **Test thoroughly**: Test all features before release
4. **Configure backend**: Ensure production API URL is set

## Notes

- Device admin requires user consent and cannot be forced
- Location tracking requires runtime permissions
- Background tasks use WorkManager for periodic checks
- Payment gateway integration requires valid API keys in admin panel

