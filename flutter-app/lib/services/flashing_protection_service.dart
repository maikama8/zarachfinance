import 'package:flutter/services.dart';

class FlashingProtectionService {
  static const MethodChannel _channel = MethodChannel('com.zarfinance.admin/flashing_protection');

  /// Start the flashing protection service
  static Future<bool> startService() async {
    try {
      final bool? success = await _channel.invokeMethod('startService');
      return success ?? false;
    } on PlatformException catch (e) {
      print("Failed to start flashing protection: '${e.message}'.");
      return false;
    }
  }

  /// Stop the flashing protection service
  static Future<bool> stopService() async {
    try {
      final bool? success = await _channel.invokeMethod('stopService');
      return success ?? false;
    } on PlatformException catch (e) {
      print("Failed to stop flashing protection: '${e.message}'.");
      return false;
    }
  }

  /// Check if service is running
  static Future<bool> isServiceRunning() async {
    try {
      final bool? running = await _channel.invokeMethod('isServiceRunning');
      return running ?? false;
    } on PlatformException catch (e) {
      print("Failed to check service status: '${e.message}'.");
      return false;
    }
  }

  /// Get tamper attempt history
  static Future<List<String>> getTamperAttempts() async {
    try {
      final List<dynamic>? attempts = await _channel.invokeMethod('getTamperAttempts');
      return attempts?.map((e) => e.toString()).toList() ?? [];
    } on PlatformException catch (e) {
      print("Failed to get tamper attempts: '${e.message}'.");
      return [];
    }
  }
}

