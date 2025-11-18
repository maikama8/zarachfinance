import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/config.dart';
import 'api_client.dart';

class RealtimeService {
  static RealtimeService? _instance;
  final Map<String, Function(Map<String, dynamic>)> _listeners = {};
  bool _isConnected = false;
  Timer? _reconnectTimer;

  RealtimeService._();

  static RealtimeService get instance {
    _instance ??= RealtimeService._();
    return _instance!;
  }

  Future<void> connect(String deviceId) async {
    if (_isConnected) {
      return;
    }

    try {
      // For Socket.IO, we need to use a Socket.IO client library
      // For now, use polling approach with periodic API calls
      // TODO: Add socket_io_client package for proper Socket.IO support
      debugPrint('Real-time service: Using polling mode (Socket.IO client to be added)');
      
      // Start polling for updates
      _startPolling(deviceId);
    } catch (e) {
      debugPrint('Error connecting real-time service: $e');
      _scheduleReconnect(deviceId);
    }
  }

  void _startPolling(String deviceId) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // Poll for device updates
        final status = await ApiClient.getPaymentStatus(deviceId);
        _notifyListeners('device:update', {
          'type': 'status',
          'deviceId': deviceId,
          'isLocked': status.isPaymentOverdue,
          'remainingBalance': status.remainingBalance,
          'isFullyPaid': status.isFullyPaid,
        });
        _isConnected = true;
      } catch (e) {
        debugPrint('Error polling for updates: $e');
        _isConnected = false;
      }
    });
    _isConnected = true;
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      final event = data['event'] as String?;
      final payload = data['data'] as Map<String, dynamic>?;

      if (event != null && payload != null) {
        _notifyListeners(event, payload);
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  void _notifyListeners(String event, Map<String, dynamic> data) {
    _listeners.forEach((key, callback) {
      if (key == event || key == '*') {
        callback(data);
      }
    });
  }

  void on(String event, Function(Map<String, dynamic>) callback) {
    _listeners[event] = callback;
  }

  void off(String event) {
    _listeners.remove(event);
  }

  void _scheduleReconnect(String deviceId) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect(deviceId);
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _isConnected = false;
    _listeners.clear();
  }

  bool get isConnected => _isConnected;
}

