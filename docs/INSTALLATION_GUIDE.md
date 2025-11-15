# Installation Guide for Store Staff

## Overview
This guide provides step-by-step instructions for store staff to install and configure the Device Admin App on financed mobile phones before handing them over to customers.

## Prerequisites

- Android device (Android 7.0 or higher)
- Internet connection
- Device Admin App APK file
- Customer information (ID, payment schedule)
- Backend system access

## Installation Steps

### 1. Prepare the Device

1. **Factory Reset the Device** (if not new)
   - Go to Settings → System → Reset options → Erase all data (factory reset)
   - Confirm the reset
   - Wait for device to restart

2. **Complete Initial Android Setup**
   - Select language and region
   - Connect to Wi-Fi
   - Skip Google account sign-in (will be done later)
   - Accept terms and conditions
   - Complete setup wizard

### 2. Install the Device Admin App

1. **Enable Unknown Sources**
   - Go to Settings → Security
   - Enable "Unknown sources" or "Install unknown apps"
   - Select the file manager or browser you'll use to install

2. **Transfer APK to Device**
   - Connect device to computer via USB, OR
   - Download APK from internal server, OR
   - Transfer via Bluetooth/file sharing

3. **Install the APK**
   - Open file manager
   - Navigate to the APK location
   - Tap on `device_admin_app.apk`
   - Tap "Install"
   - Wait for installation to complete
   - Tap "Open" (do not tap "Done")

### 3. Initial App Configuration

1. **Launch the App**
   - The app should open automatically after installation
   - If not, find "Finance Device Admin" in app drawer

2. **Complete Onboarding Flow**

   **Welcome Screen:**
   - Read the welcome message
   - Tap "Get Started"

   **Device Admin Activation:**
   - Read the explanation of device admin privileges
   - Tap "Activate Device Admin"
   - System dialog will appear
   - Tap "Activate" on the system dialog
   - **IMPORTANT:** Verify that activation was successful (green checkmark appears)

   **Location Permission:**
   - Read the location tracking explanation
   - Tap "Grant Permission"
   - Select "Allow all the time" or "Allow while using the app"
   - Tap "Continue"

   **Notification Permission:**
   - Read the notification explanation
   - Tap "Grant Permission"
   - Tap "Allow" on system dialog
   - Tap "Continue"

   **Payment Method Setup:**
   - Customer will complete this section
   - Skip for now by tapping "Set Up Later"

   **Terms and Conditions:**
   - Review terms with customer
   - Have customer read and accept
   - Tap "Accept and Continue"

### 4. Device Registration

1. **Enter Customer Information**
   - Customer ID: [Enter from system]
   - Phone Number: [Customer's phone number]
   - Email: [Customer's email - optional]

2. **Verify Device Information**
   - Device Model: [Auto-detected]
   - IMEI: [Auto-detected]
   - Android Version: [Auto-detected]
   - Verify all information is correct

3. **Submit Registration**
   - Tap "Register Device"
   - Wait for backend confirmation (5-10 seconds)
   - Success message should appear

4. **Verify Payment Schedule**
   - Payment schedule should load automatically
   - Verify:
     - Total amount matches purchase agreement
     - Payment frequency is correct (daily/weekly)
     - First payment date is correct
   - If incorrect, contact backend administrator

### 5. Final Verification

1. **Test Device Lock**
   - Go to Settings in the app
   - Tap "Test Lock" (staff mode only)
   - Device should lock immediately
   - Lock screen should display payment information
   - Tap "Unlock" (staff mode only)
   - Device should unlock

2. **Verify Admin Protection**
   - Go to Android Settings → Security → Device admin apps
   - "Finance Device Admin" should be listed
   - Try to deactivate it
   - Deactivation should be blocked with message

3. **Check Notifications**
   - Verify notification channel is active
   - Check that app can display notifications

4. **Verify Internet Connectivity**
   - Ensure device is connected to internet
   - App should show "Connected" status
   - Last sync time should be recent

### 6. Customer Handover

1. **Customer Account Setup**
   - Help customer set up payment method
   - Explain payment process
   - Show how to make payments in app

2. **Customer Education**
   - Explain payment schedule
   - Show payment reminder notifications
   - Explain what happens if payment is missed
   - Demonstrate emergency call feature
   - Provide store contact information

3. **Documentation**
   - Have customer sign financing agreement
   - Provide copy of payment schedule
   - Give customer store contact card
   - Record device IMEI and customer ID in store system

4. **Final Checks**
   - Verify customer can navigate the app
   - Ensure customer understands payment obligations
   - Answer any questions
   - Provide support contact information

## Troubleshooting Installation Issues

### Device Admin Activation Fails

**Problem:** Device admin activation is blocked or fails

**Solutions:**
- Ensure device is not already managed by another admin app
- Check if device has MDM (Mobile Device Management) restrictions
- Try restarting the device and reinstalling the app
- Verify app signature is valid (not tampered)

### Registration Fails

**Problem:** Device registration with backend fails

**Solutions:**
- Verify internet connection is active
- Check customer ID is correct in backend system
- Ensure backend server is accessible
- Check device time/date is correct (affects SSL)
- Contact backend administrator

### Permissions Not Granted

**Problem:** Location or notification permissions denied

**Solutions:**
- Go to Android Settings → Apps → Finance Device Admin → Permissions
- Manually grant required permissions
- Restart the app
- If still failing, check device restrictions

### App Crashes on Launch

**Problem:** App crashes immediately after opening

**Solutions:**
- Clear app cache: Settings → Apps → Finance Device Admin → Storage → Clear Cache
- Reinstall the app
- Check Android version compatibility (minimum Android 7.0)
- Check device has sufficient storage space
- Contact technical support with crash logs

### Payment Schedule Not Loading

**Problem:** Payment schedule doesn't appear after registration

**Solutions:**
- Check internet connection
- Verify customer ID exists in backend
- Try "Force Sync" in app settings
- Check backend logs for errors
- Re-register device if necessary

## Post-Installation Monitoring

### First 24 Hours

- Monitor device status in backend dashboard
- Verify first sync completed successfully
- Check location data is being received
- Ensure payment schedule is visible to customer

### First Week

- Verify customer received payment reminders
- Check customer made first payment successfully
- Monitor for any technical issues
- Follow up with customer for feedback

## Emergency Procedures

### Device Not Locking When Required

1. Check backend lock command was sent
2. Verify device has internet connection
3. Check app is running (not force-stopped)
4. Send remote lock command from backend
5. Contact customer to restart device

### Customer Cannot Make Payment

1. Verify payment gateway is operational
2. Check customer's payment method is valid
3. Try alternative payment method
4. Process manual payment in backend
5. Manually unlock device if payment confirmed

### Device Lost or Stolen

1. Check last known location in backend
2. Send remote lock command
3. Display custom message with store contact
4. Monitor for device activity
5. Follow company policy for lost devices

## Support Contacts

- **Technical Support:** [Phone Number]
- **Backend Administrator:** [Phone Number]
- **Store Manager:** [Phone Number]
- **Emergency Hotline:** [Phone Number]

## Appendix

### Required Permissions

- **Device Administrator:** Required for lock/unlock functionality
- **Location (All the time):** Required for device tracking
- **Notifications:** Required for payment reminders
- **Phone State:** Required for device identification
- **Internet:** Required for backend communication
- **Boot Completed:** Required for persistence after restart

### App Version Information

- **Current Version:** Check pubspec.yaml
- **Minimum Android Version:** 7.0 (API 24)
- **Target Android Version:** 14 (API 34)
- **Last Updated:** [Date]

### Security Notes

- Never share release codes with customers until full payment
- Verify customer identity before providing support
- Do not disable device admin manually
- Report any tampering attempts immediately
- Keep APK file secure and version-controlled
