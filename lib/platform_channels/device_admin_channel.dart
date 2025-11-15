import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Platform channel wrapper for Device Admin operations
/// Provides Flutter interface to native Android Device Policy Manager
class DeviceAdminChannel {
  static const MethodChannel _channel =
      MethodChannel('com.zarachtech.finance/admin');

  /// Check if device admin is currently active
  /// Returns true if the app has device administrator privileges
  Future<bool> isAdminActive() async {
    try {
      final bool result = await _channel.invokeMethod('isAdminActive');
      developer.log('Device admin active: $result', name: 'DeviceAdminChannel');
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking admin status: ${e.message}',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException(
        'Failed to check admin status: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error checking admin status',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException('Unexpected error: $e');
    }
  }

  /// Request device admin privileges from user
  /// Opens system settings to enable device admin
  /// Throws [DeviceAdminException] if the request fails
  Future<void> requestAdminPrivileges() async {
    try {
      await _channel.invokeMethod('requestAdminPrivileges');
      developer.log(
        'Admin privileges requested',
        name: 'DeviceAdminChannel',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Error requesting admin privileges: ${e.message}',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException(
        'Failed to request admin privileges: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error requesting admin privileges',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException('Unexpected error: $e');
    }
  }

  /// Lock the device immediately
  /// Requires device admin to be active
  /// Throws [DeviceAdminException] if admin is not active or lock fails
  Future<void> lockDevice() async {
    try {
      await _channel.invokeMethod('lockDevice');
      developer.log('Device locked', name: 'DeviceAdminChannel');
    } on PlatformException catch (e) {
      developer.log(
        'Error locking device: ${e.message}',
        name: 'DeviceAdminChannel',
        error: e,
      );
      
      if (e.code == 'ERROR' && e.message?.contains('admin not active') == true) {
        throw DeviceAdminException(
          'Cannot lock device: Device admin is not active',
          'ADMIN_NOT_ACTIVE',
        );
      }
      
      throw DeviceAdminException(
        'Failed to lock device: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error locking device',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException('Unexpected error: $e');
    }
  }

  /// Unlock the device (remove password/restrictions)
  /// Requires device admin to be active
  /// Throws [DeviceAdminException] if admin is not active or unlock fails
  Future<void> unlockDevice() async {
    try {
      await _channel.invokeMethod('unlockDevice');
      developer.log('Device unlocked', name: 'DeviceAdminChannel');
    } on PlatformException catch (e) {
      developer.log(
        'Error unlocking device: ${e.message}',
        name: 'DeviceAdminChannel',
        error: e,
      );
      
      if (e.code == 'ERROR' && e.message?.contains('admin not active') == true) {
        throw DeviceAdminException(
          'Cannot unlock device: Device admin is not active',
          'ADMIN_NOT_ACTIVE',
        );
      }
      
      throw DeviceAdminException(
        'Failed to unlock device: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error unlocking device',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException('Unexpected error: $e');
    }
  }

  /// Enable or disable factory reset protection
  /// @param disable true to disable factory reset, false to enable it
  /// Requires device admin to be active
  /// Note: Full factory reset protection requires device owner mode
  /// Throws [DeviceAdminException] if admin is not active or operation fails
  Future<void> disableFactoryReset({required bool disable}) async {
    try {
      await _channel.invokeMethod('disableFactoryReset', {'disable': disable});
      developer.log(
        'Factory reset protection set: disable=$disable',
        name: 'DeviceAdminChannel',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Error setting factory reset protection: ${e.message}',
        name: 'DeviceAdminChannel',
        error: e,
      );
      
      if (e.code == 'ERROR' && e.message?.contains('admin not active') == true) {
        throw DeviceAdminException(
          'Cannot modify factory reset: Device admin is not active',
          'ADMIN_NOT_ACTIVE',
        );
      }
      
      throw DeviceAdminException(
        'Failed to modify factory reset protection: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error setting factory reset protection',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException('Unexpected error: $e');
    }
  }

  /// Validate release code and enable factory reset if valid
  /// @param code The release code to validate
  /// Returns true if code is valid and factory reset is now enabled
  /// Throws [DeviceAdminException] if validation fails
  Future<bool> validateReleaseCode(String code) async {
    try {
      final bool result = await _channel.invokeMethod('validateReleaseCode', {'code': code});
      developer.log(
        'Release code validation result: $result',
        name: 'DeviceAdminChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error validating release code: ${e.message}',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException(
        'Failed to validate release code: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error validating release code',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException('Unexpected error: $e');
    }
  }

  /// Check if factory reset is currently blocked
  /// Returns true if factory reset is blocked (payment pending)
  /// Throws [DeviceAdminException] if check fails
  Future<bool> isResetBlocked() async {
    try {
      final bool result = await _channel.invokeMethod('isResetBlocked');
      developer.log(
        'Factory reset blocked: $result',
        name: 'DeviceAdminChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking reset block status: ${e.message}',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException(
        'Failed to check reset block status: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error checking reset block status',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException('Unexpected error: $e');
    }
  }

  /// Allow device admin deactivation
  /// Opens device settings to allow user to deactivate device admin
  /// Should only be called after full payment and release code validation
  /// Throws [DeviceAdminException] if operation fails
  Future<void> allowAdminDeactivation() async {
    try {
      await _channel.invokeMethod('allowAdminDeactivation');
      developer.log(
        'Device admin deactivation allowed',
        name: 'DeviceAdminChannel',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Error allowing admin deactivation: ${e.message}',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException(
        'Failed to allow admin deactivation: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error allowing admin deactivation',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException('Unexpected error: $e');
    }
  }

  /// Mark device as released in native storage
  /// This sets a flag that allows device admin deactivation
  /// Throws [DeviceAdminException] if operation fails
  Future<void> markDeviceAsReleased() async {
    try {
      await _channel.invokeMethod('markDeviceAsReleased');
      developer.log(
        'Device marked as released',
        name: 'DeviceAdminChannel',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Error marking device as released: ${e.message}',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException(
        'Failed to mark device as released: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error marking device as released',
        name: 'DeviceAdminChannel',
        error: e,
      );
      throw DeviceAdminException('Unexpected error: $e');
    }
  }
}

/// Exception thrown when device admin operations fail
class DeviceAdminException implements Exception {
  final String message;
  final String? code;

  DeviceAdminException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'DeviceAdminException [$code]: $message';
    }
    return 'DeviceAdminException: $message';
  }
}
