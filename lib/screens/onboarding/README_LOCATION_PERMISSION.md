# Location Permission Screen

## Overview

The `LocationPermissionScreen` is designed to be integrated into the app's onboarding flow to request location permissions from users. It provides a clear rationale for why location access is needed and handles permission denial gracefully.

## Features

- Clear explanation of why location permission is needed
- Visual presentation with icons and descriptions
- Handles permission grant, denial, and skip scenarios
- Graceful error handling
- User-friendly dialogs for denied and skipped permissions

## Integration

### In Onboarding Flow

When implementing the full onboarding flow (Task 10), integrate this screen as follows:

```dart
import 'package:device_admin_app/screens/onboarding/location_permission_screen.dart';

// In your onboarding PageView or navigation flow:
LocationPermissionScreen(
  onPermissionGranted: () {
    // Move to next onboarding step
    // e.g., pageController.nextPage() or Navigator.push(...)
  },
  onPermissionDenied: () {
    // Continue to next step without location permission
    // The app will still function, just without location tracking
    // e.g., pageController.nextPage() or Navigator.push(...)
  },
)
```

### Standalone Usage

You can also use this screen standalone if needed:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LocationPermissionScreen(
      onPermissionGranted: () {
        Navigator.pop(context);
        // Handle permission granted
      },
      onPermissionDenied: () {
        Navigator.pop(context);
        // Handle permission denied/skipped
      },
    ),
  ),
);
```

## Permission Handling

The screen uses the `LocationTracker` service to:
- Check current permission status
- Request location permission
- Handle permission results

### Permission States

1. **Granted**: User allows location access
   - Shows success message
   - Calls `onPermissionGranted` callback
   - Location tracking will work in background

2. **Denied**: User denies location access
   - Shows dialog explaining the denial
   - Offers option to try again or continue without
   - Calls `onPermissionDenied` callback if user chooses to continue

3. **Skipped**: User chooses to skip permission request
   - Shows dialog confirming the skip
   - Explains that permission can be granted later
   - Calls `onPermissionDenied` callback

## Privacy Considerations

The screen clearly communicates:
- Only coarse location data is collected
- Location is captured every 12 hours
- Purpose is device security and inventory management
- Users can skip if they prefer

## Background Location Tracking

After permission is granted:
- Location tracking runs automatically in the background
- Managed by `BackgroundTasksService.registerLocationCapture()`
- Captures location every 12 hours
- Queues location data when offline for later sync

## Testing

To test the location permission screen:

1. Run the app on a physical device or emulator
2. Navigate to the location permission screen
3. Test all scenarios:
   - Grant permission
   - Deny permission
   - Skip permission
   - Try again after denial

## Notes

- Location permission is optional for the app to function
- If denied, the app continues to work but without location tracking
- Users can enable location permission later in device settings
- The screen is designed to be part of a larger onboarding flow
