# Location Tracker Service

## Overview

The Location Tracker service provides device location tracking functionality for the Device Admin App. It captures device location periodically and transmits it to the backend for inventory management and device recovery purposes.

## Features

- **Coarse Location Tracking**: Uses `LocationAccuracy.low` for privacy-friendly location capture
- **Periodic Background Capture**: Automatically captures location every 12 hours
- **Offline Queue**: Queues location data when network is unavailable
- **Automatic Sync**: Syncs queued locations when connectivity is restored
- **Permission Management**: Handles location permission requests gracefully
- **Retry Logic**: Implements retry mechanism with maximum retry limit

## Architecture

### LocationTracker Class

Main service class that handles all location-related operations.

#### Key Methods

##### Permission Management

```dart
Future<bool> hasLocationPermission()
```
Checks if location permission is currently granted.

```dart
Future<bool> requestLocationPermission()
```
Requests location permission from the user.

```dart
Future<bool> isLocationServiceEnabled()
```
Checks if location services are enabled on the device.

##### Location Capture

```dart
Future<Position?> captureLocation()
```
Captures the current device location using coarse accuracy (LocationAccuracy.low).
- Returns `null` if location services are disabled or permission is not granted
- Uses 30-second timeout to prevent hanging
- Privacy-friendly with low accuracy

```dart
Future<bool> captureAndSendLocation()
```
Convenience method that captures location and sends it to backend in one operation.

##### Location Transmission

```dart
Future<bool> sendLocationToBackend(Position position)
```
Sends location data to the backend via `DeviceApiService`.
- Automatically queues location if network error occurs
- Returns `true` on success, `false` on failure

##### Offline Queue Management

```dart
Future<void> syncQueuedLocations()
```
Syncs all queued location data to the backend.
- Processes all location items in the sync queue
- Removes successfully synced items
- Implements retry logic with maximum 5 retries
- Removes items after max retries to prevent queue buildup

## Background Task Integration

Location capture is integrated with the Workmanager background task system.

### Registration

```dart
// In your app initialization (e.g., main.dart)
await BackgroundTasksService.initialize();
await BackgroundTasksService.registerLocationCapture();
```

### Task Configuration

- **Frequency**: Every 12 hours
- **Constraints**: Requires network connectivity
- **Backoff Policy**: Exponential with 30-minute delay
- **Task Name**: `location_capture_task`

### Manual Trigger

For testing or immediate location capture:

```dart
await BackgroundTasksService.runLocationCaptureNow();
```

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                  Background Task                         │
│              (Every 12 hours)                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│            LocationTracker.captureLocation()             │
│         (Uses Geolocator with low accuracy)              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│       LocationTracker.sendLocationToBackend()            │
│         (Calls DeviceApiService.sendLocation)            │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────────┐
│   Success       │    │   Network Error      │
│   (Complete)    │    │   (Queue for sync)   │
└─────────────────┘    └──────────┬───────────┘
                                  │
                                  ▼
                    ┌──────────────────────────┐
                    │   Sync Queue Database    │
                    │   (SyncType.location)    │
                    └──────────┬───────────────┘
                               │
                               ▼
                    ┌──────────────────────────┐
                    │  syncQueuedLocations()   │
                    │  (When online)           │
                    └──────────────────────────┘
```

## Database Schema

Location data is queued in the `sync_queue` table:

```sql
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,              -- 'location'
  payload TEXT NOT NULL,            -- JSON with lat, lng, accuracy, timestamp
  timestamp INTEGER NOT NULL,       -- When queued
  retryCount INTEGER NOT NULL       -- Number of retry attempts
)
```

### Payload Format

```json
{
  "latitude": 6.5244,
  "longitude": 3.3792,
  "accuracy": 100.0,
  "timestamp": "2025-11-13T10:30:00.000Z"
}
```

## API Integration

### Endpoint

```
POST /api/v1/device/{deviceId}/location
```

### Request Body

```json
{
  "latitude": 6.5244,
  "longitude": 3.3792,
  "accuracy": 100.0,
  "timestamp": "2025-11-13T10:30:00.000Z"
}
```

### Response

```json
{
  "success": true,
  "message": "Location received",
  "receivedAt": "2025-11-13T10:30:01.000Z"
}
```

## Privacy Considerations

### Coarse Location Only

The service uses `LocationAccuracy.low` which provides:
- Approximate location (typically 100-500 meters accuracy)
- Lower battery consumption
- Better privacy protection
- Sufficient for inventory management purposes

### Frequency

- Location is captured only every 12 hours
- Not continuous tracking
- Minimal battery impact

### Transparency

- Users are informed during onboarding
- Clear rationale provided (device security, inventory management)
- Permission can be denied without breaking app functionality

## Error Handling

### Permission Denied

If location permission is denied:
- `captureLocation()` returns `null`
- No error is thrown
- App continues to function normally
- Location tracking is simply disabled

### Location Services Disabled

If location services are disabled on the device:
- `captureLocation()` returns `null`
- No error is thrown
- Background task completes successfully

### Network Errors

If network is unavailable when sending location:
- Location is queued in local database
- Will be synced when connectivity is restored
- Implements retry logic with exponential backoff

### Timeout

If location capture takes too long:
- 30-second timeout is enforced
- Returns `null` after timeout
- Prevents hanging background tasks

## Testing

### Manual Testing

```dart
// Test location capture
final locationTracker = LocationTracker();
final position = await locationTracker.captureLocation();
print('Location: ${position?.latitude}, ${position?.longitude}');

// Test sending to backend
if (position != null) {
  final success = await locationTracker.sendLocationToBackend(position);
  print('Send success: $success');
}

// Test sync queued locations
await locationTracker.syncQueuedLocations();
```

### Background Task Testing

```dart
// Trigger immediate location capture
await BackgroundTasksService.runLocationCaptureNow();

// Check workmanager logs
// Look for "Background task: location_capture" in console
```

### Permission Testing

Test all permission scenarios:
1. Permission granted on first request
2. Permission denied on first request
3. Permission permanently denied
4. Location services disabled

## Configuration

### Android Permissions

Required permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Dependencies

Required packages in `pubspec.yaml`:

```yaml
dependencies:
  geolocator: ^11.0.0
  permission_handler: ^11.3.0
  workmanager: ^0.5.2
```

## Usage Example

### Basic Usage

```dart
import 'package:device_admin_app/services/location_tracker.dart';

final locationTracker = LocationTracker();

// Check permission
final hasPermission = await locationTracker.hasLocationPermission();
if (!hasPermission) {
  final granted = await locationTracker.requestLocationPermission();
  if (!granted) {
    print('Location permission denied');
    return;
  }
}

// Capture and send location
final success = await locationTracker.captureAndSendLocation();
print('Location sent: $success');
```

### With Background Tasks

```dart
// In main.dart or app initialization
await BackgroundTasksService.initialize();
await BackgroundTasksService.registerLocationCapture();

// Location will now be captured automatically every 12 hours
```

### Sync Queued Locations

```dart
// Call when connectivity is restored
final locationTracker = LocationTracker();
await locationTracker.syncQueuedLocations();
```

## Troubleshooting

### Location Not Captured

1. Check if location permission is granted
2. Check if location services are enabled
3. Check device GPS signal
4. Check for timeout (30 seconds)

### Location Not Sent to Backend

1. Check network connectivity
2. Check if device is registered (has deviceId)
3. Check backend API availability
4. Check sync queue for queued locations

### Background Task Not Running

1. Check if task is registered
2. Check battery optimization settings
3. Check workmanager logs
4. Verify network constraint is met

## Performance

### Battery Impact

- Minimal impact due to:
  - Coarse location accuracy
  - 12-hour interval
  - Quick capture with timeout

### Network Usage

- Very low bandwidth usage
- Small JSON payload (~100 bytes)
- Only when network is available

### Storage

- Queued locations stored in local database
- Automatic cleanup after successful sync
- Maximum 5 retries before removal

## Security

### Data Transmission

- All location data sent over HTTPS
- Certificate pinning enabled
- JWT authentication required

### Local Storage

- Location data in encrypted database (sqflite_sqlcipher)
- Secure storage for device ID
- Automatic cleanup on device release

## Future Enhancements

Potential improvements for future versions:

1. **Geofencing**: Alert when device leaves designated area
2. **Movement Detection**: Only capture location when device moves
3. **Adaptive Frequency**: Adjust capture frequency based on payment status
4. **Location History**: Store location history locally for user viewing
5. **Manual Location Sharing**: Allow user to manually share location
