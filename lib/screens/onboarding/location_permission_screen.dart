import 'package:flutter/material.dart';
import 'package:zaracfinance/services/location_tracker.dart';

/// Screen for requesting location permission during onboarding
class LocationPermissionScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LocationPermissionScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  final LocationTracker _locationTracker = LocationTracker();
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Location Permission'),
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
                Icons.location_on,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Location Access',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Rationale
              Text(
                'We need access to your device location to help protect your device and assist with recovery if needed.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Why we need it
              _buildReasonItem(
                icon: Icons.security,
                title: 'Device Security',
                description:
                    'Helps us locate your device in case of theft or loss',
              ),
              const SizedBox(height: 16),
              _buildReasonItem(
                icon: Icons.inventory,
                title: 'Inventory Management',
                description:
                    'Allows us to track our financed devices for better service',
              ),
              const SizedBox(height: 16),
              _buildReasonItem(
                icon: Icons.privacy_tip,
                title: 'Privacy Protected',
                description:
                    'We only collect coarse location data every 12 hours',
              ),
              const SizedBox(height: 48),

              // Allow button
              ElevatedButton(
                onPressed: _isRequesting ? null : _requestPermission,
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
                    : const Text(
                        'Allow Location Access',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // Skip button
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
      final granted = await _locationTracker.requestLocationPermission();

      if (!mounted) return;

      if (granted) {
        // Permission granted
        _showSuccessMessage();
        await Future.delayed(const Duration(seconds: 1));
        widget.onNext();
      } else {
        // Permission denied
        _showDeniedDialog();
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
        content: Text('Location permission granted'),
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
          'Location permission was denied. You can continue without it, but some features may be limited. You can enable it later in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNext();
            },
            child: const Text('Continue Without Location'),
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

  void _showSkipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Location Permission?'),
        content: const Text(
          'You can continue without granting location permission, but this may limit our ability to help you recover your device if it\'s lost or stolen.\n\nYou can enable location access later in the app settings.',
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
