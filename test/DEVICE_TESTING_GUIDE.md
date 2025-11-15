# Device Testing Guide

## Overview
This guide provides comprehensive testing procedures for the Device Lock Finance App across multiple Android versions, device types, and critical scenarios.

## Test Environment Setup

### Required Test Devices

#### Android Versions (Emulators + Physical Devices)
- [ ] Android 7.0 (API 24) - Minimum supported version
- [ ] Android 9.0 (API 28) - Common in budget devices
- [ ] Android 11 (API 30) - Scoped storage changes
- [ ] Android 12 (API 31) - Material You, permission changes
- [ ] Android 13 (API 33) - Notification permission changes
- [ ] Android 14 (API 34) - Target SDK version

#### Popular Nigerian Phone Brands
- [ ] Tecno (e.g., Spark series, Camon series)
- [ ] Infinix (e.g., Hot series, Note series)
- [ ] Samsung (e.g., Galaxy A series)

#### Device Specifications
- [ ] Low-end: 2GB RAM, 16GB storage, quad-core processor
- [ ] Mid-range: 4GB RAM, 64GB storage, octa-core processor
- [ ] High-end: 6GB+ RAM, 128GB+ storage, flagship processor

### Screen Sizes to Test
- [ ] Small (4.5" - 5.0", 720x1280)
- [ ] Medium (5.5" - 6.0", 1080x1920)
- [ ] Large (6.5"+, 1080x2400)

## Test Procedures

### 1. Installation and Onboarding Tests

#### Test Case 1.1: Fresh Installation
**Steps:**
1. Install APK on test device
2. Launch app for first time
3. Complete onboarding flow
4. Grant all required permissions

**Expected Results:**
- App installs without errors
- Onboarding screens display correctly
- Device admin privileges activated successfully
- All permissions granted properly

**Performance Metrics:**
- Installation time: < 30 seconds
- First launch time: < 5 seconds
- Onboarding completion: < 3 minutes

#### Test Case 1.2: Permission Handling
**Steps:**
1. Deny each permission individually
2. Verify app handles denial gracefully
3. Re-request permissions

**Expected Results:**
- App shows rationale for each permission
- App continues to function with reduced capabilities
- Permission re-request works correctly

### 2. UI Responsiveness Tests

#### Test Case 2.1: Screen Rotation
**Steps:**
1. Navigate to each screen
2. Rotate device to landscape
3. Rotate back to portrait
4. Verify UI adapts correctly

**Expected Results:**
- No crashes or data loss
- UI elements resize appropriately
- State is preserved

#### Test Case 2.2: Different Screen Densities
**Steps:**
1. Test on devices with different DPI (ldpi, mdpi, hdpi, xhdpi, xxhdpi)
2. Verify text readability
3. Check image quality
4. Verify touch targets are adequate (min 48dp)

**Expected Results:**
- Text is readable on all densities
- Images are crisp, not pixelated
- Buttons and touch targets are easily tappable

#### Test Case 2.3: Navigation Performance
**Steps:**
1. Navigate between all screens rapidly
2. Use back button navigation
3. Use bottom navigation bar
4. Measure transition times

**Expected Results:**
- Screen transitions: < 300ms
- No lag or stuttering
- Smooth animations

### 3. Performance Monitoring

#### Test Case 3.1: App Startup Time
**Procedure:**
```bash
# Cold start (app not in memory)
adb shell am force-stop com.finance.device_admin_app
adb shell am start -W -n com.finance.device_admin_app/.MainActivity

# Measure displayed time
```

**Target Metrics:**
- Cold start: < 3 seconds
- Warm start: < 1.5 seconds
- Hot start: < 500ms

#### Test Case 3.2: Memory Usage
**Procedure:**
```bash
# Monitor memory while using app
adb shell dumpsys meminfo com.finance.device_admin_app

# Check for memory leaks
# Use Android Studio Profiler
```

**Target Metrics:**
- Idle memory: < 50MB
- Active usage: < 100MB
- No memory leaks after 30 minutes of use

#### Test Case 3.3: Battery Consumption
**Procedure:**
```bash
# Reset battery stats
adb shell dumpsys batterystats --reset

# Use app for 1 hour
# Check battery usage
adb shell dumpsys batterystats com.finance.device_admin_app
```

**Target Metrics:**
- Background battery usage: < 2% per day
- Active usage: < 5% per hour
- No wakelocks preventing sleep

#### Test Case 3.4: Network Usage
**Procedure:**
```bash
# Monitor network traffic
adb shell dumpsys netstats detail

# Check data usage for app
```

**Target Metrics:**
- Background sync: < 5MB per day
- Payment transaction: < 100KB
- Location update: < 10KB

### 4. Database Performance Tests

#### Test Case 4.1: Query Performance
**Steps:**
1. Populate database with 1000 payment records
2. Measure query times for common operations
3. Test concurrent read/write operations

**Target Metrics:**
- Payment history query: < 100ms
- Payment schedule query: < 50ms
- Insert payment: < 20ms

#### Test Case 4.2: Database Size
**Steps:**
1. Check database file size after 6 months of simulated data
2. Verify encryption overhead

**Target Metrics:**
- Database size: < 10MB for 6 months of data
- Encryption overhead: < 20%

### 5. Background Task Tests

#### Test Case 5.1: WorkManager Reliability
**Steps:**
1. Schedule payment status check
2. Wait for execution (or use test mode)
3. Verify task executed successfully
4. Check logs for errors

**Expected Results:**
- Tasks execute within 15 minutes of scheduled time
- Tasks retry on failure (max 3 times)
- Tasks respect battery optimization settings

#### Test Case 5.2: Background Restrictions
**Steps:**
1. Enable battery saver mode
2. Enable data saver mode
3. Verify background tasks still execute
4. Check task execution frequency

**Expected Results:**
- Critical tasks execute even with restrictions
- Non-critical tasks deferred appropriately
- No excessive battery drain

## Critical Scenario Tests

### Scenario 1: Device Reboot While Locked

**Steps:**
1. Lock device using app
2. Reboot device
3. Verify lock persists after reboot
4. Check BootReceiver logs

**Expected Results:**
- Device remains locked after reboot
- Lock screen displays immediately
- Background services restart automatically
- No data loss

**Test on:**
- [ ] Android 7.0
- [ ] Android 9.0
- [ ] Android 11
- [ ] Android 12
- [ ] Android 13
- [ ] Android 14

### Scenario 2: App Update While Locked

**Steps:**
1. Lock device
2. Install app update via ADB or Play Store
3. Verify lock state maintained
4. Check all functionality works

**Expected Results:**
- Lock state persists through update
- Database migrates successfully
- No permission issues
- All features work correctly

### Scenario 3: Low Battery Scenarios

**Steps:**
1. Set battery level to 15%
2. Enable battery saver
3. Monitor background task execution
4. Verify critical functions work

**Expected Results:**
- Payment status checks continue
- Lock/unlock functions work
- Notifications still delivered
- No excessive battery drain

### Scenario 4: Airplane Mode / Offline Operation

**Steps:**
1. Enable airplane mode
2. Attempt payment
3. Verify offline queue
4. Disable airplane mode
5. Verify sync occurs

**Expected Results:**
- Operations queued when offline
- User notified of offline status
- Sync occurs automatically when online
- No duplicate transactions

### Scenario 5: SIM Card Removal

**Steps:**
1. Remove SIM card
2. Verify app continues to function
3. Check device identifier still valid
4. Test payment and lock functions

**Expected Results:**
- App works without SIM
- Device ID remains consistent
- All features functional
- No crashes

### Scenario 6: Rapid Lock/Unlock Cycles

**Steps:**
1. Lock device
2. Immediately unlock
3. Repeat 10 times rapidly
4. Monitor for race conditions

**Expected Results:**
- No crashes or freezes
- State remains consistent
- No database corruption
- UI responds correctly

## Performance Profiling

### Using Flutter DevTools

**Steps:**
1. Run app in profile mode:
   ```bash
   flutter run --profile
   ```

2. Open DevTools:
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

3. Profile areas:
   - CPU usage during payment processing
   - Memory allocation patterns
   - Frame rendering times
   - Network request timings

### Using Android Studio Profiler

**Steps:**
1. Open Android Studio
2. Run app on device
3. Open Profiler tab
4. Monitor:
   - CPU usage
   - Memory allocation
   - Network activity
   - Energy consumption

## Test Results Template

### Device Information
- Device Model: _______________
- Android Version: _______________
- RAM: _______________
- Screen Size: _______________
- Test Date: _______________

### Performance Metrics
| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Cold Start Time | < 3s | | |
| Memory Usage (Idle) | < 50MB | | |
| Memory Usage (Active) | < 100MB | | |
| Battery Usage (24h) | < 2% | | |
| Payment Query Time | < 100ms | | |

### Test Cases
| Test Case | Pass/Fail | Notes |
|-----------|-----------|-------|
| Installation | | |
| Onboarding | | |
| Device Admin Activation | | |
| Lock/Unlock | | |
| Payment Processing | | |
| Notifications | | |
| Background Sync | | |
| Reboot Persistence | | |
| Offline Operation | | |

### Issues Found
1. _______________
2. _______________
3. _______________

### Recommendations
1. _______________
2. _______________
3. _______________
