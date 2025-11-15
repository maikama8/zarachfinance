# Onboarding Permission Handling

This document describes the permission handling implementation in the onboarding flow.

## Overview

The onboarding flow requests all necessary permissions from the user in a structured, user-friendly manner. Each permission screen explains why the permission is needed and handles denials gracefully.

## Permission Screens

### 1. Device Admin Screen (`device_admin_screen.dart`)
- **Purpose**: Request Device Administrator privileges
- **Required**: Yes (critical for app functionality)
- **Features**:
  - Checks if admin is already active
  - Explains what admin privileges are used for
  - Shows success dialog on activation
  - Handles errors with retry option
  - Prevents proceeding without activation

### 2. Location Permission Screen (`location_permission_screen.dart`)
- **Purpose**: Request location access for device tracking
- **Required**: No (can be skipped)
- **Features**:
  - Explains why location is needed (security, inventory management)
  - Shows rationale with privacy protection info
  - Allows skipping with confirmation dialog
  - Handles permission denial with retry option
  - Uses coarse location (privacy-friendly)

### 3. Notification Permission Screen (`notification_permission_screen.dart`)
- **Purpose**: Request notification permission (Android 13+)
- **Required**: No (can be skipped)
- **Features**:
  - Only relevant for Android 13+ (API 33+)
  - Explains notification types (payment reminders, confirmations)
  - Allows skipping with warning dialog
  - Handles permanent denial with settings redirect
  - Shows success indicator when granted

### 4. Phone State Permission (Implicit)
- **Purpose**: Get IMEI for device identification
- **Required**: No (automatic fallback)
- **Implementation**: 
  - Handled automatically in native code
  - No explicit permission request screen
  - Falls back to Android ID if permission not granted
  - Android 10+ always uses Android ID (IMEI restricted)

## Permission Flow

```
Welcome Screen
     ↓
Device Admin Screen (Required)
     ↓
Location Permission Screen (Optional)
     ↓
Notification Permission Screen (Optional)
     ↓
Payment Method Screen
     ↓
Terms Screen
     ↓
Complete
```

## Implementation Details

### Android Manifest Permissions

```xml
<!-- Device admin and boot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Location tracking -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Notifications (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### Permission Handler Package

The app uses the `permission_handler` package (v11.3.0) for runtime permission requests:
- Location permission
- Notification permission (Android 13+)

### Device Admin

Device admin is handled through platform channels using Android's DevicePolicyManager API:
- Native implementation in `DeviceAdminMethodChannel.kt`
- Flutter wrapper in `device_admin_channel.dart`

### Graceful Degradation

The app handles permission denials gracefully:

1. **Location Denied**: 
   - App continues to function
   - Location tracking disabled
   - Can be enabled later in settings

2. **Notification Denied**:
   - App continues to function
   - No payment reminders
   - User must manually check payment status

3. **Device Admin Denied**:
   - Cannot proceed with onboarding
   - Required for core functionality
   - Must be granted to use app

4. **Phone State (IMEI) Denied**:
   - Automatic fallback to Android ID
   - No user impact
   - Transparent to user

## User Experience

### Permission Rationale

Each permission screen includes:
- Clear icon representing the permission
- Title explaining what's being requested
- Description of why it's needed
- List of specific use cases
- Visual indicators for granted permissions

### Error Handling

- **Denied**: Show dialog with explanation and retry option
- **Permanently Denied**: Show dialog with settings redirect
- **Skip**: Show confirmation dialog with consequences
- **Error**: Show error message with details

### Progress Indicator

The onboarding flow shows progress at the top:
- Linear progress bar
- Current step / total steps (e.g., "3/5")
- Only visible after welcome screen

## Testing

To test permission handling:

1. **Grant All**: Test normal flow with all permissions granted
2. **Deny Location**: Test app functionality without location
3. **Deny Notifications**: Test app without notification permission
4. **Permanent Denial**: Test settings redirect functionality
5. **Device Admin**: Test blocking admin deactivation

## Future Enhancements

Potential improvements:
- Add permission status check on app startup
- Implement in-app permission re-request flow
- Add permission status indicator in settings
- Implement permission usage analytics
