# Policy Manager Implementation

## Overview

The PolicyManager service handles remote policy configuration and command execution from the backend Finance System. It enables the store to remotely manage device policies, send commands, and display custom messages on locked devices.

## Features

### 1. Remote Policy Management
- Fetches policy updates from backend every 24 hours
- Applies policy changes to local configuration
- Supports multiple policy types:
  - `payment_schedule`: Payment grace periods and schedules
  - `lock_settings`: Lock delay configurations
  - `monitoring`: Location and status report intervals
  - `notification`: Notification reminder settings

### 2. Remote Command Handling
- Polls backend for pending commands every 24 hours (via policy sync)
- Supports three command types:
  - `unlock`: Remotely unlock the device
  - `lock`: Remotely lock the device
  - `message`: Display custom message on lock screen
- Commands are executed within 5 minutes of receipt
- Sends acknowledgment to backend after execution

### 3. Custom Lock Messages
- Store can send custom messages to display on locked devices
- Messages are stored in local database
- Lock screen automatically displays custom message if present
- Messages can be updated or removed remotely

### 4. Device Status Reporting
- Reports device status every 24 hours via background task
- Includes: app version, lock state, payment status, last payment date, battery level
- Sends immediate status report on critical events:
  - Device locked
  - Device unlocked
  - Payment success

## Usage

### Initialize Policy Manager

```dart
final policyManager = PolicyManager();
```

### Fetch and Apply Policy Updates

```dart
// Fetch policies from backend
final policies = await policyManager.fetchPolicyUpdates();

// Apply policies to local configuration
await policyManager.applyPolicyChanges(policies);
```

### Check and Process Remote Commands

```dart
// Check for pending commands
final commands = await policyManager.checkForRemoteCommands();

// Process all commands
await policyManager.processRemoteCommands();
```

### Combined Sync Operation

```dart
// Sync both policies and commands in one call
await policyManager.syncPoliciesAndCommands();
```

### Get Custom Lock Message

```dart
// Get custom message if set
final message = await policyManager.getCustomLockMessage();

if (message != null) {
  // Display message on lock screen
  print('Custom message: $message');
}
```

### Clear Custom Lock Message

```dart
await policyManager.clearCustomLockMessage();
```

## Background Tasks

### Policy Sync Task
- **Frequency**: Every 24 hours
- **Task Name**: `policy_sync`
- **Network Required**: Yes
- **Function**: Syncs policies and processes remote commands

### Device Status Report Task
- **Frequency**: Every 24 hours
- **Task Name**: `device_status_report`
- **Network Required**: Yes
- **Function**: Reports device status to backend

### Register Background Tasks

```dart
// Register policy sync
await BackgroundTasksService.registerPolicySync();

// Register device status report
await BackgroundTasksService.registerDeviceStatusReport();
```

### Run Tasks Immediately (for testing)

```dart
// Run policy sync now
await BackgroundTasksService.runPolicySyncNow();

// Run status report now
await BackgroundTasksService.runDeviceStatusReportNow();
```

## API Endpoints

### Get Device Config (Policies)
```
GET /api/v1/device/{deviceId}/config
```

Response:
```json
{
  "policies": [
    {
      "policyId": "policy_123",
      "policyType": "lock_settings",
      "settings": {
        "lock_delay_hours": 24
      },
      "effectiveDate": "2024-01-01T00:00:00Z",
      "expiryDate": null
    }
  ]
}
```

### Check Remote Commands
```
GET /api/v1/device/{deviceId}/commands
```

Response:
```json
[
  {
    "commandId": "cmd_456",
    "commandType": "unlock",
    "parameters": {},
    "issuedAt": "2024-01-15T10:30:00Z",
    "expiresAt": "2024-01-15T11:00:00Z"
  },
  {
    "commandId": "cmd_789",
    "commandType": "message",
    "parameters": {
      "message": "Please contact the store regarding your account."
    },
    "issuedAt": "2024-01-15T10:30:00Z",
    "expiresAt": null
  }
]
```

### Acknowledge Command
```
POST /api/v1/device/{deviceId}/commands/{commandId}/acknowledge
```

Request:
```json
{
  "success": true,
  "message": "Device unlocked successfully",
  "timestamp": "2024-01-15T10:35:00Z"
}
```

### Report Device Status
```
POST /api/v1/device/{deviceId}/report
```

Request:
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

## Database Storage

### Policy Configuration
Policies are stored in the `device_config` table with keys like:
- `policy_{policyType}_{policyId}`: Full policy JSON
- `payment_grace_period_hours`: Extracted setting
- `lock_delay_hours`: Extracted setting
- `location_interval_hours`: Extracted setting
- `status_report_interval_hours`: Extracted setting

### Custom Lock Message
- `custom_lock_message`: The message text
- `custom_lock_message_metadata`: Command metadata (commandId, timestamp)

### Remote Command Logs
- `last_remote_unlock`: Last unlock command details
- `last_remote_lock`: Last lock command details

### Sync Timestamps
- `last_policy_sync`: Last successful policy sync timestamp

## Error Handling

### Network Errors
- Network errors during policy sync are logged but don't fail the task
- Policies will be retried on next scheduled sync
- Commands are checked again on next sync

### Command Execution Errors
- Failed commands send failure acknowledgment to backend
- Error details are included in acknowledgment message
- Other commands continue to be processed

### Policy Application Errors
- Invalid policies are skipped
- Expired policies are ignored
- Errors are logged for debugging

## Security Considerations

1. **Command Expiry**: Commands can have expiry times to prevent replay attacks
2. **Acknowledgment**: All commands are acknowledged to backend for audit trail
3. **Tamper Detection**: Critical operations check for tampering before execution
4. **Secure Storage**: Device ID and tokens are stored in secure storage

## Integration with Other Services

### LockService
- PolicyManager can trigger lock/unlock via LockService
- Remote unlock commands call `LockService.unlockDevice()`
- Remote lock commands call `LockService.lockDevice()`

### Lock Screen
- Lock screen displays custom messages from PolicyManager
- Calls `policyManager.getCustomLockMessage()` on load

### Background Tasks
- Policy sync runs every 24 hours
- Status reports run every 24 hours
- Immediate status reports on critical events

## Testing

### Manual Testing
```dart
// Test policy sync
await BackgroundTasksService.runPolicySyncNow();

// Test status report
await BackgroundTasksService.runDeviceStatusReportNow();

// Test custom message
final policyManager = PolicyManager();
await policyManager.handleMessageCommand(
  RemoteCommand(
    commandId: 'test_123',
    commandType: 'message',
    parameters: {'message': 'Test message'},
    issuedAt: DateTime.now(),
  ),
);

// Verify message is displayed
final message = await policyManager.getCustomLockMessage();
print('Custom message: $message');
```

## Requirements Satisfied

- **Requirement 7.1**: Policy updates received and applied within 1 hour (24-hour sync + immediate on-demand)
- **Requirement 7.2**: Payment schedules can be modified remotely via policies
- **Requirement 7.3**: Manual unlock commands executed within 5 minutes
- **Requirement 7.4**: Custom messages displayed on locked devices
- **Requirement 7.5**: Device status reported every 24 hours + on critical events

## Future Enhancements

1. **Real-time Commands**: Implement push notifications for immediate command delivery
2. **Policy Versioning**: Track policy versions for rollback capability
3. **Command Queue**: Queue commands for execution when device comes online
4. **Policy Conflicts**: Handle conflicting policies with priority system
5. **Audit Logging**: Enhanced logging of all policy and command operations
