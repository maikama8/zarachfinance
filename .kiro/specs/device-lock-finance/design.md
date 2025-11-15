# Design Document - Device Lock Finance App

## Overview

The Device Lock Finance App is an Android application that enforces payment compliance for financed mobile phones. The system consists of an Android client app with Device Administrator privileges and a backend Finance System that manages payment schedules, device status, and policy configurations.

The app leverages Android's Device Policy Manager API to maintain persistent control over the device, prevent unauthorized resets, and enforce payment-based access restrictions. The architecture prioritizes security, tamper resistance, and reliable communication with the backend system.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Android Device                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │         Device Admin App (Client)                 │  │
│  │  ┌─────────────┐  ┌──────────────┐              │  │
│  │  │   Lock      │  │   Payment    │              │  │
│  │  │  Service    │  │   Service    │              │  │
│  │  └─────────────┘  └──────────────┘              │  │
│  │  ┌─────────────┐  ┌──────────────┐              │  │
│  │  │  Admin      │  │  Notification│              │  │
│  │  │  Receiver   │  │   Manager    │              │  │
│  │  └─────────────┘  └──────────────┘              │  │
│  │  ┌─────────────────────────────────┐            │  │
│  │  │    Local Database (Room)        │            │  │
│  │  └─────────────────────────────────┘            │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                    HTTPS/TLS 1.3
                          │
┌─────────────────────────────────────────────────────────┐
│              Finance System (Backend)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Payment    │  │    Device    │  │    Policy    │  │
│  │   Service    │  │   Manager    │  │   Manager    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │           Database (PostgreSQL)                  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Technology Stack

**Flutter Client:**
- Framework: Flutter 3.x
- Language: Dart
- Minimum SDK: API 24 (Android 7.0)
- Target SDK: API 34 (Android 14)
- Key Packages:
  - flutter_device_policy (Device Admin via platform channels)
  - sqflite_sqlcipher for encrypted local database
  - dio for HTTP client with interceptors
  - workmanager for background tasks
  - flutter_secure_storage for secure key storage
  - geolocator for location tracking
  - flutter_local_notifications for notifications
  - provider or riverpod for state management
- Platform Channels: Custom Android native code for Device Policy Manager integration

**Backend (Finance System):**
- Framework: Node.js with Express or similar
- Database: PostgreSQL
- Authentication: JWT tokens
- API: RESTful with JSON payloads

## Components and Interfaces

### 1. Device Admin Receiver (Native Android)

**Purpose:** Handles device administrator events and enforces admin policies via platform channel.

**Key Responsibilities:**
- Intercept and block device admin deactivation attempts
- Prevent factory reset operations
- Handle device boot events to ensure service persistence
- Respond to password change attempts

**Implementation Details:**

**Native Android (Kotlin) - android/app/src/main/kotlin:**
```kotlin
class FinanceDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "Device admin cannot be disabled while payment is pending"
    }
    
    override fun onDisabled(context: Context, intent: Intent) {
        // This should only be called after full payment with release code
    }
    
    override fun onEnabled(context: Context, intent: Intent) {
        // Initialize device policies
    }
}
```

**Flutter Side - Platform Channel:**
```dart
class DeviceAdminChannel {
  static const platform = MethodChannel('com.finance.deviceadmin/admin');
  
  Future<bool> isAdminActive() async {
    return await platform.invokeMethod('isAdminActive');
  }
  
  Future<void> requestAdminPrivileges() async {
    await platform.invokeMethod('requestAdminPrivileges');
  }
  
  Future<void> lockDevice() async {
    await platform.invokeMethod('lockDevice');
  }
}
```

### 2. Lock Service

**Purpose:** Manages device lock state based on payment status.

**Key Responsibilities:**
- Monitor payment status from local database
- Trigger device lock when payment is overdue
- Display lock screen with payment information
- Allow emergency calls during lock state
- Unlock device upon payment confirmation

**Lock Mechanism:**
- Use Device Policy Manager's `lockNow()` via platform channel
- Set password requirements to prevent bypass
- Display custom Flutter lock screen as full-screen activity
- Use WillPopScope to override back button
- Set app as launcher to intercept home button

**Implementation Strategy:**

**Flutter Lock Service:**
```dart
class LockService {
  final DeviceAdminChannel _adminChannel = DeviceAdminChannel();
  final DatabaseHelper _db = DatabaseHelper();
  
  Future<void> lockDevice() async {
    // Set lock state in database
    await _db.setLockState(true);
    // Trigger native lock
    await _adminChannel.lockDevice();
    // Navigate to lock screen
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LockScreen()),
      (route) => false,
    );
  }
  
  Future<void> unlockDevice() async {
    await _db.setLockState(false);
    // Navigate to main app
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomePage()),
      (route) => false,
    );
  }
}
```

### 3. Payment Service

**Purpose:** Handles payment verification, processing, and synchronization with backend.

**Key Responsibilities:**
- Check payment status with Finance System every 6 hours
- Process payment requests from user
- Synchronize payment history
- Handle offline payment queuing
- Validate release codes

**API Endpoints:**
```
GET  /api/v1/device/{deviceId}/payment-status
POST /api/v1/device/{deviceId}/payment
GET  /api/v1/device/{deviceId}/schedule
POST /api/v1/device/{deviceId}/verify-release-code
```

**Implementation:**
```dart
class PaymentService {
  final Dio _dio;
  final DatabaseHelper _db;
  
  Future<PaymentStatus> checkPaymentStatus() async {
    try {
      final response = await _dio.get('/api/v1/device/$deviceId/payment-status');
      return PaymentStatus.fromJson(response.data);
    } catch (e) {
      // Queue for retry
      await _db.addToSyncQueue(SyncType.paymentCheck, {});
      rethrow;
    }
  }
  
  Future<PaymentResult> processPayment(double amount, String method) async {
    final response = await _dio.post('/api/v1/device/$deviceId/payment', data: {
      'amount': amount,
      'method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
    return PaymentResult.fromJson(response.data);
  }
}
```

**Background Sync:**
- Use workmanager package with periodic tasks (6-hour intervals)
- Implement exponential backoff for failed requests
- Queue operations when offline, sync when online

### 4. Notification Manager

**Purpose:** Manages payment reminders and status notifications.

**Key Responsibilities:**
- Schedule notifications 24 hours and 6 hours before payment due
- Display overdue payment notifications
- Show payment confirmation messages
- Handle notification actions (e.g., "Pay Now" button)

**Implementation:**
```dart
class NotificationManager {
  final FlutterLocalNotificationsPlugin _notifications;
  
  Future<void> schedulePaymentReminder(DateTime dueDate, double amount) async {
    // Schedule 24 hours before
    await _notifications.zonedSchedule(
      0,
      'Payment Due Tomorrow',
      'Your payment of ₦$amount is due tomorrow',
      tz.TZDateTime.from(dueDate.subtract(Duration(hours: 24)), tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    // Schedule 6 hours before
    await _notifications.zonedSchedule(
      1,
      'Payment Due Soon',
      'Your payment of ₦$amount is due in 6 hours',
      tz.TZDateTime.from(dueDate.subtract(Duration(hours: 6)), tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
```

- Use flutter_local_notifications for notification management
- Create notification channels for different priority levels
- Implement notification actions that open payment interface

### 5. Location Tracker

**Purpose:** Tracks device location for inventory management.

**Key Responsibilities:**
- Capture device location every 12 hours
- Transmit location to Finance System
- Handle location permissions gracefully
- Queue location updates when offline

**Implementation:**
```dart
class LocationTracker {
  final Geolocator _geolocator = Geolocator();
  final ApiClient _api;
  final DatabaseHelper _db;
  
  Future<void> captureAndSendLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) return;
    
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low, // Coarse location
    );
    
    try {
      await _api.sendLocation(position.latitude, position.longitude);
    } catch (e) {
      // Queue for later
      await _db.addToSyncQueue(SyncType.location, {
        'lat': position.latitude,
        'lng': position.longitude,
      });
    }
  }
}
```

**Privacy Considerations:**
- Request location permissions during onboarding
- Clearly communicate location tracking in terms of service
- Use coarse location (not fine) to balance privacy and functionality

### 6. Tamper Detection Module

**Purpose:** Detects and responds to tampering attempts.

**Key Responsibilities:**
- Verify app signature on launch
- Detect root access and custom ROMs
- Monitor for debugging attempts
- Check for Xposed/Magisk modules
- Validate integrity of critical app components

**Implementation:**

**Native Android (Kotlin) - Platform Channel:**
```kotlin
class TamperDetector(private val context: Context) {
    fun isDeviceRooted(): Boolean {
        // Check for su binary, root management apps
        val paths = arrayOf("/system/app/Superuser.apk", "/sbin/su", "/system/bin/su")
        return paths.any { File(it).exists() }
    }
    
    fun isAppTampered(): Boolean {
        // Verify app signature
        val packageInfo = context.packageManager.getPackageInfo(
            context.packageName, 
            PackageManager.GET_SIGNATURES
        )
        // Compare with expected signature
        return false // Implementation details
    }
    
    fun isDebuggerAttached(): Boolean {
        return Debug.isDebuggerConnected()
    }
}
```

**Flutter Side:**
```dart
class TamperDetectionService {
  static const platform = MethodChannel('com.finance.deviceadmin/tamper');
  
  Future<bool> checkForTampering() async {
    final isRooted = await platform.invokeMethod('isDeviceRooted');
    final isTampered = await platform.invokeMethod('isAppTampered');
    final isDebugging = await platform.invokeMethod('isDebuggerAttached');
    
    return isRooted || isTampered || isDebugging;
  }
}
```

**Response Actions:**
- Lock device immediately
- Send alert to Finance System
- Log tampering attempt locally
- Display warning message to user

### 7. Factory Reset Protection

**Purpose:** Prevents unauthorized factory resets.

**Implementation Strategy:**

Since Android 5.0+, Device Admin apps cannot completely block factory reset from recovery mode, but we can implement multiple layers:

**Layer 1 - Settings Prevention:**
- Override factory reset intent in settings
- Use Device Policy Manager to disable factory reset option

**Layer 2 - Recovery Mode Protection:**
- Set device owner mode during initial setup (requires factory reset to install)
- Use Android Enterprise (Work Profile) if device owner mode is not feasible
- Implement Factory Reset Protection (FRP) by associating device with Google account

**Layer 3 - Post-Reset Detection:**
- Store device binding information on backend
- On first boot after reset, detect missing app and flag device as compromised
- Require online verification before device can be used

**Recommended Approach:**
- Use Device Owner mode for maximum control (requires device provisioning during initial setup)
- Fallback to Device Admin mode with FRP for existing devices

## Data Models

### Local Database Schema (SQLite with sqflite_sqlcipher)

```dart
// Dart models for local database
class PaymentSchedule {
  final String id;
  final DateTime dueDate;
  final double amount;
  final PaymentStatus status; // PENDING, PAID, OVERDUE
  final DateTime? paidDate;
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'amount': amount,
      'status': status.toString(),
      'paidDate': paidDate?.millisecondsSinceEpoch,
    };
  }
  
  factory PaymentSchedule.fromMap(Map<String, dynamic> map) {
    return PaymentSchedule(
      id: map['id'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      amount: map['amount'],
      status: PaymentStatus.values.firstWhere((e) => e.toString() == map['status']),
      paidDate: map['paidDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['paidDate']) 
        : null,
    );
  }
}

class DeviceConfig {
  final String key;
  final String value;
  final DateTime lastUpdated;
  
  Map<String, dynamic> toMap() => {
    'key': key,
    'value': value,
    'lastUpdated': lastUpdated.millisecondsSinceEpoch,
  };
}

class PaymentHistory {
  final String transactionId;
  final double amount;
  final DateTime timestamp;
  final TransactionStatus status; // SUCCESS, FAILED, PENDING
  final String method;
  
  Map<String, dynamic> toMap() => {
    'transactionId': transactionId,
    'amount': amount,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'status': status.toString(),
    'method': method,
  };
}

class SyncQueueItem {
  final int? id;
  final SyncType type; // PAYMENT, LOCATION, STATUS
  final String payload;
  final DateTime timestamp;
  final int retryCount;
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.toString(),
    'payload': payload,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'retryCount': retryCount,
  };
}

enum PaymentStatus { pending, paid, overdue }
enum TransactionStatus { success, failed, pending }
enum SyncType { payment, location, status }
```

### Backend API Models

```typescript
interface Device {
    deviceId: string;
    imei: string;
    customerId: string;
    phoneModel: string;
    purchaseDate: Date;
    totalAmount: number;
    paidAmount: number;
    status: 'ACTIVE' | 'LOCKED' | 'PAID_OFF' | 'DEFAULTED';
    lastSeen: Date;
}

interface PaymentSchedule {
    scheduleId: string;
    deviceId: string;
    installments: Installment[];
}

interface Installment {
    installmentId: string;
    dueDate: Date;
    amount: number;
    status: 'PENDING' | 'PAID' | 'OVERDUE';
    paidDate?: Date;
}

interface PaymentTransaction {
    transactionId: string;
    deviceId: string;
    amount: number;
    method: string;
    timestamp: Date;
    status: 'SUCCESS' | 'FAILED' | 'PENDING';
}
```

## Error Handling

### Network Errors

**Strategy:**
- Implement retry logic with exponential backoff (max 3 retries)
- Queue operations locally when network is unavailable
- Display user-friendly error messages
- Allow grace period for payment verification during network outages

**Grace Period Logic:**
- If payment status cannot be verified due to network issues, allow 48-hour grace period
- Display warning to user about verification pending
- Lock device only after grace period expires without successful verification

### Payment Processing Errors

**Scenarios:**
1. Payment gateway timeout
2. Insufficient funds
3. Invalid payment method
4. Duplicate transaction

**Handling:**
- Display specific error message for each scenario
- Provide retry option
- Log failed attempts for customer support
- Do not lock device for payment processing errors (only for missed payments)

### Tamper Detection Errors

**Response:**
- Immediate device lock
- Send alert to backend with tamper details
- Display message: "Security violation detected. Contact store."
- Require manual intervention from store administrator

### Critical Failures

**Scenarios:**
- App crashes repeatedly
- Database corruption
- Certificate pinning failure

**Handling:**
- Implement crash reporting (Firebase Crashlytics or similar)
- Automatic recovery attempts
- Fallback to safe mode (basic lock/unlock only)
- Remote diagnostics capability for store administrators

## Testing Strategy

### Unit Testing

**Components to Test:**
- Payment calculation logic
- Date/time handling for payment schedules
- Encryption/decryption functions
- API request/response parsing
- Tamper detection algorithms

**Tools:**
- Flutter test framework for Dart unit tests
- Mockito for mocking dependencies
- flutter_test package for widget testing

### Integration Testing

**Scenarios:**
- Payment flow end-to-end
- Lock/unlock cycle
- Background sync operations
- Notification scheduling and delivery
- API communication with backend

**Tools:**
- Flutter integration_test package for end-to-end testing
- http_mock_adapter for API mocking
- Platform channel mocking for native code testing

### Security Testing

**Tests:**
- Certificate pinning validation
- Encrypted storage verification
- Tamper detection effectiveness
- Root detection accuracy
- Factory reset prevention

**Tools:**
- Manual penetration testing
- Frida for runtime analysis testing
- APK decompilation and analysis

### Device Testing

**Test Devices:**
- Multiple Android versions (7.0 to 14)
- Different manufacturers (Samsung, Tecno, Infinix - popular in Nigeria)
- Various screen sizes
- Low-end and high-end devices

**Test Scenarios:**
- Device reboot during lock state
- App update while device is locked
- Low battery scenarios
- Airplane mode and offline usage
- SIM card removal

### User Acceptance Testing

**Scenarios:**
- Customer onboarding flow
- Making payments through app
- Receiving and responding to notifications
- Device lock and unlock experience
- Viewing payment schedule and history

## Security Considerations

### Data Protection

- Use flutter_secure_storage (backed by Android Keystore) for storing sensitive keys
- Encrypt local database using sqflite_sqlcipher
- Store JWT tokens and sensitive config in flutter_secure_storage
- Implement certificate pinning for API calls using dio
- Clear sensitive data from memory after use

### Authentication

- Device-to-backend authentication using device-specific JWT tokens
- Token rotation every 30 days
- Secure token storage in Android Keystore
- Implement device fingerprinting (IMEI + Android ID + hardware identifiers)

### Code Obfuscation

- Enable ProGuard/R8 for code obfuscation
- Obfuscate critical strings and constants
- Use native code (JNI) for critical security functions
- Implement anti-debugging measures

### Compliance

- GDPR considerations for location tracking (if applicable)
- Nigerian data protection regulations
- Clear terms of service and privacy policy
- Customer consent for device monitoring

## Deployment Strategy

### Initial Device Setup

1. Customer purchases phone on finance
2. Store staff installs Device Admin App before handover
3. App activates Device Administrator privileges
4. Device is registered with Finance System (device ID, customer ID, payment schedule)
5. Customer completes onboarding and sets up payment method
6. Device is handed over to customer

### App Updates

- Use Google Play Store for distribution (or internal distribution)
- Implement forced update mechanism for critical security patches
- Ensure updates do not disrupt lock state
- Test updates thoroughly on locked devices

### Release Code Distribution

- Generate unique release codes per device
- Codes are single-use and expire after 7 days
- Delivered to customer via SMS after full payment confirmation
- Code validation requires online verification with backend
- After successful validation, app removes all restrictions and allows uninstallation
