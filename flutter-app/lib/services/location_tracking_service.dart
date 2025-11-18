import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../models/api_models.dart';

class LocationTrackingService {
  static Future<bool> _checkPermissions() async {
    final status = await Permission.location.status;
    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  static Future<void> updateLocation() async {
    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';
      
      if (deviceId.isEmpty) {
        return;
      }

      final request = LocationRequest(
        deviceId: deviceId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        accuracy: position.accuracy,
      );

      await ApiClient.reportLocation(request);
    } catch (e) {
      // Queue for later if offline
      debugPrint('Error updating location: $e');
    }
  }
}

