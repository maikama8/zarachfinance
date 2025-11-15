# Troubleshooting Guide

## Overview

This guide provides solutions to common issues encountered with the Device Admin App. It is intended for store staff, technical support, and administrators.

## Quick Diagnostic Checklist

Before troubleshooting specific issues, verify these basics:

- [ ] Device has internet connection (Wi-Fi or mobile data)
- [ ] App is up to date (check version in Settings)
- [ ] Device admin privileges are active
- [ ] Device time/date is correct
- [ ] Sufficient storage space available (minimum 100MB free)
- [ ] Battery level above 10%

## Installation Issues

### Issue: Device Admin Activation Fails

**Symptoms:**
- "Activate Device Admin" button does nothing
- System dialog doesn't appear
- Activation fails with error message

**Possible Causes:**
1. Another device admin app is already active
2. Device has MDM (Mobile Device Management) restrictions
3. App signature is invalid
4. Android version incompatibility

**Solutions:**

**Step 1: Check for existing device admin apps**
```
Settings → Security → Device admin apps
```
- If another admin app is active, deactivate it first
- Common conflicting apps: MDM solutions, parental controls

**Step 2: Verify Android version**
- Minimum required: Android 7.0 (API 24)
- Check: Settings → About phone → Android version
- If below 7.0, device is not compatible

**Step 3: Clear app data and retry**
```
Settings → Apps → Finance Device Admin → Storage → Clear Data
```
- Reopen app and try activation again

**Step 4: Reinstall the app**
- Uninstall app (if possible)
- Reinstall from APK
- Try activation again

**Step 5: Check for device restrictions**
- Some manufacturers restrict device admin on certain models
- Check manufacturer documentation
- May require developer options to be enabled

**If still failing:**
- Contact technical support with:
  - Device model and Android version
  - Screenshot of error message
  - Logcat output (if available)

### Issue: App Installation Blocked

**Symptoms:**
- "App not installed" error
- "Package appears to be corrupt"
- Installation fails silently

**Solutions:**

**Step 1: Enable unknown sources**
```
Settings → Security → Unknown sources (enable)
OR
Settings → Apps → Special access → Install unknown apps → [File Manager] → Allow
```

**Step 2: Verify APK integrity**
- Check APK file size matches expected size
- Re-download APK if corrupted
- Verify APK signature using: `jarsigner -verify -verbose -certs app.apk`

**Step 3: Check storage space**
- Minimum 200MB free space required
- Clear cache: Settings → Storage → Cached data → Clear

**Step 4: Check for conflicting apps**
- Uninstall any previous versions
- Check for apps with same package name

**Step 5: Try different installation method**
- Use ADB: `adb install app.apk`
- Transfer to device and install from file manager
- Install via USB debugging

### Issue: Permissions Not Granted

**Symptoms:**
- Location permission denied
- Notification permission denied
- Phone state permission denied

**Solutions:**

**Step 1: Manual permission grant**
```
Settings → Apps → Finance Device Admin → Permissions
```
- Enable all required permissions:
  - Location: "Allow all the time"
  - Notifications: Enabled
  - Phone: Enabled

**Step 2: Check permission restrictions**
- Some devices have permission managers that block apps
- Check: Settings → Privacy → Permission manager
- Ensure app is not restricted

**Step 3: Disable battery optimization**
```
Settings → Battery → Battery optimization → Finance Device Admin → Don't optimize
```

**Step 4: Check Do Not Disturb settings**
- Ensure app is allowed to override DND
- Settings → Sound → Do Not Disturb → Apps

## Registration Issues

### Issue: Device Registration Fails

**Symptoms:**
- "Registration failed" error
- Timeout during registration
- "Device already registered" error

**Solutions:**

**Step 1: Verify internet connection**
- Test connection: Open browser and load a website
- Try switching between Wi-Fi and mobile data
- Check if backend server is accessible

**Step 2: Verify customer information**
- Ensure customer ID exists in backend system
- Check customer ID format is correct
- Verify customer account is active

**Step 3: Check device time/date**
```
Settings → System → Date & time
```
- Enable "Automatic date & time"
- Enable "Automatic time zone"
- Incorrect time causes SSL certificate errors

**Step 4: Clear app data and re-register**
```
Settings → Apps → Finance Device Admin → Storage → Clear Data
```
- Reopen app and start registration again

**Step 5: Check backend logs**
- Contact backend administrator
- Provide device IMEI and customer ID
- Check for server-side errors

**If "Device already registered":**
- Device may have been registered previously
- Contact backend admin to reset device registration
- Provide device IMEI for verification

### Issue: Payment Schedule Not Loading

**Symptoms:**
- Payment schedule shows empty
- "Failed to load schedule" error
- Schedule shows incorrect data

**Solutions:**

**Step 1: Force sync**
```
App → Settings → Force Sync
```
- Wait 30 seconds for sync to complete
- Check if schedule appears

**Step 2: Verify backend data**
- Contact backend administrator
- Verify payment schedule exists for customer
- Check schedule data is correctly formatted

**Step 3: Check database**
- App may have corrupted local database
- Clear app data: Settings → Apps → Finance Device Admin → Storage → Clear Data
- Re-register device

**Step 4: Check API response**
- Use API testing tool (Postman) to verify endpoint
- Endpoint: `GET /device/{deviceId}/schedule`
- Verify response contains schedule data

## Payment Issues

### Issue: Payment Not Processing

**Symptoms:**
- "Payment failed" error
- Payment stuck on "Processing"
- Payment doesn't complete

**Solutions:**

**Step 1: Verify payment method**
- Ensure payment method is valid
- Check account has sufficient funds
- Verify payment gateway is operational

**Step 2: Check internet connection**
- Payment requires stable connection
- Try switching networks
- Wait for better signal if on mobile data

**Step 3: Retry payment**
- Wait 5 minutes before retrying
- Use different payment method if available
- Check if payment was actually processed (check bank statement)

**Step 4: Check for duplicate transactions**
- Payment may have succeeded but confirmation failed
- Check payment history in app
- Contact backend to verify transaction status

**Step 5: Manual payment verification**
- If payment was made outside app
- Contact store with transaction reference
- Store can manually verify and update status

### Issue: Payment Shows as Unpaid After Payment

**Symptoms:**
- Made payment but app still shows unpaid
- Device locked despite payment
- Balance not updated

**Solutions:**

**Step 1: Wait for sync**
- Payment verification can take up to 5 minutes
- Ensure device has internet connection
- Wait and check again

**Step 2: Force sync**
```
App → Settings → Force Sync
```
- Wait 30 seconds
- Check payment status again

**Step 3: Verify payment was successful**
- Check bank statement or mobile money account
- Verify transaction was completed
- Get transaction reference number

**Step 4: Contact store**
- Provide transaction reference
- Provide payment date and time
- Provide amount paid
- Store can manually verify and unlock device

**Step 5: Check backend logs**
- Backend admin should check payment logs
- Verify payment was received
- Check if sync failed
- Manually trigger device unlock if payment confirmed

### Issue: Cannot Make Payment (App Error)

**Symptoms:**
- Payment button doesn't work
- App crashes when trying to pay
- "Payment service unavailable" error

**Solutions:**

**Step 1: Restart app**
- Force close app
- Clear from recent apps
- Reopen and try again

**Step 2: Check app version**
- Ensure app is up to date
- Update if newer version available

**Step 3: Clear app cache**
```
Settings → Apps → Finance Device Admin → Storage → Clear Cache
```
- Don't clear data (will lose payment history)
- Reopen app and try again

**Step 4: Check payment gateway status**
- Payment gateway may be down
- Try again later
- Use alternative payment method

**Step 5: Make payment outside app**
- Use bank transfer directly
- Contact store with transaction reference
- Store will manually update payment status

## Lock/Unlock Issues

### Issue: Device Won't Lock When Required

**Symptoms:**
- Payment overdue but device not locked
- Manual lock command doesn't work
- Lock screen doesn't appear

**Solutions:**

**Step 1: Verify lock command was sent**
- Check backend logs
- Verify device received lock command
- Check device status in backend dashboard

**Step 2: Check device admin status**
```
Settings → Security → Device admin apps → Finance Device Admin
```
- Ensure device admin is still active
- If deactivated, reactivate it

**Step 3: Force sync**
```
App → Settings → Force Sync
```
- This will check payment status
- Lock should trigger if payment overdue

**Step 4: Restart device**
- Power off device completely
- Wait 10 seconds
- Power on
- App should check status on boot

**Step 5: Manual lock trigger**
- Backend admin can send remote lock command
- Command should execute within 5 minutes
- Check device has internet connection

**If still not locking:**
- App may be force-stopped by user
- Check: Settings → Apps → Finance Device Admin → Force stop (should be grayed out)
- Reinstall app if necessary

### Issue: Device Won't Unlock After Payment

**Symptoms:**
- Made payment but device still locked
- "Unlock failed" error
- Lock screen persists

**Solutions:**

**Step 1: Verify payment was processed**
- Check payment history in app (if accessible)
- Verify transaction in bank statement
- Get transaction reference

**Step 2: Wait for automatic unlock**
- Unlock can take up to 5 minutes after payment
- Ensure device has internet connection
- Wait and check again

**Step 3: Tap "I Already Paid"**
- On lock screen, tap "I Already Paid" button
- App will force check payment status
- Should unlock if payment confirmed

**Step 4: Force sync from lock screen**
- If available, tap "Sync Now" on lock screen
- Wait 30 seconds
- Should unlock if payment verified

**Step 5: Contact store for remote unlock**
- Call store using "Contact Store" button
- Provide customer ID and transaction reference
- Store can send remote unlock command
- Unlock should happen within 5 minutes

**Step 6: Backend manual unlock**
- Backend admin can manually unlock device
- Verify payment in backend system
- Send unlock command
- Monitor device status for confirmation

### Issue: Device Locked Incorrectly

**Symptoms:**
- Device locked but payments are up to date
- Lock screen shows incorrect information
- Locked without warning

**Solutions:**

**Step 1: Verify payment status**
- Check payment schedule in backend
- Verify all payments are recorded
- Check for sync issues

**Step 2: Check grace period**
- Device may be in grace period due to network issues
- Check if grace period banner was shown
- Verify grace period hasn't expired

**Step 3: Force payment status check**
- Tap "I Already Paid" on lock screen
- App will verify with backend
- Should unlock if payments are current

**Step 4: Backend verification**
- Backend admin checks payment records
- Verify device lock status is correct
- Manually unlock if locked incorrectly

**Step 5: Check for tamper alerts**
- Device may be locked due to security violation
- Check backend for tamper alerts
- Investigate if tampering was detected
- Unlock only if false positive confirmed

## Notification Issues

### Issue: Not Receiving Payment Reminders

**Symptoms:**
- No notifications before payment due
- No overdue notifications
- No payment confirmation notifications

**Solutions:**

**Step 1: Check notification permissions**
```
Settings → Apps → Finance Device Admin → Notifications
```
- Ensure notifications are enabled
- Check all notification categories are enabled
- Ensure "Show notifications" is ON

**Step 2: Check Do Not Disturb**
```
Settings → Sound → Do Not Disturb
```
- Ensure DND is not blocking notifications
- Add app to DND exceptions if needed

**Step 3: Check battery optimization**
```
Settings → Battery → Battery optimization → Finance Device Admin
```
- Set to "Don't optimize"
- Battery optimization can prevent background notifications

**Step 4: Check notification channels**
- Open app → Settings → Notification Settings
- Ensure all channels are enabled:
  - Payment Reminders (High priority)
  - Payment Confirmations (Default priority)
  - System Alerts (High priority)

**Step 5: Test notifications**
- App → Settings → Test Notification
- If test notification appears, notifications are working
- If not, check system notification settings

**Step 6: Reschedule notifications**
- App → Settings → Force Sync
- This will reschedule all pending notifications
- Check if notifications appear for upcoming payments

### Issue: Too Many Notifications

**Symptoms:**
- Receiving duplicate notifications
- Notifications appearing too frequently
- Spam notifications

**Solutions:**

**Step 1: Check notification settings**
- App → Settings → Notification Settings
- Adjust notification frequency if available
- Disable non-essential notifications

**Step 2: Clear notification queue**
- Clear all notifications from notification shade
- Force close app
- Reopen app

**Step 3: Check for app bugs**
- Update app to latest version
- Report issue to technical support
- Provide screenshots of duplicate notifications

## Background Service Issues

### Issue: Background Tasks Not Running

**Symptoms:**
- Payment status not checking automatically
- Location not updating
- Status not syncing with backend

**Solutions:**

**Step 1: Check battery optimization**
```
Settings → Battery → Battery optimization → Finance Device Admin → Don't optimize
```

**Step 2: Check background data**
```
Settings → Apps → Finance Device Admin → Mobile data & Wi-Fi
```
- Enable "Background data"
- Enable "Unrestricted data usage"

**Step 3: Check autostart permission**
- Some manufacturers require autostart permission
- Settings → Apps → Finance Device Admin → Autostart (enable)
- Location varies by manufacturer

**Step 4: Disable battery saver**
- Battery saver can prevent background tasks
- Disable temporarily to test
- Add app to battery saver exceptions

**Step 5: Check WorkManager status**
- App → Settings → Background Tasks Status
- Should show "Active" for all tasks
- If "Inactive", restart device

**Step 6: Reinstall app**
- Background tasks may not have registered properly
- Reinstall app
- Verify background tasks start after installation

## Network and Sync Issues

### Issue: "No Connection" Error

**Symptoms:**
- App shows "No connection" message
- Cannot sync with backend
- All operations fail

**Solutions:**

**Step 1: Verify internet connection**
- Open browser and load website
- Check Wi-Fi or mobile data is enabled
- Try switching between Wi-Fi and mobile data

**Step 2: Check backend server status**
- Contact backend administrator
- Verify server is operational
- Check for scheduled maintenance

**Step 3: Check firewall/proxy**
- Corporate or public Wi-Fi may block app
- Try using mobile data instead
- Check if HTTPS traffic is allowed

**Step 4: Check certificate pinning**
- App uses certificate pinning for security
- If backend certificate changed, app will fail
- Update app to version with new certificate

**Step 5: Check DNS resolution**
- Backend domain may not be resolving
- Try using different DNS (e.g., 8.8.8.8)
- Contact network administrator

**Step 6: Enable offline mode**
- App should queue operations when offline
- Operations will sync when connection restored
- Check: App → Settings → Offline Queue Status

### Issue: Sync Failures

**Symptoms:**
- "Sync failed" error
- Data not updating
- Offline queue growing

**Solutions:**

**Step 1: Check internet connection**
- Ensure stable connection
- Avoid syncing on poor mobile signal
- Use Wi-Fi for better reliability

**Step 2: Clear sync queue**
- App → Settings → Clear Sync Queue
- Warning: This will delete pending operations
- Use only if queue is corrupted

**Step 3: Force sync**
- App → Settings → Force Sync
- Wait for completion
- Check if sync succeeds

**Step 4: Check backend logs**
- Backend may be rejecting requests
- Check for authentication errors
- Verify device token is valid

**Step 5: Refresh authentication token**
- App → Settings → Refresh Token
- This will get new JWT token
- Try sync again

## Security and Tamper Detection Issues

### Issue: "Tampering Detected" Alert

**Symptoms:**
- Device locked with "Security violation" message
- "Tampering detected" notification
- Cannot use device

**Solutions:**

**Step 1: Verify if device is rooted**
- Check if device has root access
- Rooted devices are not allowed
- Unroot device to continue

**Step 2: Check for Xposed/Magisk**
- Remove Xposed Framework if installed
- Remove Magisk if installed
- These tools trigger tamper detection

**Step 3: Check for debugging**
- Disable USB debugging
- Settings → Developer options → USB debugging (disable)
- Restart app

**Step 4: Verify app integrity**
- Ensure app was not modified
- Reinstall from official APK
- Do not use modified or cracked versions

**Step 5: Contact store**
- If false positive, contact store
- Provide device information
- Store can investigate and unlock if appropriate

**Important:** Tampering with the app or device violates the financing agreement and may result in immediate device lock and legal action.

### Issue: Factory Reset Blocked

**Symptoms:**
- Cannot factory reset device
- Factory reset option grayed out
- Reset fails with error

**Expected Behavior:**
- Factory reset is intentionally blocked until full payment
- This is a security feature, not a bug

**Solutions:**

**If you need to reset:**
- Complete all payments
- Request release code from store
- Enter release code in app
- Factory reset will be enabled after release

**If device is malfunctioning:**
- Contact store for support
- Do not attempt to bypass reset protection
- Store can assist with device issues

## Performance Issues

### Issue: App Running Slow

**Symptoms:**
- App takes long to open
- UI is laggy
- Operations timeout

**Solutions:**

**Step 1: Clear app cache**
```
Settings → Apps → Finance Device Admin → Storage → Clear Cache
```

**Step 2: Check storage space**
- Ensure at least 500MB free space
- Clear unnecessary files
- Move media to SD card

**Step 3: Check RAM usage**
- Close other apps
- Restart device
- Check for memory-intensive apps

**Step 4: Update app**
- Newer versions may have performance improvements
- Check for updates

**Step 5: Check for malware**
- Run antivirus scan
- Remove suspicious apps
- Factory reset if severely infected (after payment completion)

### Issue: High Battery Drain

**Symptoms:**
- Battery drains quickly
- App shows high battery usage
- Device gets hot

**Solutions:**

**Step 1: Check background tasks**
- App → Settings → Background Tasks Status
- Verify tasks are running at correct intervals
- Should not run more frequently than configured

**Step 2: Check location settings**
- Location should use "Low accuracy" mode
- Settings → Location → Mode → Battery saving

**Step 3: Disable unnecessary features**
- If available, disable non-essential features
- Keep only core payment and lock functionality

**Step 4: Update app**
- Newer versions may have battery optimizations
- Check for updates

**Step 5: Report issue**
- If battery drain is excessive, report to technical support
- Provide battery usage statistics
- May indicate app bug

## Data and Storage Issues

### Issue: Database Corruption

**Symptoms:**
- App crashes on launch
- "Database error" message
- Payment history missing

**Solutions:**

**Step 1: Clear app data**
```
Settings → Apps → Finance Device Admin → Storage → Clear Data
```
- Warning: This will delete local data
- Payment history will be restored from backend

**Step 2: Reinstall app**
- Uninstall app (if possible)
- Reinstall from APK
- Re-register device

**Step 3: Force sync**
- After reinstall, force sync
- App → Settings → Force Sync
- Payment history should restore

**Step 4: Contact backend**
- If data doesn't restore, contact backend admin
- Verify data exists in backend
- May need manual data recovery

### Issue: Secure Storage Error

**Symptoms:**
- "Secure storage error" message
- Cannot access encrypted data
- Authentication fails

**Solutions:**

**Step 1: Check device security**
- Ensure device has screen lock enabled
- Settings → Security → Screen lock
- Set PIN, pattern, or password

**Step 2: Clear secure storage**
- App → Settings → Clear Secure Storage
- Warning: Will require re-authentication
- Device will need to re-register

**Step 3: Check Android Keystore**
- Keystore may be corrupted
- Requires app reinstall
- Contact technical support

## Release Code Issues

### Issue: Release Code Not Working

**Symptoms:**
- "Invalid release code" error
- Code rejected
- Cannot complete release

**Solutions:**

**Step 1: Verify code format**
- Code should be 12 alphanumeric characters
- Check for typos
- Ensure no spaces or special characters

**Step 2: Check code expiry**
- Release codes expire after 7 days
- Request new code if expired

**Step 3: Verify full payment**
- Ensure all payments are completed
- Check payment schedule shows "Fully Paid"
- Contact store to verify payment status

**Step 4: Check internet connection**
- Code validation requires online verification
- Ensure stable internet connection
- Try again with better connection

**Step 5: Request new code**
- Contact store
- Verify identity
- Request new release code

### Issue: Cannot Uninstall After Release

**Symptoms:**
- Release code accepted but cannot uninstall
- Device admin still active
- Uninstall option grayed out

**Solutions:**

**Step 1: Deactivate device admin**
```
Settings → Security → Device admin apps → Finance Device Admin → Deactivate
```
- Should be allowed after release code

**Step 2: Restart device**
- Power off completely
- Wait 10 seconds
- Power on and try again

**Step 3: Check release status**
- App → Settings → Release Status
- Should show "Released"
- If not, contact store

**Step 4: Manual deactivation**
- Contact store for assistance
- May require backend intervention
- Verify release was completed

## Emergency Procedures

### Critical: Device Completely Locked

**If device is locked and customer cannot access anything:**

1. **Verify emergency call works**
   - Tap "Emergency Call" on lock screen
   - Should be able to dial emergency numbers

2. **Contact store immediately**
   - Use another phone to call store
   - Provide customer ID and device IMEI
   - Explain situation

3. **Backend emergency unlock**
   - Store contacts backend administrator
   - Admin verifies customer identity
   - Admin sends emergency unlock command
   - Device should unlock within 5 minutes

4. **If unlock fails**
   - Verify device has internet connection
   - Try restarting device
   - Admin can check device status in backend
   - May require in-person visit to store

### Critical: App Completely Broken

**If app is crashing and cannot be used:**

1. **Safe mode boot**
   - Boot device in safe mode
   - Attempt to open app
   - If works, third-party app is interfering

2. **Clear app data**
   ```
   Settings → Apps → Finance Device Admin → Storage → Clear Data
   ```
   - Will require re-registration
   - Payment history will restore from backend

3. **Reinstall app**
   - Uninstall if possible
   - Reinstall from APK
   - Re-register device

4. **Contact technical support**
   - Provide crash logs if available
   - Describe steps to reproduce
   - May need remote assistance

## Diagnostic Tools

### Collecting Logs

**For technical support:**

1. **Enable developer options**
   ```
   Settings → About phone → Tap "Build number" 7 times
   ```

2. **Enable USB debugging**
   ```
   Settings → Developer options → USB debugging
   ```

3. **Collect logcat**
   ```
   adb logcat -d > logcat.txt
   ```

4. **App logs**
   - App → Settings → Export Logs
   - Share logs with technical support

### Testing Connectivity

**Test backend connection:**

1. **Ping test**
   - App → Settings → Test Connection
   - Should show "Connected" if successful

2. **API test**
   - App → Settings → Test API
   - Tests all critical endpoints
   - Shows which endpoints are failing

### Device Information

**Collect device info for support:**

- App → Settings → Device Information
- Shows:
  - Device model
  - Android version
  - App version
  - IMEI
  - Device ID
  - Last sync time
  - Backend connection status

## Getting Help

### When to Contact Support

- Issue not resolved by this guide
- Critical functionality broken
- Security concerns
- Payment disputes
- Device lost or stolen

### What to Provide

When contacting support, have ready:
- Customer ID
- Device IMEI
- Device model and Android version
- App version
- Description of issue
- Steps to reproduce
- Screenshots or error messages
- Recent payment history

### Support Contacts

- **Store Support:** [Phone Number]
- **Technical Support:** [Email]
- **Emergency Hotline:** [Phone Number]
- **Backend Admin:** [Email]

### Response Times

- **Critical issues:** < 2 hours
- **High priority:** < 4 hours
- **Normal priority:** < 24 hours
- **Low priority:** < 48 hours

---

**Document Version:** 1.0  
**Last Updated:** [Date]  
**For Support:** [Contact Information]
