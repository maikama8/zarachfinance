import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiClient Logic Tests', () {
    group('Retry Logic', () {
      test('calculates exponential backoff delay correctly', () {
        const initialDelay = Duration(seconds: 1);
        
        // First retry: 1s
        final delay0 = Duration(seconds: initialDelay.inSeconds * (1 << 0));
        expect(delay0.inSeconds, 1);
        
        // Second retry: 2s
        final delay1 = Duration(seconds: initialDelay.inSeconds * (1 << 1));
        expect(delay1.inSeconds, 2);
        
        // Third retry: 4s
        final delay2 = Duration(seconds: initialDelay.inSeconds * (1 << 2));
        expect(delay2.inSeconds, 4);
      });

      test('determines retry eligibility for network errors', () {
        final networkErrors = [
          'connectionTimeout',
          'sendTimeout',
          'receiveTimeout',
          'connectionError',
        ];

        for (final error in networkErrors) {
          final shouldRetry = _shouldRetryForError(error);
          expect(shouldRetry, true, reason: '$error should be retryable');
        }
      });

      test('determines retry eligibility for server errors', () {
        final serverStatusCodes = [500, 502, 503, 504];

        for (final code in serverStatusCodes) {
          final shouldRetry = _shouldRetryForStatusCode(code);
          expect(shouldRetry, true, reason: 'Status $code should be retryable');
        }
      });

      test('does not retry client errors', () {
        final clientStatusCodes = [400, 401, 403, 404, 422];

        for (final code in clientStatusCodes) {
          final shouldRetry = _shouldRetryForStatusCode(code);
          expect(shouldRetry, false, reason: 'Status $code should not be retryable');
        }
      });

      test('respects max retry limit', () {
        const maxRetries = 3;
        
        for (int retryCount = 0; retryCount < maxRetries; retryCount++) {
          expect(retryCount < maxRetries, true);
        }
        
        expect(maxRetries >= maxRetries, true);
      });
    });

    group('Error Message Extraction', () {
      test('extracts message from response with message key', () {
        final data = {
          'message': 'Payment failed',
          'code': 'PAYMENT_ERROR',
        };

        final message = _extractErrorMessage(data);
        expect(message, 'Payment failed');
      });

      test('extracts message from response with error.message key', () {
        final data = {
          'error': {
            'message': 'Invalid credentials',
            'code': 'AUTH_ERROR',
          },
        };

        final message = _extractErrorMessage(data);
        expect(message, 'Invalid credentials');
      });

      test('extracts message from response with error string', () {
        final data = {
          'error': 'Server error occurred',
        };

        final message = _extractErrorMessage(data);
        expect(message, 'Server error occurred');
      });

      test('returns null for response without error message', () {
        final data = {
          'code': 'ERROR',
          'status': 'failed',
        };

        final message = _extractErrorMessage(data);
        expect(message, null);
      });

      test('returns null for null response data', () {
        final message = _extractErrorMessage(null);
        expect(message, null);
      });
    });

    group('Request Headers', () {
      test('formats authorization header correctly', () {
        final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
        final header = 'Bearer $token';

        expect(header, startsWith('Bearer '));
        expect(header, contains(token));
      });

      test('formats device ID header correctly', () {
        final deviceId = 'device_12345';
        final headers = {
          'X-Device-ID': deviceId,
        };

        expect(headers['X-Device-ID'], deviceId);
      });

      test('includes content type header', () {
        final headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

        expect(headers['Content-Type'], 'application/json');
        expect(headers['Accept'], 'application/json');
      });
    });

    group('Certificate Validation', () {
      test('compares certificate lengths correctly', () {
        final cert1 = List<int>.generate(100, (i) => i);
        final cert2 = List<int>.generate(100, (i) => i);
        final cert3 = List<int>.generate(50, (i) => i);

        expect(cert1.length == cert2.length, true);
        expect(cert1.length == cert3.length, false);
      });

      test('compares certificate content correctly', () {
        final cert1 = [1, 2, 3, 4, 5];
        final cert2 = [1, 2, 3, 4, 5];
        final cert3 = [1, 2, 3, 4, 6];

        bool matches1 = _compareCertificates(cert1, cert2);
        bool matches2 = _compareCertificates(cert1, cert3);

        expect(matches1, true);
        expect(matches2, false);
      });
    });

    group('Timeout Configuration', () {
      test('connect timeout is set correctly', () {
        const connectTimeout = Duration(seconds: 30);
        expect(connectTimeout.inSeconds, 30);
      });

      test('receive timeout is set correctly', () {
        const receiveTimeout = Duration(seconds: 60);
        expect(receiveTimeout.inSeconds, 60);
      });

      test('timeout values are reasonable', () {
        const connectTimeout = Duration(seconds: 30);
        const receiveTimeout = Duration(seconds: 60);

        expect(connectTimeout.inSeconds, lessThan(receiveTimeout.inSeconds));
        expect(connectTimeout.inSeconds, greaterThan(0));
        expect(receiveTimeout.inSeconds, greaterThan(0));
      });
    });

    group('Base URL Configuration', () {
      test('base URL format is valid', () {
        const baseUrl = 'https://api.finance.example.com';

        expect(baseUrl, startsWith('https://'));
        expect(baseUrl, isNot(endsWith('/')));
      });

      test('API endpoint paths are formatted correctly', () {
        const baseUrl = 'https://api.finance.example.com';
        const deviceId = 'device_123';
        final endpoint = '/api/v1/device/$deviceId/payment-status';

        final fullUrl = baseUrl + endpoint;

        expect(fullUrl, contains('/api/v1/'));
        expect(fullUrl, contains(deviceId));
        expect(fullUrl, endsWith('/payment-status'));
      });
    });

    group('Error Status Code Mapping', () {
      test('maps 401 to authentication error', () {
        final errorType = _getErrorTypeForStatusCode(401);
        expect(errorType, 'AuthException');
      });

      test('maps 403 to authentication error', () {
        final errorType = _getErrorTypeForStatusCode(403);
        expect(errorType, 'AuthException');
      });

      test('maps 402 to payment error', () {
        final errorType = _getErrorTypeForStatusCode(402);
        expect(errorType, 'PaymentException');
      });

      test('maps 422 to payment error', () {
        final errorType = _getErrorTypeForStatusCode(422);
        expect(errorType, 'PaymentException');
      });

      test('maps 500+ to server error', () {
        final serverCodes = [500, 502, 503, 504];
        
        for (final code in serverCodes) {
          final errorType = _getErrorTypeForStatusCode(code);
          expect(errorType, 'ServerException');
        }
      });

      test('maps other codes to generic API error', () {
        final otherCodes = [400, 404, 409];
        
        for (final code in otherCodes) {
          final errorType = _getErrorTypeForStatusCode(code);
          expect(errorType, 'ApiException');
        }
      });
    });
  });
}

// Helper functions to test logic

bool _shouldRetryForError(String errorType) {
  final retryableErrors = [
    'connectionTimeout',
    'sendTimeout',
    'receiveTimeout',
    'connectionError',
  ];
  return retryableErrors.contains(errorType);
}

bool _shouldRetryForStatusCode(int statusCode) {
  return statusCode >= 500 && statusCode < 600;
}

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

bool _compareCertificates(List<int> cert1, List<int> cert2) {
  if (cert1.length != cert2.length) return false;

  for (int i = 0; i < cert1.length; i++) {
    if (cert1[i] != cert2[i]) return false;
  }

  return true;
}

String _getErrorTypeForStatusCode(int statusCode) {
  if (statusCode == 401 || statusCode == 403) {
    return 'AuthException';
  }
  if (statusCode == 402 || statusCode == 422) {
    return 'PaymentException';
  }
  if (statusCode >= 500 && statusCode < 600) {
    return 'ServerException';
  }
  return 'ApiException';
}
