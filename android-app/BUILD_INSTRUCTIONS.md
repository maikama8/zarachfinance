# Building ZarFinance APK

## Prerequisites
- Android Studio installed
- Android SDK installed
- Java JDK 8 or higher

## API Configuration

Before building, update the API URL in `app/src/main/java/com/financeapp/deviceadmin/Config.kt`:

For testing on a real device:
- Use your computer's local IP address (e.g., `http://192.168.1.100:3000/api/`)
- Or use your server's public IP/domain

For emulator:
- Use `http://10.0.2.2:3000/api/` (Android emulator special IP for host machine)

## Build Commands

### Debug APK (for testing)
```bash
cd android-app
./gradlew assembleDebug
```

The APK will be at: `app/build/outputs/apk/debug/app-debug.apk`

### Release APK (for production)
```bash
cd android-app
./gradlew assembleRelease
```

The APK will be at: `app/build/outputs/apk/release/app-release.apk`

## Install on Device

### Via ADB
```bash
adb install app/build/outputs/apk/debug/app-debug.apk
```

### Via File Transfer
1. Copy the APK to your device
2. Enable "Install from Unknown Sources" in device settings
3. Open the APK file and install

## Testing

1. Install the APK on your device
2. Grant all required permissions when prompted
3. Enable Device Administrator when requested
4. The app will try to connect to the API endpoint configured in Config.kt

## Important Notes

- Make sure your server is running and accessible from the device
- For local testing, ensure device and computer are on the same network
- Update API_BASE_URL in Config.kt before building

