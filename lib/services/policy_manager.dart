import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:zaracfinance/services/device_api_service.dart';
import 'package:zaracfinance/services/database_helper.dart';
import 'package:zaracfinance/services/lock_service.dart';
import 'package:zaracfinance/services/secure_storage_service.dart';
import 'package:zaracfinance/models/device_config.dart';
import 'package:zaracfinance/services/exceptions/api_exceptions.dart';

/// Policy configuration model
class PolicyConfig {
  final String policyId;
  final String policyType;
  final Map<String, dynamic> settings;
  final DateTime effectiveDate;
  final DateTime? expiryDate;

  PolicyConfig({
    required this.policyId,
    required this.policyType,
    required this.settings,
    required this.effectiveDate,
    this.expiryDate,
  });

  factory PolicyConfig.fromJson(Map<String, dynamic> json) {
    return PolicyConfig(
      policyId: json['policyId'] as String,
      policyType: json['policyType'] as String,
      settings: json['settings'] as Map<String, dynamic>,
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policyId': policyId,
      'policyType': policyType,
      'settings': settings,
      'effectiveDate': effectiveDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}

/// Remote command model
class RemoteCommand {
  final String commandId;
  final String commandType; // 'unlock', 'lock', 'message'
  final Map<String, dynamic> parameters;
  final DateTime issuedAt;
  final DateTime? expiresAt;

  RemoteCommand({
    required this.commandId,
    required this.commandType,
    required this.parameters,
    required this.issuedAt,
    this.expiresAt,
  });

  factory RemoteCommand.fromJson(Map<String, dynamic> json) {
    return RemoteCommand(
      commandId: json['commandId'] as String,
      commandType: json['commandType'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Service for managing remote policies and commands
class PolicyManager {
  final DeviceApiService _apiService = DeviceApiService();
  final DatabaseHelper _db = DatabaseHelper();
  final SecureStorageService _secureStorage = SecureStorageService();
  final LockService _lockService = LockService();

  /// Fetch policy updates from backend
  Future<List<PolicyConfig>> fetchPolicyUpdates() async {
    try {
      developer.log('Fetching policy updates', name: 'PolicyManager');

      final deviceId = await _secureStorage.getDeviceId();
      if (deviceId == null) {
        throw Exception('Device ID not found');
      }

      final configData = await _apiService.getDeviceConfig(deviceId);

      if (configData['policies'] == null) {
        developer.log('No policies in response', name: 'PolicyManager');
        return [];
      }

      final policiesList = configData['policies'] as List<dynamic>;
      final policies = policiesList
          .map((p) => PolicyConfig.fromJson(p as Map<String, dynamic>))
          .toList();

      developer.log(
        'Fetched ${policies.length} policy updates',
        name: 'PolicyManager',
      );

      return policies;
    } on NetworkException catch (e) {
      developer.log(
        'Network error fetching policies',
        name: 'PolicyManager',
        error: e,
      );
      rethrow;
    } catch (e) {
      developer.log(
        'Error fetching policy updates',
        name: 'PolicyManager',
        error: e,
      );
      rethrow;
    }
  }

  /// Apply policy changes to local configuration
  Future<void> applyPolicyChanges(List<PolicyConfig> policies) async {
    try {
      developer.log(
        'Applying ${policies.length} policy changes',
        name: 'PolicyManager',
      );

      for (final policy in policies) {
        // Check if policy is effective
        if (DateTime.now().isBefore(policy.effectiveDate)) {
          developer.log(
            'Policy ${policy.policyId} not yet effective',
            name: 'PolicyManager',
          );
          continue;
        }

        // Check if policy has expired
        if (policy.expiryDate != null &&
            DateTime.now().isAfter(policy.expiryDate!)) {
          developer.log(
            'Policy ${policy.policyId} has expired',
            name: 'PolicyManager',
          );
          continue;
        }

        // Store policy in device_config table
        await _storePolicyConfig(policy);

        // Apply specific policy types
        await _applySpecificPolicy(policy);
      }

      // Update last policy sync timestamp
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'last_policy_sync',
          value: DateTime.now().toIso8601String(),
          lastUpdated: DateTime.now(),
        ),
      );

      developer.log('Policy changes applied successfully', name: 'PolicyManager');
    } catch (e) {
      developer.log(
        'Error applying policy changes',
        name: 'PolicyManager',
        error: e,
      );
      rethrow;
    }
  }

  /// Store policy configuration in database
  Future<void> _storePolicyConfig(PolicyConfig policy) async {
    final configKey = 'policy_${policy.policyType}_${policy.policyId}';
    await _db.insertDeviceConfig(
      DeviceConfig(
        key: configKey,
        value: jsonEncode(policy.toJson()),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Apply specific policy based on type
  Future<void> _applySpecificPolicy(PolicyConfig policy) async {
    switch (policy.policyType) {
      case 'payment_schedule':
        await _applyPaymentSchedulePolicy(policy);
        break;
      case 'lock_settings':
        await _applyLockSettingsPolicy(policy);
        break;
      case 'monitoring':
        await _applyMonitoringPolicy(policy);
        break;
      case 'notification':
        await _applyNotificationPolicy(policy);
        break;
      default:
        developer.log(
          'Unknown policy type: ${policy.policyType}',
          name: 'PolicyManager',
        );
    }
  }

  /// Apply payment schedule policy
  Future<void> _applyPaymentSchedulePolicy(PolicyConfig policy) async {
    developer.log('Applying payment schedule policy', name: 'PolicyManager');
    
    // Store payment schedule settings
    final settings = policy.settings;
    if (settings.containsKey('grace_period_hours')) {
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'payment_grace_period_hours',
          value: settings['grace_period_hours'].toString(),
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  /// Apply lock settings policy
  Future<void> _applyLockSettingsPolicy(PolicyConfig policy) async {
    developer.log('Applying lock settings policy', name: 'PolicyManager');
    
    final settings = policy.settings;
    if (settings.containsKey('lock_delay_hours')) {
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'lock_delay_hours',
          value: settings['lock_delay_hours'].toString(),
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  /// Apply monitoring policy
  Future<void> _applyMonitoringPolicy(PolicyConfig policy) async {
    developer.log('Applying monitoring policy', name: 'PolicyManager');
    
    final settings = policy.settings;
    if (settings.containsKey('location_interval_hours')) {
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'location_interval_hours',
          value: settings['location_interval_hours'].toString(),
          lastUpdated: DateTime.now(),
        ),
      );
    }
    
    if (settings.containsKey('status_report_interval_hours')) {
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'status_report_interval_hours',
          value: settings['status_report_interval_hours'].toString(),
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  /// Apply notification policy
  Future<void> _applyNotificationPolicy(PolicyConfig policy) async {
    developer.log('Applying notification policy', name: 'PolicyManager');
    
    final settings = policy.settings;
    if (settings.containsKey('reminder_hours_before')) {
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'notification_reminder_hours',
          value: jsonEncode(settings['reminder_hours_before']),
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  /// Check for remote commands from backend
  Future<List<RemoteCommand>> checkForRemoteCommands() async {
    try {
      developer.log('Checking for remote commands', name: 'PolicyManager');

      final deviceId = await _secureStorage.getDeviceId();
      if (deviceId == null) {
        throw Exception('Device ID not found');
      }

      final commandsData = await _apiService.checkRemoteCommands(deviceId);

      final commands = commandsData
          .map((c) => RemoteCommand.fromJson(c))
          .where((cmd) => !cmd.isExpired())
          .toList();

      developer.log(
        'Found ${commands.length} pending commands',
        name: 'PolicyManager',
      );

      return commands;
    } on NetworkException catch (e) {
      developer.log(
        'Network error checking commands',
        name: 'PolicyManager',
        error: e,
      );
      rethrow;
    } catch (e) {
      developer.log(
        'Error checking remote commands',
        name: 'PolicyManager',
        error: e,
      );
      rethrow;
    }
  }

  /// Handle unlock command
  Future<void> handleUnlockCommand(RemoteCommand command) async {
    try {
      developer.log(
        'Handling unlock command: ${command.commandId}',
        name: 'PolicyManager',
      );

      // Unlock the device
      await _lockService.unlockDevice();

      // Log the remote unlock event
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'last_remote_unlock',
          value: jsonEncode({
            'commandId': command.commandId,
            'timestamp': DateTime.now().toIso8601String(),
            'issuedAt': command.issuedAt.toIso8601String(),
          }),
          lastUpdated: DateTime.now(),
        ),
      );

      // Send confirmation to backend
      final deviceId = await _secureStorage.getDeviceId();
      if (deviceId != null) {
        await _apiService.acknowledgeCommand(
          deviceId: deviceId,
          commandId: command.commandId,
          success: true,
          message: 'Device unlocked successfully',
        );
      }

      developer.log('Unlock command executed successfully', name: 'PolicyManager');
    } catch (e) {
      developer.log(
        'Error handling unlock command',
        name: 'PolicyManager',
        error: e,
      );

      // Send failure confirmation to backend
      try {
        final deviceId = await _secureStorage.getDeviceId();
        if (deviceId != null) {
          await _apiService.acknowledgeCommand(
            deviceId: deviceId,
            commandId: command.commandId,
            success: false,
            message: 'Failed to unlock device: $e',
          );
        }
      } catch (_) {
        // Ignore acknowledgment errors
      }

      rethrow;
    }
  }

  /// Handle lock command
  Future<void> handleLockCommand(RemoteCommand command) async {
    try {
      developer.log(
        'Handling lock command: ${command.commandId}',
        name: 'PolicyManager',
      );

      // Lock the device
      await _lockService.lockDevice();

      // Log the remote lock event
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'last_remote_lock',
          value: jsonEncode({
            'commandId': command.commandId,
            'timestamp': DateTime.now().toIso8601String(),
            'issuedAt': command.issuedAt.toIso8601String(),
          }),
          lastUpdated: DateTime.now(),
        ),
      );

      // Send confirmation to backend
      final deviceId = await _secureStorage.getDeviceId();
      if (deviceId != null) {
        await _apiService.acknowledgeCommand(
          deviceId: deviceId,
          commandId: command.commandId,
          success: true,
          message: 'Device locked successfully',
        );
      }

      developer.log('Lock command executed successfully', name: 'PolicyManager');
    } catch (e) {
      developer.log(
        'Error handling lock command',
        name: 'PolicyManager',
        error: e,
      );

      // Send failure confirmation to backend
      try {
        final deviceId = await _secureStorage.getDeviceId();
        if (deviceId != null) {
          await _apiService.acknowledgeCommand(
            deviceId: deviceId,
            commandId: command.commandId,
            success: false,
            message: 'Failed to lock device: $e',
          );
        }
      } catch (_) {
        // Ignore acknowledgment errors
      }

      rethrow;
    }
  }

  /// Handle custom message command
  Future<void> handleMessageCommand(RemoteCommand command) async {
    try {
      developer.log(
        'Handling message command: ${command.commandId}',
        name: 'PolicyManager',
      );

      final message = command.parameters['message'] as String?;
      if (message == null || message.isEmpty) {
        throw Exception('Message parameter is required');
      }

      // Store custom message in database
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'custom_lock_message',
          value: message,
          lastUpdated: DateTime.now(),
        ),
      );

      // Store message metadata
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'custom_lock_message_metadata',
          value: jsonEncode({
            'commandId': command.commandId,
            'timestamp': DateTime.now().toIso8601String(),
            'issuedAt': command.issuedAt.toIso8601String(),
          }),
          lastUpdated: DateTime.now(),
        ),
      );

      // Send confirmation to backend
      final deviceId = await _secureStorage.getDeviceId();
      if (deviceId != null) {
        await _apiService.acknowledgeCommand(
          deviceId: deviceId,
          commandId: command.commandId,
          success: true,
          message: 'Custom message set successfully',
        );
      }

      developer.log('Message command executed successfully', name: 'PolicyManager');
    } catch (e) {
      developer.log(
        'Error handling message command',
        name: 'PolicyManager',
        error: e,
      );

      // Send failure confirmation to backend
      try {
        final deviceId = await _secureStorage.getDeviceId();
        if (deviceId != null) {
          await _apiService.acknowledgeCommand(
            deviceId: deviceId,
            commandId: command.commandId,
            success: false,
            message: 'Failed to set custom message: $e',
          );
        }
      } catch (_) {
        // Ignore acknowledgment errors
      }

      rethrow;
    }
  }

  /// Process all pending remote commands
  Future<void> processRemoteCommands() async {
    try {
      final commands = await checkForRemoteCommands();

      for (final command in commands) {
        try {
          switch (command.commandType) {
            case 'unlock':
              await handleUnlockCommand(command);
              break;
            case 'lock':
              await handleLockCommand(command);
              break;
            case 'message':
              await handleMessageCommand(command);
              break;
            default:
              developer.log(
                'Unknown command type: ${command.commandType}',
                name: 'PolicyManager',
              );
          }
        } catch (e) {
          developer.log(
            'Error processing command ${command.commandId}',
            name: 'PolicyManager',
            error: e,
          );
          // Continue processing other commands
        }
      }
    } catch (e) {
      developer.log(
        'Error processing remote commands',
        name: 'PolicyManager',
        error: e,
      );
    }
  }

  /// Get custom lock message if set
  Future<String?> getCustomLockMessage() async {
    final config = await _db.getDeviceConfig('custom_lock_message');
    return config?.value;
  }

  /// Clear custom lock message
  Future<void> clearCustomLockMessage() async {
    await _db.deleteDeviceConfig('custom_lock_message');
    await _db.deleteDeviceConfig('custom_lock_message_metadata');
  }

  /// Sync policies and commands (combined operation)
  Future<void> syncPoliciesAndCommands() async {
    try {
      developer.log('Syncing policies and commands', name: 'PolicyManager');

      // Fetch and apply policy updates
      final policies = await fetchPolicyUpdates();
      if (policies.isNotEmpty) {
        await applyPolicyChanges(policies);
      }

      // Process remote commands
      await processRemoteCommands();

      developer.log('Sync completed successfully', name: 'PolicyManager');
    } catch (e) {
      developer.log(
        'Error during sync',
        name: 'PolicyManager',
        error: e,
      );
    }
  }
}
