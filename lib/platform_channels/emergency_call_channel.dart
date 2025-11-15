import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Platform channel wrapper for emergency call functionality
/// Allows launching emergency dialer even when device is locked
class EmergencyCallChannel {
  static const MethodChannel _channel =
      MethodChannel('com.zarachtech.finance/emergency');

  /// Launch the emergency dialer
  /// Opens the phone dialer with emergency numbers (112, 911)
  /// This should work even when the device is locked
  Future<void> launchEmergencyDialer() async {
    try {
      await _channel.invokeMethod('launchEmergencyDialer');
      developer.log(
        'Emergency dialer launched',
        name: 'EmergencyCallChannel',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Error launching emergency dialer: ${e.message}',
        name: 'EmergencyCallChannel',
        error: e,
      );
      throw EmergencyCallException(
        'Failed to launch emergency dialer: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error launching emergency dialer',
        name: 'EmergencyCallChannel',
        error: e,
      );
      throw EmergencyCallException('Unexpected error: $e');
    }
  }

  /// Launch emergency dialer with specific number
  /// @param number The emergency number to dial (e.g., "112", "911")
  Future<void> launchEmergencyDialerWithNumber(String number) async {
    try {
      await _channel.invokeMethod('launchEmergencyDialerWithNumber', {
        'number': number,
      });
      developer.log(
        'Emergency dialer launched with number: $number',
        name: 'EmergencyCallChannel',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Error launching emergency dialer with number: ${e.message}',
        name: 'EmergencyCallChannel',
        error: e,
      );
      throw EmergencyCallException(
        'Failed to launch emergency dialer: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error launching emergency dialer with number',
        name: 'EmergencyCallChannel',
        error: e,
      );
      throw EmergencyCallException('Unexpected error: $e');
    }
  }
}

/// Exception thrown when emergency call operations fail
class EmergencyCallException implements Exception {
  final String message;
  final String? code;

  EmergencyCallException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'EmergencyCallException [$code]: $message';
    }
    return 'EmergencyCallException: $message';
  }
}
