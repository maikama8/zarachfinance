import 'package:flutter/material.dart';
import '../../platform_channels/device_admin_channel.dart';
import 'dart:developer' as developer;

/// Screen for requesting and activating device administrator privileges
class DeviceAdminScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const DeviceAdminScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<DeviceAdminScreen> createState() => _DeviceAdminScreenState();
}

class _DeviceAdminScreenState extends State<DeviceAdminScreen> {
  final DeviceAdminChannel _adminChannel = DeviceAdminChannel();
  bool _isAdminActive = false;
  bool _isChecking = true;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  /// Check if device admin is already active
  Future<void> _checkAdminStatus() async {
    try {
      developer.log('Checking device admin status', name: 'DeviceAdminScreen');
      final isActive = await _adminChannel.isAdminActive();
      setState(() {
        _isAdminActive = isActive;
        _isChecking = false;
      });
      developer.log('Device admin active: $isActive', name: 'DeviceAdminScreen');
    } catch (e) {
      developer.log(
        'Error checking admin status',
        name: 'DeviceAdminScreen',
        error: e,
      );
      setState(() {
        _isChecking = false;
      });
    }
  }

  /// Request device admin privileges
  Future<void> _requestAdminPrivileges() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      developer.log('Requesting device admin privileges', name: 'DeviceAdminScreen');
      await _adminChannel.requestAdminPrivileges();
      
      // Check status after request
      await Future.delayed(const Duration(seconds: 1));
      await _checkAdminStatus();
      
      if (_isAdminActive) {
        _showSuccessDialog();
      }
    } catch (e) {
      developer.log(
        'Error requesting admin privileges',
        name: 'DeviceAdminScreen',
        error: e,
      );
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Success'),
          ],
        ),
        content: const Text(
          'Device administrator privileges have been activated successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNext();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(
          'Failed to activate device administrator privileges.\n\n$error',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Device Administrator'),
      ),
      body: _isChecking
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    const Icon(
                      Icons.security,
                      size: 80,
                      color: Colors.blue,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    const Text(
                      'Device Administrator Required',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Description
                    const Text(
                      'This app requires device administrator privileges to:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Permissions list
                    _buildPermissionItem(
                      Icons.lock,
                      'Manage device lock state',
                      'Lock device when payment is overdue',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildPermissionItem(
                      Icons.block,
                      'Prevent factory reset',
                      'Protect device until financing is complete',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildPermissionItem(
                      Icons.verified_user,
                      'Ensure app security',
                      'Prevent unauthorized app removal',
                    ),
                    
                    const Spacer(),
                    
                    // Status indicator
                    if (_isAdminActive)
                      Container(
                        padding: const EdgeInsets.all(16),
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
                                'Device administrator is active',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Activate button
                    ElevatedButton(
                      onPressed: _isAdminActive
                          ? widget.onNext
                          : (_isRequesting ? null : _requestAdminPrivileges),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_isAdminActive ? 'Continue' : 'Activate'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Info text
                    const Text(
                      'These permissions are required for the financing program. '
                      'They will be removed once you complete all payments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
