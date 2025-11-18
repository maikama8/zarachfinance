import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class DeviceAdminService {
  static const MethodChannel _channel = MethodChannel('com.zarfinance.admin/device_admin');

  /// Check if device admin is currently active
  static Future<bool> isActive() async {
    try {
      final bool isActive = await _channel.invokeMethod('isDeviceAdminActive');
      return isActive;
    } catch (e) {
      debugPrint('Error checking device admin status: $e');
      return false;
    }
  }

  /// Request device admin privileges
  static Future<bool> requestDeviceAdmin() async {
    try {
      final bool result = await _channel.invokeMethod('requestDeviceAdmin');
      return result;
    } catch (e) {
      debugPrint('Error requesting device admin: $e');
      return false;
    }
  }

  /// Lock the device (requires device admin to be active)
  static Future<bool> lockDevice() async {
    try {
      final bool result = await _channel.invokeMethod('lockDevice');
      return result;
    } catch (e) {
      debugPrint('Error locking device: $e');
      return false;
    }
  }

  /// Get device ID
  static Future<String> getDeviceId() async {
    try {
      final String deviceId = await _channel.invokeMethod('getDeviceId');
      return deviceId;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return '';
    }
  }
}

