import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'dart:convert';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  
  factory SecureStorageService() {
    return _instance;
  }

  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Storage keys
  static const String _jwtTokenKey = 'jwt_token';
  static const String _deviceIdKey = 'device_id';
  static const String _databasePasswordKey = 'database_password';
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _deviceFingerprintKey = 'device_fingerprint';

  // JWT Token operations
  Future<void> storeJwtToken(String token) async {
    await _storage.write(key: _jwtTokenKey, value: token);
  }

  Future<String?> getJwtToken() async {
    return await _storage.read(key: _jwtTokenKey);
  }

  Future<void> deleteJwtToken() async {
    await _storage.delete(key: _jwtTokenKey);
  }

  // Device ID operations
  Future<void> storeDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return await _storage.read(key: _deviceIdKey);
  }

  Future<void> deleteDeviceId() async {
    await _storage.delete(key: _deviceIdKey);
  }

  // Database password operations
  Future<String> generateAndStoreDatabasePassword() async {
    // Check if password already exists
    final existingPassword = await _storage.read(key: _databasePasswordKey);
    if (existingPassword != null && existingPassword.isNotEmpty) {
      return existingPassword;
    }

    // Generate a new secure password
    final password = _generateSecurePassword(32);
    await _storage.write(key: _databasePasswordKey, value: password);
    return password;
  }

  Future<String?> getDatabasePassword() async {
    return await _storage.read(key: _databasePasswordKey);
  }

  Future<void> deleteDatabasePassword() async {
    await _storage.delete(key: _databasePasswordKey);
  }

  // Encryption key operations
  Future<void> storeEncryptionKey(String key) async {
    await _storage.write(key: _encryptionKeyKey, value: key);
  }

  Future<String?> getEncryptionKey() async {
    return await _storage.read(key: _encryptionKeyKey);
  }

  Future<String> generateAndStoreEncryptionKey() async {
    // Check if key already exists
    final existingKey = await _storage.read(key: _encryptionKeyKey);
    if (existingKey != null && existingKey.isNotEmpty) {
      return existingKey;
    }

    // Generate a new encryption key
    final key = _generateSecurePassword(64);
    await _storage.write(key: _encryptionKeyKey, value: key);
    return key;
  }

  Future<void> deleteEncryptionKey() async {
    await _storage.delete(key: _encryptionKeyKey);
  }

  // Device fingerprint operations
  Future<void> storeDeviceFingerprint(String fingerprint) async {
    await _storage.write(key: _deviceFingerprintKey, value: fingerprint);
  }

  Future<String?> getDeviceFingerprint() async {
    return await _storage.read(key: _deviceFingerprintKey);
  }

  Future<void> deleteDeviceFingerprint() async {
    await _storage.delete(key: _deviceFingerprintKey);
  }

  // Clear all secure storage (used on release code validation)
  Future<void> clearAllSecureStorage() async {
    await _storage.deleteAll();
  }

  // Check if secure storage is initialized
  Future<bool> isInitialized() async {
    final deviceId = await getDeviceId();
    final dbPassword = await getDatabasePassword();
    return deviceId != null && dbPassword != null;
  }

  // Store custom key-value pair
  Future<void> storeCustomValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Retrieve custom key-value pair
  Future<String?> getCustomValue(String key) async {
    return await _storage.read(key: key);
  }

  // Delete custom key-value pair
  Future<void> deleteCustomValue(String key) async {
    await _storage.delete(key: key);
  }

  // Get all stored keys
  Future<Map<String, String>> getAllValues() async {
    return await _storage.readAll();
  }

  // Private helper method to generate secure random password
  String _generateSecurePassword(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final random = Random.secure();
    final password = List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return password;
  }

  // Store multiple values at once
  Future<void> storeMultipleValues(Map<String, String> values) async {
    for (final entry in values.entries) {
      await _storage.write(key: entry.key, value: entry.value);
    }
  }

  // Check if a specific key exists
  Future<bool> containsKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }
}
