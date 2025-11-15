# Build and Release Guide

This guide provides step-by-step instructions for building and releasing the Device Admin App.

## Prerequisites

Before building a release version, ensure you have:

1. Flutter SDK installed (version 3.x or higher)
2. Android SDK with API level 24-34
3. Java Development Kit (JDK) 11 or higher
4. Keystore file for app signing (see below)

## Step 1: Generate Keystore (First Time Only)

The keystore is used to sign your app and verify its authenticity. You only need to do this once.

### On Linux/Mac:

```bash
cd scripts
chmod +x generate_keystore.sh
./generate_keystore.sh
```

### On Windows:

```cmd
cd scripts
generate_keystore.bat
```

Follow the prompts to enter:
- Keystore password (minimum 6 characters)
- Key alias (e.g., "device-admin-key")
- Key password (minimum 6 characters)
- Your name and organization details

**IMPORTANT:** 
- Store the keystore file (`android/app-release-key.jks`) and `android/key.properties` securely
- Create backups of these files
- Never commit them to version control (they're already in .gitignore)
- If you lose these files, you cannot update your app in the Play Store

## Step 2: Update Version Number

Before each release, update the version in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

- **MAJOR**: Increment for breaking changes
- **MINOR**: Increment for new features
- **PATCH**: Increment for bug fixes
- **BUILD_NUMBER**: Increment for every release (must always increase)

Example progression:
- `1.0.0+1` → First release
- `1.0.1+2` → Bug fix release
- `1.1.0+3` → New feature release
- `2.0.0+4` → Major version with breaking changes

## Step 3: Clean Previous Builds

```bash
flutter clean
flutter pub get
```

## Step 4: Build Release APK

### Standard Release Build:

```bash
flutter build apk --release
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

### Split APKs by Architecture (Smaller file sizes):

```bash
flutter build apk --release --split-per-abi
```

This generates separate APKs for different CPU architectures:
- `app-armeabi-v7a-release.apk` (32-bit ARM - most common)
- `app-arm64-v8a-release.apk` (64-bit ARM - newer devices)
- `app-x86_64-release.apk` (64-bit x86 - rare)

### Build App Bundle (For Google Play Store):

```bash
flutter build appbundle --release
```

The bundle will be at: `build/app/outputs/bundle/release/app-release.aab`

**Note:** App bundles are preferred for Play Store as they allow Google to optimize APK size for each device.

## Step 5: Verify the Build

### Check APK Signature:

```bash
# On Linux/Mac
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# On Windows
keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk
```

Verify that the certificate matches your keystore details.

### Check APK Size:

```bash
# On Linux/Mac
ls -lh build/app/outputs/flutter-apk/app-release.apk

# On Windows
dir build\app\outputs\flutter-apk\app-release.apk
```

Typical size should be 20-50 MB depending on features.

### Test on Physical Device:

```bash
# Install the release APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or if device is already installed with debug version
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Step 6: Test Release Build

**Critical tests for release builds:**

1. **Device Admin Activation**: Verify admin privileges can be activated
2. **Lock/Unlock Flow**: Test device locking and unlocking
3. **Payment Processing**: Test payment submission and verification
4. **Background Tasks**: Verify background sync works (wait 6+ hours or use WorkManager testing)
5. **Notifications**: Check payment reminders appear correctly
6. **Tamper Detection**: Verify security checks work
7. **Factory Reset Protection**: Confirm factory reset is blocked
8. **Release Code**: Test full payment release flow
9. **Offline Mode**: Test app behavior without internet
10. **Performance**: Check app startup time and memory usage

## Step 7: Prepare for Distribution

### For Internal Testing:

1. Copy the APK to a secure location
2. Share with test devices via secure channel
3. Document the version number and build date

### For Google Play Store:

1. Upload the app bundle (`.aab` file) to Play Console
2. Complete the store listing (description, screenshots, etc.)
3. Set up pricing and distribution
4. Submit for review

### For Direct Distribution:

1. Host the APK on a secure server
2. Generate a download link
3. Provide installation instructions to store staff
4. Consider using Mobile Device Management (MDM) for bulk deployment

## Build Troubleshooting

### Issue: "Keystore file not found"

**Solution:** Ensure `android/key.properties` exists and points to the correct keystore file.

### Issue: "Execution failed for task ':app:lintVitalRelease'"

**Solution:** Add to `android/app/build.gradle.kts`:

```kotlin
android {
    lintOptions {
        checkReleaseBuilds = false
        abortOnError = false
    }
}
```

### Issue: "Out of memory" during build

**Solution:** Increase Gradle memory in `android/gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m
```

### Issue: ProGuard errors

**Solution:** Check `android/app/proguard-rules.pro` and add keep rules for classes causing issues.

### Issue: App crashes on release but works in debug

**Solution:** This is usually due to ProGuard removing necessary code. Add keep rules or disable minification temporarily to identify the issue.

## Build Optimization Tips

1. **Reduce APK Size:**
   - Use `--split-per-abi` to create architecture-specific APKs
   - Remove unused resources
   - Optimize images and assets
   - Use vector graphics where possible

2. **Improve Build Speed:**
   - Use `flutter build apk --release --no-tree-shake-icons` if you don't use many icons
   - Enable Gradle daemon
   - Use incremental builds when possible

3. **Security Hardening:**
   - Ensure ProGuard is enabled (already configured)
   - Verify certificate pinning works in release mode
   - Test tamper detection on release builds
   - Check that sensitive strings are obfuscated

## Version History Template

Keep a record of all releases:

```
Version 1.0.0+1 (2024-01-15)
- Initial release
- Device admin functionality
- Payment processing
- Lock/unlock features

Version 1.0.1+2 (2024-01-20)
- Bug fix: Payment notification timing
- Improved error handling
- Performance optimizations

Version 1.1.0+3 (2024-02-01)
- New feature: Payment history export
- Enhanced security checks
- UI improvements
```

## Release Checklist

Before releasing to production:

- [ ] Version number updated in pubspec.yaml
- [ ] Keystore file is backed up securely
- [ ] Release APK/AAB built successfully
- [ ] APK signature verified
- [ ] Tested on multiple devices (different Android versions)
- [ ] All critical features tested
- [ ] Performance benchmarks met
- [ ] Security tests passed
- [ ] Release notes prepared
- [ ] Store listing updated (if applicable)
- [ ] Support documentation updated
- [ ] Rollback plan prepared

## Emergency Rollback

If a critical issue is discovered after release:

1. Immediately stop distribution of the problematic version
2. Revert to the previous stable version
3. Notify all users to not update
4. Fix the issue and increment the build number
5. Test thoroughly before re-releasing
6. Document the incident and lessons learned

## Support

For build issues or questions:
- Check Flutter documentation: https://docs.flutter.dev/deployment/android
- Review Android signing documentation: https://developer.android.com/studio/publish/app-signing
- Contact the development team
