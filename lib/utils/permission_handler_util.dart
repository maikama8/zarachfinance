import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// Utility class for handling app permissions
class PermissionHandlerUtil {
  /// Check if device admin permission is required and available
  static Future<bool> isDeviceAdminActive() async {
    // This should be checked via platform channel
    // Placeholder for now - actual implementation in DeviceAdminChannel
    return false;
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  static Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }

  /// Check if notification permission is granted
  /// Note: Only required for Android 13+ (API 33+)
  static Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    // iOS handles notifications differently
    return true;
  }

  /// Request notification permission
  /// Note: Only required for Android 13+ (API 33+)
  static Future<PermissionStatus> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      return await Permission.notification.request();
    }
    // iOS handles notifications differently
    return PermissionStatus.granted;
  }

  /// Check if all critical permissions are granted
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await hasLocationPermission(),
      'notification': await hasNotificationPermission(),
    };
  }

  /// Open app settings for manual permission management
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Get user-friendly permission status message
  static String getPermissionStatusMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.restricted:
        return 'Permission restricted';
      case PermissionStatus.limited:
        return 'Permission limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied. Please enable it in settings.';
      case PermissionStatus.provisional:
        return 'Permission provisional';
      default:
        return 'Unknown permission status';
    }
  }
}
