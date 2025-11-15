# Implementation Plan

- [x] 1. Set up Flutter project structure and dependencies







  - Create new Flutter project with appropriate package name (com.finance.deviceadmin)
  - Configure pubspec.yaml with required dependencies: dio, sqflite_sqlcipher, workmanager, flutter_secure_storage, geolocator, flutter_local_notifications, provider/riverpod
  - Set up Android-specific configuration (minSdkVersion 24, targetSdkVersion 34)
  - Create folder structure: lib/services, lib/models, lib/screens, lib/widgets, lib/utils, lib/platform_channels
  - Configure ProGuard rules for release builds
  - _Requirements: 8.1, 8.4_

- [x] 2. Create native Android Device Admin Receiver and platform channel bridge






  - [x] 2.1 Create native Android Device Admin Receiver in Kotlin

    - Create FinanceDeviceAdminReceiver class extending DeviceAdminReceiver in android/app/src/main/kotlin
    - Implement onDisableRequested to block admin deactivation with message
    - Implement onEnabled to initialize device policies
    - Implement onDisabled to handle release code scenario
    - Create device_admin.xml policy file in res/xml with required permissions (force-lock, disable-keyguard, wipe-data)
    - Register receiver in AndroidManifest.xml
    - _Requirements: 2.1, 2.2, 2.3, 2.4_


  - [x] 2.2 Create platform channel for Device Admin operations

    - Create DeviceAdminMethodChannel class in Kotlin to handle method calls from Flutter
    - Implement methods: isAdminActive, requestAdminPrivileges, lockDevice, unlockDevice, disableFactoryReset
    - Register method channel in MainActivity with channel name 'com.finance.deviceadmin/admin'
    - _Requirements: 2.1, 2.5_

  - [x] 2.3 Create Flutter DeviceAdminChannel service


    - Create lib/platform_channels/device_admin_channel.dart
    - Implement MethodChannel wrapper with methods: isAdminActive(), requestAdminPrivileges(), lockDevice(), unlockDevice()
    - Add error handling for platform exceptions
    - _Requirements: 2.1, 2.2, 2.3, 2.4_


  - [x] 2.4 Implement factory reset protection in native code

    - Use DevicePolicyManager.setFactoryResetProtectionPolicy() in native code
    - Implement intent filter to intercept factory reset attempts
    - Create logic to block reset operations when payment is pending
    - Implement release code validation to enable factory reset
    - Add platform channel method to enable/disable factory reset
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 3. Create local database schema and data access layer





  - [x] 3.1 Define Dart models for local storage

    - Create lib/models/payment_schedule.dart with fields: id, dueDate, amount, status, paidDate
    - Create lib/models/device_config.dart for app configuration
    - Create lib/models/payment_history.dart for transaction records
    - Create lib/models/sync_queue_item.dart for offline operation queuing
    - Add toMap() and fromMap() methods for each model
    - Create enums: PaymentStatus, TransactionStatus, SyncType
    - _Requirements: 4.2, 6.5_


  - [x] 3.2 Create DatabaseHelper class with sqflite_sqlcipher

    - Create lib/services/database_helper.dart
    - Implement database initialization with encryption using sqflite_sqlcipher
    - Create tables: payment_schedule, device_config, payment_history, sync_queue
    - Implement CRUD methods for PaymentSchedule (insert, update, delete, query)
    - Implement CRUD methods for DeviceConfig, PaymentHistory, SyncQueueItem
    - Add methods: getUpcomingPayments(), getOverduePayments(), getPaymentHistory()
    - _Requirements: 4.2, 4.4_

  - [x] 3.3 Implement secure storage for sensitive data


    - Create lib/services/secure_storage_service.dart using flutter_secure_storage
    - Implement methods to store/retrieve JWT token, device ID, encryption keys
    - Create method to generate and store database encryption password
    - Implement method to clear all secure storage on release code validation
    - _Requirements: 8.3, 8.5_

- [x] 4. Implement API client and communication layer





  - [x] 4.1 Create Dio-based API client with interceptors

    - Create lib/services/api_client.dart
    - Configure Dio instance with base URL, timeouts (30s connect, 60s receive)
    - Implement JWT authentication interceptor to add token to headers
    - Implement logging interceptor for debugging
    - Implement retry interceptor with exponential backoff (max 3 retries)
    - _Requirements: 1.4, 4.4, 6.2_

  - [x] 4.2 Implement certificate pinning for secure communication


    - Configure Dio with custom HttpClient for certificate pinning
    - Add backend SSL certificate to assets folder
    - Implement certificate validation logic in Dio configuration
    - Add fallback handling for certificate pinning failures
    - _Requirements: 8.3_

  - [x] 4.3 Create API service classes for backend endpoints


    - Create lib/services/payment_api_service.dart
    - Implement methods: getPaymentStatus(deviceId), submitPayment(deviceId, amount, method)
    - Implement methods: getPaymentSchedule(deviceId), verifyReleaseCode(deviceId, code)
    - Create lib/services/device_api_service.dart
    - Implement methods: registerDevice(), updateDeviceStatus(), sendLocation()
    - Add error handling with custom exceptions for network errors
    - _Requirements: 4.4, 6.2, 6.3_

- [x] 5. Implement Payment Service and payment verification





  - [x] 5.1 Create PaymentService class for payment operations

    - Create lib/services/payment_service.dart
    - Implement checkPaymentStatus() method to query backend
    - Implement processPayment(amount, method) for user-initiated payments
    - Implement syncPaymentHistory() for backend synchronization
    - Implement validateReleaseCode(code) for full payment verification
    - Add offline queue handling - save to sync_queue when network unavailable
    - _Requirements: 1.4, 6.2, 6.3, 2.5_


  - [x] 5.2 Implement Workmanager for background payment status checks

    - Create lib/services/background_tasks.dart
    - Register periodic task for payment status check (6-hour intervals)
    - Implement callbackDispatcher function for background execution
    - In callback: check payment status, update local database, trigger lock if overdue
    - Implement grace period logic (48 hours) for network outages
    - Handle work constraints (require network connectivity)
    - _Requirements: 1.1, 1.4_


  - [x] 5.3 Create payment processing UI screens

    - Create lib/screens/payment_screen.dart
    - Design UI with payment amount display and mobile money options (bank transfer, USSD, card)
    - Implement payment method selection (dropdown or radio buttons)
    - Add "Make Payment" button that calls PaymentService.processPayment()
    - Display payment confirmation dialog on success
    - Show error messages with retry option on failure
    - Create lib/screens/payment_history_screen.dart to display transaction history
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_


  - [x] 5.4 Implement offline payment queue and sync

    - In PaymentService, add failed operations to sync_queue table
    - Create syncQueuedOperations() method to process queued items
    - Implement connectivity listener using connectivity_plus package
    - Trigger sync when connectivity resumes
    - Handle duplicate transaction prevention using transaction IDs
    - _Requirements: 4.4_

- [x] 6. Implement Lock Service and device lock functionality



  - [x] 6.1 Create LockService class for lock state management


    - Create lib/services/lock_service.dart
    - Implement lockDevice() method: set lock state in DB, call native lockDevice(), navigate to lock screen
    - Implement unlockDevice() method: clear lock state, navigate to home
    - Create monitorPaymentStatus() method to check for overdue payments
    - Implement 24-hour delay logic before locking after missed payment
    - _Requirements: 1.1, 1.3_

  - [x] 6.2 Create lock screen UI


    - Create lib/screens/lock_screen.dart
    - Design full-screen lock UI with payment reminder message
    - Display store contact information (phone, address)
    - Show remaining balance and overdue amount from database
    - Add "Pay Now" button that navigates to payment screen
    - Use WillPopScope to disable back button
    - Implement SystemChrome to hide status bar and navigation bar
    - _Requirements: 1.2_

  - [x] 6.3 Implement emergency call functionality during lock


    - In lock screen, add "Emergency Call" button
    - Implement platform channel method to launch emergency dialer
    - In native code, create intent for emergency dialer (tel:112, tel:911)
    - Ensure emergency calls work without unlocking device
    - _Requirements: 1.5_

  - [x] 6.4 Handle app lifecycle and lock state persistence


    - In main.dart, check lock state on app startup
    - If locked, navigate directly to LockScreen
    - Create native BroadcastReceiver for BOOT_COMPLETED in Kotlin
    - In receiver, check lock state and start app on lock screen if needed
    - Ensure LockService monitoring starts automatically on boot
    - _Requirements: 3.5_

  - [x] 6.5 Set app as launcher to prevent bypass


    - In AndroidManifest.xml, add intent-filter for HOME category to lock screen activity
    - Create native method to enable/disable launcher mode
    - Enable launcher mode when device is locked
    - Disable launcher mode when device is unlocked
    - _Requirements: 1.2, 2.3_

- [x] 7. Implement Notification Manager and payment reminders






  - [x] 7.1 Create NotificationService class

    - Create lib/services/notification_service.dart
    - Initialize flutter_local_notifications with Android notification channels
    - Create channels: payment_reminders (high priority), payment_confirmations (default)
    - Implement schedulePaymentReminder(dueDate, amount) method
    - Schedule notification 24 hours before due date
    - Schedule notification 6 hours before due date
    - _Requirements: 5.1, 5.2_


  - [x] 7.2 Implement overdue and confirmation notifications

    - Implement showOverdueNotification(amount) method
    - Implement showPaymentConfirmation(amount, newBalance) method
    - Add notification actions: "Pay Now" button that opens payment screen
    - Implement notification tap handlers using onSelectNotification callback
    - Handle deep linking to payment screen from notifications
    - _Requirements: 5.3, 5.4, 6.2_

  - [x] 7.3 Create payment schedule display UI


    - Create lib/screens/payment_schedule_screen.dart
    - Display list of all scheduled payments with due dates and amounts
    - Use different colors for pending (blue), paid (green), overdue (red) payments
    - Show payment history section with status indicators
    - Highlight next upcoming payment at the top
    - Add pull-to-refresh to sync with backend
    - _Requirements: 5.5, 4.3_

- [x] 8. Implement Location Tracker for device tracking





  - [x] 8.1 Create LocationTracker class

    - Create lib/services/location_tracker.dart
    - Request location permissions using permission_handler package
    - Implement captureLocation() using geolocator with LocationAccuracy.low (coarse)
    - Implement sendLocationToBackend() to transmit coordinates
    - Create Workmanager periodic task for location capture (12-hour intervals)
    - _Requirements: 4.1_


  - [x] 8.2 Implement location transmission and offline queuing

    - In LocationTracker, call DeviceApiService.sendLocation()
    - On network error, add location to sync_queue table
    - Implement syncQueuedLocations() to send queued locations when online
    - Add location data to sync queue with retry logic
    - _Requirements: 4.1, 4.4_


  - [x] 8.3 Handle location permissions in onboarding

    - In onboarding flow, add location permission request screen
    - Display rationale explaining why location is needed
    - Use permission_handler to request location permission
    - Handle permission denial gracefully (continue without location)
    - _Requirements: 4.1_

- [x] 9. Implement Tamper Detection Module




  - [x] 9.1 Create native TamperDetector class in Kotlin


    - Create TamperDetector.kt in android/app/src/main/kotlin
    - Implement isDeviceRooted(): check for su binary, root management apps
    - Implement isAppTampered(): verify app signature against expected signature
    - Implement isDebuggerAttached(): use Debug.isDebuggerConnected()
    - Implement checkForXposedMagisk(): check for Xposed/Magisk indicators
    - _Requirements: 8.1, 8.2_


  - [x] 9.2 Create platform channel for tamper detection

    - Create method channel 'com.finance.deviceadmin/tamper' in MainActivity
    - Implement methods: isDeviceRooted, isAppTampered, isDebuggerAttached
    - Create lib/platform_channels/tamper_detection_channel.dart
    - Implement Flutter wrapper methods for tamper checks
    - _Requirements: 8.1, 8.2_


  - [x] 9.3 Implement tamper response actions

    - Create lib/services/tamper_detection_service.dart
    - Implement checkForTampering() that calls all detection methods
    - On tamper detection: call LockService.lockDevice() immediately
    - Send alert to backend via DeviceApiService.reportTamper()
    - Log tampering attempt to local database
    - Display warning dialog: "Security violation detected. Contact store."
    - _Requirements: 8.2_


  - [x] 9.4 Integrate tamper detection into app lifecycle

    - In main.dart, run tamper check on app startup
    - Implement periodic tamper checks every 30 minutes using Timer
    - Run tamper check before critical operations (payment, unlock)
    - If tampering detected, prevent operation and lock device
    - _Requirements: 8.4_

- [x] 10. Implement device registration and onboarding flow












  - [x] 10.1 Create onboarding UI screens



    - Create lib/screens/onboarding/welcome_screen.dart explaining app purpose
    - Create lib/screens/onboarding/device_admin_screen.dart for admin activation
    - Create lib/screens/onboarding/payment_method_screen.dart for payment setup
    - Create lib/screens/onboarding/terms_screen.dart for terms of service and privacy policy
    - Implement PageView for smooth screen transitions
    - _Requirements: 2.1_

  - [x] 10.2 Implement device registration with backend


    - Create lib/services/registration_service.dart
    - Implement collectDeviceInfo(): get IMEI (via platform channel), Android ID, model, manufacturer
    - Implement generateDeviceFingerprint() combining device identifiers
    - Implement registerDevice() to call DeviceApiService.registerDevice()
    - Receive and store payment schedule from backend response
    - Store JWT token in SecureStorageService
    - Save device registration status to local database
    - _Requirements: 4.4, 7.5_

  - [x] 10.3 Handle permission requests in onboarding



    - Request device admin privileges using DeviceAdminChannel
    - Request location permissions with rationale dialog
    - Request notification permissions (Android 13+) using permission_handler
    - Request phone state permission for IMEI (or use alternative identifier)
    - Handle permission denials: show explanation and retry option
    - _Requirements: 2.1, 4.1_


  - [x] 10.4 Create native method to get device identifiers

    - In MainActivity, add method to get IMEI or alternative unique identifier
    - Use TelephonyManager for IMEI (with permission check)
    - Fallback to Android ID if IMEI unavailable
    - Return device model and manufacturer information
    - _Requirements: 4.4_

- [x] 11. Implement remote policy management





  - [x] 11.1 Create PolicyManager class for remote configuration


    - Create lib/services/policy_manager.dart
    - Implement fetchPolicyUpdates() to get policies from backend
    - Implement applyPolicyChanges(policies) to update local configuration
    - Store policy configuration in device_config table
    - Create Workmanager task to check for policy updates every 24 hours
    - _Requirements: 7.1, 7.2_

  - [x] 11.2 Implement remote unlock command handling


    - In PolicyManager, implement checkForRemoteCommands()
    - Poll backend for pending commands (unlock, lock, message)
    - Implement handleUnlockCommand() to call LockService.unlockDevice()
    - Ensure unlock happens within 5 minutes of command receipt
    - Log remote unlock events to database and send confirmation to backend
    - _Requirements: 7.3_

  - [x] 11.3 Implement custom message display on locked devices


    - Add customMessage field to lock state in database
    - In PolicyManager, receive custom messages from backend
    - Update lock screen to display custom message if present
    - Support message updates and removal
    - _Requirements: 7.4_

  - [x] 11.4 Implement device status reporting


    - Create reportDeviceStatus() method in DeviceApiService
    - Include: app version, lock state, payment status, last payment date, battery level
    - Create Workmanager periodic task to report status every 24 hours
    - Send status immediately on critical events (lock, unlock, payment)
    - _Requirements: 7.5_
-

- [x] 12. Implement release code functionality






  - [x] 12.1 Create release code validation flow

    - Create lib/screens/release_code_screen.dart
    - Design UI with text field for code entry and submit button
    - Implement validation: check format (e.g., 12 alphanumeric characters)
    - Call PaymentService.validateReleaseCode(code)
    - Display loading indicator during validation
    - Show error message for invalid/expired codes
    - _Requirements: 2.5, 3.4_


  - [x] 12.2 Implement device release after full payment

    - On successful release code validation, call releaseDevice() method
    - Remove all device restrictions: disable factory reset protection
    - Allow device admin deactivation via DeviceAdminChannel
    - Clear all local data: database, secure storage
    - Unregister from backend (mark device as released)
    - Display success message with instructions to uninstall app
    - Navigate to final screen with "Uninstall App" button
    - _Requirements: 2.5, 3.4_
- [x] 13. Implement error handling and recovery mechanisms











- [ ] 13. Implement error handling and recovery mechanisms


  - [x] 13.1 Create centralized error handling system

    - Create lib/utils/error_handler.dart
    - Define custom exception classes: NetworkException, AuthException, PaymentException
    - Implement handleError(error) method for consistent error processing
    - Create user-friendly error messages for common scenarios
    - Implement logging to local database for debugging
    - _Requirements: 6.4_

  - [x] 13.2 Implement crash reporting and diagnostics


    - Integrate Firebase Crashlytics (or Sentry)
    - Wrap main() with FlutterError.onError handler
    - Implement automatic crash recovery: restart app on crash
    - Create safe mode: if app crashes 3 times in 5 minutes, enter basic lock/unlock only mode
    - Add remote diagnostics: send device logs to backend on request
    - _Requirements: 8.2_

  - [x] 13.3 Handle network error scenarios


    - Implement 48-hour grace period for payment verification failures
    - Store grace period start time in database
    - Display warning banner during grace period: "Unable to verify payment. Please check connection."
    - Lock device only after grace period expires without successful verification
    - Implement retry logic with exponential backoff in ApiClient
    - _Requirements: 4.4_

- [x] 14. Implement security hardening and code obfuscation



  - [x] 14.1 Configure code obfuscation for release builds


    - Enable obfuscation in android/app/build.gradle (minifyEnabled true)
    - Configure ProGuard rules in proguard-rules.pro
    - Add keep rules for necessary classes (models, platform channels)
    - Test release build to ensure obfuscation doesn't break functionality
    - _Requirements: 8.1_

  - [x] 14.2 Implement anti-debugging measures


    - In TamperDetector, add checks for debugging tools
    - Implement timing checks to detect debugging (measure execution time)
    - Obfuscate security-critical methods using native code
    - Add checks in critical code paths (payment, unlock)
    - _Requirements: 8.1, 8.2_

  - [x] 14.3 Write security validation tests


    - Create test/security_test.dart
    - Test certificate pinning: verify it rejects invalid certificates
    - Test encrypted storage: verify data is encrypted at rest
    - Test tamper detection: verify it detects rooted devices (use emulator)
    - Test factory reset prevention: verify native methods work correctly
    - Create integration test for end-to-end security flow
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 15. Create main app UI and navigation








  - [x] 15.1 Design main dashboard screen



    - Create lib/screens/home_screen.dart
    - Display payment status card: next payment date, amount, remaining balance
    - Add quick action buttons: "Make Payment", "View Schedule", "Contact Support"
    - Show recent notifications list
    - Display device status indicator (active, locked, paid off)
    - Use provider/riverpod for state management
    - _Requirements: 4.3, 5.5_

  - [x] 15.2 Implement navigation structure


    - Set up navigation using Navigator 2.0 or go_router
    - Create bottom navigation bar with tabs: Home, Payments, Schedule, Settings
    - Implement deep linking for notifications (payment screen, schedule screen)
    - Handle navigation guards: redirect to lock screen if locked
    - _Requirements: 4.3, 5.5, 6.5_

  - [x] 15.3 Create settings screen


    - Create lib/screens/settings_screen.dart
    - Display app version and device information
    - Show store contact information (phone, email, address)
    - Add links to terms of service and privacy policy
    - Add "Enter Release Code" button
    - Display sync status and last sync time
    - Add "Force Sync" button for manual synchronization
    - _Requirements: 1.2_

- [x] 16. Write unit tests for core functionality




  - Create test/models/payment_schedule_test.dart for model serialization
  - Create test/services/payment_service_test.dart for payment logic
  - Test date/time handling for payment schedules and due date calculations
  - Create test/services/database_helper_test.dart for database operations
  - Test API request/response parsing in test/services/api_client_test.dart
  - Use mockito to mock dependencies (Dio, DatabaseHelper)
  - Achieve minimum 70% code coverage for services and models
  - _Requirements: All_

- [x] 17. Write integration tests for critical flows



  - Create integration_test/payment_flow_test.dart
  - Test complete payment flow: select amount, choose method, submit, verify confirmation
  - Create integration_test/lock_unlock_test.dart
  - Test lock cycle: trigger lock, display lock screen, unlock after payment
  - Create integration_test/background_sync_test.dart
  - Test background tasks: payment check, location capture, status reporting
  - Create integration_test/notification_test.dart
  - Test notification scheduling and delivery
  - Use http_mock_adapter to mock backend API responses
  - _Requirements: 1.1, 1.3, 1.4, 6.2, 6.3_

- [x] 18. Perform device testing and optimization





  - [x] 18.1 Test on multiple Android versions and devices


    - Test on Android 7.0, 9.0, 11, 12, 13, 14 (emulators and physical devices)
    - Test on popular Nigerian phone brands: Tecno, Infinix, Samsung
    - Test on low-end devices (2GB RAM) and high-end devices
    - Verify UI responsiveness on different screen sizes
    - Monitor performance: app startup time, memory usage, battery consumption
    - _Requirements: All_


  - [x] 18.2 Test critical scenarios

    - Test device reboot while locked: verify lock persists after reboot
    - Test app update while device is locked: verify lock state maintained
    - Test low battery scenarios: ensure background tasks don't drain battery
    - Test airplane mode: verify offline queue works correctly
    - Test SIM card removal: verify app continues to function
    - Test rapid lock/unlock cycles
    - _Requirements: 1.1, 1.3, 3.5, 4.4_


  - [x] 18.3 Optimize performance and battery usage


    - Optimize background task frequency: reduce unnecessary wake-ups
    - Use WorkManager constraints to run tasks only when appropriate
    - Optimize database queries: add indexes, use transactions
    - Minimize network requests: batch operations where possible
    - Reduce app size: remove unused assets, optimize images
    - Profile app using Flutter DevTools to identify bottlenecks
    - _Requirements: 1.4, 4.1, 7.5_

- [x] 19. Prepare for deployment







  - [x] 19.1 Configure app signing and release build


    - Generate keystore for app signing
    - Configure signing in android/app/build.gradle
    - Update app version and build number in pubspec.yaml
    - Build release APK: flutter build apk --release
    - Test release build on physical devices
    - _Requirements: All_

  - [x] 19.2 Create deployment documentation



    - Document installation process for store staff
    - Create user guide for customers
    - Document backend API requirements
    - Create troubleshooting guide for common issues
    - Document release code generation process
    - _Requirements: All_
