class PaymentStatusResponse {
  final bool isPaymentOverdue;
  final bool isFullyPaid;
  final int lastPaymentDate;
  final int nextPaymentDate;
  final double remainingBalance;
  final double overdueAmount;
  final double? nextPaymentAmount;
  final String? paymentFrequency;

  PaymentStatusResponse({
    required this.isPaymentOverdue,
    required this.isFullyPaid,
    required this.lastPaymentDate,
    required this.nextPaymentDate,
    required this.remainingBalance,
    required this.overdueAmount,
    this.nextPaymentAmount,
    this.paymentFrequency,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      isPaymentOverdue: json['isPaymentOverdue'] ?? false,
      isFullyPaid: json['isFullyPaid'] ?? false,
      lastPaymentDate: json['lastPaymentDate'] ?? 0,
      nextPaymentDate: json['nextPaymentDate'] ?? 0,
      remainingBalance: (json['remainingBalance'] ?? 0).toDouble(),
      overdueAmount: (json['overdueAmount'] ?? 0).toDouble(),
      nextPaymentAmount: json['nextPaymentAmount'] != null ? (json['nextPaymentAmount'] as num).toDouble() : null,
      paymentFrequency: json['paymentFrequency'],
    );
  }
}

class PaymentInitializeRequest {
  final String deviceId;
  final double amount;
  final String email;

  PaymentInitializeRequest({
    required this.deviceId,
    required this.amount,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'amount': amount,
      'email': email,
    };
  }
}

class PaymentInitializeResponse {
  final bool success;
  final String authorizationUrl;
  final String reference;
  final String gateway;

  PaymentInitializeResponse({
    required this.success,
    required this.authorizationUrl,
    required this.reference,
    required this.gateway,
  });

  factory PaymentInitializeResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitializeResponse(
      success: json['success'] ?? false,
      authorizationUrl: json['authorizationUrl'] ?? '',
      reference: json['reference'] ?? '',
      gateway: json['gateway'] ?? '',
    );
  }
}

class PaymentVerifyRequest {
  final String reference;
  final String deviceId;

  PaymentVerifyRequest({
    required this.reference,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'deviceId': deviceId,
    };
  }
}

class PaymentResponse {
  final bool success;
  final String transactionId;
  final String message;
  final double newBalance;

  PaymentResponse({
    required this.success,
    required this.transactionId,
    required this.message,
    required this.newBalance,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      transactionId: json['transactionId'] ?? '',
      message: json['message'] ?? '',
      newBalance: (json['newBalance'] ?? 0).toDouble(),
    );
  }
}

class PaymentHistoryItem {
  final int date;
  final double amount;
  final String status;
  final String transactionId;
  final String? paymentMethod;

  PaymentHistoryItem({
    required this.date,
    required this.amount,
    required this.status,
    required this.transactionId,
    this.paymentMethod,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      date: json['date'] is String 
          ? DateTime.parse(json['date']).millisecondsSinceEpoch
          : (json['date'] ?? 0),
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      transactionId: json['transactionId'] ?? '',
      paymentMethod: json['paymentMethod'],
    );
  }
}

class PaymentSchedule {
  final List<ScheduleItem> schedule;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? paymentFrequency;

  PaymentSchedule({
    required this.schedule,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.paymentFrequency,
  });

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) {
    return PaymentSchedule(
      schedule: (json['schedule'] as List? ?? [])
          .map((item) => ScheduleItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      paymentFrequency: json['paymentFrequency'],
    );
  }
}

class ScheduleItem {
  final int dueDate;
  final double amount;
  final String status;

  ScheduleItem({
    required this.dueDate,
    required this.amount,
    required this.status,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      dueDate: json['dueDate'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

class LocationRequest {
  final String deviceId;
  final double latitude;
  final double longitude;
  final int timestamp;
  final double accuracy;

  LocationRequest({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'accuracy': accuracy,
    };
  }
}

class DeviceStatusReport {
  final String deviceId;
  final bool isLocked;
  final String appVersion;
  final int batteryLevel;
  final bool isCharging;

  DeviceStatusReport({
    required this.deviceId,
    required this.isLocked,
    required this.appVersion,
    required this.batteryLevel,
    required this.isCharging,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'isLocked': isLocked,
      'appVersion': appVersion,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
    };
  }
}

class PolicyResponse {
  final LockPolicy lockPolicy;
  final PaymentSchedule paymentSchedule;
  final String? customMessage;

  PolicyResponse({
    required this.lockPolicy,
    required this.paymentSchedule,
    this.customMessage,
  });

  factory PolicyResponse.fromJson(Map<String, dynamic> json) {
    return PolicyResponse(
      lockPolicy: LockPolicy.fromJson(json['lockPolicy'] ?? {}),
      paymentSchedule: PaymentSchedule.fromJson(json['paymentSchedule'] ?? {}),
      customMessage: json['customMessage'],
    );
  }
}

class LockPolicy {
  final bool lockOnOverdue;
  final int lockDelayHours;
  final bool allowEmergencyCalls;

  LockPolicy({
    required this.lockOnOverdue,
    required this.lockDelayHours,
    required this.allowEmergencyCalls,
  });

  factory LockPolicy.fromJson(Map<String, dynamic> json) {
    return LockPolicy(
      lockOnOverdue: json['lockOnOverdue'] ?? true,
      lockDelayHours: json['lockDelayHours'] ?? 24,
      allowEmergencyCalls: json['allowEmergencyCalls'] ?? true,
    );
  }
}

