import 'dart:developer' as developer;
import '../services/tamper_detection_service.dart';

/// Utility class for running tamper checks before critical operations
/// Use this to protect sensitive operations like payments and unlocking
class TamperGuard {
  static final TamperDetectionService _tamperService = TamperDetectionService();

  /// Run tamper check before executing a critical operation
  /// Returns true if operation should proceed, false if tampering detected
  /// 
  /// Usage:
  /// ```dart
  /// if (await TamperGuard.checkBeforeCriticalOperation('payment')) {
  ///   // Proceed with payment
  /// } else {
  ///   // Operation blocked due to tampering
  /// }
  /// ```
  static Future<bool> checkBeforeCriticalOperation(String operationName) async {
    try {
      developer.log(
        'Running tamper check before $operationName',
        name: 'TamperGuard',
      );

      final isTampered = await _tamperService.checkForTampering();

      if (isTampered) {
        developer.log(
          'Tampering detected - blocking $operationName',
          name: 'TamperGuard',
        );
        return false;
      }

      developer.log(
        'Tamper check passed - allowing $operationName',
        name: 'TamperGuard',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error during tamper check for $operationName',
        name: 'TamperGuard',
        error: e,
      );
      // On error, allow operation to proceed (fail open)
      // This prevents tamper check failures from breaking critical functionality
      return true;
    }
  }

  /// Run quick tamper check for time-sensitive operations
  /// Focuses on immediate threats (debugger, timing checks)
  /// Faster than full check, suitable for frequent checks
  static Future<bool> quickCheckBeforeOperation(String operationName) async {
    try {
      developer.log(
        'Running quick tamper check before $operationName',
        name: 'TamperGuard',
      );

      final isTampered = await _tamperService.performQuickCheck();

      if (isTampered) {
        developer.log(
          'Immediate threat detected - blocking $operationName',
          name: 'TamperGuard',
        );
        return false;
      }

      developer.log(
        'Quick check passed - allowing $operationName',
        name: 'TamperGuard',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error during quick check for $operationName',
        name: 'TamperGuard',
        error: e,
      );
      return true;
    }
  }

  /// Check for specific tamper types before operation
  static Future<Map<String, bool>> getDetailedTamperStatus() async {
    final status = <String, bool>{};

    try {
      status['isRooted'] = await _tamperService.isDeviceRooted();
    } catch (e) {
      status['isRooted'] = false;
    }

    try {
      status['isAppTampered'] = await _tamperService.isAppTampered();
    } catch (e) {
      status['isAppTampered'] = false;
    }

    try {
      status['isDebuggerAttached'] = await _tamperService.isDebuggerAttached();
    } catch (e) {
      status['isDebuggerAttached'] = false;
    }

    try {
      status['hasXposedMagisk'] = await _tamperService.hasXposedMagisk();
    } catch (e) {
      status['hasXposedMagisk'] = false;
    }

    return status;
  }
}
