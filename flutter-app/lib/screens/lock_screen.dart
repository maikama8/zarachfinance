import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'payment_screen.dart';
import 'main_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _message = 'Your device is locked due to overdue payment. Please make your payment to unlock the device.';
  String _storeContact = 'Store';
  String? _storePhone;

  @override
  void initState() {
    super.initState();
    _loadLockScreenData();
    _enableFullScreen();
  }

  void _enableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _loadLockScreenData() async {
    final prefs = await SharedPreferences.getInstance();
    final customMessage = prefs.getString('custom_message');
    final storeContact = prefs.getString('store_contact') ?? 'Store';
    final storePhone = prefs.getString('store_phone');

    setState(() {
      if (customMessage != null) {
        _message = customMessage;
      }
      _storeContact = storeContact;
      _storePhone = storePhone;
    });
  }

  void _checkPaymentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';
      
      if (deviceId.isEmpty) {
        return;
      }

      final status = await ApiClient.getPaymentStatus(deviceId);

      if (!status.isPaymentOverdue && !status.isFullyPaid) {
        // Payment is up to date, unlock device
        await prefs.setBool('is_locked', false);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    }
  }

  Future<void> _callStore() async {
    if (_storePhone != null && _storePhone!.isNotEmpty) {
      final uri = Uri.parse('tel:$_storePhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _makeEmergencyCall() async {
    final uri = Uri.parse('tel:112'); // Emergency number
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade700,
                Colors.red.shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Device Locked',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Make Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_storePhone != null && _storePhone!.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _callStore,
                        icon: const Icon(Icons.phone),
                        label: Text('Contact $_storeContact'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _makeEmergencyCall,
                      icon: const Icon(Icons.emergency),
                      label: const Text('Emergency Call'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

