import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/api_client.dart';
import '../services/device_admin_service.dart';

class PaymentVerificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  static Future<void> checkPaymentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';
      
      if (deviceId.isEmpty) {
        return;
      }

      final status = await ApiClient.getPaymentStatus(deviceId);

      // Update local storage
      await prefs.setBool('is_fully_paid', status.isFullyPaid);
      await prefs.setBool('is_payment_overdue', status.isPaymentOverdue);

      if (status.isPaymentOverdue && !status.isFullyPaid) {
        // Lock the device
        await _lockDevice();
      } else if (!status.isPaymentOverdue && !status.isFullyPaid) {
        // Unlock if payment is up to date
        await prefs.setBool('is_locked', false);
      }

      if (status.isFullyPaid) {
        // Allow device admin removal
        await prefs.setBool('is_fully_paid', true);
        await prefs.setBool('is_locked', false);
      }
    } catch (e) {
      // Handle error - queue for retry
      debugPrint('Error checking payment status: $e');
    }
  }

  static Future<void> _lockDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_locked', true);

      // Lock device using Device Admin
      final isActive = await DeviceAdminService.isActive();
      if (isActive) {
        await DeviceAdminService.lockDevice();
      }

      // Show notification
      await _showLockNotification();
    } catch (e) {
      debugPrint('Error locking device: $e');
    }
  }

  static Future<void> _showLockNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'payment_channel',
      'Payment Notifications',
      channelDescription: 'Notifications about payment status',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      'Device Locked',
      'Your device has been locked due to overdue payment. Please make payment to unlock.',
      notificationDetails,
    );
  }
}

