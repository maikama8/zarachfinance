import 'package:dio/dio.dart';
import 'package:zaracfinance/services/api_client.dart';
import 'package:zaracfinance/services/exceptions/api_exceptions.dart';

/// Request model for device registration
class DeviceRegistrationRequest {
  final String imei;
  final String androidId;
  final String model;
  final String manufacturer;
  final String osVersion;
  final String appVersion;
  final String deviceFingerprint;
  final String customerId;

  DeviceRegistrationRequest({
    required this.imei,
    required this.androidId,
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    required this.appVersion,
    required this.deviceFingerprint,
    required this.customerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'imei': imei,
      'androidId': androidId,
      'model': model,
      'manufacturer': manufacturer,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'deviceFingerprint': deviceFingerprint,
      'customerId': customerId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Response model for device registration
class DeviceRegistrationResponse {
  final String deviceId;
  final String jwtToken;
  final DateTime tokenExpiry;
  final Map<String, dynamic> paymentSchedule;
  final Map<String, dynamic> deviceConfig;

  DeviceRegistrationResponse({
    required this.deviceId,
    required this.jwtToken,
    required this.tokenExpiry,
    required this.paymentSchedule,
    required this.deviceConfig,
  });

  factory DeviceRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationResponse(
      deviceId: json['deviceId'] as String,
      jwtToken: json['jwtToken'] as String,
      tokenExpiry: DateTime.parse(json['tokenExpiry'] as String),
      paymentSchedule: json['paymentSchedule'] as Map<String, dynamic>,
      deviceConfig: json['deviceConfig'] as Map<String, dynamic>,
    );
  }
}

/// Request model for device status update
class DeviceStatusUpdate {
  final String status; // 'ACTIVE', 'LOCKED', 'PAID_OFF'
  final String? lockReason;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  DeviceStatusUpdate({
    required this.status,
    this.lockReason,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'lockReason': lockReason,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata ?? {},
    };
  }
}

/// Response model for device status update
class DeviceStatusResponse {
  final String deviceId;
  final String status;
  final DateTime lastUpdated;
  final bool success;

  DeviceStatusResponse({
    required this.deviceId,
    required this.status,
    required this.lastUpdated,
    required this.success,
  });

  factory DeviceStatusResponse.fromJson(Map<String, dynamic> json) {
    return DeviceStatusResponse(
      deviceId: json['deviceId'] as String,
      status: json['status'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      success: json['success'] as bool,
    );
  }
}

/// Request model for location data
class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Response model for location submission
class LocationSubmissionResponse {
  final bool success;
  final String? message;
  final DateTime receivedAt;

  LocationSubmissionResponse({
    required this.success,
    this.message,
    required this.receivedAt,
  });

  factory LocationSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return LocationSubmissionResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
    );
  }
}

/// Request model for tamper alert
class TamperAlert {
  final String tamperType; // 'ROOT_DETECTED', 'APP_TAMPERED', 'DEBUGGER_ATTACHED'
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  TamperAlert({
    required this.tamperType,
    required this.description,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'tamperType': tamperType,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'details': details ?? {},
    };
  }
}

/// Service class for device-related API endpoints
class DeviceApiService {
  final ApiClient _apiClient = ApiClient();

  /// Register a new device with the backend
  Future<DeviceRegistrationResponse> registerDevice(
    DeviceRegistrationRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/device/register',
        data: request.toJson(),
      );

      return DeviceRegistrationResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update device status
  Future<DeviceStatusResponse> updateDeviceStatus({
    required String deviceId,
    required DeviceStatusUpdate statusUpdate,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/device/$deviceId/status',
        data: statusUpdate.toJson(),
      );

      return DeviceStatusResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send device location to backend
  Future<LocationSubmissionResponse> sendLocation({
    required String deviceId,
    required LocationData location,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/device/$deviceId/location',
        data: location.toJson(),
      );

      return LocationSubmissionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Report device status (comprehensive report)
  Future<Map<String, dynamic>> reportDeviceStatus({
    required String deviceId,
    required String appVersion,
    required String lockState,
    required String paymentStatus,
    required DateTime? lastPaymentDate,
    required int batteryLevel,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/device/$deviceId/report',
        data: {
          'appVersion': appVersion,
          'lockState': lockState,
          'paymentStatus': paymentStatus,
          'lastPaymentDate': lastPaymentDate?.toIso8601String(),
          'batteryLevel': batteryLevel,
          'timestamp': DateTime.now().toIso8601String(),
          'additionalData': additionalData ?? {},
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Report tampering attempt
  Future<void> reportTamper({
    required String deviceId,
    required TamperAlert alert,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/v1/device/$deviceId/tamper-alert',
        data: alert.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get device configuration from backend
  Future<Map<String, dynamic>> getDeviceConfig(String deviceId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/device/$deviceId/config',
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check for remote commands (unlock, lock, message)
  Future<List<Map<String, dynamic>>> checkRemoteCommands(String deviceId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/device/$deviceId/commands',
      );

      return (response.data as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Acknowledge remote command execution
  Future<void> acknowledgeCommand({
    required String deviceId,
    required String commandId,
    required bool success,
    String? message,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/v1/device/$deviceId/commands/$commandId/acknowledge',
        data: {
          'success': success,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Unregister device (after full payment and release)
  Future<void> unregisterDevice(String deviceId) async {
    try {
      await _apiClient.dio.delete(
        '/api/v1/device/$deviceId',
      );
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

    // Device registration errors
    if (statusCode == 409) {
      return DeviceRegistrationException(
        _extractErrorMessage(error.response?.data) ?? 'Device already registered',
        statusCode: statusCode,
        data: error.response?.data,
      );
    }

    // Validation errors
    if (statusCode == 400 || statusCode == 422) {
      return ValidationException(
        _extractErrorMessage(error.response?.data) ?? 'Invalid request data',
        statusCode: statusCode,
        data: error.response?.data,
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
