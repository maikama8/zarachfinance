# Location Tracker Implementation Summary

## Task 8: Implement Location Tracker for device tracking

**Status**: ✅ COMPLETED

All subtasks have been successfully implemented.

---

## Subtask 8.1: Create LocationTracker class ✅

### Files Created
- `lib/services/location_tracker.dart`

### Implementation Details

Created a comprehensive `LocationTracker` class with the following features:

#### Permission Management
- `hasLocationPermission()` - Check if permission is granted
- `requestLocationPermission()` - Request permission from user
- `isLocationServiceEnabled()` - Check if location services are enabled

#### Location Capture
- `captureLocation()` - Capture device location using `LocationAccuracy.low` (coarse)
- Uses 30-second timeout to prevent hanging
- Returns `null` gracefully if permission denied or services disabled

#### Location Transmission
- `sendLocationToBackend()` - Send location to backend via `DeviceApiService`
- Automatically queues location on network errors
- `captureAndSendLocation()` - Convenience method combining capture and send

#### Offline Queue Management
- `_queueLocationForSync()` - Queue location when offline
- `syncQueuedLocations()` - Sync all queued locations when online
- `_updateRetryCount()` - Retry logic with max 5 attempts

### Background Task Integration

Updated `lib/services/background_tasks.dart`:
- Added `BackgroundTaskNames.locationCapture` constant
- Implemented `_handleLocationCapture()` callback function
- Added `registerLocationCapture()` - Register 12-hour periodic task
- Added `cancelLocationCapture()` - Cancel location task
- Added `runLocationCaptureNow()` - Manual trigger for testing

### Android Permissions

Updated `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

---

## Subtask 8.2: Implement location transmission and offline queuing ✅

### Implementation Details

All functionality implemented in `LocationTracker` class:

1. **DeviceApiService Integration**
   - Calls `DeviceApiService.sendLocation()` with device ID and location data
   - Retrieves device ID from `SecureStorageService`

2. **Network Error Handling**
   - Catches `NetworkException` from API calls
   - Automatically queues failed transmissions

3. **Sync Queue Integration**
   - Stores location data in `sync_queue` table with `SyncType.location`
   - JSON payload format:
     ```json
     {
       "latitude": 6.5244,
       "longitude": 3.3792,
       "accuracy": 100.0,
       "timestamp": "2025-11-13T10:30:00.000Z"
     }
     ```

4. **Retry Logic**
   - Maximum 5 retry attempts per location
   - Increments retry count on each failure
   - Removes from queue after max retries
   - Prevents queue buildup

---

## Subtask 8.3: Handle location permissions in onboarding ✅

### Files Created
- `lib/screens/onboarding/location_permission_screen.dart`
- `lib/screens/onboarding/README_LOCATION_PERMISSION.md`

### Implementation Details

Created a comprehensive location permission screen with:

#### UI Features
- Clear visual presentation with icons
- Explanation of why location is needed
- Three reasons displayed:
  1. Device Security - helps locate device if lost/stolen
  2. Inventory Management - track financed devices
  3. Privacy Protected - only coarse location every 12 hours

#### User Actions
- **Allow Location Access** - Requests permission
- **Skip for Now** - Continue without permission

#### Permission Handling
- Success: Shows confirmation, calls `onPermissionGranted` callback
- Denied: Shows dialog with option to retry or continue
- Skipped: Shows confirmation dialog, calls `onPermissionDenied` callback

#### Integration Ready
- Designed to be part of larger onboarding flow
- Callbacks allow flexible navigation
- Can be used standalone or in PageView

---

## Documentation Created

### Service Documentation
- `lib/services/README_LOCATION.md` - Comprehensive location tracker documentation
  - Architecture overview
  - API integration details
  - Data flow diagrams
  - Privacy considerations
  - Error handling strategies
  - Testing guidelines
  - Usage examples

### Onboarding Documentation
- `lib/screens/onboarding/README_LOCATION_PERMISSION.md`
  - Integration instructions
  - Permission handling details
  - Testing scenarios
  - Privacy considerations

---

## Key Features

### Privacy-Friendly
- Uses coarse location (LocationAccuracy.low)
- 12-hour capture interval
- Minimal battery impact
- Clear user communication

### Robust Error Handling
- Graceful permission denial
- Network error recovery
- Offline queue with retry logic
- Timeout protection

### Background Operation
- Workmanager integration
- Automatic periodic capture
- Network constraint enforcement
- Exponential backoff on failure

### Data Persistence
- Encrypted local database storage
- Automatic sync when online
- Retry logic with max attempts
- Queue cleanup after success

---

## Testing Recommendations

### Manual Testing
```dart
// Test location capture
final locationTracker = LocationTracker();
final position = await locationTracker.captureLocation();

// Test sending to backend
if (position != null) {
  await locationTracker.sendLocationToBackend(position);
}

// Test sync
await locationTracker.syncQueuedLocations();
```

### Background Task Testing
```dart
// Trigger immediate capture
await BackgroundTasksService.runLocationCaptureNow();
```

### Permission Testing
- Test permission grant
- Test permission denial
- Test permanent denial
- Test location services disabled

---

## Integration Points

### With Background Tasks
```dart
// In app initialization
await BackgroundTasksService.initialize();
await BackgroundTasksService.registerLocationCapture();
```

### With Onboarding Flow
```dart
// In onboarding PageView
LocationPermissionScreen(
  onPermissionGranted: () => moveToNextStep(),
  onPermissionDenied: () => continueWithoutLocation(),
)
```

### With Connectivity Monitoring
```dart
// When connectivity restored
final locationTracker = LocationTracker();
await locationTracker.syncQueuedLocations();
```

---

## Requirements Satisfied

✅ **Requirement 4.1**: Device location tracking
- Captures location every 12 hours
- Transmits to Finance System
- Uses coarse location for privacy

✅ **Requirement 4.4**: Offline operation handling
- Queues location updates when offline
- Syncs when connectivity resumes
- Implements retry logic

---

## Next Steps

When implementing Task 10 (Device registration and onboarding):
1. Integrate `LocationPermissionScreen` into onboarding flow
2. Call `BackgroundTasksService.registerLocationCapture()` after registration
3. Handle permission denial gracefully (app continues to work)

---

## Notes

- Location tracking is optional - app works without it
- Permission can be granted later in device settings
- Background task requires network connectivity constraint
- Location data is encrypted in local database
- All transmissions use HTTPS with certificate pinning
