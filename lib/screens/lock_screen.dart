import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../services/database_helper.dart';
import '../services/policy_manager.dart';
import '../models/payment_schedule.dart';
import '../platform_channels/emergency_call_channel.dart';

/// Full-screen lock screen displayed when device is locked due to missed payment
/// Prevents user from accessing device until payment is made
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final EmergencyCallChannel _emergencyChannel = EmergencyCallChannel();
  final PolicyManager _policyManager = PolicyManager();
  
  double _remainingBalance = 0.0;
  double _overdueAmount = 0.0;
  String _storePhone = '';
  String _storeAddress = '';
  String? _customMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _hideSystemUI();
    _loadPaymentInfo();
  }

  /// Hide status bar and navigation bar for full-screen lock
  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  /// Load payment information from database
  Future<void> _loadPaymentInfo() async {
    try {
      developer.log('Loading payment info', name: 'LockScreen');
      
      // Get all payment schedules
      final allPayments = await _db.getAllPaymentSchedules();
      
      // Calculate remaining balance (all pending and overdue payments)
      _remainingBalance = allPayments
          .where((p) => p.status != PaymentStatus.paid)
          .fold(0.0, (sum, p) => sum + p.amount);
      
      // Calculate overdue amount
      final overduePayments = await _db.getOverduePayments();
      _overdueAmount = overduePayments.fold(0.0, (sum, p) => sum + p.amount);
      
      // Get store contact information from device config
      final phoneConfig = await _db.getDeviceConfig('store_phone');
      final addressConfig = await _db.getDeviceConfig('store_address');
      
      _storePhone = phoneConfig?.value ?? '+234 XXX XXX XXXX';
      _storeAddress = addressConfig?.value ?? 'Store Address Not Available';
      
      // Get custom lock message if present
      _customMessage = await _policyManager.getCustomLockMessage();
      
      setState(() {
        _isLoading = false;
      });
      
      developer.log(
        'Payment info loaded: balance=$_remainingBalance, overdue=$_overdueAmount, customMessage=${_customMessage != null}',
        name: 'LockScreen',
      );
    } catch (e) {
      developer.log(
        'Error loading payment info',
        name: 'LockScreen',
        error: e,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Navigate to payment screen
  void _navigateToPayment() {
    developer.log('Navigating to payment screen', name: 'LockScreen');
    Navigator.pushNamed(context, '/payment');
  }

  /// Launch emergency dialer
  Future<void> _makeEmergencyCall() async {
    try {
      developer.log('Launching emergency dialer', name: 'LockScreen');
      await _emergencyChannel.launchEmergencyDialer();
    } catch (e) {
      developer.log(
        'Error launching emergency dialer',
        name: 'LockScreen',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to launch emergency dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Disable back button
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Lock icon
                        const Icon(
                          Icons.lock_outline,
                          size: 80,
                          color: Colors.redAccent,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Title
                        const Text(
                          'Device Locked',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Custom message or default payment reminder message
                        if (_customMessage != null && _customMessage!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orangeAccent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.message,
                                  color: Colors.orangeAccent,
                                  size: 32,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Message from Store',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _customMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Text(
                            'Your device has been locked due to missed payment(s). Please make your payment to unlock your device.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        
                        const SizedBox(height: 40),
                        
                        // Payment information card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Overdue amount
                              _buildPaymentRow(
                                'Overdue Amount',
                                _overdueAmount,
                                Colors.redAccent,
                              ),
                              
                              const Divider(
                                color: Colors.white24,
                                height: 32,
                              ),
                              
                              // Remaining balance
                              _buildPaymentRow(
                                'Total Remaining Balance',
                                _remainingBalance,
                                Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Pay Now button
                        ElevatedButton(
                          onPressed: _navigateToPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Pay Now',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Emergency Call button
                        OutlinedButton(
                          onPressed: _makeEmergencyCall,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Emergency Call',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Store contact information
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Store Contact Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Phone
                              _buildContactRow(
                                Icons.phone,
                                'Phone',
                                _storePhone,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Address
                              _buildContactRow(
                                Icons.location_on,
                                'Address',
                                _storeAddress,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Help text
                        const Text(
                          'If you have already made a payment, please wait a few minutes for verification.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// Build payment information row
  Widget _buildPaymentRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        Text(
          '₦${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Build contact information row
  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blueAccent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Restore system UI when leaving lock screen
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }
}
