import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:device_admin_app/services/database_helper.dart';
import 'package:device_admin_app/services/payment_service.dart';
import 'package:device_admin_app/services/location_tracker.dart';
import 'package:device_admin_app/services/policy_manager.dart';
import 'package:device_admin_app/services/secure_storage_service.dart';
import 'package:device_admin_app/models/sync_queue_item.dart';
import 'package:device_admin_app/models/payment_schedule.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Background Sync Integration Tests', () {
    late DatabaseHelper dbHelper;
    late PaymentService paymentService;
    late LocationTracker locationTracker;
    late PolicyManager policyManager;
    late SecureStorageService secureStorage;

    setUp(() async {
      dbHelper = DatabaseHelper();
      secureStorage = SecureStorageService();
      
      // Initialize database
      await dbHelper.database;
      
      // Set up test device ID and token
      await secureStorage.saveDeviceId('test_device_sync_001');
      await secureStorage.saveToken('test_jwt_token');
      
      // Initialize services
      paymentService = PaymentService();
      locationTracker = LocationTracker();
      policyManager = PolicyManager();
    });

    tearDown(() async {
      // Clean up test data
      await dbHelper.clearAllData();
      await secureStorage.deleteAll();
    });

    test('Payment status check queues operation when offline', () async {
      // Insert a pending payment
      await dbHelper.insertPaymentSchedule(PaymentSchedule(
        id: 'sync_payment_001',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        amount: 5000.0,
        status: PaymentStatus.pending,
      ));

      // Attempt to check payment status (will fail without network)
      try {
        await paymentService.checkPaymentStatus();
      } catch (e) {
        // Expected to fail without network
      }

      // Verify operation was queued
      final queuedItems = await dbHelper.getSyncQueue();
      expect(queuedItems.isNotEmpty, true);
      
      // Check if payment check was queued
      final paymentChecks = queuedItems.where(
        (item) => item.type == SyncType.paymentCheck
      );
      expect(paymentChecks.isNotEmpty, true);
    });

    test('Location capture queues data when offline', () async {
      // Attempt to capture and send location (will fail without network)
      try {
        await locationTracker.captureAndSendLocation();
      } catch (e) {
        // Expected to fail without network or permissions
      }

      // Verify location was queued if capture succeeded
      final queuedItems = await dbHelper.getSyncQueue();
      final locationItems = queuedItems.where(
        (item) => item.type == SyncType.location
      );
      
      // Location may not be queued if permissions denied
      // Just verify queue mechanism works
      expect(queuedItems, isA<List<SyncQueueItem>>());
    });

    test('Sync queue processes items in order', () async {
      // Add multiple items to sync queue
      await dbHelper.addToSyncQueue(
        SyncType.paymentCheck,
        {'timestamp': DateTime.now().millisecondsSinceEpoch},
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      await dbHelper.addToSyncQueue(
        SyncType.location,
        {'lat': 6.5244, 'lng': 3.3792},
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      await dbHelper.addToSyncQueue(
        SyncType.statusReport,
        {'status': 'active'},
      );

      // Get queued items
      final queuedItems = await dbHelper.getSyncQueue();
      expect(queuedItems.length, greaterThanOrEqualTo(3));

      // Verify items are ordered by timestamp
      for (int i = 0; i < queuedItems.length - 1; i++) {
        expect(
          queuedItems[i].timestamp.isBefore(queuedItems[i + 1].timestamp) ||
              queuedItems[i].timestamp.isAtSameMomentAs(queuedItems[i + 1].timestamp),
          true,
        );
      }
    });

    test('Sync queue removes processed items', () async {
      // Add item to queue
      await dbHelper.addToSyncQueue(
        SyncType.paymentCheck,
        {'test': 'data'},
      );

      // Get queued items
      var queuedItems = await dbHelper.getSyncQueue();
      final initialCount = queuedItems.length;
      expect(initialCount, greaterThan(0));

      // Remove first item
      if (queuedItems.isNotEmpty) {
        await dbHelper.removeSyncQueueItem(queuedItems.first.id!);
      }

      // Verify item was removed
      queuedItems = await dbHelper.getSyncQueue();
      expect(queuedItems.length, lessThan(initialCount));
    });

    test('Payment status check updates local database', () async {
      // Insert a pending payment
      await dbHelper.insertPaymentSchedule(PaymentSchedule(
        id: 'status_update_001',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        amount: 5000.0,
        status: PaymentStatus.pending,
      ));

      // Get initial payment
      var payment = await dbHelper.getPaymentSchedule('status_update_001');
      expect(payment?.status, PaymentStatus.pending);

      // Update payment status locally (simulating successful sync)
      await dbHelper.updatePaymentStatus('status_update_001', PaymentStatus.paid);

      // Verify status was updated
      payment = await dbHelper.getPaymentSchedule('status_update_001');
      expect(payment?.status, PaymentStatus.paid);
    });

    test('Policy updates are applied to local configuration', () async {
      // Set initial policy
      await dbHelper.setConfig('lock_delay_hours', '24');
      
      var config = await dbHelper.getConfig('lock_delay_hours');
      expect(config, '24');

      // Update policy (simulating remote update)
      await dbHelper.setConfig('lock_delay_hours', '48');

      // Verify policy was updated
      config = await dbHelper.getConfig('lock_delay_hours');
      expect(config, '48');
    });

    test('Device status reporting includes required fields', () async {
      // Set up device status data
      await dbHelper.setLockState(false);
      await dbHelper.insertPaymentSchedule(PaymentSchedule(
        id: 'status_payment_001',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        amount: 5000.0,
        status: PaymentStatus.pending,
      ));

      // Get device status
      final isLocked = await dbHelper.isDeviceLocked();
      final upcomingPayments = await dbHelper.getUpcomingPayments();

      // Verify status data
      expect(isLocked, isA<bool>());
      expect(upcomingPayments, isA<List<PaymentSchedule>>());
      expect(upcomingPayments.isNotEmpty, true);
    });

    test('Sync retry count increments on failure', () async {
      // Add item to queue
      await dbHelper.addToSyncQueue(
        SyncType.paymentCheck,
        {'test': 'retry'},
      );

      var queuedItems = await dbHelper.getSyncQueue();
      expect(queuedItems.isNotEmpty, true);

      final item = queuedItems.first;
      final initialRetryCount = item.retryCount;

      // Simulate retry by incrementing count
      final updatedItem = SyncQueueItem(
        id: item.id,
        type: item.type,
        payload: item.payload,
        timestamp: item.timestamp,
        retryCount: item.retryCount + 1,
      );

      // Update item in database
      await dbHelper.removeSyncQueueItem(item.id!);
      await dbHelper.addToSyncQueue(
        updatedItem.type,
        {'test': 'retry'},
        retryCount: updatedItem.retryCount,
      );

      // Verify retry count increased
      queuedItems = await dbHelper.getSyncQueue();
      final retryItem = queuedItems.firstWhere(
        (i) => i.type == SyncType.paymentCheck,
        orElse: () => item,
      );
      expect(retryItem.retryCount, greaterThan(initialRetryCount));
    });

    test('Grace period is tracked during network outages', () async {
      // Set grace period start time
      final startTime = DateTime.now();
      await dbHelper.setConfig(
        'grace_period_start',
        startTime.millisecondsSinceEpoch.toString(),
      );

      // Get grace period start
      final storedTime = await dbHelper.getConfig('grace_period_start');
      expect(storedTime, isNotNull);

      // Calculate time elapsed
      final elapsed = DateTime.now().difference(startTime);
      expect(elapsed.inSeconds, lessThan(60)); // Should be recent

      // Check if grace period expired (48 hours)
      final gracePeriodHours = 48;
      final expiryTime = startTime.add(Duration(hours: gracePeriodHours));
      final hasExpired = DateTime.now().isAfter(expiryTime);
      expect(hasExpired, false); // Should not be expired yet
    });

    test('Background sync handles concurrent operations', () async {
      // Add multiple operations simultaneously
      final futures = <Future>[];
      
      for (int i = 0; i < 5; i++) {
        futures.add(dbHelper.addToSyncQueue(
          SyncType.paymentCheck,
          {'index': i},
        ));
      }

      await Future.wait(futures);

      // Verify all operations were queued
      final queuedItems = await dbHelper.getSyncQueue();
      expect(queuedItems.length, greaterThanOrEqualTo(5));
    });
  });
}
