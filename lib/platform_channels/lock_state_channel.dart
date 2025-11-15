import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Platform channel for syncing lock state with native SharedPreferences
/// This allows the BootReceiver to check lock state on device boot
class LockStateChannel {
  static const MethodChannel _channel =
      MethodChannel('com.zarachtech.finance/lockstate');

  /// Sync lock state to native SharedPreferences
  /// This is needed so the BootReceiver can check lock state on boot
  Future<void> syncLockState(bool isLocked) async {
    try {
      await _channel.invokeMethod('syncLockState', {'isLocked': isLocked});
      developer.log(
        'Lock state synced to native: $isLocked',
        name: 'LockStateChannel',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Error syncing lock state: ${e.message}',
        name: 'LockStateChannel',
        error: e,
      );
      throw LockStateException(
        'Failed to sync lock state: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error syncing lock state',
        name: 'LockStateChannel',
        error: e,
      );
      throw LockStateException('Unexpected error: $e');
    }
  }

  /// Get lock state from native SharedPreferences
  Future<bool> getLockState() async {
    try {
      final bool result = await _channel.invokeMethod('getLockState');
      developer.log(
        'Lock state retrieved from native: $result',
        name: 'LockStateChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error getting lock state: ${e.message}',
        name: 'LockStateChannel',
        error: e,
      );
      throw LockStateException(
        'Failed to get lock state: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error getting lock state',
        name: 'LockStateChannel',
        error: e,
      );
      throw LockStateException('Unexpected error: $e');
    }
  }
}

/// Exception thrown when lock state operations fail
class LockStateException implements Exception {
  final String message;
  final String? code;

  LockStateException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'LockStateException [$code]: $message';
    }
    return 'LockStateException: $message';
  }
}
