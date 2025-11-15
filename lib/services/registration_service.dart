import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:zaracfinance/platform_channels/device_identifier_channel.dart';
import 'package:zaracfinance/services/device_api_service.dart';
import 'package:zaracfinance/services/secure_storage_service.dart';
import 'package:zaracfinance/services/database_helper.dart';
import 'package:zaracfinance/models/device_config.dart';
import 'package:zaracfinance/models/payment_schedule.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as developer;

/// Service class for device registration and onboarding
class RegistrationService {
  final DeviceIdentifierChannel _deviceIdentifierChannel = DeviceIdentifierChannel();
  final DeviceApiService _deviceApiService = DeviceApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final DatabaseHelper _db = DatabaseHelper();

  /// Collect comprehensive device information
  /// Returns a map with all device identifiers and hardware info
  Future<Map<String, String>> collectDeviceInfo() async {
    try {
      developer.log('Collecting device information', name: 'RegistrationService');
      
      // Get device info from platform channel
      final deviceInfo = await _deviceIdentifierChannel.getDeviceInfo();
      
      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      deviceInfo['appVersion'] = packageInfo.version;
      deviceInfo['buildNumber'] = packageInfo.buildNumber;
      
      developer.log(
        'Device info collected: ${deviceInfo.keys.length} fields',
        name: 'RegistrationService',
      );
      
      return deviceInfo;
    } catch (e) {
      developer.log(
        'Error collecting device info',
        name: 'RegistrationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Generate a unique device fingerprint
  /// Combines multiple device identifiers to create a unique hash
  /// Returns the fingerprint string
  Future<String> generateDeviceFingerprint() async {
    try {
      developer.log('Generating device fingerprint', name: 'RegistrationService');
      
      final deviceInfo = await collectDeviceInfo();
      
      // Combine key identifiers
      final fingerprintData = [
        deviceInfo['imei'] ?? '',
        deviceInfo['androidId'] ?? '',
        deviceInfo['model'] ?? '',
        deviceInfo['manufacturer'] ?? '',
        deviceInfo['hardware'] ?? '',
        deviceInfo['board'] ?? '',
      ].join('|');
      
      // Generate SHA-256 hash
      final bytes = utf8.encode(fingerprintData);
      final digest = sha256.convert(bytes);
      final fingerprint = digest.toString();
      
      // Store fingerprint in secure storage
      await _secureStorage.storeDeviceFingerprint(fingerprint);
      
      developer.log(
        'Device fingerprint generated',
        name: 'RegistrationService',
      );
      
      return fingerprint;
    } catch (e) {
      developer.log(
        'Error generating device fingerprint',
        name: 'RegistrationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Register device with backend
  /// @param customerId The customer ID from the store
  /// Returns the device registration response
  Future<DeviceRegistrationResponse> registerDevice({
    required String customerId,
  }) async {
    try {
      developer.log(
        'Starting device registration for customer: $customerId',
        name: 'RegistrationService',
      );
      
      // Collect device information
      final deviceInfo = await collectDeviceInfo();
      
      // Generate device fingerprint
      final fingerprint = await generateDeviceFingerprint();
      
      // Create registration request
      final request = DeviceRegistrationRequest(
        imei: deviceInfo['imei'] ?? '',
        androidId: deviceInfo['androidId'] ?? '',
        model: deviceInfo['model'] ?? '',
        manufacturer: deviceInfo['manufacturer'] ?? '',
        osVersion: deviceInfo['osVersion'] ?? '',
        appVersion: deviceInfo['appVersion'] ?? '',
        deviceFingerprint: fingerprint,
        customerId: customerId,
      );
      
      // Send registration request to backend
      developer.log('Sending registration request to backend', name: 'RegistrationService');
      final response = await _deviceApiService.registerDevice(request);
      
      // Store registration data
      await _storeRegistrationData(response);
      
      developer.log(
        'Device registration completed successfully',
        name: 'RegistrationService',
      );
      
      return response;
    } catch (e) {
      developer.log(
        'Error during device registration',
        name: 'RegistrationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Store registration data locally
  /// Saves JWT token, device ID, payment schedule, and device config
  Future<void> _storeRegistrationData(DeviceRegistrationResponse response) async {
    try {
      developer.log('Storing registration data', name: 'RegistrationService');
      
      // Store JWT token in secure storage
      await _secureStorage.storeJwtToken(response.jwtToken);
      developer.log('JWT token stored', name: 'RegistrationService');
      
      // Store device ID in secure storage
      await _secureStorage.storeDeviceId(response.deviceId);
      developer.log('Device ID stored', name: 'RegistrationService');
      
      // Store token expiry in device config
      final tokenExpiryConfig = DeviceConfig(
        key: 'token_expiry',
        value: response.tokenExpiry.toIso8601String(),
        lastUpdated: DateTime.now(),
      );
      await _db.insertDeviceConfig(tokenExpiryConfig);
      
      // Store registration status
      final registrationConfig = DeviceConfig(
        key: 'is_registered',
        value: 'true',
        lastUpdated: DateTime.now(),
      );
      await _db.insertDeviceConfig(registrationConfig);
      
      // Store registration timestamp
      final registrationTimestampConfig = DeviceConfig(
        key: 'registration_timestamp',
        value: DateTime.now().toIso8601String(),
        lastUpdated: DateTime.now(),
      );
      await _db.insertDeviceConfig(registrationTimestampConfig);
      
      // Store payment schedule
      await _storePaymentSchedule(response.paymentSchedule);
      
      // Store device configuration
      await _storeDeviceConfig(response.deviceConfig);
      
      developer.log('Registration data stored successfully', name: 'RegistrationService');
    } catch (e) {
      developer.log(
        'Error storing registration data',
        name: 'RegistrationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Store payment schedule from backend response
  Future<void> _storePaymentSchedule(Map<String, dynamic> scheduleData) async {
    try {
      developer.log('Storing payment schedule', name: 'RegistrationService');
      
      // Extract installments from schedule data
      final installments = scheduleData['installments'] as List<dynamic>?;
      
      if (installments == null || installments.isEmpty) {
        developer.log('No installments in payment schedule', name: 'RegistrationService');
        return;
      }
      
      // Store each installment as a payment schedule entry
      for (final installment in installments) {
        final installmentMap = installment as Map<String, dynamic>;
        
        final paymentSchedule = PaymentSchedule(
          id: installmentMap['installmentId'] as String,
          dueDate: DateTime.parse(installmentMap['dueDate'] as String),
          amount: (installmentMap['amount'] as num).toDouble(),
          status: _parsePaymentStatus(installmentMap['status'] as String),
          paidDate: installmentMap['paidDate'] != null
              ? DateTime.parse(installmentMap['paidDate'] as String)
              : null,
        );
        
        await _db.insertPaymentSchedule(paymentSchedule);
      }
      
      developer.log(
        'Stored ${installments.length} payment schedule entries',
        name: 'RegistrationService',
      );
    } catch (e) {
      developer.log(
        'Error storing payment schedule',
        name: 'RegistrationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Store device configuration from backend response
  Future<void> _storeDeviceConfig(Map<String, dynamic> configData) async {
    try {
      developer.log('Storing device configuration', name: 'RegistrationService');
      
      // Store each config key-value pair
      for (final entry in configData.entries) {
        final config = DeviceConfig(
          key: 'backend_${entry.key}',
          value: entry.value.toString(),
          lastUpdated: DateTime.now(),
        );
        
        await _db.insertDeviceConfig(config);
      }
      
      developer.log(
        'Stored ${configData.length} device config entries',
        name: 'RegistrationService',
      );
    } catch (e) {
      developer.log(
        'Error storing device configuration',
        name: 'RegistrationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Parse payment status string to enum
  PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return PaymentStatus.paid;
      case 'OVERDUE':
        return PaymentStatus.overdue;
      case 'PENDING':
      default:
        return PaymentStatus.pending;
    }
  }

  /// Check if device is already registered
  /// Returns true if device has been registered
  Future<bool> isDeviceRegistered() async {
    try {
      final config = await _db.getDeviceConfig('is_registered');
      return config?.value.toLowerCase() == 'true';
    } catch (e) {
      developer.log(
        'Error checking registration status',
        name: 'RegistrationService',
        error: e,
      );
      return false;
    }
  }

  /// Get stored device ID
  /// Returns the device ID or null if not registered
  Future<String?> getDeviceId() async {
    try {
      return await _secureStorage.getDeviceId();
    } catch (e) {
      developer.log(
        'Error getting device ID',
        name: 'RegistrationService',
        error: e,
      );
      return null;
    }
  }

  /// Clear registration data (for testing or re-registration)
  Future<void> clearRegistrationData() async {
    try {
      developer.log('Clearing registration data', name: 'RegistrationService');
      
      // Clear secure storage
      await _secureStorage.deleteJwtToken();
      await _secureStorage.deleteDeviceId();
      await _secureStorage.deleteDeviceFingerprint();
      
      // Clear database
      await _db.deleteDeviceConfig('is_registered');
      await _db.deleteDeviceConfig('registration_timestamp');
      await _db.deleteDeviceConfig('token_expiry');
      
      developer.log('Registration data cleared', name: 'RegistrationService');
    } catch (e) {
      developer.log(
        'Error clearing registration data',
        name: 'RegistrationService',
        error: e,
      );
      rethrow;
    }
  }
}
