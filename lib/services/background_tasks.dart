import 'package:workmanager/workmanager.dart';
import 'package:zaracfinance/services/payment_service.dart';
import 'package:zaracfinance/services/database_helper.dart';
import 'package:zaracfinance/services/location_tracker.dart';
import 'package:zaracfinance/services/policy_manager.dart';
import 'package:zaracfinance/services/device_api_service.dart';
import 'package:zaracfinance/services/secure_storage_service.dart';
import 'package:zaracfinance/services/exceptions/api_exceptions.dart';
import 'package:zaracfinance/models/device_config.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Background task names
class BackgroundTaskNames {
  static const String paymentStatusCheck = 'payment_status_check';
  static const String locationCapture = 'location_capture';
  static const String policySync = 'policy_sync';
  static const String deviceStatusReport = 'device_status_report';
}

/// Callback dispatcher for background tasks
/// This function runs in a separate isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case BackgroundTaskNames.paymentStatusCheck:
          return await _handlePaymentStatusCheck();
        case BackgroundTaskNames.locationCapture:
          return await _handleLocationCapture();
        case BackgroundTaskNames.policySync:
          return await _handlePolicySync();
        case BackgroundTaskNames.deviceStatusReport:
          return await _handleDeviceStatusReport();
        default:
          return Future.value(true);
      }
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

/// Handle payment status check in background
Future<bool> _handlePaymentStatusCheck() async {
  try {
    final paymentService = PaymentService();
    final db = DatabaseHelper();

    // Check payment status with backend
    final paymentStatus = await paymentService.checkPaymentStatus();

    // Check if payment is overdue
    if (paymentStatus.isOverdue) {
      // Check grace period before locking
      final shouldLock = await _checkGracePeriod(db);
      
      if (shouldLock) {
        // Trigger device lock
        await _triggerDeviceLock(db);
      }
    } else {
      // Clear grace period if payment is not overdue
      await _clearGracePeriod(db);
    }

    return true;
  } on NetworkException catch (e) {
    // Handle network errors with grace period
    print('Network error during payment check: $e');
    return await _handleNetworkError();
  } catch (e) {
    print('Error checking payment status: $e');
    return false;
  }
}

/// Check if grace period has expired
Future<bool> _checkGracePeriod(DatabaseHelper db) async {
  final gracePeriodConfig = await db.getDeviceConfig('grace_period_start');
  
  if (gracePeriodConfig == null) {
    // Start grace period
    await db.insertDeviceConfig(
      DeviceConfig(
        key: 'grace_period_start',
        value: DateTime.now().toIso8601String(),
        lastUpdated: DateTime.now(),
      ),
    );
    return false; // Don't lock yet, grace period just started
  }

  // Check if 24 hours have passed since grace period started
  final gracePeriodStart = DateTime.parse(gracePeriodConfig.value);
  final hoursSinceStart = DateTime.now().difference(gracePeriodStart).inHours;

  // Lock after 24 hours
  return hoursSinceStart >= 24;
}

/// Clear grace period
Future<void> _clearGracePeriod(DatabaseHelper db) async {
  await db.deleteDeviceConfig('grace_period_start');
  await db.deleteDeviceConfig('network_grace_period_start');
}

/// Handle network errors with 48-hour grace period
Future<bool> _handleNetworkError() async {
  final db = DatabaseHelper();
  final networkGracePeriodConfig = await db.getDeviceConfig('network_grace_period_start');
  
  if (networkGracePeriodConfig == null) {
    // Start network grace period
    await db.insertDeviceConfig(
      DeviceConfig(
        key: 'network_grace_period_start',
        value: DateTime.now().toIso8601String(),
        lastUpdated: DateTime.now(),
      ),
    );
    return true; // Task succeeded, just started grace period
  }

  // Check if 48 hours have passed
  final gracePeriodStart = DateTime.parse(networkGracePeriodConfig.value);
  final hoursSinceStart = DateTime.now().difference(gracePeriodStart).inHours;

  if (hoursSinceStart >= 48) {
    // Grace period expired, lock device
    await _triggerDeviceLock(db);
  }

  return true; // Task succeeded
}

/// Trigger device lock
Future<void> _triggerDeviceLock(DatabaseHelper db) async {
  await db.setLockState(true);
  
  // Store lock reason
  await db.insertDeviceConfig(
    DeviceConfig(
      key: 'lock_reason',
      value: 'overdue_payment',
      lastUpdated: DateTime.now(),
    ),
  );

  await db.insertDeviceConfig(
    DeviceConfig(
      key: 'lock_timestamp',
      value: DateTime.now().toIso8601String(),
      lastUpdated: DateTime.now(),
    ),
  );
}

/// Handle location capture in background
Future<bool> _handleLocationCapture() async {
  try {
    final locationTracker = LocationTracker();
    
    // Capture and send location
    final success = await locationTracker.captureAndSendLocation();
    
    // Also try to sync any queued locations
    await locationTracker.syncQueuedLocations();
    
    return success;
  } catch (e) {
    print('Error capturing location: $e');
    return false;
  }
}

/// Handle policy sync in background
Future<bool> _handlePolicySync() async {
  try {
    final policyManager = PolicyManager();
    
    // Sync policies and process remote commands
    await policyManager.syncPoliciesAndCommands();
    
    return true;
  } on NetworkException catch (e) {
    print('Network error during policy sync: $e');
    return true; // Don't fail the task on network errors
  } catch (e) {
    print('Error syncing policies: $e');
    return false;
  }
}

/// Handle device status report in background
Future<bool> _handleDeviceStatusReport() async {
  try {
    final deviceApiService = DeviceApiService();
    final db = DatabaseHelper();
    final secureStorage = SecureStorageService();
    
    // Get device ID
    final deviceId = await secureStorage.getDeviceId();
    if (deviceId == null) {
      print('Device ID not found, skipping status report');
      return false;
    }
    
    // Get app version
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;
    
    // Get lock state
    final isLocked = await db.getLockState();
    final lockState = isLocked ? 'LOCKED' : 'UNLOCKED';
    
    // Get payment status
    final overduePayments = await db.getOverduePayments();
    final paymentStatus = overduePayments.isEmpty ? 'CURRENT' : 'OVERDUE';
    
    // Get last payment date
    final paymentHistory = await db.getPaymentHistory(limit: 1);
    final lastPaymentDate = paymentHistory.isNotEmpty 
        ? DateTime.fromMillisecondsSinceEpoch(paymentHistory.first.timestamp.millisecondsSinceEpoch)
        : null;
    
    // Get battery level
    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;
    
    // Send status report
    await deviceApiService.reportDeviceStatus(
      deviceId: deviceId,
      appVersion: appVersion,
      lockState: lockState,
      paymentStatus: paymentStatus,
      lastPaymentDate: lastPaymentDate,
      batteryLevel: batteryLevel,
    );
    
    // Update last report timestamp
    await db.insertDeviceConfig(
      DeviceConfig(
        key: 'last_status_report',
        value: DateTime.now().toIso8601String(),
        lastUpdated: DateTime.now(),
      ),
    );
    
    return true;
  } on NetworkException catch (e) {
    print('Network error during status report: $e');
    return true; // Don't fail the task on network errors
  } catch (e) {
    print('Error reporting device status: $e');
    return false;
  }
}

/// Service class for managing background tasks
class BackgroundTasksService {
  /// Initialize background tasks
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Register periodic payment status check
  /// Runs every 6 hours with optimized constraints
  static Future<void> registerPaymentStatusCheck() async {
    await Workmanager().registerPeriodicTask(
      'payment_status_check_task',
      BackgroundTaskNames.paymentStatusCheck,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true, // Don't run when battery is low
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // Keep existing to avoid duplicate work
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  /// Cancel payment status check task
  static Future<void> cancelPaymentStatusCheck() async {
    await Workmanager().cancelByUniqueName('payment_status_check_task');
  }

  /// Register periodic location capture
  /// Runs every 12 hours with optimized constraints
  static Future<void> registerLocationCapture() async {
    await Workmanager().registerPeriodicTask(
      'location_capture_task',
      BackgroundTaskNames.locationCapture,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true, // Don't run when battery is low
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // Keep existing to avoid duplicate work
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 30),
    );
  }

  /// Cancel location capture task
  static Future<void> cancelLocationCapture() async {
    await Workmanager().cancelByUniqueName('location_capture_task');
  }

  /// Run location capture immediately (for testing)
  static Future<void> runLocationCaptureNow() async {
    await Workmanager().registerOneOffTask(
      'location_capture_once',
      BackgroundTaskNames.locationCapture,
    );
  }

  /// Cancel all background tasks
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }

  /// Run payment status check immediately (for testing)
  static Future<void> runPaymentStatusCheckNow() async {
    await Workmanager().registerOneOffTask(
      'payment_status_check_once',
      BackgroundTaskNames.paymentStatusCheck,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Register periodic policy sync
  /// Runs every 24 hours with optimized constraints
  static Future<void> registerPolicySync() async {
    await Workmanager().registerPeriodicTask(
      'policy_sync_task',
      BackgroundTaskNames.policySync,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true, // Don't run when battery is low
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // Keep existing to avoid duplicate work
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 30),
    );
  }

  /// Cancel policy sync task
  static Future<void> cancelPolicySync() async {
    await Workmanager().cancelByUniqueName('policy_sync_task');
  }

  /// Run policy sync immediately (for testing)
  static Future<void> runPolicySyncNow() async {
    await Workmanager().registerOneOffTask(
      'policy_sync_once',
      BackgroundTaskNames.policySync,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Register periodic device status report
  /// Runs every 24 hours with optimized constraints
  static Future<void> registerDeviceStatusReport() async {
    await Workmanager().registerPeriodicTask(
      'device_status_report_task',
      BackgroundTaskNames.deviceStatusReport,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true, // Don't run when battery is low
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // Keep existing to avoid duplicate work
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 30),
    );
  }

  /// Cancel device status report task
  static Future<void> cancelDeviceStatusReport() async {
    await Workmanager().cancelByUniqueName('device_status_report_task');
  }

  /// Run device status report immediately (for testing)
  static Future<void> runDeviceStatusReportNow() async {
    await Workmanager().registerOneOffTask(
      'device_status_report_once',
      BackgroundTaskNames.deviceStatusReport,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Send device status report immediately on critical events
  /// This is a direct call, not a background task
  static Future<void> sendStatusReportOnCriticalEvent(String eventType) async {
    try {
      final deviceApiService = DeviceApiService();
      final db = DatabaseHelper();
      final secureStorage = SecureStorageService();
      
      // Get device ID
      final deviceId = await secureStorage.getDeviceId();
      if (deviceId == null) {
        print('Device ID not found, skipping status report');
        return;
      }
      
      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      
      // Get lock state
      final isLocked = await db.getLockState();
      final lockState = isLocked ? 'LOCKED' : 'UNLOCKED';
      
      // Get payment status
      final overduePayments = await db.getOverduePayments();
      final paymentStatus = overduePayments.isEmpty ? 'CURRENT' : 'OVERDUE';
      
      // Get last payment date
      final paymentHistory = await db.getPaymentHistory(limit: 1);
      final lastPaymentDate = paymentHistory.isNotEmpty 
          ? DateTime.fromMillisecondsSinceEpoch(paymentHistory.first.timestamp.millisecondsSinceEpoch)
          : null;
      
      // Get battery level
      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      
      // Send status report with event type
      await deviceApiService.reportDeviceStatus(
        deviceId: deviceId,
        appVersion: appVersion,
        lockState: lockState,
        paymentStatus: paymentStatus,
        lastPaymentDate: lastPaymentDate,
        batteryLevel: batteryLevel,
        additionalData: {
          'eventType': eventType,
          'eventTimestamp': DateTime.now().toIso8601String(),
        },
      );
      
      print('Status report sent for event: $eventType');
    } catch (e) {
      print('Error sending status report on critical event: $e');
      // Don't throw - this is a best-effort operation
    }
  }
}
