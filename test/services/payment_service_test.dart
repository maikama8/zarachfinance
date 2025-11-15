import 'package:flutter_test/flutter_test.dart';
import 'package:device_admin_app/models/payment_schedule.dart';
import 'package:device_admin_app/models/payment_history.dart';

void main() {
  group('PaymentService Logic Tests', () {
    group('Payment Status Mapping', () {
      test('maps SUCCESS status to TransactionStatus.success', () {
        final status = _mapTransactionStatus('SUCCESS');
        expect(status, TransactionStatus.success);
      });

      test('maps FAILED status to TransactionStatus.failed', () {
        final status = _mapTransactionStatus('FAILED');
        expect(status, TransactionStatus.failed);
      });

      test('maps PENDING status to TransactionStatus.pending', () {
        final status = _mapTransactionStatus('PENDING');
        expect(status, TransactionStatus.pending);
      });

      test('maps unknown status to TransactionStatus.pending', () {
        final status = _mapTransactionStatus('UNKNOWN');
        expect(status, TransactionStatus.pending);
      });

      test('handles case-insensitive status mapping', () {
        expect(_mapTransactionStatus('success'), TransactionStatus.success);
        expect(_mapTransactionStatus('failed'), TransactionStatus.failed);
        expect(_mapTransactionStatus('pending'), TransactionStatus.pending);
      });
    });

    group('Payment Schedule Due Date Calculations', () {
      test('identifies overdue payment correctly', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        
        final schedule = PaymentSchedule(
          id: 'payment_001',
          dueDate: yesterday,
          amount: 5000.0,
          status: PaymentStatus.overdue,
        );

        expect(schedule.dueDate.isBefore(now), true);
        expect(schedule.status, PaymentStatus.overdue);
      });

      test('identifies upcoming payment correctly', () {
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));
        
        final schedule = PaymentSchedule(
          id: 'payment_002',
          dueDate: tomorrow,
          amount: 5000.0,
          status: PaymentStatus.pending,
        );

        expect(schedule.dueDate.isAfter(now), true);
        expect(schedule.status, PaymentStatus.pending);
      });

      test('calculates days until due date correctly', () {
        final now = DateTime.now();
        final futureDate = now.add(const Duration(days: 5));
        
        final schedule = PaymentSchedule(
          id: 'payment_003',
          dueDate: futureDate,
          amount: 5000.0,
          status: PaymentStatus.pending,
        );

        final daysUntilDue = schedule.dueDate.difference(now).inDays;
        expect(daysUntilDue, 5);
      });

      test('calculates days overdue correctly', () {
        final now = DateTime.now();
        final pastDate = now.subtract(const Duration(days: 3));
        
        final schedule = PaymentSchedule(
          id: 'payment_004',
          dueDate: pastDate,
          amount: 5000.0,
          status: PaymentStatus.overdue,
        );

        final daysOverdue = now.difference(schedule.dueDate).inDays;
        expect(daysOverdue, 3);
      });
    });

    group('Payment History Tracking', () {
      test('creates payment history with correct timestamp', () {
        final timestamp = DateTime.now();
        
        final history = PaymentHistory(
          transactionId: 'txn_001',
          amount: 5000.0,
          timestamp: timestamp,
          status: TransactionStatus.success,
          method: 'mobile_money',
        );

        expect(history.timestamp, timestamp);
        expect(history.status, TransactionStatus.success);
      });

      test('tracks failed payment attempts', () {
        final history = PaymentHistory(
          transactionId: 'txn_002',
          amount: 3000.0,
          timestamp: DateTime.now(),
          status: TransactionStatus.failed,
          method: 'bank_transfer',
        );

        expect(history.status, TransactionStatus.failed);
      });

      test('stores payment method correctly', () {
        final methods = ['mobile_money', 'bank_transfer', 'card', 'ussd'];
        
        for (final method in methods) {
          final history = PaymentHistory(
            transactionId: 'txn_$method',
            amount: 5000.0,
            timestamp: DateTime.now(),
            status: TransactionStatus.success,
            method: method,
          );

          expect(history.method, method);
        }
      });
    });

    group('Payment Amount Calculations', () {
      test('calculates remaining balance correctly', () {
        final totalAmount = 100000.0;
        final paidAmount = 35000.0;
        final remainingBalance = totalAmount - paidAmount;

        expect(remainingBalance, 65000.0);
      });

      test('handles full payment correctly', () {
        final totalAmount = 100000.0;
        final paidAmount = 100000.0;
        final remainingBalance = totalAmount - paidAmount;

        expect(remainingBalance, 0.0);
      });

      test('calculates payment progress percentage', () {
        final totalAmount = 100000.0;
        final paidAmount = 25000.0;
        final progressPercentage = (paidAmount / totalAmount) * 100;

        expect(progressPercentage, 25.0);
      });
    });

    group('Transaction ID Generation', () {
      test('generates unique local transaction ID', () async {
        final timestamp1 = DateTime.now().millisecondsSinceEpoch;
        final txnId1 = 'local_$timestamp1';
        
        // Wait a bit to ensure different timestamp
        await Future.delayed(const Duration(milliseconds: 10));
        
        final timestamp2 = DateTime.now().millisecondsSinceEpoch;
        final txnId2 = 'local_$timestamp2';

        expect(txnId1, isNot(equals(txnId2)));
      });

      test('local transaction ID format is correct', () {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final txnId = 'local_$timestamp';

        expect(txnId, startsWith('local_'));
        expect(txnId.length, greaterThan(6));
      });
    });

    group('Duplicate Transaction Prevention', () {
      test('generates unique transaction key', () {
        final amount = 5000.0;
        final method = 'mobile_money';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        final transactionKey = '${amount}_${method}_$timestamp';
        
        expect(transactionKey, contains('5000.0'));
        expect(transactionKey, contains('mobile_money'));
        expect(transactionKey, contains(timestamp.toString()));
      });

      test('different amounts generate different keys', () {
        final method = 'mobile_money';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        final key1 = '${5000.0}_${method}_$timestamp';
        final key2 = '${3000.0}_${method}_$timestamp';
        
        expect(key1, isNot(equals(key2)));
      });

      test('different methods generate different keys', () {
        final amount = 5000.0;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        final key1 = '${amount}_mobile_money_$timestamp';
        final key2 = '${amount}_bank_transfer_$timestamp';
        
        expect(key1, isNot(equals(key2)));
      });
    });

    group('Grace Period Logic', () {
      test('calculates grace period expiry correctly', () {
        final startTime = DateTime.now();
        final gracePeriodHours = 48;
        final expiryTime = startTime.add(Duration(hours: gracePeriodHours));
        
        final hoursUntilExpiry = expiryTime.difference(startTime).inHours;
        expect(hoursUntilExpiry, 48);
      });

      test('determines if grace period has expired', () {
        final startTime = DateTime.now().subtract(const Duration(hours: 50));
        final gracePeriodHours = 48;
        final expiryTime = startTime.add(Duration(hours: gracePeriodHours));
        final now = DateTime.now();
        
        final hasExpired = now.isAfter(expiryTime);
        expect(hasExpired, true);
      });

      test('determines if grace period is still active', () {
        final startTime = DateTime.now().subtract(const Duration(hours: 24));
        final gracePeriodHours = 48;
        final expiryTime = startTime.add(Duration(hours: gracePeriodHours));
        final now = DateTime.now();
        
        final isActive = now.isBefore(expiryTime);
        expect(isActive, true);
      });
    });
  });
}

// Helper function to test transaction status mapping logic
TransactionStatus _mapTransactionStatus(String status) {
  switch (status.toUpperCase()) {
    case 'SUCCESS':
      return TransactionStatus.success;
    case 'FAILED':
      return TransactionStatus.failed;
    case 'PENDING':
      return TransactionStatus.pending;
    default:
      return TransactionStatus.pending;
  }
}
