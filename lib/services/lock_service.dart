import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../platform_channels/device_admin_channel.dart';
import '../platform_channels/lock_state_channel.dart';
import '../platform_channels/launcher_mode_channel.dart';
import '../utils/tamper_guard.dart';
import 'database_helper.dart';
import 'background_tasks.dart';
import 'grace_period_manager.dart';
import '../models/payment_schedule.dart';
import '../models/device_config.dart';

/// Service for managing device lock state based on payment status
/// Handles locking/unlocking device and monitoring payment compliance
class LockService {
  final DeviceAdminChannel _adminChannel = DeviceAdminChannel();
  final LockStateChannel _lockStateChannel = LockStateChannel();
  final LauncherModeChannel _launcherModeChannel = LauncherModeChannel();
  final DatabaseHelper _db = DatabaseHelper();
  
  // Global navigator key for navigation from service
  static GlobalKey<NavigatorState>? navigatorKey;
  
  // Timer for periodic payment monitoring
  Timer? _monitoringTimer;
  
  // Lock delay configuration (24 hours)
  static const Duration lockDelay = Duration(hours: 24);
  
  /// Lock the device due to payment non-compliance
  /// Sets lock state in database, calls native lock, and navigates to lock screen
  Future<void> lockDevice() async {
    try {
      developer.log('Locking device', name: 'LockService');
      
      // Set lock state in database
      await _db.setLockState(true);
      
      // Sync lock state to native SharedPreferences for boot receiver
      await _lockStateChannel.syncLockState(true);
      
      // Enable launcher mode to prevent bypass
      await _launcherModeChannel.enableLauncherMode();
      
      // Store lock timestamp
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'lock_timestamp',
          value: DateTime.now().millisecondsSinceEpoch.toString(),
          lastUpdated: DateTime.now(),
        ),
      );
      
      // Call native lock
      await _adminChannel.lockDevice();
      
      // Navigate to lock screen
      _navigateToLockScreen();
      
      // Send status report on lock event
      BackgroundTasksService.sendStatusReportOnCriticalEvent('device_locked');
      
      developer.log('Device locked successfully', name: 'LockService');
    } catch (e) {
      developer.log(
        'Error locking device',
        name: 'LockService',
        error: e,
      );
      rethrow;
    }
  }
  
  /// Unlock the device after payment confirmation
  /// Clears lock state and navigates to home screen
  Future<void> unlockDevice() async {
    // Run tamper check before unlocking
    final canProceed = await TamperGuard.checkBeforeCriticalOperation('unlock');
    if (!canProceed) {
      developer.log(
        'Unlock blocked due to security violation',
        name: 'LockService',
      );
      throw Exception('Unlock blocked due to security violation');
    }
    
    try {
      developer.log('Unlocking device', name: 'LockService');
      
      // Clear lock state in database
      await _db.setLockState(false);
      
      // Sync lock state to native SharedPreferences for boot receiver
      await _lockStateChannel.syncLockState(false);
      
      // Disable launcher mode to restore normal functionality
      await _launcherModeChannel.disableLauncherMode();
      
      // Remove lock timestamp
      await _db.deleteDeviceConfig('lock_timestamp');
      
      // Remove missed payment timestamp if exists
      await _db.deleteDeviceConfig('missed_payment_timestamp');
      
      // Call native unlock
      await _adminChannel.unlockDevice();
      
      // Navigate to home screen
      _navigateToHome();
      
      // Send status report on unlock event
      BackgroundTasksService.sendStatusReportOnCriticalEvent('device_unlocked');
      
      developer.log('Device unlocked successfully', name: 'LockService');
    } catch (e) {
      developer.log(
        'Error unlocking device',
        name: 'LockService',
        error: e,
      );
      rethrow;
    }
  }
  
  /// Monitor payment status and trigger lock if payment is overdue
  /// Implements 24-hour delay before locking after missed payment
  /// Also considers 48-hour grace period for network verification failures
  Future<void> monitorPaymentStatus() async {
    try {
      developer.log('Checking payment status', name: 'LockService');
      
      // Get overdue payments
      final overduePayments = await _db.getOverduePayments();
      
      if (overduePayments.isEmpty) {
        developer.log('No overdue payments', name: 'LockService');
        // Clear missed payment timestamp if it exists
        await _db.deleteDeviceConfig('missed_payment_timestamp');
        return;
      }
      
      developer.log(
        'Found ${overduePayments.length} overdue payment(s)',
        name: 'LockService',
      );
      
      // Check if device is already locked
      final isLocked = await _db.getLockState();
      if (isLocked) {
        developer.log('Device already locked', name: 'LockService');
        return;
      }

      // Check grace period status (48-hour grace for network failures)
      final gracePeriodManager = GracePeriodManager();
      final gracePeriodStatus = await gracePeriodManager.getGracePeriodStatus();
      
      // If grace period is active and not expired, don't lock yet
      if (gracePeriodStatus.isActive && !gracePeriodStatus.hasExpired) {
        developer.log(
          'Grace period active, delaying lock. Remaining: ${gracePeriodStatus.remainingTime}',
          name: 'LockService',
        );
        return;
      }
      
      // Get or set missed payment timestamp
      final missedPaymentConfig = await _db.getDeviceConfig('missed_payment_timestamp');
      DateTime missedPaymentTime;
      
      if (missedPaymentConfig == null) {
        // First time detecting overdue payment
        missedPaymentTime = DateTime.now();
        await _db.insertDeviceConfig(
          DeviceConfig(
            key: 'missed_payment_timestamp',
            value: missedPaymentTime.millisecondsSinceEpoch.toString(),
            lastUpdated: DateTime.now(),
          ),
        );
        developer.log(
          'Missed payment detected, starting 24-hour grace period',
          name: 'LockService',
        );
      } else {
        // Get existing timestamp
        missedPaymentTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(missedPaymentConfig.value),
        );
      }
      
      // Check if 24 hours have passed since missed payment
      final timeSinceMissed = DateTime.now().difference(missedPaymentTime);
      
      if (timeSinceMissed >= lockDelay) {
        developer.log(
          '24-hour grace period expired, locking device',
          name: 'LockService',
        );
        await lockDevice();
      } else {
        final remainingTime = lockDelay - timeSinceMissed;
        developer.log(
          'Grace period active, ${remainingTime.inHours} hours remaining',
          name: 'LockService',
        );
      }
    } catch (e) {
      developer.log(
        'Error monitoring payment status',
        name: 'LockService',
        error: e,
      );
    }
  }
  
  /// Start periodic monitoring of payment status
  /// Checks every hour for overdue payments
  void startMonitoring() {
    developer.log('Starting payment monitoring', name: 'LockService');
    
    // Stop existing timer if any
    stopMonitoring();
    
    // Run initial check
    monitorPaymentStatus();
    
    // Set up periodic check (every hour)
    _monitoringTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => monitorPaymentStatus(),
    );
  }
  
  /// Stop periodic monitoring
  void stopMonitoring() {
    if (_monitoringTimer != null) {
      developer.log('Stopping payment monitoring', name: 'LockService');
      _monitoringTimer?.cancel();
      _monitoringTimer = null;
    }
  }
  
  /// Check current lock state
  Future<bool> isDeviceLocked() async {
    return await _db.getLockState();
  }
  
  /// Get time remaining before device will be locked
  /// Returns null if no overdue payments or already locked
  Future<Duration?> getTimeUntilLock() async {
    final isLocked = await _db.getLockState();
    if (isLocked) return null;
    
    final overduePayments = await _db.getOverduePayments();
    if (overduePayments.isEmpty) return null;
    
    final missedPaymentConfig = await _db.getDeviceConfig('missed_payment_timestamp');
    if (missedPaymentConfig == null) return lockDelay;
    
    final missedPaymentTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(missedPaymentConfig.value),
    );
    
    final timeSinceMissed = DateTime.now().difference(missedPaymentTime);
    final remaining = lockDelay - timeSinceMissed;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// Navigate to lock screen
  void _navigateToLockScreen() {
    if (navigatorKey?.currentState != null) {
      // Import will be added when lock screen is created
      navigatorKey!.currentState!.pushNamedAndRemoveUntil(
        '/lock',
        (route) => false,
      );
    }
  }
  
  /// Navigate to home screen
  void _navigateToHome() {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }
  
  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
