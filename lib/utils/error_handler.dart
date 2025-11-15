import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';
import '../models/error_log.dart';

/// Custom exception classes for different error types

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  NetworkException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'NetworkException: $message (Status: $statusCode)';
}

class AuthException implements Exception {
  final String message;
  final dynamic originalError;

  AuthException(this.message, {this.originalError});

  @override
  String toString() => 'AuthException: $message';
}

class PaymentException implements Exception {
  final String message;
  final String? transactionId;
  final dynamic originalError;

  PaymentException(this.message, {this.transactionId, this.originalError});

  @override
  String toString() => 'PaymentException: $message (Transaction: $transactionId)';
}

class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  DatabaseException(this.message, {this.originalError});

  @override
  String toString() => 'DatabaseException: $message';
}

class TamperException implements Exception {
  final String message;
  final String? detectionType;

  TamperException(this.message, {this.detectionType});

  @override
  String toString() => 'TamperException: $message (Type: $detectionType)';
}

class DeviceAdminException implements Exception {
  final String message;
  final dynamic originalError;

  DeviceAdminException(this.message, {this.originalError});

  @override
  String toString() => 'DeviceAdminException: $message';
}

/// Centralized error handler for consistent error processing
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  final DatabaseHelper _db = DatabaseHelper();

  factory ErrorHandler() {
    return _instance;
  }

  ErrorHandler._internal();

  /// Handle any error with consistent processing
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool logToDatabase = true,
    bool showToUser = true,
  }) async {
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('Error in $context: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    // Log to database for debugging
    if (logToDatabase) {
      await _logErrorToDatabase(error, stackTrace, context);
    }

    // Return user-friendly message if needed
    if (showToUser) {
      // This can be used by UI to show error messages
      // The UI layer should call getUserFriendlyMessage separately
    }
  }

  /// Get user-friendly error message for display
  String getUserFriendlyMessage(dynamic error) {
    if (error is NetworkException) {
      return _getNetworkErrorMessage(error);
    } else if (error is AuthException) {
      return 'Authentication failed. Please try again or contact support.';
    } else if (error is PaymentException) {
      return _getPaymentErrorMessage(error);
    } else if (error is DatabaseException) {
      return 'A local storage error occurred. Please restart the app.';
    } else if (error is TamperException) {
      return 'Security violation detected. Please contact the store immediately.';
    } else if (error is DeviceAdminException) {
      return 'Device admin error. Please contact support.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  String _getNetworkErrorMessage(NetworkException error) {
    if (error.statusCode == null) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    switch (error.statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication failed. Please restart the app.';
      case 403:
        return 'Access denied. Please contact support.';
      case 404:
        return 'Service not found. Please contact support.';
      case 408:
        return 'Request timeout. Please check your connection and try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      case 504:
        return 'Server timeout. Please try again later.';
      default:
        return 'Network error occurred. Please try again.';
    }
  }

  String _getPaymentErrorMessage(PaymentException error) {
    final message = error.message.toLowerCase();
    
    if (message.contains('insufficient')) {
      return 'Insufficient funds. Please check your account balance.';
    } else if (message.contains('timeout')) {
      return 'Payment processing timeout. Please check if payment was successful.';
    } else if (message.contains('duplicate')) {
      return 'Duplicate transaction detected. Please check your payment history.';
    } else if (message.contains('invalid')) {
      return 'Invalid payment details. Please check and try again.';
    } else if (message.contains('declined')) {
      return 'Payment declined. Please try a different payment method.';
    } else {
      return 'Payment failed. Please try again or contact support.';
    }
  }

  /// Log error to local database for debugging
  Future<void> _logErrorToDatabase(
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  ) async {
    try {
      final errorLog = ErrorLog(
        timestamp: DateTime.now(),
        errorType: error.runtimeType.toString(),
        message: error.toString(),
        stackTrace: stackTrace?.toString(),
        context: context,
      );

      await _db.insertErrorLog(errorLog);

      // Clean up old logs (keep only last 100)
      await _cleanupOldLogs();
    } catch (e) {
      // If logging fails, just print to console
      if (kDebugMode) {
        debugPrint('Failed to log error to database: $e');
      }
    }
  }

  /// Clean up old error logs to prevent database bloat
  Future<void> _cleanupOldLogs() async {
    try {
      final logs = await _db.getAllErrorLogs();
      if (logs.length > 100) {
        // Keep only the most recent 100 logs
        final logsToDelete = logs.skip(100).toList();
        for (final log in logsToDelete) {
          if (log.id != null) {
            await _db.deleteErrorLog(log.id!);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to cleanup old logs: $e');
      }
    }
  }

  /// Get recent error logs for diagnostics
  Future<List<ErrorLog>> getRecentErrors({int limit = 50}) async {
    try {
      return await _db.getRecentErrorLogs(limit: limit);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get recent errors: $e');
      }
      return [];
    }
  }

  /// Clear all error logs
  Future<void> clearErrorLogs() async {
    try {
      await _db.clearErrorLogs();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to clear error logs: $e');
      }
    }
  }

  /// Get error statistics for diagnostics
  Future<Map<String, int>> getErrorStatistics() async {
    try {
      final logs = await _db.getAllErrorLogs();
      final stats = <String, int>{};

      for (final log in logs) {
        stats[log.errorType] = (stats[log.errorType] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get error statistics: $e');
      }
      return {};
    }
  }
}
