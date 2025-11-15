enum TransactionStatus {
  success,
  failed,
  pending;

  @override
  String toString() => name;

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

class PaymentHistory {
  final String transactionId;
  final double amount;
  final DateTime timestamp;
  final TransactionStatus status;
  final String method;

  PaymentHistory({
    required this.transactionId,
    required this.amount,
    required this.timestamp,
    required this.status,
    required this.method,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.toString(),
      'method': method,
    };
  }

  factory PaymentHistory.fromMap(Map<String, dynamic> map) {
    return PaymentHistory(
      transactionId: map['transactionId'] as String,
      amount: map['amount'] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: TransactionStatus.fromString(map['status'] as String),
      method: map['method'] as String,
    );
  }

  PaymentHistory copyWith({
    String? transactionId,
    double? amount,
    DateTime? timestamp,
    TransactionStatus? status,
    String? method,
  }) {
    return PaymentHistory(
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      method: method ?? this.method,
    );
  }
}
