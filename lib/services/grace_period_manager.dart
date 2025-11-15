import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'secure_storage_service.dart';
import '../models/device_config.dart';

/// Manages grace period for payment verification failures
/// Implements 48-hour grace period when payment status cannot be verified due to network issues
class GracePeriodManager {
  static final GracePeriodManager _instance = GracePeriodManager._internal();
  final DatabaseHelper _db = DatabaseHelper();
  final SecureStorageService _secureStorage = SecureStorageService();

  // Grace period configuration
  static const Duration gracePeriodDuration = Duration(hours: 48);
  static const String _gracePeriodStartKey = 'grace_period_start';
  static const String _gracePeriodActiveKey = 'grace_period_active';
  static const String _lastSuccessfulVerificationKey = 'last_successful_verification';

  factory GracePeriodManager() {
    return _instance;
  }

  GracePeriodManager._internal();

  /// Start grace period for payment verification failure
  Future<void> startGracePeriod() async {
    try {
      final now = DateTime.now();
      
      // Check if grace period is already active
      final isActive = await isGracePeriodActive();
      if (isActive) {
        if (kDebugMode) {
          debugPrint('Grace period already active');
        }
        return;
      }

      // Store grace period start time
      await _secureStorage.storeCustomValue(
        _gracePeriodStartKey,
        now.toIso8601String(),
      );
      await _secureStorage.storeCustomValue(_gracePeriodActiveKey, 'true');

      // Store in database as well for redundancy
      await _db.insertDeviceConfig(DeviceConfig(
        key: _gracePeriodStartKey,
        value: now.toIso8601String(),
        lastUpdated: now,
      ));
      await _db.insertDeviceConfig(DeviceConfig(
        key: _gracePeriodActiveKey,
        value: 'true',
        lastUpdated: now,
      ));

      if (kDebugMode) {
        debugPrint('Grace period started at $now');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to start grace period: $e');
      }
    }
  }

  /// End grace period (called when verification succeeds)
  Future<void> endGracePeriod() async {
    try {
      final now = DateTime.now();

      // Clear grace period flags
      await _secureStorage.deleteCustomValue(_gracePeriodStartKey);
      await _secureStorage.deleteCustomValue(_gracePeriodActiveKey);

      // Update database
      await _db.deleteDeviceConfig(_gracePeriodStartKey);
      await _db.deleteDeviceConfig(_gracePeriodActiveKey);

      // Store last successful verification time
      await _secureStorage.storeCustomValue(
        _lastSuccessfulVerificationKey,
        now.toIso8601String(),
      );
      await _db.insertDeviceConfig(DeviceConfig(
        key: _lastSuccessfulVerificationKey,
        value: now.toIso8601String(),
        lastUpdated: now,
      ));

      if (kDebugMode) {
        debugPrint('Grace period ended at $now');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to end grace period: $e');
      }
    }
  }

  /// Check if grace period is currently active
  Future<bool> isGracePeriodActive() async {
    try {
      final activeStr = await _secureStorage.getCustomValue(_gracePeriodActiveKey);
      return activeStr == 'true';
    } catch (e) {
      // Fallback to database
      try {
        final config = await _db.getDeviceConfig(_gracePeriodActiveKey);
        return config?.value == 'true';
      } catch (e) {
        return false;
      }
    }
  }

  /// Check if grace period has expired
  Future<bool> hasGracePeriodExpired() async {
    try {
      final isActive = await isGracePeriodActive();
      if (!isActive) {
        return false;
      }

      final startTimeStr = await _secureStorage.getCustomValue(_gracePeriodStartKey);
      if (startTimeStr == null) {
        // Try database
        final config = await _db.getDeviceConfig(_gracePeriodStartKey);
        if (config == null) {
          return false;
        }
        final startTime = DateTime.tryParse(config.value);
        if (startTime == null) {
          return false;
        }
        
        final now = DateTime.now();
        final elapsed = now.difference(startTime);
        return elapsed >= gracePeriodDuration;
      }

      final startTime = DateTime.tryParse(startTimeStr);
      if (startTime == null) {
        return false;
      }

      final now = DateTime.now();
      final elapsed = now.difference(startTime);
      return elapsed >= gracePeriodDuration;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to check grace period expiration: $e');
      }
      return false;
    }
  }

  /// Get remaining grace period time
  Future<Duration?> getRemainingGracePeriod() async {
    try {
      final isActive = await isGracePeriodActive();
      if (!isActive) {
        return null;
      }

      final startTimeStr = await _secureStorage.getCustomValue(_gracePeriodStartKey);
      if (startTimeStr == null) {
        // Try database
        final config = await _db.getDeviceConfig(_gracePeriodStartKey);
        if (config == null) {
          return null;
        }
        final startTime = DateTime.tryParse(config.value);
        if (startTime == null) {
          return null;
        }
        
        final now = DateTime.now();
        final elapsed = now.difference(startTime);
        final remaining = gracePeriodDuration - elapsed;
        return remaining.isNegative ? Duration.zero : remaining;
      }

      final startTime = DateTime.tryParse(startTimeStr);
      if (startTime == null) {
        return null;
      }

      final now = DateTime.now();
      final elapsed = now.difference(startTime);
      final remaining = gracePeriodDuration - elapsed;
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get remaining grace period: $e');
      }
      return null;
    }
  }

  /// Get grace period status for display
  Future<GracePeriodStatus> getGracePeriodStatus() async {
    final isActive = await isGracePeriodActive();
    if (!isActive) {
      return GracePeriodStatus(
        isActive: false,
        hasExpired: false,
        remainingTime: null,
        startTime: null,
      );
    }

    final hasExpired = await hasGracePeriodExpired();
    final remainingTime = await getRemainingGracePeriod();
    
    DateTime? startTime;
    final startTimeStr = await _secureStorage.getCustomValue(_gracePeriodStartKey);
    if (startTimeStr != null) {
      startTime = DateTime.tryParse(startTimeStr);
    }

    return GracePeriodStatus(
      isActive: true,
      hasExpired: hasExpired,
      remainingTime: remainingTime,
      startTime: startTime,
    );
  }

  /// Get last successful verification time
  Future<DateTime?> getLastSuccessfulVerification() async {
    try {
      final timeStr = await _secureStorage.getCustomValue(_lastSuccessfulVerificationKey);
      if (timeStr != null) {
        return DateTime.tryParse(timeStr);
      }

      // Try database
      final config = await _db.getDeviceConfig(_lastSuccessfulVerificationKey);
      if (config != null) {
        return DateTime.tryParse(config.value);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get last successful verification: $e');
      }
      return null;
    }
  }

  /// Reset grace period (for testing or manual intervention)
  Future<void> resetGracePeriod() async {
    try {
      await _secureStorage.deleteCustomValue(_gracePeriodStartKey);
      await _secureStorage.deleteCustomValue(_gracePeriodActiveKey);
      await _db.deleteDeviceConfig(_gracePeriodStartKey);
      await _db.deleteDeviceConfig(_gracePeriodActiveKey);

      if (kDebugMode) {
        debugPrint('Grace period reset');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to reset grace period: $e');
      }
    }
  }
}

/// Grace period status data class
class GracePeriodStatus {
  final bool isActive;
  final bool hasExpired;
  final Duration? remainingTime;
  final DateTime? startTime;

  GracePeriodStatus({
    required this.isActive,
    required this.hasExpired,
    this.remainingTime,
    this.startTime,
  });

  String getDisplayMessage() {
    if (!isActive) {
      return '';
    }

    if (hasExpired) {
      return 'Grace period has expired. Device will be locked.';
    }

    if (remainingTime != null) {
      final hours = remainingTime!.inHours;
      final minutes = remainingTime!.inMinutes % 60;
      return 'Unable to verify payment. Grace period: ${hours}h ${minutes}m remaining.';
    }

    return 'Unable to verify payment. Please check your connection.';
  }

  @override
  String toString() {
    return 'GracePeriodStatus{isActive: $isActive, hasExpired: $hasExpired, remainingTime: $remainingTime, startTime: $startTime}';
  }
}
