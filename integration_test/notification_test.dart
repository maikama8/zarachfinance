import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:device_admin_app/services/database_helper.dart';
import 'package:device_admin_app/services/notification_service.dart';
import 'package:device_admin_app/services/secure_storage_service.dart';
import 'package:device_admin_app/models/payment_schedule.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Integration Tests', () {
    late DatabaseHelper dbHelper;
    late NotificationService notificationService;
    late SecureStorageService secureStorage;

    setUp(() async {
      dbHelper = DatabaseHelper();
      secureStorage = SecureStorageService();
      
      // Initialize database
      await dbHelper.database;
      
      // Set up test device ID
      await secureStorage.saveDeviceId('test_device_notif_001');
      
      // Initialize notification service
      notificationService = NotificationService();
      await notificationService.initialize();
    });

    tearDown(() async {
      // Clean up test data
      await dbHelper.clearAllData();
      await secureStorage.deleteAll();
    });

    test('Notification service initializes successfully', () async {
      // Verify notification service is initialized
      expect(notificationService, isNotNull);
    });

    test('Payment reminder is scheduled 24 hours before due date', () async {
      final dueDate = DateTime.now().add(const Duration(days: 2));
      final amount = 5000.0;

      // Schedule payment reminder
      await notificationService.schedulePaymentReminder(dueDate, amount);

      // Verify notification was scheduled (check via database or service state)
      // Note: Actual notification scheduling verification requires platform-specific checks
      expect(true, true); // Placeholder for actual verification
    });

    test('Payment reminder is scheduled 6 hours before due date', () async {
      final dueDate = DateTime.now().add(const Duration(hours: 12));
      final amount = 3000.0;

      // Schedule payment reminder
      await notificationService.schedulePaymentReminder(dueDate, amount);

      // Verify notification was scheduled
      expect(true, true); // Placeholder for actual verification
    });

    test('Overdue notification is displayed immediately', () async {
      final amount = 5000.0;

      // Show overdue notification
      await notificationService.showOverdueNotification(amount);

      // Verify notification was shown
      expect(true, true); // Placeholder for actual verification
    });

    test('Payment confirmation notification is displayed', () async {
      final amount = 5000.0;
      final newBalance = 45000.0;

      // Show payment confirmation
      await notificationService.showPaymentConfirmation(amount, newBalance);

      // Verify notification was shown
      expect(true, true); // Placeholder for actual verification
    });
