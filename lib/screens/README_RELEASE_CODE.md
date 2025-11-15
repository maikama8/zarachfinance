# Release Code Functionality

## Overview

The release code functionality allows customers to fully release their device after completing all payments. This removes all restrictions and allows the customer to uninstall the app and deactivate device admin.

## Components

### 1. ReleaseCodeScreen (`release_code_screen.dart`)

The main screen where users enter their release code.

**Features:**
- Text input field for 12-character alphanumeric code
- Format validation (exactly 12 alphanumeric characters)
- Loading indicator during validation
- Error message display for invalid/expired codes
- Automatic navigation to success screen on valid code

**Validation Rules:**
- Code must be exactly 12 characters
- Only alphanumeric characters allowed (A-Z, a-z, 0-9)
- Whitespace is automatically removed
- Code is converted to uppercase before submission

### 2. DeviceReleaseSuccessScreen (`release_code_screen.dart`)

Success screen shown after device release is complete.

**Features:**
- Automatic device release process on screen load
- Progress indicator during release
- Success confirmation with checklist of completed actions
- Instructions for next steps
- Buttons to:
  - Deactivate device admin (opens settings)
  - View uninstall instructions

**Release Process:**
1. Mark device as released (sets native flag)
2. Disable factory reset protection
3. Unregister device from backend
4. Clear local database
5. Clear secure storage

### 3. DeviceReleaseService (`device_release_service.dart`)

Service class that handles the device release process.

**Methods:**
- `releaseDevice()`: Performs complete device release
- `openAdminDeactivationSettings()`: Opens device admin settings
- `isDeviceReleased()`: Checks if device is released
- `getReleaseStatusMessage()`: Gets release status message

**Release Steps:**
1. **Mark as Released**: Sets a flag in native shared preferences that allows device admin deactivation
2. **Disable Factory Reset Protection**: Re-enables factory reset functionality
3. **Unregister from Backend**: Notifies backend that device is released
4. **Clear Database**: Removes all local payment and configuration data
5. **Clear Secure Storage**: Removes all sensitive data (tokens, keys, etc.)

### 4. Native Implementation

**DeviceAdminMethodChannel.kt:**
- `markDeviceAsReleased()`: Sets shared preference flag
- `allowAdminDeactivation()`: Opens security settings

**FinanceDeviceAdminReceiver.kt:**
- Updated `onDisableRequested()` to check release flag
- Allows deactivation if device is released
- Blocks deactivation if payment is still pending

## Usage Flow

### Customer Perspective

1. **Complete All Payments**
   - Customer makes final payment
   - Backend generates unique release code
   - Code is sent to customer via SMS

2. **Enter Release Code**
   - Customer opens app
   - Navigates to "Enter Release Code" screen
   - Enters 12-character code
   - Taps "Validate Code"

3. **Device Release**
   - App validates code with backend
   - If valid, automatic release process begins
   - Success screen shows progress
   - All restrictions are removed

4. **Deactivate and Uninstall**
   - Customer taps "Deactivate Device Admin"
   - System settings open
   - Customer deactivates device admin
   - Customer can now uninstall the app

### Backend Requirements

The backend must implement the release code verification endpoint:

```
POST /api/v1/device/{deviceId}/verify-release-code
```

**Request:**
```json
{
  "code": "ABC123XYZ789",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Response (Success):**
```json
{
  "isValid": true,
  "deviceReleased": true,
  "message": "Device successfully released!",
  "expiryDate": "2024-01-22T10:30:00Z"
}
```

**Response (Invalid):**
```json
{
  "isValid": false,
  "deviceReleased": false,
  "message": "Invalid or expired release code",
  "expiryDate": null
}
```

## Security Considerations

### Release Code Generation

- Codes should be cryptographically random
- 12 alphanumeric characters provide ~62^12 possible combinations
- Codes should be single-use
- Codes should expire after 7 days
- Codes should be tied to specific device ID

### Validation

- Code validation requires online connection
- Backend verifies:
  - Code format and validity
  - Code not already used
  - Code not expired
  - Code matches device ID
  - All payments completed

### Device Release

- Release process is irreversible
- All local data is cleared
- Device is unregistered from backend
- Factory reset protection is disabled
- Device admin can be deactivated

## Error Handling

### Network Errors

- Display user-friendly message
- Suggest checking internet connection
- Allow retry

### Invalid Code

- Display specific error message
- Show code format requirements
- Allow re-entry

### Release Process Errors

- Log detailed error information
- Display generic error to user
- Provide retry option
- Contact support if persistent

## Testing

### Manual Testing

1. **Valid Code Flow**
   - Enter valid release code
   - Verify device release completes
   - Verify all data is cleared
   - Verify device admin can be deactivated

2. **Invalid Code Flow**
   - Enter invalid code (wrong format)
   - Verify validation error
   - Enter expired code
   - Verify backend error message

3. **Network Error Flow**
   - Disable network
   - Attempt code validation
   - Verify error message
   - Enable network and retry

4. **Deactivation Flow**
   - Complete release process
   - Tap "Deactivate Device Admin"
   - Verify settings open
   - Deactivate admin
   - Verify no blocking message

### Integration Testing

```dart
// Test release code validation
test('Valid release code triggers device release', () async {
  final service = PaymentService();
  final response = await service.validateReleaseCode('ABC123XYZ789');
  
  expect(response.isValid, true);
  expect(response.deviceReleased, true);
});

// Test device release process
test('Device release clears all data', () async {
  final releaseService = DeviceReleaseService();
  await releaseService.releaseDevice();
  
  final db = DatabaseHelper();
  final configs = await db.getAllDeviceConfigs();
  expect(configs.isEmpty, true);
});
```

## Future Enhancements

1. **QR Code Support**
   - Allow scanning QR code instead of manual entry
   - Faster and more convenient for users

2. **Biometric Confirmation**
   - Require fingerprint/face ID before release
   - Additional security layer

3. **Release History**
   - Track release attempts
   - Send to backend for audit trail

4. **Partial Release**
   - Allow temporary unlock for specific features
   - Useful for service/repair scenarios

## Troubleshooting

### "Cannot deactivate device admin"

**Cause:** Device not properly marked as released

**Solution:**
1. Check shared preferences flag
2. Verify release process completed
3. Restart app and try again

### "Release code validation failed"

**Cause:** Network error or invalid code

**Solution:**
1. Check internet connection
2. Verify code format (12 characters)
3. Contact support for new code

### "Data not cleared after release"

**Cause:** Database or storage error

**Solution:**
1. Check app permissions
2. Verify storage not full
3. Manual data clear may be needed

## Support

For issues with release code functionality:
1. Check app logs for detailed error messages
2. Verify backend API is responding correctly
3. Contact technical support with device ID and error details
