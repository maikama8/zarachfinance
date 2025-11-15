# Tamper Detection Module

## Overview

The Tamper Detection Module provides comprehensive security checks to detect device rooting, app tampering, debugging attempts, and framework modifications (Xposed/Magisk). When tampering is detected, the device is immediately locked and an alert is sent to the backend.

## Components

### 1. Native Android Layer

**TamperDetector.kt**
- Implements security checks at the native Android level
- Detects:
  - Device root access (su binary, root apps, test-keys)
  - App signature tampering
  - Debugger attachment
  - Xposed/Magisk frameworks

**TamperDetectionMethodChannel.kt**
- Platform channel bridge between Flutter and native code
- Exposes tamper detection methods to Flutter layer

### 2. Flutter Layer

**tamper_detection_channel.dart**
- Flutter wrapper for platform channel
- Provides type-safe interface to native tamper detection

**tamper_detection_service.dart**
- High-level service for tamper detection
- Handles tamper response actions:
  - Logs tampering attempts to local database
  - Sends alerts to backend
  - Locks device immediately
  - Shows warning dialog to user

**tamper_guard.dart**
- Utility class for protecting critical operations
- Use before sensitive operations like payments and unlocking

### 3. Integration

**main.dart**
- Runs tamper check on app startup
- Implements periodic checks every 30 minutes
- Manages tamper detection lifecycle

**payment_service.dart**
- Runs tamper check before processing payments

**lock_service.dart**
- Runs tamper check before unlocking device

## Usage

### Automatic Checks

Tamper detection runs automatically:
- On app startup
- Every 30 minutes (periodic check)
- Before payment processing
- Before device unlock

### Manual Checks

Use `TamperGuard` for custom critical operations:

```dart
import 'package:device_admin_app/utils/tamper_guard.dart';

// Before critical operation
if (await TamperGuard.checkBeforeCriticalOperation('operation_name')) {
  // Proceed with operation
} else {
  // Operation blocked due to tampering
}

// Get detailed tamper status
final status = await TamperGuard.getDetailedTamperStatus();
print('Is rooted: ${status['isRooted']}');
print('Is tampered: ${status['isAppTampered']}');
```

### Direct Service Access

For more control, use `TamperDetectionService`:

```dart
import 'package:device_admin_app/services/tamper_detection_service.dart';

final tamperService = TamperDetectionService();

// Full tamper check
final isTampered = await tamperService.checkForTampering();

// Individual checks
final isRooted = await tamperService.isDeviceRooted();
final isAppTampered = await tamperService.isAppTampered();
final isDebugging = await tamperService.isDebuggerAttached();
final hasFramework = await tamperService.hasXposedMagisk();
```

## Response Actions

When tampering is detected:

1. **Immediate Lock**: Device is locked via `LockService.lockDevice()`
2. **Local Logging**: Attempt is logged to device_config table
3. **Backend Alert**: Alert sent to backend with tamper details
4. **User Warning**: Dialog shown: "Security violation detected. Contact store."

## Detection Methods

### Root Detection
- Checks for su binary in common locations
- Scans for root management apps (SuperSU, Magisk, etc.)
- Verifies build tags for test-keys
- Tests if system directories are writable

### App Tampering
- Verifies app signature against expected signature
- Detects if app has been repackaged or modified

### Debugger Detection
- Uses `Debug.isDebuggerConnected()`
- Checks `Debug.waitingForDebugger()`

### Framework Detection
- Scans for Xposed framework files and classes
- Checks for Magisk files and app
- Detects runtime modification frameworks

## Security Considerations

1. **Fail Open**: If tamper check fails due to error, operations proceed to prevent breaking functionality
2. **Multiple Layers**: Combines multiple detection methods for comprehensive coverage
3. **Periodic Checks**: Regular checks prevent bypass after initial startup
4. **Critical Operation Guards**: Protects sensitive operations with pre-checks

## Backend Integration

Tamper alerts are sent to:
```
POST /api/v1/device/{deviceId}/tamper-alert
```

Alert payload includes:
- `tamperType`: ROOT_DETECTED, APP_TAMPERED, DEBUGGER_ATTACHED, FRAMEWORK_DETECTED
- `description`: Human-readable description
- `timestamp`: When tampering was detected
- `details`: Detailed information about what was detected

## Testing

To test tamper detection:

1. **Root Detection**: Test on rooted device or emulator with root
2. **App Tampering**: Modify app signature and reinstall
3. **Debugger**: Attach debugger and verify detection
4. **Framework**: Test on device with Xposed/Magisk installed

## Limitations

- Root detection can be bypassed by sophisticated root hiding tools
- App signature verification requires proper configuration in production
- Some detection methods may have false positives on custom ROMs
- Framework detection may not catch all modification tools

## Production Configuration

Before production deployment:

1. Update `TamperDetector.kt` with expected app signature hash
2. Test on target devices (Tecno, Infinix, Samsung)
3. Adjust detection sensitivity based on false positive rate
4. Configure backend to handle tamper alerts appropriately
