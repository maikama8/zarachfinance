# Lock Service Implementation

This document describes the Lock Service implementation for the Device Admin Finance app.

## Overview

The Lock Service manages device lock state based on payment compliance. It implements a 24-hour grace period before locking the device after a missed payment and provides mechanisms to prevent bypass attempts.

## Components

### Flutter Components

#### 1. LockService (`lib/services/lock_service.dart`)
- **Purpose**: Core service for managing device lock state
- **Key Features**:
  - Lock/unlock device based on payment status
  - Monitor payment status with 24-hour grace period
  - Periodic monitoring (every hour)
  - Integration with native device admin
  - Launcher mode management
  - Lock state persistence

#### 2. LockScreen (`lib/screens/lock_screen.dart`)
- **Purpose**: Full-screen UI displayed when device is locked
- **Features**:
  - Payment reminder message
  - Display overdue and remaining balance
  - Store contact information
  - "Pay Now" button to navigate to payment screen
  - "Emergency Call" button for emergency access
  - Disabled back button (WillPopScope)
  - Hidden system UI (status bar, navigation bar)

#### 3. Platform Channels
- **EmergencyCallChannel** (`lib/platform_channels/emergency_call_channel.dart`)
  - Launch emergency dialer during lock
  - Support for specific emergency numbers
  
- **LockStateChannel** (`lib/platform_channels/lock_state_channel.dart`)
  - Sync lock state with native SharedPreferences
  - Enables BootReceiver to check lock state
  
- **LauncherModeChannel** (`lib/platform_channels/launcher_mode_channel.dart`)
  - Enable/disable launcher mode
  - Prevents home button bypass

### Native Android Components

#### 1. EmergencyCallMethodChannel (`EmergencyCallMethodChannel.kt`)
- Handles emergency dialer launch requests
- Uses ACTION_DIAL intent for emergency numbers

#### 2. LockStateMethodChannel (`LockStateMethodChannel.kt`)
- Syncs lock state to SharedPreferences
- Provides lock state to BootReceiver

#### 3. LauncherModeMethodChannel (`LauncherModeMethodChannel.kt`)
- Enables/disables LauncherActivity component
- Manages HOME intent filter

#### 4. LauncherActivity (`LauncherActivity.kt`)
- Intercepts HOME button presses when enabled
- Redirects to MainActivity (lock screen)

#### 5. BootReceiver (`BootReceiver.kt`)
- Listens for BOOT_COMPLETED broadcast
- Checks lock state on device boot
- Starts app on lock screen if device is locked

## Lock Flow

### Locking Device
1. Check for overdue payments
2. If overdue payment detected:
   - Store missed payment timestamp
   - Wait 24 hours (grace period)
3. After grace period expires:
   - Set lock state in database
   - Sync lock state to native SharedPreferences
   - Enable launcher mode
   - Call native device lock
   - Navigate to lock screen

### Unlocking Device
1. Payment confirmed
2. Clear lock state in database
3. Sync lock state to native SharedPreferences
4. Disable launcher mode
5. Call native device unlock
6. Navigate to home screen

## Security Features

### 1. Grace Period
- 24-hour delay before locking after missed payment
- Prevents immediate lockout due to temporary issues
- Configurable via `LockService.lockDelay`

### 2. Bypass Prevention
- **Launcher Mode**: Intercepts HOME button when locked
- **Back Button Disabled**: WillPopScope prevents back navigation
- **System UI Hidden**: Status bar and navigation bar hidden
- **Boot Persistence**: Device remains locked after reboot

### 3. Emergency Access
- Emergency call functionality always available
- Launches dialer without unlocking device
- Supports standard emergency numbers (112, 911)

## App Lifecycle Integration

### Startup
1. Check lock state from database
2. If locked, navigate to lock screen
3. Start lock monitoring service

### Boot
1. BootReceiver checks lock state from SharedPreferences
2. If locked, start app on lock screen
3. Lock monitoring resumes automatically

## Configuration

### Lock Delay
```dart
static const Duration lockDelay = Duration(hours: 24);
```

### Monitoring Interval
```dart
Timer.periodic(const Duration(hours: 1), (_) => monitorPaymentStatus());
```

## Usage

### Initialize Lock Service
```dart
final lockService = LockService();
lockService.startMonitoring();
```

### Lock Device
```dart
await lockService.lockDevice();
```

### Unlock Device
```dart
await lockService.unlockDevice();
```

### Check Lock State
```dart
final isLocked = await lockService.isDeviceLocked();
```

### Get Time Until Lock
```dart
final timeRemaining = await lockService.getTimeUntilLock();
```

## Requirements Satisfied

- **Requirement 1.1**: Device locks within 24 hours of missed payment
- **Requirement 1.2**: Lock screen displays payment reminder and store contact
- **Requirement 1.3**: Device unlocks within 5 minutes of payment confirmation
- **Requirement 1.5**: Emergency calls function during lock
- **Requirement 2.3**: Prevents bypass through launcher mode
- **Requirement 3.5**: Lock state persists after device reboot

## Testing Considerations

1. Test 24-hour grace period logic
2. Test lock persistence after reboot
3. Test emergency call functionality
4. Test launcher mode bypass prevention
5. Test lock/unlock cycle
6. Test with multiple overdue payments
7. Test app lifecycle scenarios
