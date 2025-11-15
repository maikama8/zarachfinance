class ErrorLog {
  final int? id;
  final DateTime timestamp;
  final String errorType;
  final String message;
  final String? stackTrace;
  final String? context;

  ErrorLog({
    this.id,
    required this.timestamp,
    required this.errorType,
    required this.message,
    this.stackTrace,
    this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'errorType': errorType,
      'message': message,
      'stackTrace': stackTrace,
      'context': context,
    };
  }

  factory ErrorLog.fromMap(Map<String, dynamic> map) {
    return ErrorLog(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      errorType: map['errorType'] as String,
      message: map['message'] as String,
      stackTrace: map['stackTrace'] as String?,
      context: map['context'] as String?,
    );
  }

  @override
  String toString() {
    return 'ErrorLog{id: $id, timestamp: $timestamp, errorType: $errorType, message: $message, context: $context}';
  }
}
