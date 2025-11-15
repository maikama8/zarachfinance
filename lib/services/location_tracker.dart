import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zaracfinance/services/device_api_service.dart';
import 'package:zaracfinance/services/database_helper.dart';
import 'package:zaracfinance/services/secure_storage_service.dart';
import 'package:zaracfinance/services/exceptions/api_exceptions.dart';
import 'package:zaracfinance/models/sync_queue_item.dart';

/// Service class for tracking and transmitting device location
class LocationTracker {
  final DeviceApiService _apiService = DeviceApiService();
  final DatabaseHelper _db = DatabaseHelper();
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Capture current device location
  /// Uses coarse location (LocationAccuracy.low) for privacy
  Future<Position?> captureLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permission
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        print('Location permission not granted');
        return null;
      }

      // Get current position with low accuracy (coarse location)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 30),
      );

      return position;
    } catch (e) {
      print('Error capturing location: $e');
      return null;
    }
  }

  /// Send location to backend
  Future<bool> sendLocationToBackend(Position position) async {
    try {
      // Get device ID from secure storage
      final deviceId = await _secureStorage.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        print('Device ID not found, cannot send location');
        return false;
      }

      // Create location data
      final locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      // Send to backend
      final response = await _apiService.sendLocation(
        deviceId: deviceId,
        location: locationData,
      );

      return response.success;
    } on NetworkException catch (e) {
      print('Network error sending location: $e');
      // Queue for later transmission
      await _queueLocationForSync(position);
      return false;
    } catch (e) {
      print('Error sending location to backend: $e');
      // Queue for later transmission
      await _queueLocationForSync(position);
      return false;
    }
  }

  /// Queue location data for later synchronization
  Future<void> _queueLocationForSync(Position position) async {
    try {
      final locationPayload = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final syncItem = SyncQueueItem(
        type: SyncType.location,
        payload: jsonEncode(locationPayload),
        timestamp: DateTime.now(),
        retryCount: 0,
      );

      await _db.insertSyncQueueItem(syncItem);
      print('Location queued for sync');
    } catch (e) {
      print('Error queuing location for sync: $e');
    }
  }

  /// Capture and send location in one operation
  Future<bool> captureAndSendLocation() async {
    try {
      final position = await captureLocation();
      if (position == null) {
        return false;
      }

      return await sendLocationToBackend(position);
    } catch (e) {
      print('Error in captureAndSendLocation: $e');
      return false;
    }
  }

  /// Sync queued locations to backend with batching
  Future<void> syncQueuedLocations() async {
    try {
      // Get device ID
      final deviceId = await _secureStorage.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        print('Device ID not found, cannot sync locations');
        return;
      }

      // Get all location sync items
      final queuedItems = await _db.getSyncQueueItemsByType(SyncType.location);
      
      if (queuedItems.isEmpty) {
        return;
      }

      print('Syncing ${queuedItems.length} queued locations');

      final successfulIds = <int>[];
      final itemsToUpdate = <SyncQueueItem>[];

      for (final item in queuedItems) {
        try {
          // Parse location data from payload
          final locationMap = jsonDecode(item.payload) as Map<String, dynamic>;
          
          final locationData = LocationData(
            latitude: locationMap['latitude'] as double,
            longitude: locationMap['longitude'] as double,
            accuracy: locationMap['accuracy'] as double?,
            timestamp: DateTime.parse(locationMap['timestamp'] as String),
          );

          // Send to backend
          final response = await _apiService.sendLocation(
            deviceId: deviceId,
            location: locationData,
          );

          if (response.success) {
            // Mark for deletion
            successfulIds.add(item.id!);
            print('Location synced successfully');
          } else {
            // Mark for retry count update
            itemsToUpdate.add(item);
          }
        } on NetworkException catch (e) {
          print('Network error syncing location: $e');
          // Mark for retry count update
          itemsToUpdate.add(item);
        } catch (e) {
          print('Error syncing location item ${item.id}: $e');
          // Mark for retry count update
          itemsToUpdate.add(item);
        }
      }

      // Batch delete successful items
      if (successfulIds.isNotEmpty) {
        await _db.batchDeleteSyncQueueItems(successfulIds);
      }

      // Update retry counts for failed items
      for (final item in itemsToUpdate) {
        await _updateRetryCount(item);
      }
    } catch (e) {
      print('Error syncing queued locations: $e');
    }
  }

  /// Update retry count for a sync queue item
  Future<void> _updateRetryCount(SyncQueueItem item) async {
    final maxRetries = 5;
    final newRetryCount = item.retryCount + 1;

    if (newRetryCount >= maxRetries) {
      // Remove item after max retries
      await _db.deleteSyncQueueItem(item.id!);
      print('Location sync item ${item.id} removed after $maxRetries retries');
    } else {
      // Update retry count
      final updatedItem = item.copyWith(retryCount: newRetryCount);
      await _db.updateSyncQueueItem(updatedItem);
    }
  }
}
