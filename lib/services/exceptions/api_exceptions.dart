/// Base class for all API-related exceptions
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Exception thrown when network connection fails
class NetworkException extends ApiException {
  NetworkException(String message) : super(message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when authentication fails
class AuthException extends ApiException {
  AuthException(String message, {int? statusCode, dynamic data})
      : super(message, statusCode: statusCode, data: data);

  @override
  String toString() => 'AuthException: $message (Status: $statusCode)';
}

/// Exception thrown when payment processing fails
class PaymentException extends ApiException {
  final String? transactionId;
  final String? failureReason;

  PaymentException(
    String message, {
    int? statusCode,
    dynamic data,
    this.transactionId,
    this.failureReason,
  }) : super(message, statusCode: statusCode, data: data);

  @override
  String toString() =>
      'PaymentException: $message (Status: $statusCode, TransactionId: $transactionId, Reason: $failureReason)';
}

/// Exception thrown when device registration fails
class DeviceRegistrationException extends ApiException {
  DeviceRegistrationException(String message, {int? statusCode, dynamic data})
      : super(message, statusCode: statusCode, data: data);

  @override
  String toString() => 'DeviceRegistrationException: $message (Status: $statusCode)';
}

/// Exception thrown when server returns an error
class ServerException extends ApiException {
  ServerException(String message, {int? statusCode, dynamic data})
      : super(message, statusCode: statusCode, data: data);

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Exception thrown when request validation fails
class ValidationException extends ApiException {
  final Map<String, dynamic>? validationErrors;

  ValidationException(
    String message, {
    int? statusCode,
    dynamic data,
    this.validationErrors,
  }) : super(message, statusCode: statusCode, data: data);

  @override
  String toString() => 'ValidationException: $message (Errors: $validationErrors)';
}
