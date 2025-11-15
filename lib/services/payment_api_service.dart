import 'package:dio/dio.dart';
import 'package:zaracfinance/services/api_client.dart';
import 'package:zaracfinance/services/exceptions/api_exceptions.dart';
import 'package:zaracfinance/models/payment_schedule.dart';
import 'package:zaracfinance/models/payment_history.dart';

/// Response model for payment status
class PaymentStatusResponse {
  final String deviceId;
  final String status; // 'ACTIVE', 'LOCKED', 'PAID_OFF', 'DEFAULTED'
  final double totalAmount;
  final double paidAmount;
  final double remainingBalance;
  final DateTime? nextPaymentDue;
  final bool isOverdue;
  final DateTime lastUpdated;

  PaymentStatusResponse({
    required this.deviceId,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingBalance,
    this.nextPaymentDue,
    required this.isOverdue,
    required this.lastUpdated,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      deviceId: json['deviceId'] as String,
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      remainingBalance: (json['remainingBalance'] as num).toDouble(),
      nextPaymentDue: json['nextPaymentDue'] != null
          ? DateTime.parse(json['nextPaymentDue'] as String)
          : null,
      isOverdue: json['isOverdue'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// Response model for payment submission
class PaymentSubmissionResponse {
  final String transactionId;
  final String status; // 'SUCCESS', 'FAILED', 'PENDING'
  final double amount;
  final DateTime timestamp;
  final String? message;
  final double? newBalance;

  PaymentSubmissionResponse({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.timestamp,
    this.message,
    this.newBalance,
  });

  factory PaymentSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return PaymentSubmissionResponse(
      transactionId: json['transactionId'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String?,
      newBalance: json['newBalance'] != null
          ? (json['newBalance'] as num).toDouble()
          : null,
    );
  }
}

/// Response model for payment schedule
class PaymentScheduleResponse {
  final String deviceId;
  final List<PaymentSchedule> installments;
  final double totalAmount;
  final double paidAmount;
  final int totalInstallments;
  final int paidInstallments;

  PaymentScheduleResponse({
    required this.deviceId,
    required this.installments,
    required this.totalAmount,
    required this.paidAmount,
    required this.totalInstallments,
    required this.paidInstallments,
  });

  factory PaymentScheduleResponse.fromJson(Map<String, dynamic> json) {
    return PaymentScheduleResponse(
      deviceId: json['deviceId'] as String,
      installments: (json['installments'] as List)
          .map((item) => PaymentSchedule.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      totalInstallments: json['totalInstallments'] as int,
      paidInstallments: json['paidInstallments'] as int,
    );
  }
}

/// Response model for release code verification
class ReleaseCodeVerificationResponse {
  final bool isValid;
  final String? message;
  final DateTime? expiryDate;
  final bool deviceReleased;

  ReleaseCodeVerificationResponse({
    required this.isValid,
    this.message,
    this.expiryDate,
    required this.deviceReleased,
  });

  factory ReleaseCodeVerificationResponse.fromJson(Map<String, dynamic> json) {
    return ReleaseCodeVerificationResponse(
      isValid: json['isValid'] as bool,
      message: json['message'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      deviceReleased: json['deviceReleased'] as bool,
    );
  }
}

/// Service class for payment-related API endpoints
class PaymentApiService {
  final ApiClient _apiClient = ApiClient();

  /// Get current payment status for a device
  Future<PaymentStatusResponse> getPaymentStatus(String deviceId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/device/$deviceId/payment-status',
      );

      return PaymentStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Submit a payment for a device
  Future<PaymentSubmissionResponse> submitPayment({
    required String deviceId,
    required double amount,
    required String method,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/device/$deviceId/payment',
        data: {
          'amount': amount,
          'method': method,
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': metadata ?? {},
        },
      );

      final result = PaymentSubmissionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Check if payment failed
      if (result.status == 'FAILED') {
        throw PaymentException(
          result.message ?? 'Payment failed',
          statusCode: response.statusCode,
          data: response.data,
          transactionId: result.transactionId,
          failureReason: result.message,
        );
      }

      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get payment schedule for a device
  Future<PaymentScheduleResponse> getPaymentSchedule(String deviceId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/device/$deviceId/schedule',
      );

      return PaymentScheduleResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify release code for full payment
  Future<ReleaseCodeVerificationResponse> verifyReleaseCode({
    required String deviceId,
    required String code,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/device/$deviceId/verify-release-code',
        data: {
          'code': code,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return ReleaseCodeVerificationResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get payment history for a device
  Future<List<PaymentHistory>> getPaymentHistory({
    required String deviceId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _apiClient.dio.get(
        '/api/v1/device/$deviceId/payment-history',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((item) => PaymentHistory.fromMap(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and convert to appropriate exception type
  Exception _handleError(DioException error) {
    final statusCode = error.response?.statusCode;

    // Network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(
        'Network error: ${error.message ?? "Unable to connect to server"}',
      );
    }

    // Authentication errors
    if (statusCode == 401 || statusCode == 403) {
      return AuthException(
        _extractErrorMessage(error.response?.data) ?? 'Authentication failed',
        statusCode: statusCode,
        data: error.response?.data,
      );
    }

    // Payment-specific errors
    if (statusCode == 402 || statusCode == 422) {
      return PaymentException(
        _extractErrorMessage(error.response?.data) ?? 'Payment processing failed',
        statusCode: statusCode,
        data: error.response?.data,
        failureReason: _extractErrorMessage(error.response?.data),
      );
    }

    // Server errors
    if (statusCode != null && statusCode >= 500) {
      return ServerException(
        _extractErrorMessage(error.response?.data) ?? 'Server error occurred',
        statusCode: statusCode,
        data: error.response?.data,
      );
    }

    // Default to ApiException
    return ApiException(
      _extractErrorMessage(error.response?.data) ?? error.message ?? 'Unknown error',
      statusCode: statusCode,
      data: error.response?.data,
    );
  }

  /// Extract error message from response data
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      if (data.containsKey('message')) {
        return data['message'] as String?;
      }
      if (data.containsKey('error')) {
        final error = data['error'];
        if (error is String) return error;
        if (error is Map && error.containsKey('message')) {
          return error['message'] as String?;
        }
      }
    }

    return null;
  }
}
