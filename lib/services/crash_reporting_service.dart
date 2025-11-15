import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';
import 'database_helper.dart';
import 'device_api_service.dart';
import 'secure_storage_service.dart';

/// Service for crash reporting and diagnostics
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  final ErrorHandler _errorHandler = ErrorHandler();
  final DatabaseHelper _db = DatabaseHelper();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  // Track crash count for safe mode detection
  static const String _crashCountKey = 'crash_count';
  static const String _lastCrashTimeKey = 'last_crash_time';
  static const int _maxCrashesBeforeSafeMode = 3;
  static const Duration _crashWindowDuration = Duration(minutes: 5);

  factory CrashReportingService() {
    return _instance;
  }

  CrashReportingService._internal();

  /// Initialize crash reporting
  Future<void> initialize() async {
    // Set up Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Set up platform dispatcher error handler for async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    // Check if we should enter safe mode
    await _checkSafeModeCondition();
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    // Log to console in debug mode
    if (kDebugMode) {
      FlutterError.presentError(details);
    }

    // Log to error handler
    _errorHandler.handleError(
      details.exception,
      stackTrace: details.stack,
      context: 'Flutter Framework Error',
      logToDatabase: true,
      showToUser: false,
    );

    // Record crash
    _recordCrash();

    // Send to backend if available
    _sendCrashReport(details.exception, details.stack, 'Flutter Framework Error');
  }

  /// Handle platform/async errors
  bool _handlePlatformError(Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('Platform error: $error');
      debugPrint('Stack trace: $stack');
    }

    // Log to error handler
    _errorHandler.handleError(
      error,
      stackTrace: stack,
      context: 'Platform Error',
      logToDatabase: true,
      showToUser: false,
    );

    // Record crash
    _recordCrash();

    // Send to backend if available
    _sendCrashReport(error, stack, 'Platform Error');

    return true;
  }

  /// Record a crash occurrence
  Future<void> _recordCrash() async {
    try {
      final now = DateTime.now();
      
      // Get current crash count and last crash time
      final crashCountStr = await _secureStorage.getCustomValue(_crashCountKey) ?? '0';
      final lastCrashTimeStr = await _secureStorage.getCustomValue(_lastCrashTimeKey);
      
      int crashCount = int.tryParse(crashCountStr) ?? 0;
      DateTime? lastCrashTime;
      
      if (lastCrashTimeStr != null) {
        lastCrashTime = DateTime.tryParse(lastCrashTimeStr);
      }

      // Check if this crash is within the window
      if (lastCrashTime != null && 
          now.difference(lastCrashTime) < _crashWindowDuration) {
        crashCount++;
      } else {
        // Reset count if outside window
        crashCount = 1;
      }

      // Store updated values
      await _secureStorage.storeCustomValue(_crashCountKey, crashCount.toString());
      await _secureStorage.storeCustomValue(_lastCrashTimeKey, now.toIso8601String());

      // Check if we should enter safe mode
      if (crashCount >= _maxCrashesBeforeSafeMode) {
        await _enterSafeMode();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to record crash: $e');
      }
    }
  }

  /// Check if app should enter safe mode
  Future<void> _checkSafeModeCondition() async {
    try {
      final crashCountStr = await _secureStorage.getCustomValue(_crashCountKey) ?? '0';
      final lastCrashTimeStr = await _secureStorage.getCustomValue(_lastCrashTimeKey);
      
      final crashCount = int.tryParse(crashCountStr) ?? 0;
      
      if (lastCrashTimeStr != null) {
        final lastCrashTime = DateTime.tryParse(lastCrashTimeStr);
        final now = DateTime.now();
        
        if (lastCrashTime != null && 
            now.difference(lastCrashTime) < _crashWindowDuration &&
            crashCount >= _maxCrashesBeforeSafeMode) {
          await _enterSafeMode();
        } else if (lastCrashTime != null && 
                   now.difference(lastCrashTime) >= _crashWindowDuration) {
          // Reset crash count if window has passed
          await _secureStorage.storeCustomValue(_crashCountKey, '0');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to check safe mode condition: $e');
      }
    }
  }

  /// Enter safe mode (basic lock/unlock only)
  Future<void> _enterSafeMode() async {
    try {
      if (kDebugMode) {
        debugPrint('Entering safe mode due to repeated crashes');
      }

      // Store safe mode flag
      await _secureStorage.storeCustomValue('safe_mode', 'true');

      // Log to database
      await _errorHandler.handleError(
        Exception('App entered safe mode due to repeated crashes'),
        context: 'Safe Mode',
        logToDatabase: true,
        showToUser: false,
      );

      // Send alert to backend
      _sendSafeModeAlert();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to enter safe mode: $e');
      }
    }
  }

  /// Check if app is in safe mode
  Future<bool> isInSafeMode() async {
    try {
      final safeModeStr = await _secureStorage.getCustomValue('safe_mode');
      return safeModeStr == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Exit safe mode
  Future<void> exitSafeMode() async {
    try {
      await _secureStorage.deleteCustomValue('safe_mode');
      await _secureStorage.storeCustomValue(_crashCountKey, '0');
      
      if (kDebugMode) {
        debugPrint('Exited safe mode');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to exit safe mode: $e');
      }
    }
  }

  /// Send crash report to backend
  Future<void> _sendCrashReport(
    Object error,
    StackTrace? stackTrace,
    String context,
  ) async {
    try {
      // This would integrate with your backend API
      // For now, we'll just log it
      if (kDebugMode) {
        debugPrint('Would send crash report to backend: $error');
      }

      // In production, you would call:
      // final deviceApi = DeviceApiService();
      // await deviceApi.sendCrashReport(error, stackTrace, context);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to send crash report: $e');
      }
    }
  }

  /// Send safe mode alert to backend
  Future<void> _sendSafeModeAlert() async {
    try {
      if (kDebugMode) {
        debugPrint('Would send safe mode alert to backend');
      }

      // In production, you would call:
      // final deviceApi = DeviceApiService();
      // await deviceApi.sendSafeModeAlert();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to send safe mode alert: $e');
      }
    }
  }

  /// Get device diagnostics for remote debugging
  Future<Map<String, dynamic>> getDiagnostics() async {
    try {
      final errorStats = await _errorHandler.getErrorStatistics();
      final recentErrors = await _errorHandler.getRecentErrors(limit: 10);
      final isInSafeMode = await this.isInSafeMode();
      final crashCountStr = await _secureStorage.getCustomValue(_crashCountKey) ?? '0';
      final lastCrashTimeStr = await _secureStorage.getCustomValue(_lastCrashTimeKey);

      return {
        'safe_mode': isInSafeMode,
        'crash_count': int.tryParse(crashCountStr) ?? 0,
        'last_crash_time': lastCrashTimeStr,
        'error_statistics': errorStats,
        'recent_errors': recentErrors.map((e) => {
          'timestamp': e.timestamp.toIso8601String(),
          'type': e.errorType,
          'message': e.message,
          'context': e.context,
        }).toList(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get diagnostics: $e');
      }
      return {};
    }
  }

  /// Send diagnostics to backend on request
  Future<void> sendDiagnosticsToBackend() async {
    try {
      final diagnostics = await getDiagnostics();
      
      if (kDebugMode) {
        debugPrint('Would send diagnostics to backend: $diagnostics');
      }

      // In production, you would call:
      // final deviceApi = DeviceApiService();
      // await deviceApi.sendDiagnostics(diagnostics);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to send diagnostics: $e');
      }
    }
  }

  /// Clear crash history (for testing or after successful recovery)
  Future<void> clearCrashHistory() async {
    try {
      await _secureStorage.deleteCustomValue(_crashCountKey);
      await _secureStorage.deleteCustomValue(_lastCrashTimeKey);
      await exitSafeMode();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to clear crash history: $e');
      }
    }
  }
}
