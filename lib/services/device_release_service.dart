import 'package:zaracfinance/platform_channels/device_admin_channel.dart';
import 'package:zaracfinance/services/database_helper.dart';
import 'package:zaracfinance/services/secure_storage_service.dart';
import 'package:zaracfinance/services/device_api_service.dart';
import 'dart:developer' as developer;

/// Service class for handling device release after full payment
class DeviceReleaseService {
  final DeviceAdminChannel _adminChannel = DeviceAdminChannel();
  final DatabaseHelper _db = DatabaseHelper();
  final SecureStorageService _secureStorage = SecureStorageService();
  final DeviceApiService _deviceApi = DeviceApiService();

  /// Release device after successful release code validation
  /// This method performs all necessary cleanup and removes restrictions
  Future<void> releaseDevice() async {
    developer.log('Starting device release process', name: 'DeviceReleaseService');

    try {
      // Step 1: Mark device as released (before clearing data)
      // This sets a flag that allows device admin deactivation
      developer.log('Marking device as released', name: 'DeviceReleaseService');
      await _markDeviceAsReleased();

      // Step 2: Disable factory reset protection
      developer.log('Disabling factory reset protection', name: 'DeviceReleaseService');
      await _adminChannel.disableFactoryReset(disable: false);

      // Step 3: Unregister device from backend
      developer.log('Unregistering device from backend', name: 'DeviceReleaseService');
      try {
        final deviceId = await _secureStorage.getDeviceId();
        if (deviceId != null && deviceId.isNotEmpty) {
          await _deviceApi.unregisterDevice(deviceId);
        }
      } catch (e) {
        // Log error but continue with release process
        developer.log(
          'Failed to unregister device from backend: $e',
          name: 'DeviceReleaseService',
          error: e,
        );
      }

      // Step 4: Clear all local database data
      developer.log('Clearing local database', name: 'DeviceReleaseService');
      await _db.clearAllData();

      // Step 5: Clear all secure storage
      developer.log('Clearing secure storage', name: 'DeviceReleaseService');
      await _secureStorage.clearAllSecureStorage();

      developer.log('Device release process completed successfully', name: 'DeviceReleaseService');
    } catch (e) {
      developer.log(
        'Error during device release process',
        name: 'DeviceReleaseService',
        error: e,
      );
      rethrow;
    }
  }

  /// Mark device as released in native shared preferences
  /// This allows device admin deactivation
  Future<void> _markDeviceAsReleased() async {
    // We need to call a native method to set the shared preference
    // Let's add this to the device admin channel
    await _adminChannel.markDeviceAsReleased();
  }

  /// Open device admin settings to allow user to deactivate
  Future<void> openAdminDeactivationSettings() async {
    developer.log('Opening admin deactivation settings', name: 'DeviceReleaseService');
    await _adminChannel.allowAdminDeactivation();
  }

  /// Check if device is released
  Future<bool> isDeviceReleased() async {
    try {
      final config = await _db.getDeviceConfig('device_released');
      return config?.value.toLowerCase() == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Get release status message
  Future<String> getReleaseStatusMessage() async {
    final isReleased = await isDeviceReleased();
    if (isReleased) {
      return 'Your device has been successfully released. All restrictions have been removed.';
    } else {
      return 'Device is still under financing agreement.';
    }
  }
}
