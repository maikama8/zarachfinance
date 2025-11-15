# Critical Scenarios Testing Guide

## Overview
This document provides detailed test procedures for critical scenarios that must work reliably in the Device Lock Finance App.

## Test Environment Setup

### Prerequisites
- ADB installed and configured
- Test devices with different Android versions
- Backend API access for testing
- Test payment credentials

### Test Data Setup
```bash
# Enable test mode (if available)
adb shell setprop debug.finance.testmode true

# Set test backend URL
adb shell setprop debug.finance.backend "https://test-api.example.com"
```

## Critical Scenario 1: Device Reboot While Locked

### Objective
Verify that device lock persists after reboot and all services restart correctly.

### Test Procedure

#### Setup
1. Ensure device is registered and has payment schedule
2. Trigger device lock (simulate overdue payment)
3. Verify lock screen is displayed

#### Test Steps
```bash
# 1. Check lock state before reboot
adb shell dumpsys activity | grep -i "lock"

# 2. Reboot device
adb reboot

# 3. Wait for device to boot (check with)
adb wait-for-device

# 4. Check if app auto-starts
adb shell dumpsys activity | grep com.finance.device_admin_app

# 5. Verify BootReceiver was triggered
adb logcat -d | grep "BootReceiver"

# 6. Check lock state persisted
adb shell run-as com.finance.device_admin_app cat /data/data/com.finance.device_admin_app/databases/device_lock.db
```

#### Expected Results
- [ ] Lock screen displays immediately after boot
- [ ] BootReceiver executes successfully
- [ ] Lock state in database is preserved
- [ ] Background services restart automatically
- [ ] No crashes or errors in logcat

#### Verification Checklist
- [ ] Lock screen visible within 10 seconds of boot
- [ ] Payment status check scheduled
- [ ] Location tracking resumed
- [ ] Notification service active
- [ ] Database integrity maintained

#### Test on Android Versions
- [ ] Android 7.0 (API 24)
- [ ] Android 9.0 (API 28)
- [ ] Android 11 (API 30)
- [ ] Android 12 (API 31)
- [ ] Android 13 (API 33)
- [ ] Android 14 (API 34)

### Troubleshooting
If lock doesn't persist:
1. Check BootReceiver registration in AndroidManifest.xml
2. Verify RECEIVE_BOOT_COMPLETED permission
3. Check database encryption key availability
4. Review logcat for errors

## Critical Scenario 2: App Update While Device is Locked

### Objective
Verify that app updates don't break lock state or lose data.

### Test Procedure

#### Setup
1. Install version N of the app
2. Lock the device
3. Prepare version N+1 APK with minor changes

#### Test Steps
```bash
# 1. Verify current version and lock state
adb shell dumpsys package com.finance.device_admin_app | grep versionName
adb shell am start -n com.finance.device_admin_app/.MainActivity

# 2. Install update (without uninstalling)
adb install -r app-release-v2.apk

# 3. Verify app still locked
adb shell am start -n com.finance.device_admin_app/.MainActivity

# 4. Check database migration
adb logcat -d | grep "DatabaseHelper"

# 5. Verify all data preserved
adb shell run-as com.finance.device_admin_app sqlite3 /data/data/com.finance.device_admin_app/databases/device_lock.db "SELECT * FROM payment_schedule;"
```

#### Expected Results
- [ ] Update installs successfully
- [ ] Lock state maintained
- [ ] Database migrates without errors
- [ ] All payment data preserved
- [ ] Device admin privileges retained
- [ ] Background tasks continue

#### Verification Checklist
- [ ] Lock screen still displays
- [ ] Payment history intact
- [ ] Scheduled payments preserved
- [ ] Secure storage accessible
- [ ] No permission issues
- [ ] Background sync works

#### Edge Cases to Test
- [ ] Update with database schema changes
- [ ] Update with new permissions
- [ ] Update with ProGuard changes
- [ ] Downgrade (should be blocked)

## Critical Scenario 3: Low Battery Scenarios

### Objective
Ensure app functions correctly and doesn't drain battery excessively in low battery conditions.

### Test Procedure

#### Setup
```bash
# Simulate low battery
adb shell dumpsys battery set level 15
adb shell dumpsys battery set status 3  # discharging

# Enable battery saver
adb shell settings put global low_power 1
```

#### Test Steps
1. Monitor battery usage:
```bash
# Reset battery stats
adb shell dumpsys batterystats --reset

# Use app for 1 hour
# Check battery consumption
adb shell dumpsys batterystats com.finance.device_admin_app | grep "Estimated power use"
```

2. Test critical functions:
   - Lock/unlock device
   - Make payment
   - Check payment status
   - Receive notifications

3. Monitor background tasks:
```bash
# Check WorkManager tasks
adb shell dumpsys jobscheduler | grep com.finance.device_admin_app

# Check wakelocks
adb shell dumpsys power | grep com.finance.device_admin_app
```

#### Expected Results
- [ ] App uses < 2% battery in 24 hours (background)
- [ ] Critical functions work in battery saver mode
- [ ] Background tasks respect battery constraints
- [ ] No excessive wakelocks
- [ ] No battery drain when idle

#### Battery Optimization Tests
- [ ] Test with Doze mode enabled
- [ ] Test with App Standby enabled
- [ ] Test with battery optimization ON
- [ ] Test with battery optimization OFF

#### Monitoring Commands
```bash
# Check if app is in battery optimization whitelist
adb shell dumpsys deviceidle whitelist | grep com.finance.device_admin_app

# Monitor battery drain over time
adb shell dumpsys batterystats --charged com.finance.device_admin_app
```

## Critical Scenario 4: Airplane Mode / Offline Operation

### Objective
Verify app handles offline scenarios gracefully and syncs correctly when back online.

### Test Procedure

#### Setup
```bash
# Enable airplane mode
adb shell cmd connectivity airplane-mode enable

# Verify no connectivity
adb shell ping -c 1 8.8.8.8
```

#### Test Steps

1. **Offline Payment Attempt**
   - Navigate to payment screen
   - Enter payment details
   - Submit payment
   - Verify queued for sync

2. **Offline Lock Status Check**
   - Wait for scheduled payment check
   - Verify grace period activated
   - Check warning banner displayed

3. **Offline Location Capture**
   - Wait for location capture task
   - Verify location queued

4. **Return Online**
```bash
# Disable airplane mode
adb shell cmd connectivity airplane-mode disable

# Wait for connectivity
adb shell ping -c 1 8.8.8.8
```

5. **Verify Sync**
   - Monitor sync queue processing
   - Verify all queued items sent
   - Check for duplicate prevention

#### Expected Results
- [ ] App detects offline status
- [ ] Operations queued in sync_queue table
- [ ] User notified of offline status
- [ ] Grace period activated for payment checks
- [ ] Sync occurs automatically when online
- [ ] No duplicate transactions
- [ ] No data loss

#### Verification Queries
```bash
# Check sync queue
adb shell run-as com.finance.device_admin_app sqlite3 /data/data/com.finance.device_admin_app/databases/device_lock.db "SELECT * FROM sync_queue;"

# Monitor sync process
adb logcat -s "PaymentService:*" "LocationTracker:*" "BackgroundTasks:*"
```

#### Test Variations
- [ ] Offline for 1 hour
- [ ] Offline for 24 hours
- [ ] Offline for 48 hours (grace period expiry)
- [ ] Intermittent connectivity
- [ ] Slow/unstable connection

## Critical Scenario 5: SIM Card Removal

### Objective
Verify app continues to function when SIM card is removed.

### Test Procedure

#### Setup
1. Install and register app with SIM card inserted
2. Note device identifier used

#### Test Steps
1. Remove SIM card from device
2. Restart app
3. Verify device identifier remains consistent
4. Test all major functions:
   - Lock/unlock
   - Payment processing
   - Background sync
   - Notifications

#### Expected Results
- [ ] App launches successfully
- [ ] Device ID remains consistent
- [ ] All features functional
- [ ] No crashes or errors
- [ ] Background tasks continue

#### Device Identifier Verification
```bash
# Check device identifier
adb shell run-as com.finance.device_admin_app cat /data/data/com.finance.device_admin_app/shared_prefs/FlutterSecureStorage.xml | grep device_id

# Verify it matches original
```

#### Test Cases
- [ ] Remove SIM before app launch
- [ ] Remove SIM while app running
- [ ] Remove SIM while locked
- [ ] Replace with different SIM
- [ ] Use device without SIM from start

## Critical Scenario 6: Rapid Lock/Unlock Cycles

### Objective
Test for race conditions and state consistency during rapid lock/unlock operations.

### Test Procedure

#### Automated Test Script
```bash
#!/bin/bash
# rapid_lock_unlock_test.sh

for i in {1..10}
do
  echo "Cycle $i: Locking device..."
  adb shell am broadcast -a com.finance.device_admin_app.LOCK_DEVICE
  sleep 2
  
  echo "Cycle $i: Unlocking device..."
  adb shell am broadcast -a com.finance.device_admin_app.UNLOCK_DEVICE
  sleep 2
  
  # Check for crashes
  adb logcat -d | grep -i "crash\|exception\|error" | tail -5
done

echo "Test complete. Checking final state..."
adb shell dumpsys activity | grep com.finance.device_admin_app
```

#### Manual Test Steps
1. Lock device via app
2. Immediately unlock (within 1 second)
3. Repeat 10 times rapidly
4. Monitor for:
   - Crashes
   - UI freezes
   - Database errors
   - State inconsistencies

#### Expected Results
- [ ] No crashes or ANRs
- [ ] State remains consistent
- [ ] Database not corrupted
- [ ] UI responds correctly
- [ ] No race conditions
- [ ] Proper state transitions

#### Monitoring
```bash
# Monitor for ANRs
adb logcat -s "ActivityManager:*" | grep ANR

# Check database integrity
adb shell run-as com.finance.device_admin_app sqlite3 /data/data/com.finance.device_admin_app/databases/device_lock.db "PRAGMA integrity_check;"

# Monitor state changes
adb logcat -s "LockService:*"
```

#### Stress Test Variations
- [ ] 10 rapid cycles
- [ ] 50 rapid cycles
- [ ] 100 rapid cycles
- [ ] Concurrent lock requests
- [ ] Lock during unlock transition

## Additional Critical Scenarios

### Scenario 7: Factory Reset Attempt

#### Test Steps
```bash
# Attempt factory reset via settings
adb shell am start -a android.settings.FACTORY_RESET

# Attempt via recovery (requires manual testing)
# Boot into recovery mode and attempt wipe
```

#### Expected Results
- [ ] Factory reset blocked in settings
- [ ] Warning message displayed
- [ ] Device remains locked
- [ ] Data preserved

### Scenario 8: Time/Date Manipulation

#### Test Steps
```bash
# Disable automatic time
adb shell settings put global auto_time 0

# Set date to future
adb shell date 123123592025.00  # Dec 31, 2025

# Test payment schedule
# Set date to past
adb shell date 010100002020.00  # Jan 1, 2020
```

#### Expected Results
- [ ] App detects time manipulation
- [ ] Payment schedule not affected
- [ ] Lock logic uses server time
- [ ] No bypass possible

### Scenario 9: Storage Full

#### Test Steps
```bash
# Fill device storage
adb shell dd if=/dev/zero of=/sdcard/largefile bs=1M count=1000

# Attempt operations
```

#### Expected Results
- [ ] App handles storage errors gracefully
- [ ] Critical data preserved
- [ ] User notified of storage issue
- [ ] No crashes

### Scenario 10: Network Timeout

#### Test Steps
```bash
# Simulate slow network
adb shell settings put global network_speed 1  # slow

# Attempt payment
# Monitor timeout handling
```

#### Expected Results
- [ ] Requests timeout appropriately (30s)
- [ ] Retry logic activates
- [ ] User notified of delay
- [ ] No indefinite hangs

## Test Results Template

### Test Session Information
- Tester: _______________
- Date: _______________
- App Version: _______________
- Device: _______________
- Android Version: _______________

### Critical Scenarios Results

| Scenario | Pass | Fail | Notes |
|----------|------|------|-------|
| Device Reboot While Locked | ☐ | ☐ | |
| App Update While Locked | ☐ | ☐ | |
| Low Battery | ☐ | ☐ | |
| Airplane Mode | ☐ | ☐ | |
| SIM Card Removal | ☐ | ☐ | |
| Rapid Lock/Unlock | ☐ | ☐ | |
| Factory Reset Attempt | ☐ | ☐ | |
| Time Manipulation | ☐ | ☐ | |
| Storage Full | ☐ | ☐ | |
| Network Timeout | ☐ | ☐ | |

### Issues Discovered
1. **Issue:** _______________
   - **Severity:** Critical / High / Medium / Low
   - **Steps to Reproduce:** _______________
   - **Expected:** _______________
   - **Actual:** _______________

### Recommendations
1. _______________
2. _______________
3. _______________

### Sign-off
- [ ] All critical scenarios passed
- [ ] All issues documented
- [ ] Ready for production

Tester Signature: _______________ Date: _______________
