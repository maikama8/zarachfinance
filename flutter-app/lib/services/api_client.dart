import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';
import '../models/api_models.dart';
import 'device_admin_service.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Config.apiBaseUrl,
      connectTimeout: Config.apiTimeout,
      receiveTimeout: Config.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_key') ?? '';
  }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_id');
    
    if (deviceId == null || deviceId.isEmpty) {
      // Get device ID from native code
      try {
        deviceId = await DeviceAdminService.getDeviceId();
        if (deviceId.isNotEmpty) {
          await prefs.setString('device_id', deviceId);
        }
      } catch (e) {
        // Fallback to generated ID
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('device_id', deviceId);
      }
    }
    
    return deviceId;
  }

  static Future<Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final apiKey = await _getApiKey();
    
    final options = Options(
      headers: {
        'X-API-Key': apiKey,
      },
    );

    switch (method.toUpperCase()) {
      case 'GET':
        return await _dio.get(path, options: options, queryParameters: queryParameters);
      case 'POST':
        return await _dio.post(path, data: data, options: options);
      case 'PUT':
        return await _dio.put(path, data: data, options: options);
      case 'DELETE':
        return await _dio.delete(path, options: options);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // Payment Service
  static Future<PaymentStatusResponse> getPaymentStatus(String deviceId) async {
    final response = await _request('GET', '/payment/status/$deviceId');
    return PaymentStatusResponse.fromJson(response.data);
  }

  static Future<PaymentInitializeResponse> initializePayment(
    PaymentInitializeRequest request,
  ) async {
    final response = await _request('POST', '/payment/initialize', data: request.toJson());
    return PaymentInitializeResponse.fromJson(response.data);
  }

  static Future<PaymentResponse> verifyPayment(PaymentVerifyRequest request) async {
    final response = await _request('POST', '/payment/verify', data: request.toJson());
    return PaymentResponse.fromJson(response.data);
  }

  static Future<List<PaymentHistoryItem>> getPaymentHistory(String deviceId) async {
    final response = await _request('GET', '/payment/history/$deviceId');
    final data = response.data;
    if (data is Map && data['payments'] != null) {
      return (data['payments'] as List)
          .map((item) => PaymentHistoryItem.fromJson(item))
          .toList();
    }
    return (data as List? ?? [])
        .map((item) => PaymentHistoryItem.fromJson(item))
        .toList();
  }

  static Future<PaymentSchedule> getPaymentSchedule(String deviceId) async {
    final response = await _request('GET', '/payment/schedule/$deviceId');
    return PaymentSchedule.fromJson(response.data);
  }

  // Device Service
  static Future<void> reportLocation(LocationRequest request) async {
    await _request('POST', '/device/location', data: request.toJson());
  }

  static Future<void> reportDeviceStatus(DeviceStatusReport request) async {
    await _request('POST', '/device/status', data: request.toJson());
  }

  // Admin Service
  static Future<PolicyResponse> getPolicy(String deviceId) async {
    final response = await _request('GET', '/admin/policy/$deviceId');
    return PolicyResponse.fromJson(response.data);
  }
}

