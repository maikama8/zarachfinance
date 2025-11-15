import 'package:flutter_test/flutter_test.dart';
import 'package:device_admin_app/models/payment_schedule.dart';

void main() {
  group('PaymentSchedule Model Tests', () {
    test('toMap converts PaymentSchedule to Map correctly', () {
      final dueDate = DateTime(2024, 12, 25);
      final paidDate = DateTime(2024, 12, 20);
      
      final schedule = PaymentSchedule(
        id: 'payment_001',
        dueDate: dueDate,
        amount: 5000.0,
        status: PaymentStatus.paid,
        paidDate: paidDate,
      );

      final map = schedule.toMap();

      expect(map['id'], 'payment_001');
      expect(map['dueDate'], dueDate.millisecondsSinceEpoch);
      expect(map['amount'], 5000.0);
      expect(map['status'], 'paid');
      expect(map['paidDate'], paidDate.millisecondsSinceEpoch);
    });

    test('toMap handles null paidDate correctly', () {
      final dueDate = DateTime(2024, 12, 25);
      
      final schedule = PaymentSchedule(
        id: 'payment_002',
        dueDate: dueDate,
        amount: 3000.0,
        status: PaymentStatus.pending,
        paidDate: null,
      );

      final map = schedule.toMap();

      expect(map['id'], 'payment_002');
      expect(map['paidDate'], null);
    });

    test('fromMap creates PaymentSchedule from Map correctly', () {
      final dueDate = DateTime(2024, 12, 25);
      final paidDate = DateTime(2024, 12, 20);
      
      final map = {
        'id': 'payment_003',
        'dueDate': dueDate.millisecondsSinceEpoch,
        'amount': 7500.0,
        'status': 'overdue',
        'paidDate': paidDate.millisecondsSinceEpoch,
      };

      final schedule = PaymentSchedule.fromMap(map);

      expect(schedule.id, 'payment_003');
      expect(schedule.dueDate, dueDate);
      expect(schedule.amount, 7500.0);
      expect(schedule.status, PaymentStatus.overdue);
      expect(schedule.paidDate, paidDate);
    });

    test('fromMap handles null paidDate correctly', () {
      final dueDate = DateTime(2024, 12, 25);
      
      final map = {
        'id': 'payment_004',
        'dueDate': dueDate.millisecondsSinceEpoch,
        'amount': 2500.0,
        'status': 'pending',
        'paidDate': null,
      };

      final schedule = PaymentSchedule.fromMap(map);

      expect(schedule.id, 'payment_004');
      expect(schedule.paidDate, null);
    });

    test('copyWith creates new instance with updated values', () {
      final originalDate = DateTime(2024, 12, 25);
      final newDate = DateTime(2024, 12, 30);
      
      final original = PaymentSchedule(
        id: 'payment_005',
        dueDate: originalDate,
        amount: 4000.0,
        status: PaymentStatus.pending,
        paidDate: null,
      );

      final updated = original.copyWith(
        status: PaymentStatus.paid,
        paidDate: newDate,
      );

      expect(updated.id, 'payment_005');
      expect(updated.dueDate, originalDate);
      expect(updated.amount, 4000.0);
      expect(updated.status, PaymentStatus.paid);
      expect(updated.paidDate, newDate);
      
      // Original should remain unchanged
      expect(original.status, PaymentStatus.pending);
      expect(original.paidDate, null);
    });

    test('PaymentStatus enum toString returns correct string', () {
      expect(PaymentStatus.pending.toString(), 'pending');
      expect(PaymentStatus.paid.toString(), 'paid');
      expect(PaymentStatus.overdue.toString(), 'overdue');
    });

    test('PaymentStatus fromString parses correctly', () {
      expect(PaymentStatus.fromString('pending'), PaymentStatus.pending);
      expect(PaymentStatus.fromString('paid'), PaymentStatus.paid);
      expect(PaymentStatus.fromString('overdue'), PaymentStatus.overdue);
    });

    test('PaymentStatus fromString returns pending for invalid value', () {
      expect(PaymentStatus.fromString('invalid'), PaymentStatus.pending);
      expect(PaymentStatus.fromString(''), PaymentStatus.pending);
    });

    test('serialization round-trip maintains data integrity', () {
      final dueDate = DateTime(2024, 12, 25);
      final paidDate = DateTime(2024, 12, 20);
      
      final original = PaymentSchedule(
        id: 'payment_006',
        dueDate: dueDate,
        amount: 6000.0,
        status: PaymentStatus.paid,
        paidDate: paidDate,
      );

      final map = original.toMap();
      final deserialized = PaymentSchedule.fromMap(map);

      expect(deserialized.id, original.id);
      expect(deserialized.dueDate, original.dueDate);
      expect(deserialized.amount, original.amount);
      expect(deserialized.status, original.status);
      expect(deserialized.paidDate, original.paidDate);
    });
  });
}
