# Zaracfinance

A comprehensive device financing management application for mobile phone retailers in Nigeria. This Flutter-based Android app enables stores to offer device financing with built-in payment tracking, device lock/unlock functionality, and comprehensive security features.

## Features

### Core Functionality
- **Device Registration**: Register financed devices with customer information
- **Payment Management**: Track payment schedules and process payments
- **Device Lock/Unlock**: Automatically lock devices for missed payments
- **Payment Reminders**: Automated notifications for upcoming and overdue payments
- **Location Tracking**: Monitor device location for security purposes
- **Tamper Detection**: Detect rooting, debugging, and other security violations
- **Release Code System**: Secure device release after full payment completion

### Security Features
- Device Administrator privileges
- Factory reset protection
- Certificate pinning for API communication
- Encrypted local storage (SQLCipher)
- Secure credential storage
- Anti-tampering mechanisms
- Code obfuscation (ProGuard/R8)

### Background Services
- Periodic payment status checks
- Location updates
- Policy synchronization
- Device status reporting
- Offline queue for network failures

## Technical Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **Platform**: Android (API 24+)
- **Database**: SQLite with SQLCipher encryption
- **State Management**: Provider
- **Navigation**: GoRouter
- **Background Tasks**: WorkManager
- **HTTP Client**: Dio with interceptors

## Prerequisites

- Flutter SDK 3.x or higher
- Android SDK (API 24-34)
- Java Development Kit (JDK) 11 or higher
- Android Studio or VS Code with Flutter extensions

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/maikama8/zarachfinance.git
cd zarachfinance
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Backend API

Update the API base URL in `lib/services/api_client.dart`:

```dart
static const String baseUrl = 'https://your-backend-api.com';
```

### 4. Generate Keystore (For Release Builds)

**On Windows:**
```cmd
cd scripts
generate_keystore.bat
```

**On Linux/Mac:**
```bash
cd scripts
chmod +x generate_keystore.sh
./generate_keystore.sh
```

### 5. Run the App

**Debug mode:**
```bash
flutter run
```

**Release mode:**
```bash
flutter build apk --release
```

The release APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
zaracfinance/
├── android/                    # Android native code
│   └── app/
│       └── src/main/kotlin/   # Kotlin platform channels
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   ├── screens/               # UI screens
│   │   └── onboarding/        # Onboarding flow
│   ├── services/              # Business logic services
│   ├── platform_channels/     # Flutter-Kotlin bridges
│   ├── navigation/            # Routing configuration
│   ├── widgets/               # Reusable widgets
│   └── utils/                 # Utility functions
├── test/                      # Unit tests
├── integration_test/          # Integration tests
├── docs/                      # Documentation
└── scripts/                   # Build and utility scripts
```

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[Installation Guide](docs/INSTALLATION_GUIDE.md)** - For store staff
- **[User Guide](docs/USER_GUIDE.md)** - For customers
- **[Backend API Requirements](docs/BACKEND_API_REQUIREMENTS.md)** - For backend developers
- **[Troubleshooting Guide](docs/TROUBLESHOOTING_GUIDE.md)** - Common issues and solutions
- **[Release Code Generation](docs/RELEASE_CODE_GENERATION.md)** - Release code management
- **[Deployment Checklist](docs/DEPLOYMENT_CHECKLIST.md)** - Pre-deployment verification

## Configuration

### Required Permissions

The app requires the following Android permissions:

- `DEVICE_ADMIN` - For lock/unlock functionality
- `ACCESS_FINE_LOCATION` - For device tracking
- `ACCESS_COARSE_LOCATION` - For device tracking
- `POST_NOTIFICATIONS` - For payment reminders (Android 13+)
- `RECEIVE_BOOT_COMPLETED` - For persistence after reboot
- `INTERNET` - For backend communication

### Backend Integration

The app requires a backend API that implements the endpoints specified in [Backend API Requirements](docs/BACKEND_API_REQUIREMENTS.md).

Key endpoints:
- Device registration
- Payment processing
- Payment status checks
- Device status updates
- Location reporting
- Policy management
- Release code verification

## Building for Production

### 1. Update Version

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1  # Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

### 2. Configure Signing

Ensure `android/key.properties` exists with your keystore details:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../app-release-key.jks
```

### 3. Build Release APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 4. Build App Bundle (For Play Store)

```bash
flutter build appbundle --release
```

## Testing

### Run Unit Tests

```bash
flutter test
```

### Run Integration Tests

```bash
flutter test integration_test/
```

### Run Specific Test

```bash
flutter test test/services/payment_service_test.dart
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Never commit keystore files** - They are excluded in `.gitignore`
2. **Keep API keys secure** - Use environment variables or secure storage
3. **Certificate pinning** - Update certificates in `assets/certificates/`
4. **Backend authentication** - Implement proper JWT token management
5. **Data encryption** - All sensitive data is encrypted at rest

## Troubleshooting

### Common Issues

**Build fails with "Keystore not found":**
- Run the keystore generation script in `scripts/`

**App crashes on startup:**
- Check backend API connectivity
- Verify all permissions are granted
- Check device admin activation

**Background tasks not running:**
- Disable battery optimization for the app
- Check WorkManager configuration

For more issues, see [Troubleshooting Guide](docs/TROUBLESHOOTING_GUIDE.md).

## Contributing

This is a private project. For internal contributions:

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## License

Proprietary - All rights reserved by Zarachtech

## Support

For technical support or questions:
- **Email**: support@zarachtech.com
- **Documentation**: See `docs/` directory
- **Issues**: Use GitHub Issues for bug reports

## Changelog

### Version 1.0.0 (Initial Release)

**Features:**
- Device registration and management
- Payment processing and tracking
- Automated device lock/unlock
- Payment reminders and notifications
- Location tracking
- Tamper detection
- Release code system
- Comprehensive security features
- Offline support with sync queue
- Grace period management

**Security:**
- Device admin protection
- Factory reset prevention
- Encrypted storage
- Certificate pinning
- Code obfuscation

**Documentation:**
- Complete user and technical documentation
- API specifications
- Troubleshooting guides

---

**Built with ❤️ by Zarachtech**
