import 'package:flutter_test/flutter_test.dart';
import 'package:device_admin_app/models/payment_history.dart';

void main() {
  group('PaymentHistory Model Tests', () {
    test('toMap converts PaymentHistory to Map correctly', () {
      final timestamp = DateTime(2024, 12, 20, 10, 30);
      
      final history = PaymentHistory(
        transactionId: 'txn_001',
        amount: 5000.0,
        timestamp: timestamp,
        status: TransactionStatus.success,
        method: 'mobile_money',
      );

      final map = history.toMap();

      expect(map['transactionId'], 'txn_001');
      expect(map['amount'], 5000.0);
      expect(map['timestamp'], timestamp.millisecondsSinceEpoch);
      expect(map['status'], 'success');
      expect(map['method'], 'mobile_money');
    });

    test('fromMap creates PaymentHistory from Map correctly', () {
      final timestamp = DateTime(2024, 12, 20, 10, 30);
      
      final map = {
        'transactionId': 'txn_002',
        'amount': 3000.0,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'status': 'failed',
        'method': 'bank_transfer',
      };

      final history = PaymentHistory.fromMap(map);

      expect(history.transactionId, 'txn_002');
      expect(history.amount, 3000.0);
      expect(history.timestamp, timestamp);
      expect(history.status, TransactionStatus.failed);
      expect(history.method, 'bank_transfer');
    });

    test('copyWith creates new instance with updated values', () {
      final timestamp = DateTime(2024, 12, 20, 10, 30);
      
      final original = PaymentHistory(
        transactionId: 'txn_003',
        amount: 4000.0,
        timestamp: timestamp,
        status: TransactionStatus.pending,
        method: 'card',
      );

      final updated = original.copyWith(
        status: TransactionStatus.success,
      );

      expect(updated.transactionId, 'txn_003');
      expect(updated.amount, 4000.0);
      expect(updated.timestamp, timestamp);
      expect(updated.status, TransactionStatus.success);
      expect(updated.method, 'card');
      
      // Original should remain unchanged
      expect(original.status, TransactionStatus.pending);
    });

    test('TransactionStatus enum toString returns correct string', () {
      expect(TransactionStatus.success.toString(), 'success');
      expect(TransactionStatus.failed.toString(), 'failed');
      expect(TransactionStatus.pending.toString(), 'pending');
    });

    test('TransactionStatus fromString parses correctly', () {
      expect(TransactionStatus.fromString('success'), TransactionStatus.success);
      expect(TransactionStatus.fromString('failed'), TransactionStatus.failed);
      expect(TransactionStatus.fromString('pending'), TransactionStatus.pending);
    });

    test('TransactionStatus fromString returns pending for invalid value', () {
      expect(TransactionStatus.fromString('invalid'), TransactionStatus.pending);
      expect(TransactionStatus.fromString(''), TransactionStatus.pending);
    });

    test('serialization round-trip maintains data integrity', () {
      final timestamp = DateTime(2024, 12, 20, 10, 30);
      
      final original = PaymentHistory(
        transactionId: 'txn_004',
        amount: 7500.0,
        timestamp: timestamp,
        status: TransactionStatus.success,
        method: 'ussd',
      );

      final map = original.toMap();
      final deserialized = PaymentHistory.fromMap(map);

      expect(deserialized.transactionId, original.transactionId);
      expect(deserialized.amount, original.amount);
      expect(deserialized.timestamp, original.timestamp);
      expect(deserialized.status, original.status);
      expect(deserialized.method, original.method);
    });
  });
}
