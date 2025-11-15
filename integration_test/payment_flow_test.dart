import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:device_admin_app/main.dart' as app;
import 'package:device_admin_app/services/database_helper.dart';
import 'package:device_admin_app/services/secure_storage_service.dart';
import 'package:device_admin_app/models/payment_schedule.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment Flow Integration Tests', () {
    late DatabaseHelper dbHelper;
    late SecureStorageService secureStorage;

    setUp(() async {
      dbHelper = DatabaseHelper();
      secureStorage = SecureStorageService();
      
      // Initialize database
      await dbHelper.database;
      
      // Set up test device ID
      await secureStorage.saveDeviceId('test_device_001');
      
      // Insert test payment schedule
      await dbHelper.insertPaymentSchedule(PaymentSchedule(
        id: 'test_payment_001',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        amount: 5000.0,
        status: PaymentStatus.pending,
      ));
    });

    tearDown(() async {
      // Clean up test data
      await dbHelper.clearAllData();
      await secureStorage.deleteAll();
    });

    testWidgets('Complete payment flow - select amount, choose method, submit',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to payment screen
      final paymentButton = find.text('Make Payment');
      expect(paymentButton, findsOneWidget);
      await tester.tap(paymentButton);
      await tester.pumpAndSettle();

      // Verify payment screen is displayed
      expect(find.text('Make Payment'), findsWidgets);

      // Select payment amount
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '5000');
      await tester.pumpAndSettle();

      // Choose payment method
      final methodDropdown = find.byType(DropdownButton<String>);
      expect(methodDropdown, findsOneWidget);
      await tester.tap(methodDropdown);
      await tester.pumpAndSettle();

      // Select mobile money option
      final mobileMoneyOption = find.text('Mobile Money').last;
      await tester.tap(mobileMoneyOption);
      await tester.pumpAndSettle();

      // Submit payment
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit Payment');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Wait for processing
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify confirmation or error message is displayed
      expect(
        find.byType(SnackBar).evaluate().isNotEmpty ||
            find.byType(AlertDialog).evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('Payment flow handles invalid amount',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to payment screen
      await tester.tap(find.text('Make Payment'));
      await tester.pumpAndSettle();

      // Enter invalid amount (negative)
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '-100');
      await tester.pumpAndSettle();

      // Try to submit
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit Payment');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(
        find.textContaining('Invalid').evaluate().isNotEmpty ||
            find.textContaining('error').evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('Payment flow displays payment history',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to payment history
      final historyButton = find.text('Payment History');
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();

        // Verify history screen is displayed
        expect(find.text('Payment History'), findsWidgets);
      }
    });

    testWidgets('Payment flow shows remaining balance',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for balance display on home screen
      expect(
        find.textContaining('Balance').evaluate().isNotEmpty ||
            find.textContaining('₦').evaluate().isNotEmpty,
        true,
      );
    });
  });
}
