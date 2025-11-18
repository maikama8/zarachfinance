import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/api_client.dart';
import '../utils/config.dart';

class PaymentReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> checkAndSendReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';
      
      if (deviceId.isEmpty) {
        return;
      }

      final schedule = await ApiClient.getPaymentSchedule(deviceId);
      final now = DateTime.now();

      for (final item in schedule.schedule) {
        if (item.status == 'paid') {
          continue;
        }

        final dueDate = DateTime.fromMillisecondsSinceEpoch(item.dueDate);
        final hoursUntilDue = dueDate.difference(now).inHours;

        if (hoursUntilDue <= 0) {
          // Overdue
          await _showReminderNotification(
            'Payment Overdue!',
            'Your payment of ₦${item.amount.toStringAsFixed(2)} is overdue. Please make payment immediately.',
          );
        } else if (hoursUntilDue <= Config.paymentReminder6H.inHours) {
          // 6 hours before
          await _showReminderNotification(
            'Payment Due Soon',
            'Your payment of ₦${item.amount.toStringAsFixed(2)} is due in $hoursUntilDue hours.',
          );
        } else if (hoursUntilDue <= Config.paymentReminder24H.inHours) {
          // 24 hours before
          await _showReminderNotification(
            'Payment Reminder',
            'Your payment of ₦${item.amount.toStringAsFixed(2)} is due in $hoursUntilDue hours.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking payment reminders: $e');
    }
  }

  static Future<void> _showReminderNotification(
    String title,
    String body,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'payment_reminders',
      'Payment Reminders',
      channelDescription: 'Reminders about upcoming payments',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
    );
  }
}

