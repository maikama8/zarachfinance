enum SyncType {
  payment,
  location,
  status;

  @override
  String toString() => name;

  static SyncType fromString(String value) {
    return SyncType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncType.status,
    );
  }
}

class SyncQueueItem {
  final int? id;
  final SyncType type;
  final String payload;
  final DateTime timestamp;
  final int retryCount;

  SyncQueueItem({
    this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'payload': payload,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'retryCount': retryCount,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      type: SyncType.fromString(map['type'] as String),
      payload: map['payload'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      retryCount: map['retryCount'] as int,
    );
  }

  SyncQueueItem copyWith({
    int? id,
    SyncType? type,
    String? payload,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
