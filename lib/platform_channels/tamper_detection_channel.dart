import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Platform channel wrapper for Tamper Detection operations
/// Provides Flutter interface to native Android tamper detection
class TamperDetectionChannel {
  static const MethodChannel _channel =
      MethodChannel('com.zarachtech.finance/tamper');

  /// Check if device is rooted
  /// Returns true if device has root access (su binary, root apps, etc.)
  Future<bool> isDeviceRooted() async {
    try {
      final bool result = await _channel.invokeMethod('isDeviceRooted');
      developer.log('Device rooted: $result', name: 'TamperDetectionChannel');
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking root status: ${e.message}',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException(
        'Failed to check root status: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error checking root status',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException('Unexpected error: $e');
    }
  }

  /// Check if app has been tampered with
  /// Returns true if app signature doesn't match expected signature
  Future<bool> isAppTampered() async {
    try {
      final bool result = await _channel.invokeMethod('isAppTampered');
      developer.log('App tampered: $result', name: 'TamperDetectionChannel');
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking app tampering: ${e.message}',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException(
        'Failed to check app tampering: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error checking app tampering',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException('Unexpected error: $e');
    }
  }

  /// Check if debugger is attached to the app
  /// Returns true if debugger is connected
  Future<bool> isDebuggerAttached() async {
    try {
      final bool result = await _channel.invokeMethod('isDebuggerAttached');
      developer.log(
        'Debugger attached: $result',
        name: 'TamperDetectionChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking debugger status: ${e.message}',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException(
        'Failed to check debugger status: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error checking debugger status',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException('Unexpected error: $e');
    }
  }

  /// Check for Xposed or Magisk framework
  /// Returns true if Xposed or Magisk is detected
  Future<bool> checkForXposedMagisk() async {
    try {
      final bool result = await _channel.invokeMethod('checkForXposedMagisk');
      developer.log(
        'Xposed/Magisk detected: $result',
        name: 'TamperDetectionChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking for Xposed/Magisk: ${e.message}',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException(
        'Failed to check for Xposed/Magisk: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error checking for Xposed/Magisk',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException('Unexpected error: $e');
    }
  }

  /// Perform comprehensive tamper check
  /// Returns true if any tampering is detected
  /// Checks: root, app tampering, debugger, Xposed/Magisk, debugging tools
  Future<bool> performFullCheck() async {
    try {
      final bool result = await _channel.invokeMethod('performFullCheck');
      developer.log(
        'Full tamper check result: $result',
        name: 'TamperDetectionChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error performing full tamper check: ${e.message}',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException(
        'Failed to perform full tamper check: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error performing full tamper check',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException('Unexpected error: $e');
    }
  }

  /// Perform quick security check for critical operations
  /// Focuses on immediate threats (debugger, timing)
  /// Returns true if immediate threat detected
  Future<bool> performQuickCheck() async {
    try {
      final bool result = await _channel.invokeMethod('performQuickCheck');
      developer.log(
        'Quick tamper check result: $result',
        name: 'TamperDetectionChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error performing quick check: ${e.message}',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException(
        'Failed to perform quick check: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error performing quick check',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException('Unexpected error: $e');
    }
  }

  /// Detect debugging tools and emulator
  /// Returns true if debugging tools or emulator detected
  Future<bool> detectDebuggingTools() async {
    try {
      final bool result = await _channel.invokeMethod('detectDebuggingTools');
      developer.log(
        'Debugging tools detected: $result',
        name: 'TamperDetectionChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error detecting debugging tools: ${e.message}',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException(
        'Failed to detect debugging tools: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error detecting debugging tools',
        name: 'TamperDetectionChannel',
        error: e,
      );
      throw TamperDetectionException('Unexpected error: $e');
    }
  }
}

/// Exception thrown when tamper detection operations fail
class TamperDetectionException implements Exception {
  final String message;
  final String? code;

  TamperDetectionException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'TamperDetectionException [$code]: $message';
    }
    return 'TamperDetectionException: $message';
  }
}
