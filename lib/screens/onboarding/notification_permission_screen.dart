import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// Screen for requesting notification permission during onboarding (Android 13+)
class NotificationPermissionScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const NotificationPermissionScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _isRequesting = false;
  bool _isChecking = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  /// Check current notification permission status
  Future<void> _checkPermissionStatus() async {
    try {
      final status = await Permission.notification.status;
      setState(() {
        _permissionGranted = status.isGranted;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Notification Permission'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.notifications_active,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Stay Informed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Rationale
              Text(
                'Enable notifications to receive important payment reminders and updates about your device.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Why we need it
              _buildReasonItem(
                icon: Icons.payment,
                title: 'Payment Reminders',
                description:
                    'Get notified before your payment is due to avoid device lockouts',
              ),
              const SizedBox(height: 16),
              _buildReasonItem(
                icon: Icons.check_circle,
                title: 'Payment Confirmations',
                description:
                    'Receive instant confirmation when your payment is processed',
              ),
              const SizedBox(height: 16),
              _buildReasonItem(
                icon: Icons.info,
                title: 'Important Updates',
                description:
                    'Stay informed about your payment schedule and account status',
              ),
              const SizedBox(height: 48),

              // Status indicator
              if (_permissionGranted)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifications are enabled',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Allow button
              ElevatedButton(
                onPressed: _permissionGranted
                    ? widget.onNext
                    : (_isRequesting ? null : _requestPermission),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _permissionGranted
                            ? 'Continue'
                            : 'Enable Notifications',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // Skip button (only show if not granted)
              if (!_permissionGranted)
                TextButton(
                  onPressed: _isRequesting ? null : _skipPermission,
                  child: const Text(
                    'Skip for Now',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final status = await Permission.notification.request();

      if (!mounted) return;

      if (status.isGranted) {
        // Permission granted
        setState(() {
          _permissionGranted = true;
        });
        _showSuccessMessage();
        await Future.delayed(const Duration(seconds: 1));
        widget.onNext();
      } else if (status.isDenied) {
        // Permission denied
        _showDeniedDialog();
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied
        _showPermanentlyDeniedDialog();
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Error requesting permission: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  void _skipPermission() {
    _showSkipDialog();
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification permission granted'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
          'Notification permission was denied. You can continue without it, but you won\'t receive payment reminders. You can enable it later in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNext();
            },
            child: const Text('Continue Without Notifications'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestPermission();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Permanently Denied'),
        content: const Text(
          'Notification permission has been permanently denied. To enable notifications, please go to your device settings and grant permission manually.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNext();
            },
            child: const Text('Continue Without Notifications'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSkipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Notification Permission?'),
        content: const Text(
          'Without notifications, you won\'t receive payment reminders and may miss important updates. This could lead to unexpected device lockouts.\n\nYou can enable notifications later in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNext();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
