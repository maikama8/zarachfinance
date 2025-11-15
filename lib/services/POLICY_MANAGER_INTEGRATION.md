# PolicyManager Integration Guide

## Quick Start

### 1. Register Background Tasks

Add to your app initialization (e.g., in `main.dart` after device registration):

```dart
import 'package:device_admin_app/services/background_tasks.dart';

Future<void> initializeApp() async {
  // ... other initialization code ...
  
  // Initialize background tasks
  await BackgroundTasksService.initialize();
  
  // Register policy sync (every 24 hours)
  await BackgroundTasksService.registerPolicySync();
  
  // Register device status report (every 24 hours)
  await BackgroundTasksService.registerDeviceStatusReport();
  
  // ... other initialization code ...
}
```

### 2. Using PolicyManager in Your Code

```dart
import 'package:device_admin_app/services/policy_manager.dart';

// Create instance
final policyManager = PolicyManager();

// Sync policies and commands
await policyManager.syncPoliciesAndCommands();

// Get custom lock message (for lock screen)
final message = await policyManager.getCustomLockMessage();
if (message != null) {
  // Display message
}
```

### 3. Lock Screen Integration

The lock screen automatically displays custom messages. No additional code needed - it's already integrated in `lib/screens/lock_screen.dart`.

### 4. Status Reports on Critical Events

Status reports are automatically sent on:
- Device lock (in `LockService.lockDevice()`)
- Device unlock (in `LockService.unlockDevice()`)
- Successful payment (in `PaymentService.processPayment()`)

No additional code needed - already integrated.

## Backend API Requirements

### 1. Get Device Config (Policies)

**Endpoint**: `GET /api/v1/device/{deviceId}/config`

**Response Format**:
```json
{
  "policies": [
    {
      "policyId": "policy_001",
      "policyType": "lock_settings",
      "settings": {
        "lock_delay_hours": 24
      },
      "effectiveDate": "2024-01-01T00:00:00Z",
      "expiryDate": null
    },
    {
      "policyId": "policy_002",
      "policyType": "payment_schedule",
      "settings": {
        "grace_period_hours": 48
      },
      "effectiveDate": "2024-01-01T00:00:00Z",
      "expiryDate": null
    }
  ]
}
```

**Policy Types**:
- `payment_schedule`: Payment-related settings
  - `grace_period_hours`: Grace period before lock
- `lock_settings`: Lock behavior settings
  - `lock_delay_hours`: Delay before locking after missed payment
- `monitoring`: Monitoring intervals
  - `location_interval_hours`: Location capture frequency
  - `status_report_interval_hours`: Status report frequency
- `notification`: Notification settings
  - `reminder_hours_before`: Array of hours before payment to send reminders

### 2. Check Remote Commands

**Endpoint**: `GET /api/v1/device/{deviceId}/commands`

**Response Format**:
```json
[
  {
    "commandId": "cmd_001",
    "commandType": "unlock",
    "parameters": {},
    "issuedAt": "2024-01-15T10:00:00Z",
    "expiresAt": "2024-01-15T10:30:00Z"
  },
  {
    "commandId": "cmd_002",
    "commandType": "message",
    "parameters": {
      "message": "Please contact the store to discuss your payment plan."
    },
    "issuedAt": "2024-01-15T10:00:00Z",
    "expiresAt": null
  }
]
```

**Command Types**:
- `unlock`: Unlock the device
  - Parameters: none
- `lock`: Lock the device
  - Parameters: none
- `message`: Display custom message on lock screen
  - Parameters: `message` (string)

**Command Expiry**:
- Commands with `expiresAt` will be ignored after that time
- Commands without `expiresAt` never expire
- Expired commands are filtered out automatically

### 3. Acknowledge Command

**Endpoint**: `POST /api/v1/device/{deviceId}/commands/{commandId}/acknowledge`

**Request Format**:
```json
{
  "success": true,
  "message": "Device unlocked successfully",
  "timestamp": "2024-01-15T10:05:00Z"
}
```

**Success Response**: 200 OK

**Error Response**: 4xx/5xx with error details

### 4. Report Device Status

**Endpoint**: `POST /api/v1/device/{deviceId}/report`

**Request Format**:
```json
{
  "appVersion": "1.0.0",
  "lockState": "UNLOCKED",
  "paymentStatus": "CURRENT",
  "lastPaymentDate": "2024-01-10T00:00:00Z",
  "batteryLevel": 85,
  "timestamp": "2024-01-15T10:00:00Z",
  "additionalData": {
    "eventType": "payment_success",
    "eventTimestamp": "2024-01-15T10:00:00Z"
  }
}
```

**Lock States**:
- `LOCKED`: Device is currently locked
- `UNLOCKED`: Device is currently unlocked

**Payment Statuses**:
- `CURRENT`: No overdue payments
- `OVERDUE`: Has overdue payments

**Event Types** (in additionalData):
- `device_locked`: Device was just locked
- `device_unlocked`: Device was just unlocked
- `payment_success`: Payment was successfully processed
- `scheduled_report`: Regular 24-hour report

## Testing

### Test Policy Sync

```dart
// Trigger immediate policy sync
await BackgroundTasksService.runPolicySyncNow();

// Check if policies were applied
final db = DatabaseHelper();
final lockDelayConfig = await db.getDeviceConfig('lock_delay_hours');
print('Lock delay: ${lockDelayConfig?.value}');
```

### Test Remote Unlock Command

1. Add unlock command to backend queue
2. Trigger policy sync: `await BackgroundTasksService.runPolicySyncNow()`
3. Verify device unlocks
4. Check backend for acknowledgment

### Test Custom Message

1. Add message command to backend queue
2. Trigger policy sync
3. Navigate to lock screen
4. Verify custom message is displayed

### Test Status Report

```dart
// Trigger immediate status report
await BackgroundTasksService.runDeviceStatusReportNow();

// Or trigger on critical event
await BackgroundTasksService.sendStatusReportOnCriticalEvent('test_event');

// Check backend for received report
```

## Troubleshooting

### Policies Not Applying

**Check**:
1. Device ID is set in secure storage
2. Backend returns valid policy format
3. Policy `effectiveDate` is in the past
4. Policy `expiryDate` is null or in the future
5. Network connectivity is available

**Debug**:
```dart
final policyManager = PolicyManager();
try {
  final policies = await policyManager.fetchPolicyUpdates();
  print('Fetched ${policies.length} policies');
  await policyManager.applyPolicyChanges(policies);
  print('Policies applied successfully');
} catch (e) {
  print('Error: $e');
}
```

### Commands Not Executing

**Check**:
1. Commands are not expired
2. Backend returns valid command format
3. Device ID is correct
4. Network connectivity is available

**Debug**:
```dart
final policyManager = PolicyManager();
try {
  final commands = await policyManager.checkForRemoteCommands();
  print('Found ${commands.length} commands');
  for (final cmd in commands) {
    print('Command: ${cmd.commandType}, Expired: ${cmd.isExpired()}');
  }
} catch (e) {
  print('Error: $e');
}
```

### Status Reports Not Sending

**Check**:
1. Device ID is set
2. Network connectivity is available
3. Backend endpoint is accessible
4. Battery level can be read

**Debug**:
```dart
try {
  await BackgroundTasksService.sendStatusReportOnCriticalEvent('debug_test');
  print('Status report sent successfully');
} catch (e) {
  print('Error sending status report: $e');
}
```

### Custom Message Not Displaying

**Check**:
1. Message command was executed successfully
2. Message is stored in database
3. Lock screen is loading the message

**Debug**:
```dart
final policyManager = PolicyManager();
final message = await policyManager.getCustomLockMessage();
print('Custom message: ${message ?? "None"}');

// Check database directly
final db = DatabaseHelper();
final config = await db.getDeviceConfig('custom_lock_message');
print('DB value: ${config?.value}');
```

## Performance Considerations

### Background Task Frequency

- Policy sync: 24 hours (configurable via Workmanager)
- Status report: 24 hours (configurable via Workmanager)
- Both tasks require network connectivity
- Both use exponential backoff on failures

### Network Usage

- Policy sync: ~1-5 KB per request
- Command check: ~1-5 KB per request
- Status report: ~1-2 KB per request
- Total: ~3-12 KB per day (scheduled tasks only)

### Battery Impact

- Background tasks run only when device is idle
- Network constraints prevent excessive wake-ups
- Minimal battery impact (<1% per day)

### Storage Usage

- Policies: ~1-5 KB per policy
- Commands: ~1-2 KB per command
- Logs: ~1 KB per event
- Total: <100 KB for typical usage

## Security Considerations

### Command Authentication

- All commands require valid device ID
- Commands are fetched over HTTPS
- JWT token authentication on all API calls

### Command Expiry

- Commands can expire to prevent replay attacks
- Expired commands are automatically filtered
- Backend should clean up old commands

### Acknowledgment

- All commands are acknowledged
- Success/failure status is reported
- Audit trail maintained on backend

### Tamper Detection

- Critical operations check for tampering
- Unlock commands verify device integrity
- Tampered devices are locked immediately

## Best Practices

### 1. Command Timing

- Set reasonable expiry times (30 minutes recommended)
- Don't rely on immediate execution (24-hour sync interval)
- For urgent commands, consider push notifications

### 2. Policy Updates

- Test policies in staging before production
- Use effective dates for gradual rollout
- Set expiry dates for temporary policies

### 3. Custom Messages

- Keep messages concise and clear
- Include contact information if needed
- Update messages as situations change
- Clear messages when no longer needed

### 4. Status Monitoring

- Monitor status report delivery rate
- Alert on missing reports (>48 hours)
- Track command acknowledgment rate
- Monitor policy application success

### 5. Error Handling

- Log all errors for debugging
- Don't fail silently on network errors
- Retry failed operations with backoff
- Alert on repeated failures

## Migration Guide

If you're adding PolicyManager to an existing app:

### 1. Update Dependencies

```yaml
# pubspec.yaml
dependencies:
  battery_plus: ^6.0.0  # Add this
  package_info_plus: ^8.0.0  # Should already exist
```

### 2. Register Background Tasks

Add to your initialization code:

```dart
await BackgroundTasksService.registerPolicySync();
await BackgroundTasksService.registerDeviceStatusReport();
```

### 3. Update Lock Screen

The lock screen is already updated to display custom messages. No changes needed.

### 4. Update Lock/Payment Services

Status reporting is already integrated. No changes needed.

### 5. Test Integration

Run the test commands above to verify everything works.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the README_POLICY_MANAGER.md documentation
3. Check the implementation in policy_manager.dart
4. Review the background_tasks.dart integration

## Version History

- **v1.0.0** (January 2024): Initial implementation
  - Policy management
  - Remote commands (unlock, lock, message)
  - Custom lock messages
  - Device status reporting
  - Background task integration
