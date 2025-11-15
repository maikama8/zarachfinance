enum PaymentStatus {
  pending,
  paid,
  overdue;

  @override
  String toString() => name;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class PaymentSchedule {
  final String id;
  final DateTime dueDate;
  final double amount;
  final PaymentStatus status;
  final DateTime? paidDate;

  PaymentSchedule({
    required this.id,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'amount': amount,
      'status': status.toString(),
      'paidDate': paidDate?.millisecondsSinceEpoch,
    };
  }

  factory PaymentSchedule.fromMap(Map<String, dynamic> map) {
    return PaymentSchedule(
      id: map['id'] as String,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      amount: map['amount'] as double,
      status: PaymentStatus.fromString(map['status'] as String),
      paidDate: map['paidDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paidDate'] as int)
          : null,
    );
  }

  PaymentSchedule copyWith({
    String? id,
    DateTime? dueDate,
    double? amount,
    PaymentStatus? status,
    DateTime? paidDate,
  }) {
    return PaymentSchedule(
      id: id ?? this.id,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
    );
  }
}
