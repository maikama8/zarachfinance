class DeviceConfig {
  final String key;
  final String value;
  final DateTime lastUpdated;

  DeviceConfig({
    required this.key,
    required this.value,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory DeviceConfig.fromMap(Map<String, dynamic> map) {
    return DeviceConfig(
      key: map['key'] as String,
      value: map['value'] as String,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] as int),
    );
  }

  DeviceConfig copyWith({
    String? key,
    String? value,
    DateTime? lastUpdated,
  }) {
    return DeviceConfig(
      key: key ?? this.key,
      value: value ?? this.value,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
