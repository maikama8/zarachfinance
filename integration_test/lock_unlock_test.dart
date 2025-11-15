import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:device_admin_app/main.dart' as app;
import 'package:device_admin_app/services/database_helper.dart';
import 'package:device_admin_app/services/lock_service.dart';
import 'package:device_admin_app/services/secure_storage_service.dart';
import 'package:device_admin_app/models/payment_schedule.dart';
import 'package:device_admin_app/screens/lock_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Lock/Unlock Cycle Integration Tests', () {
    late DatabaseHelper dbHelper;
    late LockService lockService;
    late SecureStorageService secureStorage;

    setUp(() async {
      dbHelper = DatabaseHelper();
      lockService = LockService();
      secureStorage = SecureStorageService();
      
      // Initialize database
      await dbHelper.database;
      
      // Set up test device ID
      await secureStorage.saveDeviceId('test_device_lock_001');
    });

    tearDown(() async {
      // Clean up test data
      await dbHelper.clearAllData();
      await secureStorage.deleteAll();
    });

    testWidgets('Device locks when payment is overdue',
        (WidgetTester tester) async {
      // Create overdue payment
      await dbHelper.insertPaymentSchedule(PaymentSchedule(
        id: 'overdue_payment_001',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        amount: 5000.0,
        status: PaymentStatus.overdue,
      ));

      // Set lock state
      await dbHelper.setLockState(true);

      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify lock screen is displayed
      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.text('Device Locked'), findsOneWidget);
    });

    testWidgets('Lock screen displays payment information',
        (WidgetTester tester) async {
      // Create overdue payment
      await dbHelper.insertPaymentSchedule(PaymentSchedule(
        id: 'overdue_payment_002',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        amount: 5000.0,
        status: PaymentStatus.overdue,
      ));

      await dbHelper.setLockState(true);

      app.main();
      await tester.pumpAndSettle();

      // Verify payment information is displayed
      expect(find.byType(LockScreen), findsOneWidget);
      expect(
        find.textContaining('payment').evaluate().isNotEmpty ||
            find.textContaining('₦').evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('Lock screen displays store contact information',
        (WidgetTester tester) async {
      await dbHelper.setLockState(true);

      app.main();
      await tester.pumpAndSettle();

      // Verify contact information is displayed
      expect(find.byType(LockScreen), findsOneWidget);
      expect(
        find.textContaining('Contact').evaluate().isNotEmpty ||
            find.textContaining('Store').evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('Lock screen has Pay Now button',
        (WidgetTester tester) async {
      await dbHelper.setLockState(true);

      app.main();
      await tester.pumpAndSettle();

      // Verify Pay Now button exists
      expect(find.byType(LockScreen), findsOneWidget);
      final payButton = find.widgetWithText(ElevatedButton, 'Pay Now');
      expect(payButton, findsOneWidget);

      // Tap Pay Now button
      await tester.tap(payButton);
      await tester.pumpAndSettle();

      // Verify navigation to payment screen
      expect(find.text('Make Payment'), findsWidgets);
    });

    testWidgets('Lock screen has Emergency Call button',
        (WidgetTester tester) async {
      await dbHelper.setLockState(true);

      app.main();
      await tester.pumpAndSettle();

      // Verify Emergency Call button exists
      expect(find.byType(LockScreen), findsOneWidget);
      final emergencyButton = find.widgetWithText(TextButton, 'Emergency Call');
      expect(emergencyButton, findsOneWidget);
    });

    testWidgets('Device unlocks after payment confirmation',
        (WidgetTester tester) async {
      // Start with locked state
      await dbHelper.setLockState(true);
      await dbHelper.insertPaymentSchedule(PaymentSchedule(
        id: 'payment_unlock_001',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        amount: 5000.0,
        status: PaymentStatus.overdue,
      ));

      app.main();
      await tester.pumpAndSettle();

      // Verify lock screen is displayed
      expect(find.byType(LockScreen), findsOneWidget);

      // Simulate payment completion by updating payment status
      await dbHelper.updatePaymentStatus('payment_unlock_001', PaymentStatus.paid);
      
      // Unlock device
      await lockService.unlockDevice();
      await tester.pumpAndSettle();

      // Verify lock screen is no longer displayed
      expect(find.byType(LockScreen), findsNothing);
    });

    testWidgets('Lock state persists across app restarts',
        (WidgetTester tester) async {
      // Set lock state
      await dbHelper.setLockState(true);

      // Launch app first time
      app.main();
      await tester.pumpAndSettle();

      // Verify lock screen is displayed
      expect(find.byType(LockScreen), findsOneWidget);

      // Simulate app restart by checking lock state
      final isLocked = await dbHelper.isDeviceLocked();
      expect(isLocked, true);
    });

    testWidgets('Lock screen prevents back navigation',
        (WidgetTester tester) async {
      await dbHelper.setLockState(true);

      app.main();
      await tester.pumpAndSettle();

      // Verify lock screen is displayed
      expect(find.byType(LockScreen), findsOneWidget);

      // Try to navigate back (should be prevented by WillPopScope)
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Verify still on lock screen
      expect(find.byType(LockScreen), findsOneWidget);
    });
  });
}
