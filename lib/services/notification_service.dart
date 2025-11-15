import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Service for managing payment reminder notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service with Android notification channels
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    _initialized = true;
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    // High priority channel for payment reminders
    const paymentRemindersChannel = AndroidNotificationChannel(
      'payment_reminders',
      'Payment Reminders',
      description: 'Notifications for upcoming payment due dates',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Default priority channel for payment confirmations
    const paymentConfirmationsChannel = AndroidNotificationChannel(
      'payment_confirmations',
      'Payment Confirmations',
      description: 'Notifications for payment confirmations and updates',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(paymentRemindersChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(paymentConfirmationsChannel);
  }

  /// Schedule payment reminder notifications
  /// Schedules notifications 24 hours and 6 hours before the due date
  Future<void> schedulePaymentReminder(DateTime dueDate, double amount) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    final reminder24h = dueDate.subtract(const Duration(hours: 24));
    final reminder6h = dueDate.subtract(const Duration(hours: 6));

    // Schedule 24-hour reminder if it's in the future
    if (reminder24h.isAfter(now)) {
      await _scheduleNotification(
        id: dueDate.millisecondsSinceEpoch ~/ 1000, // Unique ID based on due date
        title: 'Payment Due Tomorrow',
        body: 'Your payment of ₦${amount.toStringAsFixed(2)} is due tomorrow',
        scheduledDate: reminder24h,
        channelId: 'payment_reminders',
      );
    }

    // Schedule 6-hour reminder if it's in the future
    if (reminder6h.isAfter(now)) {
      await _scheduleNotification(
        id: (dueDate.millisecondsSinceEpoch ~/ 1000) + 1, // Unique ID
        title: 'Payment Due Soon',
        body: 'Your payment of ₦${amount.toStringAsFixed(2)} is due in 6 hours',
        scheduledDate: reminder6h,
        channelId: 'payment_reminders',
      );
    }
  }

  /// Schedule a notification at a specific time
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    String? payload,
  }) async {
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'payment_reminders'
          ? 'Payment Reminders'
          : 'Payment Confirmations',
      channelDescription: channelId == 'payment_reminders'
          ? 'Notifications for upcoming payment due dates'
          : 'Notifications for payment confirmations and updates',
      importance: channelId == 'payment_reminders'
          ? Importance.high
          : Importance.defaultImportance,
      priority: channelId == 'payment_reminders'
          ? Priority.high
          : Priority.defaultPriority,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Show overdue payment notification
  Future<void> showOverdueNotification(double amount) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'payment_reminders',
      'Payment Reminders',
      channelDescription: 'Notifications for upcoming payment due dates',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'pay_now',
          'Pay Now',
          showsUserInterface: true,
        ),
      ],
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999999, // Fixed ID for overdue notifications
      'Payment Overdue',
      'Your payment of ₦${amount.toStringAsFixed(2)} is overdue. Please pay now to avoid device lock.',
      notificationDetails,
      payload: 'payment_screen',
    );
  }

  /// Show payment confirmation notification
  Future<void> showPaymentConfirmation(double amount, double newBalance) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'payment_confirmations',
      'Payment Confirmations',
      channelDescription: 'Notifications for payment confirmations and updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Payment Confirmed',
      'Payment of ₦${amount.toStringAsFixed(2)} received. Remaining balance: ₦${newBalance.toStringAsFixed(2)}',
      notificationDetails,
    );
  }

  /// Handle notification tap events
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Handle deep linking based on payload
      _handleDeepLink(response.payload!);
    }

    // Handle notification actions
    if (response.actionId == 'pay_now') {
      _handleDeepLink('payment_screen');
    }
  }

  /// Handle deep linking to screens
  void _handleDeepLink(String route) {
    // Store the route for the app to handle
    // This will be picked up by the main app navigation
    _pendingRoute = route;
  }

  String? _pendingRoute;

  /// Get and clear pending route for navigation
  String? getPendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
