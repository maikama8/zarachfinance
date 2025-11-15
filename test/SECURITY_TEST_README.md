# Security Validation Tests

## Overview

The security validation tests in `test/security_test.dart` provide comprehensive testing for:
- Tamper detection (root, app tampering, debugger, Xposed/Magisk)
- Encrypted storage (secure storage service)
- Database encryption (SQLCipher)
- Security integration flows
- Certificate pinning validation
- Factory reset protection

## Test Execution

### Unit Tests
The tests that don't require platform channels can be run with:
```bash
flutter test test/security_test.dart
```

### Integration Tests
Tests that require platform channels (tamper detection, secure storage, database) need to be run on a device or emulator:
```bash
flutter test test/security_test.dart --device-id=<device_id>
```

Or run as integration tests:
```bash
flutter test integration_test/security_integration_test.dart
```

## Test Categories

### 1. Tamper Detection Tests
- **Root Detection**: Verifies detection of rooted devices
- **App Tampering**: Validates app signature verification
- **Debugger Detection**: Checks for attached debuggers and timing anomalies
- **Framework Detection**: Detects Xposed/Magisk frameworks
- **Debugging Tools**: Identifies Frida and emulator environments
- **Quick Check**: Fast security check for critical operations
- **Full Check**: Comprehensive security validation

### 2. Encrypted Storage Tests
- **Custom Values**: Store and retrieve encrypted key-value pairs
- **Device ID**: Secure device identifier storage
- **JWT Tokens**: Secure authentication token storage
- **Encryption Keys**: Secure encryption key management
- **Clear All**: Verify complete secure storage wipe
- **Non-existent Keys**: Handle missing keys gracefully

### 3. Database Encryption Tests
- **Database Creation**: Verify encrypted database initialization
- **Data Storage**: Test encrypted data persistence
- **Concurrent Operations**: Validate thread-safe database access

### 4. Security Integration Tests
- **Critical Operations**: Test tamper checks before payments/unlocks
- **End-to-End Flow**: Validate complete security workflow

### 5. Certificate Pinning Tests
- **Configuration**: Verify certificate pinning is configured
- **Invalid Certificates**: Ensure rejection of invalid certificates

### 6. Factory Reset Protection Tests
- **Implementation**: Verify factory reset protection exists
- **Payment Pending**: Ensure reset is blocked when payment pending
- **Release Code**: Validate reset is allowed after release code

## Running Tests on Device

For tests that require platform channels, run on an actual device or emulator:

```bash
# List available devices
flutter devices

# Run tests on specific device
flutter test test/security_test.dart --device-id=<device_id>
```

## Expected Results

### Clean Test Device
On a non-rooted, non-tampered device:
- Root detection: `false`
- App tampering: `false` (valid signature)
- Debugger attached: `false` (unless debugging)
- Xposed/Magisk: `false`
- Full tamper check: `false` (no tampering)

### Rooted/Tampered Device
On a rooted or tampered device:
- Root detection: `true`
- Full tamper check: `true`
- Operations should be blocked

## Test Limitations

### Platform Channel Tests
Tests that use platform channels require Flutter bindings to be initialized. These tests are best run as integration tests on actual devices.

### Emulator Detection
Some tests may detect emulators as potential security risks. This is expected behavior for production security.

### Debug Builds
Debug builds may have different security characteristics than release builds (e.g., debuggable flag set).

## Security Test Coverage

The security tests cover the following requirements:
- **Requirement 8.1**: Tamper detection and prevention
- **Requirement 8.2**: Response to tampering attempts
- **Requirement 8.3**: Encrypted communication and storage
- **Requirement 8.4**: Code integrity validation
- **Requirement 8.5**: Secure data storage

## Manual Security Testing

In addition to automated tests, perform manual security testing:

1. **Root Detection**
   - Test on rooted device
   - Verify app locks and alerts backend

2. **Debugger Detection**
   - Attach debugger to running app
   - Verify detection and response

3. **Certificate Pinning**
   - Use proxy with invalid certificate
   - Verify connection is rejected

4. **Factory Reset Protection**
   - Attempt factory reset with payment pending
   - Verify reset is blocked

5. **Release Build Testing**
   - Build release APK with obfuscation
   - Verify all security features work
   - Test on multiple devices

## Continuous Security Testing

Integrate security tests into CI/CD pipeline:
```yaml
# Example CI configuration
test:
  script:
    - flutter test test/security_test.dart
    - flutter test integration_test/security_integration_test.dart --device-id=emulator
```

## Security Test Maintenance

- Update tests when security features change
- Add tests for new security measures
- Review test coverage regularly
- Test on various Android versions
- Test on different device manufacturers
