import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:zaracfinance/services/payment_api_service.dart';
import 'package:zaracfinance/services/database_helper.dart';
import 'package:zaracfinance/services/secure_storage_service.dart';
import 'package:zaracfinance/services/background_tasks.dart';
import 'package:zaracfinance/services/grace_period_manager.dart';
import 'package:zaracfinance/services/exceptions/api_exceptions.dart';
import 'package:zaracfinance/models/payment_schedule.dart';
import 'package:zaracfinance/models/payment_history.dart';
import 'package:zaracfinance/models/sync_queue_item.dart';
import 'package:zaracfinance/models/device_config.dart';
import 'package:zaracfinance/utils/tamper_guard.dart';

/// Service class for payment operations
class PaymentService {
  final PaymentApiService _apiService = PaymentApiService();
  final DatabaseHelper _db = DatabaseHelper();
  final SecureStorageService _secureStorage = SecureStorageService();
  final Connectivity _connectivity = Connectivity();
  final GracePeriodManager _gracePeriodManager = GracePeriodManager();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Set<String> _processedTransactionIds = {};

  /// Check payment status with backend
  Future<PaymentStatusResponse> checkPaymentStatus() async {
    try {
      final deviceId = await _getDeviceId();
      final response = await _apiService.getPaymentStatus(deviceId);

      // Update local database with latest status
      await _updateLocalPaymentStatus(response);

      // End grace period on successful verification
      await _gracePeriodManager.endGracePeriod();

      return response;
    } on NetworkException catch (e) {
      // Start grace period if not already active
      final isGracePeriodActive = await _gracePeriodManager.isGracePeriodActive();
      if (!isGracePeriodActive) {
        await _gracePeriodManager.startGracePeriod();
      }

      // Queue for retry when network is unavailable
      await _queuePaymentCheck();
      rethrow;
    } catch (e) {
      // Start grace period for other errors as well
      final isGracePeriodActive = await _gracePeriodManager.isGracePeriodActive();
      if (!isGracePeriodActive) {
        await _gracePeriodManager.startGracePeriod();
      }
      rethrow;
    }
  }

  /// Check if device should be locked considering grace period
  Future<bool> shouldLockDevice() async {
    // Check if there are overdue payments
    final overduePayments = await _db.getOverduePayments();
    if (overduePayments.isEmpty) {
      return false;
    }

    // Check grace period status
    final gracePeriodStatus = await _gracePeriodManager.getGracePeriodStatus();
    
    // If grace period is active and not expired, don't lock
    if (gracePeriodStatus.isActive && !gracePeriodStatus.hasExpired) {
      return false;
    }

    // If grace period has expired or is not active, lock device
    return true;
  }

  /// Process a user-initiated payment
  Future<PaymentSubmissionResponse> processPayment({
    required double amount,
    required String method,
    Map<String, dynamic>? metadata,
  }) async {
    // Run tamper check before processing payment
    final canProceed = await TamperGuard.checkBeforeCriticalOperation('payment');
    if (!canProceed) {
      throw PaymentException(
        'Payment blocked due to security violation',
        statusCode: 403,
      );
    }
    
    try {
      final deviceId = await _getDeviceId();
      
      // Submit payment to backend
      final response = await _apiService.submitPayment(
        deviceId: deviceId,
        amount: amount,
        method: method,
        metadata: metadata,
      );

      // Save to local payment history
      final paymentHistory = PaymentHistory(
        transactionId: response.transactionId,
        amount: response.amount,
        timestamp: response.timestamp,
        status: _mapTransactionStatus(response.status),
        method: method,
      );
      await _db.insertPaymentHistory(paymentHistory);

      // Update payment schedule if payment was successful
      if (response.status == 'SUCCESS') {
        await _updatePaymentScheduleAfterPayment(response);
        
        // Send status report on successful payment
        BackgroundTasksService.sendStatusReportOnCriticalEvent('payment_success');
      }

      return response;
    } on NetworkException catch (e) {
      // Queue payment for retry when network is unavailable
      await _queuePaymentOperation(amount, method, metadata);
      rethrow;
    } catch (e) {
      // Save failed payment attempt to history
      final failedPayment = PaymentHistory(
        transactionId: 'local_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        timestamp: DateTime.now(),
        status: TransactionStatus.failed,
        method: method,
      );
      await _db.insertPaymentHistory(failedPayment);
      rethrow;
    }
  }

  /// Synchronize payment history with backend
  Future<void> syncPaymentHistory() async {
    try {
      final deviceId = await _getDeviceId();
      
      // Fetch payment history from backend
      final remoteHistory = await _apiService.getPaymentHistory(
        deviceId: deviceId,
        limit: 100,
      );

      // Fetch and update payment schedule
      final scheduleResponse = await _apiService.getPaymentSchedule(deviceId);

      // Use transaction for batch updates to improve performance
      await _db.batchUpdatePaymentData(
        paymentHistory: remoteHistory,
        paymentSchedules: scheduleResponse.installments,
      );
    } on NetworkException catch (e) {
      // Queue sync for retry
      await _queueSyncOperation();
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Validate release code for full payment
  Future<ReleaseCodeVerificationResponse> validateReleaseCode(String code) async {
    try {
      final deviceId = await _getDeviceId();
      
      final response = await _apiService.verifyReleaseCode(
        deviceId: deviceId,
        code: code,
      );

      // If device is released, update local state
      if (response.deviceReleased) {
        await _markDeviceAsReleased();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get device ID from secure storage
  Future<String> _getDeviceId() async {
    final deviceId = await _secureStorage.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      throw Exception('Device ID not found. Please register the device.');
    }
    return deviceId;
  }

  /// Update local payment status from backend response
  Future<void> _updateLocalPaymentStatus(PaymentStatusResponse response) async {
    // Store payment status in device config
    await _db.insertDeviceConfig(
      DeviceConfig(
        key: 'payment_status',
        value: response.status,
        lastUpdated: DateTime.now(),
      ),
    );

    await _db.insertDeviceConfig(
      DeviceConfig(
        key: 'remaining_balance',
        value: response.remainingBalance.toString(),
        lastUpdated: DateTime.now(),
      ),
    );

    await _db.insertDeviceConfig(
      DeviceConfig(
        key: 'is_overdue',
        value: response.isOverdue.toString(),
        lastUpdated: DateTime.now(),
      ),
    );

    if (response.nextPaymentDue != null) {
      await _db.insertDeviceConfig(
        DeviceConfig(
          key: 'next_payment_due',
          value: response.nextPaymentDue!.toIso8601String(),
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  /// Update payment schedule after successful payment
  Future<void> _updatePaymentScheduleAfterPayment(
    PaymentSubmissionResponse response,
  ) async {
    // Fetch updated schedule from backend
    try {
      final deviceId = await _getDeviceId();
      final scheduleResponse = await _apiService.getPaymentSchedule(deviceId);
      
      for (final schedule in scheduleResponse.installments) {
        await _db.insertPaymentSchedule(schedule);
      }
    } catch (e) {
      // If we can't fetch updated schedule, just log the error
      // The next sync will update it
      print('Failed to update payment schedule: $e');
    }
  }

  /// Queue payment check for retry
  Future<void> _queuePaymentCheck() async {
    final queueItem = SyncQueueItem(
      type: SyncType.payment,
      payload: jsonEncode({'action': 'check_status'}),
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    await _db.insertSyncQueueItem(queueItem);
  }

  /// Queue payment operation for retry
  Future<void> _queuePaymentOperation(
    double amount,
    String method,
    Map<String, dynamic>? metadata,
  ) async {
    final queueItem = SyncQueueItem(
      type: SyncType.payment,
      payload: jsonEncode({
        'action': 'process_payment',
        'amount': amount,
        'method': method,
        'metadata': metadata ?? {},
      }),
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    await _db.insertSyncQueueItem(queueItem);
  }

  /// Queue sync operation for retry
  Future<void> _queueSyncOperation() async {
    final queueItem = SyncQueueItem(
      type: SyncType.payment,
      payload: jsonEncode({'action': 'sync_history'}),
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    await _db.insertSyncQueueItem(queueItem);
  }

  /// Mark device as released after successful release code validation
  Future<void> _markDeviceAsReleased() async {
    await _db.insertDeviceConfig(
      DeviceConfig(
        key: 'device_released',
        value: 'true',
        lastUpdated: DateTime.now(),
      ),
    );

    await _db.insertDeviceConfig(
      DeviceConfig(
        key: 'payment_status',
        value: 'PAID_OFF',
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Map API transaction status to local enum
  TransactionStatus _mapTransactionStatus(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return TransactionStatus.success;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'PENDING':
        return TransactionStatus.pending;
      default:
        return TransactionStatus.pending;
    }
  }

  /// Start listening to connectivity changes
  void startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        // Check if we have any connectivity
        final hasConnectivity = results.any((result) => 
          result != ConnectivityResult.none
        );
        
        if (hasConnectivity) {
          // Trigger sync when connectivity is restored
          syncQueuedOperations();
        }
      },
    );
  }

  /// Stop listening to connectivity changes
  void stopConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Sync all queued operations with batching
  Future<void> syncQueuedOperations() async {
    try {
      // Check if we have connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnectivity = connectivityResult.any((result) => 
        result != ConnectivityResult.none
      );
      
      if (!hasConnectivity) {
        return; // No connectivity, skip sync
      }

      // Get all queued items
      final queuedItems = await _db.getAllSyncQueueItems();
      
      if (queuedItems.isEmpty) {
        return; // Nothing to sync
      }

      final successfulIds = <int>[];
      final itemsToUpdate = <SyncQueueItem>[];
      final itemsToDelete = <int>[];

      // Process each queued item
      for (final item in queuedItems) {
        try {
          await _processSyncQueueItem(item);
          // Mark for deletion after successful processing
          successfulIds.add(item.id!);
        } catch (e) {
          // Increment retry count
          final updatedItem = item.copyWith(
            retryCount: item.retryCount + 1,
          );
          
          // Remove item if retry count exceeds limit (e.g., 5 retries)
          if (updatedItem.retryCount >= 5) {
            itemsToDelete.add(item.id!);
            print('Removed queue item after max retries: ${item.id}');
          } else {
            itemsToUpdate.add(updatedItem);
          }
        }
      }

      // Batch delete successful and expired items
      final allIdsToDelete = [...successfulIds, ...itemsToDelete];
      if (allIdsToDelete.isNotEmpty) {
        await _db.batchDeleteSyncQueueItems(allIdsToDelete);
      }

      // Update items that need retry
      for (final item in itemsToUpdate) {
        await _db.updateSyncQueueItem(item);
      }
    } catch (e) {
      print('Error syncing queued operations: $e');
    }
  }

  /// Process a single sync queue item
  Future<void> _processSyncQueueItem(SyncQueueItem item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    final action = payload['action'] as String?;

    switch (action) {
      case 'check_status':
        await checkPaymentStatus();
        break;
        
      case 'process_payment':
        final amount = payload['amount'] as double;
        final method = payload['method'] as String;
        final metadata = payload['metadata'] as Map<String, dynamic>?;
        
        // Check for duplicate transaction
        final transactionKey = '${amount}_${method}_${item.timestamp.millisecondsSinceEpoch}';
        if (_processedTransactionIds.contains(transactionKey)) {
          return; // Skip duplicate
        }
        
        final response = await _apiService.submitPayment(
          deviceId: await _getDeviceId(),
          amount: amount,
          method: method,
          metadata: metadata,
        );
        
        // Mark as processed
        _processedTransactionIds.add(transactionKey);
        
        // Update local history
        final paymentHistory = PaymentHistory(
          transactionId: response.transactionId,
          amount: response.amount,
          timestamp: response.timestamp,
          status: _mapTransactionStatus(response.status),
          method: method,
        );
        await _db.insertPaymentHistory(paymentHistory);
        break;
        
      case 'sync_history':
        await syncPaymentHistory();
        break;
        
      default:
        print('Unknown sync action: $action');
    }
  }

  /// Get pending sync queue count
  Future<int> getPendingSyncCount() async {
    final items = await _db.getAllSyncQueueItems();
    return items.length;
  }

  /// Clear processed transaction IDs cache
  void clearProcessedTransactionCache() {
    _processedTransactionIds.clear();
  }

  /// Dispose resources
  void dispose() {
    stopConnectivityListener();
    clearProcessedTransactionCache();
  }
}
