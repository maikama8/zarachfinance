import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:zaracfinance/services/secure_storage_service.dart';
import 'package:zaracfinance/services/exceptions/api_exceptions.dart';

/// API Client with interceptors for authentication, logging, and retry logic
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  
  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  late Dio _dio;
  final SecureStorageService _secureStorage = SecureStorageService();

  // Base URL - should be configured based on environment
  static const String _baseUrl = 'https://api.finance.example.com'; // TODO: Replace with actual backend URL
  
  // Timeout configurations
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 60);

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 1);

  // Certificate pinning configuration
  bool _certificatePinningEnabled = true;
  static const String _certificatePath = 'assets/certificates/backend_cert.pem';

  /// Initialize the Dio instance with interceptors
  void initialize({
    bool enableCertificatePinning = true,
    bool enableLogging = false,
  }) async {
    _certificatePinningEnabled = enableCertificatePinning;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Configure certificate pinning if enabled
    if (_certificatePinningEnabled) {
      await _configureCertificatePinning();
    }

    // Add interceptors in order
    _dio.interceptors.add(_authInterceptor());
    
    // Only add logging interceptor in debug mode or when explicitly enabled
    if (enableLogging) {
      _dio.interceptors.add(_loggingInterceptor());
    }
    
    _dio.interceptors.add(_retryInterceptor());
  }

  /// Configure certificate pinning for secure communication
  Future<void> _configureCertificatePinning() async {
    try {
      // Load the certificate from assets
      final certificateData = await rootBundle.load(_certificatePath);
      final certificate = certificateData.buffer.asUint8List();

      // Create custom HttpClient with certificate validation
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        
        // Set security context with certificate pinning
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Verify the certificate matches our pinned certificate
          return _verifyCertificate(cert, certificate);
        };

        return client;
      };

      print('Certificate pinning configured successfully');
    } catch (e) {
      print('Warning: Failed to configure certificate pinning: $e');
      
      // Fallback: Continue without certificate pinning but log the error
      // In production, you might want to fail hard here for security
      if (_certificatePinningEnabled) {
        print('Continuing without certificate pinning - SECURITY WARNING');
      }
    }
  }

  /// Verify if the server certificate matches our pinned certificate
  bool _verifyCertificate(X509Certificate serverCert, List<int> pinnedCert) {
    try {
      // Compare the DER-encoded certificates
      final serverCertDer = serverCert.der;
      
      // Check if the certificates match
      if (serverCertDer.length != pinnedCert.length) {
        print('Certificate length mismatch');
        return false;
      }

      for (int i = 0; i < serverCertDer.length; i++) {
        if (serverCertDer[i] != pinnedCert[i]) {
          print('Certificate content mismatch at byte $i');
          return false;
        }
      }

      print('Certificate validation successful');
      return true;
    } catch (e) {
      print('Certificate verification error: $e');
      return false;
    }
  }

  /// Enable or disable certificate pinning
  void setCertificatePinning(bool enabled) {
    _certificatePinningEnabled = enabled;
  }

  /// Get the Dio instance
  Dio get dio => _dio;

  /// JWT Authentication Interceptor
  /// Adds JWT token to request headers
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get JWT token from secure storage
        final token = await _secureStorage.getJwtToken();
        
        if (token != null && token.isNotEmpty) {
          // Add Authorization header with Bearer token
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Add device ID to headers if available
        final deviceId = await _secureStorage.getDeviceId();
        if (deviceId != null && deviceId.isNotEmpty) {
          options.headers['X-Device-ID'] = deviceId;
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized errors
        if (error.response?.statusCode == 401) {
          // Token might be expired or invalid
          // Could implement token refresh logic here
          print('Authentication error: Token might be expired');
        }
        handler.next(error);
      },
    );
  }

  /// Logging Interceptor
  /// Logs request and response details for debugging
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('REQUEST[${options.method}] => PATH: ${options.path}');
        print('Headers: ${options.headers}');
        if (options.data != null) {
          print('Data: ${options.data}');
        }
        if (options.queryParameters.isNotEmpty) {
          print('Query Parameters: ${options.queryParameters}');
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        print('Data: ${response.data}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        handler.next(response);
      },
      onError: (error, handler) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
        print('Message: ${error.message}');
        if (error.response?.data != null) {
          print('Error Data: ${error.response?.data}');
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        handler.next(error);
      },
    );
  }

  /// Retry Interceptor with Exponential Backoff
  /// Retries failed requests up to maxRetries times with exponential backoff
  Interceptor _retryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // Only retry on network errors or 5xx server errors
        final shouldRetry = _shouldRetryRequest(error);
        
        if (!shouldRetry) {
          handler.next(error);
          return;
        }

        // Get retry count from request options
        final retryCount = error.requestOptions.extra['retryCount'] as int? ?? 0;

        if (retryCount >= _maxRetries) {
          print('Max retries reached for ${error.requestOptions.path}');
          handler.next(error);
          return;
        }

        // Calculate exponential backoff delay
        final delay = _calculateRetryDelay(retryCount);
        
        print('Retrying request (attempt ${retryCount + 1}/$_maxRetries) after ${delay.inSeconds}s...');
        
        await Future.delayed(delay);

        // Increment retry count
        error.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          // Retry the request
          final response = await _dio.fetch(error.requestOptions);
          handler.resolve(response);
        } catch (e) {
          handler.next(error);
        }
      },
    );
  }

  /// Determine if a request should be retried
  bool _shouldRetryRequest(DioException error) {
    // Retry on network errors (no response)
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors
    if (error.response?.statusCode != null) {
      final statusCode = error.response!.statusCode!;
      if (statusCode >= 500 && statusCode < 600) {
        return true;
      }
    }

    // Don't retry on client errors (4xx) or other errors
    return false;
  }

  /// Calculate exponential backoff delay
  Duration _calculateRetryDelay(int retryCount) {
    // Exponential backoff: 1s, 2s, 4s
    final delaySeconds = _initialRetryDelay.inSeconds * (1 << retryCount);
    return Duration(seconds: delaySeconds);
  }

  /// Update base URL (useful for switching environments)
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Add custom header
  void addHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  /// Remove custom header
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// Handle API errors and convert to ApiException
  ApiException handleError(DioException error) {
    String message;
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Request timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Response timeout. Please try again.';
        break;
      case DioExceptionType.badResponse:
        message = _extractErrorMessage(error.response?.data) ?? 
                  'Server error occurred. Please try again later.';
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        break;
      default:
        message = 'An unexpected error occurred. Please try again.';
    }

    return ApiException(
      message,
      statusCode: statusCode,
      data: error.response?.data,
    );
  }

  /// Extract error message from response data
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    
    if (data is Map) {
      // Try common error message keys
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
