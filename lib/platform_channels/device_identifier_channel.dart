import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Platform channel wrapper for Device Identifier operations
/// Provides Flutter interface to native Android device information
class DeviceIdentifierChannel {
  static const MethodChannel _channel =
      MethodChannel('com.zarachtech.finance/device_identifier');

  /// Get comprehensive device information
  /// Returns a map with device identifiers and hardware info
  /// Keys: imei, androidId, model, manufacturer, brand, product, osVersion, sdkVersion, hardware, board
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('getDeviceInfo');
      
      // Convert to Map<String, String>
      final deviceInfo = result.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      
      developer.log(
        'Device info retrieved: ${deviceInfo.keys.join(", ")}',
        name: 'DeviceIdentifierChannel',
      );
      
      return deviceInfo;
    } on PlatformException catch (e) {
      developer.log(
        'Error getting device info: ${e.message}',
        name: 'DeviceIdentifierChannel',
        error: e,
      );
      throw DeviceIdentifierException(
        'Failed to get device info: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error getting device info',
        name: 'DeviceIdentifierChannel',
        error: e,
      );
      throw DeviceIdentifierException('Unexpected error: $e');
    }
  }

  /// Get IMEI or alternative unique identifier
  /// For Android 10+, returns Android ID as IMEI access is restricted
  /// Returns the device identifier string
  Future<String> getIMEI() async {
    try {
      final String result = await _channel.invokeMethod('getIMEI');
      developer.log(
        'IMEI/Identifier retrieved',
        name: 'DeviceIdentifierChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error getting IMEI: ${e.message}',
        name: 'DeviceIdentifierChannel',
        error: e,
      );
      throw DeviceIdentifierException(
        'Failed to get IMEI: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error getting IMEI',
        name: 'DeviceIdentifierChannel',
        error: e,
      );
      throw DeviceIdentifierException('Unexpected error: $e');
    }
  }

  /// Get Android ID (unique identifier for the device)
  /// This is available on all Android versions and doesn't require permissions
  /// Returns the Android ID string
  Future<String> getAndroidId() async {
    try {
      final String result = await _channel.invokeMethod('getAndroidId');
      developer.log(
        'Android ID retrieved',
        name: 'DeviceIdentifierChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error getting Android ID: ${e.message}',
        name: 'DeviceIdentifierChannel',
        error: e,
      );
      throw DeviceIdentifierException(
        'Failed to get Android ID: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error getting Android ID',
        name: 'DeviceIdentifierChannel',
        error: e,
      );
      throw DeviceIdentifierException('Unexpected error: $e');
    }
  }
}

/// Exception thrown when device identifier operations fail
class DeviceIdentifierException implements Exception {
  final String message;
  final String? code;

  DeviceIdentifierException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'DeviceIdentifierException [$code]: $message';
    }
    return 'DeviceIdentifierException: $message';
  }
}
