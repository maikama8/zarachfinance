import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../platform_channels/tamper_detection_channel.dart';
import '../models/device_config.dart';
import 'lock_service.dart';
import 'device_api_service.dart';
import 'database_helper.dart';
import 'secure_storage_service.dart';

/// Service for detecting and responding to device tampering attempts
/// Monitors for root access, app tampering, debugging, and framework modifications
class TamperDetectionService {
  final TamperDetectionChannel _tamperChannel = TamperDetectionChannel();
  final LockService _lockService = LockService();
  final DeviceApiService _deviceApi = DeviceApiService();
  final DatabaseHelper _db = DatabaseHelper();
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Check for any tampering attempts
  /// Returns true if tampering is detected
  Future<bool> checkForTampering() async {
    try {
      developer.log('Starting tamper detection check', name: 'TamperDetectionService');

      // Perform comprehensive tamper check
      final isTampered = await _tamperChannel.performFullCheck();

      if (isTampered) {
        developer.log(
          'TAMPERING DETECTED!',
          name: 'TamperDetectionService',
        );

        // Get detailed information about what was detected
        final details = await _getDetailedTamperInfo();

        // Handle tamper detection
        await _handleTamperDetection(details);

        return true;
      }

      developer.log('No tampering detected', name: 'TamperDetectionService');
      return false;
    } catch (e) {
      developer.log(
        'Error during tamper detection',
        name: 'TamperDetectionService',
        error: e,
      );
      // Don't throw - we don't want tamper detection failures to break the app
      return false;
    }
  }

  /// Get detailed information about detected tampering
  Future<Map<String, bool>> _getDetailedTamperInfo() async {
    final details = <String, bool>{};

    try {
      details['isRooted'] = await _tamperChannel.isDeviceRooted();
    } catch (e) {
      details['isRooted'] = false;
    }

    try {
      details['isAppTampered'] = await _tamperChannel.isAppTampered();
    } catch (e) {
      details['isAppTampered'] = false;
    }

    try {
      details['isDebuggerAttached'] = await _tamperChannel.isDebuggerAttached();
    } catch (e) {
      details['isDebuggerAttached'] = false;
    }

    try {
      details['hasXposedMagisk'] = await _tamperChannel.checkForXposedMagisk();
    } catch (e) {
      details['hasXposedMagisk'] = false;
    }

    return details;
  }

  /// Handle detected tampering
  Future<void> _handleTamperDetection(Map<String, bool> details) async {
    try {
      // Log tampering attempt to local database
      await _logTamperAttempt(details);

      // Send alert to backend
      await _sendTamperAlert(details);

      // Lock device immediately
      await _lockService.lockDevice();

      // Show warning dialog
      _showTamperWarningDialog();

      developer.log(
        'Tamper response actions completed',
        name: 'TamperDetectionService',
      );
    } catch (e) {
      developer.log(
        'Error handling tamper detection',
        name: 'TamperDetectionService',
        error: e,
      );
    }
  }

  /// Log tampering attempt to local database
  Future<void> _logTamperAttempt(Map<String, bool> details) async {
    try {
      // Store tamper log in device_config table
      final timestamp = DateTime.now();
      final logEntry = {
        'timestamp': timestamp.toIso8601String(),
        'details': details,
      };

      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'tamper_log_${timestamp.millisecondsSinceEpoch}',
          value: logEntry.toString(),
          lastUpdated: timestamp,
        ),
      );

      developer.log(
        'Tamper attempt logged to database',
        name: 'TamperDetectionService',
      );
    } catch (e) {
      developer.log(
        'Error logging tamper attempt',
        name: 'TamperDetectionService',
        error: e,
      );
    }
  }

  /// Send tamper alert to backend
  Future<void> _sendTamperAlert(Map<String, bool> details) async {
    try {
      // Get device ID from secure storage
      final deviceId = await _secureStorage.getDeviceId();
      if (deviceId == null) {
        developer.log(
          'Cannot send tamper alert: device ID not found',
          name: 'TamperDetectionService',
        );
        return;
      }

      // Determine tamper type
      String tamperType = 'UNKNOWN';
      String description = 'Security violation detected';

      if (details['isRooted'] == true) {
        tamperType = 'ROOT_DETECTED';
        description = 'Device root access detected';
      } else if (details['isAppTampered'] == true) {
        tamperType = 'APP_TAMPERED';
        description = 'App signature verification failed';
      } else if (details['isDebuggerAttached'] == true) {
        tamperType = 'DEBUGGER_ATTACHED';
        description = 'Debugger connection detected';
      } else if (details['hasXposedMagisk'] == true) {
        tamperType = 'FRAMEWORK_DETECTED';
        description = 'Xposed or Magisk framework detected';
      }

      // Create tamper alert
      final alert = TamperAlert(
        tamperType: tamperType,
        description: description,
        timestamp: DateTime.now(),
        details: details.map((key, value) => MapEntry(key, value.toString())),
      );

      // Send to backend
      await _deviceApi.reportTamper(
        deviceId: deviceId,
        alert: alert,
      );

      developer.log(
        'Tamper alert sent to backend',
        name: 'TamperDetectionService',
      );
    } catch (e) {
      developer.log(
        'Error sending tamper alert to backend',
        name: 'TamperDetectionService',
        error: e,
      );
      // Don't throw - we still want to lock the device even if alert fails
    }
  }

  /// Show warning dialog to user
  void _showTamperWarningDialog() {
    final context = LockService.navigatorKey?.currentContext;
    if (context == null) {
      developer.log(
        'Cannot show tamper dialog: context not available',
        name: 'TamperDetectionService',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent dismissal
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('Security Violation'),
              ],
            ),
            content: const Text(
              'Security violation detected. Contact store.\n\n'
              'Your device has been locked for security reasons. '
              'Please contact the store for assistance.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Check for specific tamper types
  Future<bool> isDeviceRooted() async {
    try {
      return await _tamperChannel.isDeviceRooted();
    } catch (e) {
      developer.log(
        'Error checking root status',
        name: 'TamperDetectionService',
        error: e,
      );
      return false;
    }
  }

  Future<bool> isAppTampered() async {
    try {
      return await _tamperChannel.isAppTampered();
    } catch (e) {
      developer.log(
        'Error checking app tampering',
        name: 'TamperDetectionService',
        error: e,
      );
      return false;
    }
  }

  Future<bool> isDebuggerAttached() async {
    try {
      return await _tamperChannel.isDebuggerAttached();
    } catch (e) {
      developer.log(
        'Error checking debugger',
        name: 'TamperDetectionService',
        error: e,
      );
      return false;
    }
  }

  Future<bool> hasXposedMagisk() async {
    try {
      return await _tamperChannel.checkForXposedMagisk();
    } catch (e) {
      developer.log(
        'Error checking Xposed/Magisk',
        name: 'TamperDetectionService',
        error: e,
      );
      return false;
    }
  }

  /// Perform quick security check for critical operations
  /// Focuses on immediate threats (debugger, timing checks)
  /// Faster than full check, suitable for frequent checks
  Future<bool> performQuickCheck() async {
    try {
      return await _tamperChannel.performQuickCheck();
    } catch (e) {
      developer.log(
        'Error performing quick check',
        name: 'TamperDetectionService',
        error: e,
      );
      return false;
    }
  }

  /// Detect debugging tools and emulator
  Future<bool> detectDebuggingTools() async {
    try {
      return await _tamperChannel.detectDebuggingTools();
    } catch (e) {
      developer.log(
        'Error detecting debugging tools',
        name: 'TamperDetectionService',
        error: e,
      );
      return false;
    }
  }
}
