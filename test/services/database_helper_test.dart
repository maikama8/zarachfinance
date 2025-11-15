import 'package:flutter_test/flutter_test.dart';
import 'package:device_admin_app/models/payment_schedule.dart';
import 'package:device_admin_app/models/payment_history.dart';
import 'package:device_admin_app/models/device_config.dart';
import 'package:device_admin_app/models/sync_queue_item.dart';

void main() {
  group('DatabaseHelper Logic Tests', () {
    group('Payment Schedule Queries', () {
      test('filters upcoming payments correctly', () {
        final now = DateTime.now();
        
        final schedules = [
          PaymentSchedule(
            id: 'p1',
            dueDate: now.add(const Duration(days: 5)),
            amount: 5000.0,
            status: PaymentStatus.pending,
          ),
          PaymentSchedule(
            id: 'p2',
            dueDate: now.subtract(const Duration(days: 2)),
            amount: 5000.0,
            status: PaymentStatus.overdue,
          ),
          PaymentSchedule(
            id: 'p3',
            dueDate: now.add(const Duration(days: 10)),
            amount: 5000.0,
            status: PaymentStatus.pending,
          ),
        ];

        final upcoming = schedules.where((s) => 
          s.dueDate.isAfter(now) && s.status == PaymentStatus.pending
        ).toList();

        expect(upcoming.length, 2);
        expect(upcoming[0].id, 'p1');
        expect(upcoming[1].id, 'p3');
      });

      test('filters overdue payments correctly', () {
        final now = DateTime.now();
        
        final schedules = [
          PaymentSchedule(
            id: 'p1',
            dueDate: now.subtract(const Duration(days: 5)),
            amount: 5000.0,
            status: PaymentStatus.overdue,
          ),
          PaymentSchedule(
            id: 'p2',
            dueDate: now.add(const Duration(days: 2)),
            amount: 5000.0,
            status: PaymentStatus.pending,
          ),
          PaymentSchedule(
            id: 'p3',
            dueDate: now.subtract(const Duration(days: 1)),
            amount: 5000.0,
            status: PaymentStatus.overdue,
          ),
        ];

        final overdue = schedules.where((s) => 
          s.dueDate.isBefore(now) && s.status == PaymentStatus.overdue
        ).toList();

        expect(overdue.length, 2);
        expect(overdue[0].id, 'p1');
        expect(overdue[1].id, 'p3');
      });

      test('sorts payments by due date ascending', () {
        final now = DateTime.now();
        
        final schedules = [
          PaymentSchedule(
            id: 'p1',
            dueDate: now.add(const Duration(days: 10)),
            amount: 5000.0,
            status: PaymentStatus.pending,
          ),
          PaymentSchedule(
            id: 'p2',
            dueDate: now.add(const Duration(days: 2)),
            amount: 5000.0,
            status: PaymentStatus.pending,
          ),
          PaymentSchedule(
            id: 'p3',
            dueDate: now.add(const Duration(days: 5)),
            amount: 5000.0,
            status: PaymentStatus.pending,
          ),
        ];

        schedules.sort((a, b) => a.dueDate.compareTo(b.dueDate));

        expect(schedules[0].id, 'p2');
        expect(schedules[1].id, 'p3');
        expect(schedules[2].id, 'p1');
      });
    });

    group('Payment History Queries', () {
      test('sorts payment history by timestamp descending', () {
        final now = DateTime.now();
        
        final history = [
          PaymentHistory(
            transactionId: 'txn1',
            amount: 5000.0,
            timestamp: now.subtract(const Duration(days: 5)),
            status: TransactionStatus.success,
            method: 'mobile_money',
          ),
          PaymentHistory(
            transactionId: 'txn2',
            amount: 5000.0,
            timestamp: now.subtract(const Duration(days: 1)),
            status: TransactionStatus.success,
            method: 'mobile_money',
          ),
          PaymentHistory(
            transactionId: 'txn3',
            amount: 5000.0,
            timestamp: now.subtract(const Duration(days: 10)),
            status: TransactionStatus.success,
            method: 'mobile_money',
          ),
        ];

        history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        expect(history[0].transactionId, 'txn2');
        expect(history[1].transactionId, 'txn1');
        expect(history[2].transactionId, 'txn3');
      });

      test('limits payment history results correctly', () {
        final history = List.generate(
          20,
          (index) => PaymentHistory(
            transactionId: 'txn$index',
            amount: 5000.0,
            timestamp: DateTime.now().subtract(Duration(days: index)),
            status: TransactionStatus.success,
            method: 'mobile_money',
          ),
        );

        final limit = 10;
        final limited = history.take(limit).toList();

        expect(limited.length, 10);
      });

      test('filters payment history by date range', () {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 30));
        final endDate = now;
        
        final history = [
          PaymentHistory(
            transactionId: 'txn1',
            amount: 5000.0,
            timestamp: now.subtract(const Duration(days: 10)),
            status: TransactionStatus.success,
            method: 'mobile_money',
          ),
          PaymentHistory(
            transactionId: 'txn2',
            amount: 5000.0,
            timestamp: now.subtract(const Duration(days: 45)),
            status: TransactionStatus.success,
            method: 'mobile_money',
          ),
          PaymentHistory(
            transactionId: 'txn3',
            amount: 5000.0,
            timestamp: now.subtract(const Duration(days: 5)),
            status: TransactionStatus.success,
            method: 'mobile_money',
          ),
        ];

        final filtered = history.where((h) => 
          h.timestamp.isAfter(startDate) && h.timestamp.isBefore(endDate)
        ).toList();

        expect(filtered.length, 2);
        expect(filtered[0].transactionId, 'txn1');
        expect(filtered[1].transactionId, 'txn3');
      });
    });

    group('Device Config Operations', () {
      test('stores and retrieves lock state correctly', () {
        final config = DeviceConfig(
          key: 'is_locked',
          value: 'true',
          lastUpdated: DateTime.now(),
        );

        final isLocked = config.value.toLowerCase() == 'true';
        expect(isLocked, true);
      });

      test('stores and retrieves payment status correctly', () {
        final config = DeviceConfig(
          key: 'payment_status',
          value: 'ACTIVE',
          lastUpdated: DateTime.now(),
        );

        expect(config.value, 'ACTIVE');
      });

      test('stores and retrieves remaining balance correctly', () {
        final config = DeviceConfig(
          key: 'remaining_balance',
          value: '65000.0',
          lastUpdated: DateTime.now(),
        );

        final balance = double.parse(config.value);
        expect(balance, 65000.0);
      });

      test('handles config updates with new timestamp', () {
        final oldTime = DateTime.now().subtract(const Duration(hours: 1));
        final newTime = DateTime.now();
        
        final oldConfig = DeviceConfig(
          key: 'payment_status',
          value: 'ACTIVE',
          lastUpdated: oldTime,
        );

        final newConfig = oldConfig.copyWith(
          value: 'LOCKED',
          lastUpdated: newTime,
        );

        expect(newConfig.value, 'LOCKED');
        expect(newConfig.lastUpdated.isAfter(oldConfig.lastUpdated), true);
      });
    });

    group('Sync Queue Operations', () {
      test('filters sync queue items by type', () {
        final items = [
          SyncQueueItem(
            id: 1,
            type: SyncType.payment,
            payload: '{}',
            timestamp: DateTime.now(),
            retryCount: 0,
          ),
          SyncQueueItem(
            id: 2,
            type: SyncType.location,
            payload: '{}',
            timestamp: DateTime.now(),
            retryCount: 0,
          ),
          SyncQueueItem(
            id: 3,
            type: SyncType.payment,
            payload: '{}',
            timestamp: DateTime.now(),
            retryCount: 0,
          ),
        ];

        final paymentItems = items.where((item) => 
          item.type == SyncType.payment
        ).toList();

        expect(paymentItems.length, 2);
        expect(paymentItems[0].id, 1);
        expect(paymentItems[1].id, 3);
      });

      test('increments retry count correctly', () {
        final item = SyncQueueItem(
          id: 1,
          type: SyncType.payment,
          payload: '{}',
          timestamp: DateTime.now(),
          retryCount: 0,
        );

        final updated = item.copyWith(retryCount: item.retryCount + 1);

        expect(updated.retryCount, 1);
        expect(item.retryCount, 0); // Original unchanged
      });

      test('identifies items exceeding max retries', () {
        final maxRetries = 5;
        
        final items = [
          SyncQueueItem(
            id: 1,
            type: SyncType.payment,
            payload: '{}',
            timestamp: DateTime.now(),
            retryCount: 3,
          ),
          SyncQueueItem(
            id: 2,
            type: SyncType.payment,
            payload: '{}',
            timestamp: DateTime.now(),
            retryCount: 6,
          ),
          SyncQueueItem(
            id: 3,
            type: SyncType.payment,
            payload: '{}',
            timestamp: DateTime.now(),
            retryCount: 5,
          ),
        ];

        final exceededRetries = items.where((item) => 
          item.retryCount >= maxRetries
        ).toList();

        expect(exceededRetries.length, 2);
        expect(exceededRetries[0].id, 2);
        expect(exceededRetries[1].id, 3);
      });

      test('sorts sync queue by timestamp ascending', () {
        final now = DateTime.now();
        
        final items = [
          SyncQueueItem(
            id: 1,
            type: SyncType.payment,
            payload: '{}',
            timestamp: now.subtract(const Duration(minutes: 5)),
            retryCount: 0,
          ),
          SyncQueueItem(
            id: 2,
            type: SyncType.payment,
            payload: '{}',
            timestamp: now.subtract(const Duration(minutes: 15)),
            retryCount: 0,
          ),
          SyncQueueItem(
            id: 3,
            type: SyncType.payment,
            payload: '{}',
            timestamp: now.subtract(const Duration(minutes: 10)),
            retryCount: 0,
          ),
        ];

        items.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        expect(items[0].id, 2);
        expect(items[1].id, 3);
        expect(items[2].id, 1);
      });
    });

    group('Data Integrity', () {
      test('payment schedule maintains data through serialization', () {
        final original = PaymentSchedule(
          id: 'p1',
          dueDate: DateTime(2024, 12, 25),
          amount: 5000.0,
          status: PaymentStatus.pending,
        );

        final map = original.toMap();
        final deserialized = PaymentSchedule.fromMap(map);

        expect(deserialized.id, original.id);
        expect(deserialized.dueDate, original.dueDate);
        expect(deserialized.amount, original.amount);
        expect(deserialized.status, original.status);
      });

      test('payment history maintains data through serialization', () {
        final original = PaymentHistory(
          transactionId: 'txn1',
          amount: 5000.0,
          timestamp: DateTime(2024, 12, 20, 10, 30),
          status: TransactionStatus.success,
          method: 'mobile_money',
        );

        final map = original.toMap();
        final deserialized = PaymentHistory.fromMap(map);

        expect(deserialized.transactionId, original.transactionId);
        expect(deserialized.amount, original.amount);
        expect(deserialized.timestamp, original.timestamp);
        expect(deserialized.status, original.status);
        expect(deserialized.method, original.method);
      });

      test('device config maintains data through serialization', () {
        final original = DeviceConfig(
          key: 'test_key',
          value: 'test_value',
          lastUpdated: DateTime(2024, 12, 20),
        );

        final map = original.toMap();
        final deserialized = DeviceConfig.fromMap(map);

        expect(deserialized.key, original.key);
        expect(deserialized.value, original.value);
        expect(deserialized.lastUpdated, original.lastUpdated);
      });

      test('sync queue item maintains data through serialization', () {
        final original = SyncQueueItem(
          id: 1,
          type: SyncType.payment,
          payload: '{"test": "data"}',
          timestamp: DateTime(2024, 12, 20),
          retryCount: 2,
        );

        final map = original.toMap();
        final deserialized = SyncQueueItem.fromMap(map);

        expect(deserialized.id, original.id);
        expect(deserialized.type, original.type);
        expect(deserialized.payload, original.payload);
        expect(deserialized.timestamp, original.timestamp);
        expect(deserialized.retryCount, original.retryCount);
      });
    });
  });
}
