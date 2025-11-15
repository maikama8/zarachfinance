import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Platform channel for managing launcher mode
/// Allows setting the app as the default launcher to prevent bypass
class LauncherModeChannel {
  static const MethodChannel _channel =
      MethodChannel('com.zarachtech.finance/launcher');

  /// Enable launcher mode - sets app as default launcher
  /// This prevents users from bypassing the lock screen by pressing home button
  Future<void> enableLauncherMode() async {
    try {
      await _channel.invokeMethod('enableLauncherMode');
      developer.log(
        'Launcher mode enabled',
        name: 'LauncherModeChannel',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Error enabling launcher mode: ${e.message}',
        name: 'LauncherModeChannel',
        error: e,
      );
      throw LauncherModeException(
        'Failed to enable launcher mode: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error enabling launcher mode',
        name: 'LauncherModeChannel',
        error: e,
      );
      throw LauncherModeException('Unexpected error: $e');
    }
  }

  /// Disable launcher mode - removes app as default launcher
  /// This allows normal home button functionality
  Future<void> disableLauncherMode() async {
    try {
      await _channel.invokeMethod('disableLauncherMode');
      developer.log(
        'Launcher mode disabled',
        name: 'LauncherModeChannel',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Error disabling launcher mode: ${e.message}',
        name: 'LauncherModeChannel',
        error: e,
      );
      throw LauncherModeException(
        'Failed to disable launcher mode: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error disabling launcher mode',
        name: 'LauncherModeChannel',
        error: e,
      );
      throw LauncherModeException('Unexpected error: $e');
    }
  }

  /// Check if launcher mode is currently enabled
  Future<bool> isLauncherModeEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isLauncherModeEnabled');
      developer.log(
        'Launcher mode enabled: $result',
        name: 'LauncherModeChannel',
      );
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking launcher mode: ${e.message}',
        name: 'LauncherModeChannel',
        error: e,
      );
      throw LauncherModeException(
        'Failed to check launcher mode: ${e.message}',
        e.code,
      );
    } catch (e) {
      developer.log(
        'Unexpected error checking launcher mode',
        name: 'LauncherModeChannel',
        error: e,
      );
      throw LauncherModeException('Unexpected error: $e');
    }
  }
}

/// Exception thrown when launcher mode operations fail
class LauncherModeException implements Exception {
  final String message;
  final String? code;

  LauncherModeException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'LauncherModeException [$code]: $message';
    }
    return 'LauncherModeException: $message';
  }
}
