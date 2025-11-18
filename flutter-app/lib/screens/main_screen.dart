import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/payment_provider.dart';
import '../services/api_client.dart';
import '../services/device_admin_service.dart';
import '../services/realtime_service.dart';
import 'payment_screen.dart';
import 'schedule_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isAdminActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDeviceAdmin();
    _loadPaymentInfo();
    _setupRealtimeUpdates();
  }

  Future<void> _setupRealtimeUpdates() async {
    try {
      final deviceId = await ApiClient.getDeviceId();
      await RealtimeService.instance.connect(deviceId);
      
      RealtimeService.instance.on('device:update', (data) {
        if (mounted) {
          _loadPaymentInfo();
          if (data['type'] == 'lock' && data['isLocked'] == true) {
            // Navigate to lock screen
            // Navigator.pushReplacementNamed(context, '/lock');
          }
        }
      });
    } catch (e) {
      debugPrint('Error setting up realtime updates: $e');
    }
  }

  @override
  void dispose() {
    RealtimeService.instance.disconnect();
    super.dispose();
  }

  Future<void> _checkDeviceAdmin() async {
    try {
      final isActive = await DeviceAdminService.isActive();
      setState(() {
        _isAdminActive = isActive;
      });

      if (!isActive) {
        _showDeviceAdminDialog();
      } else {
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('device_admin_active', true);
      }
    } catch (e) {
      debugPrint('Error checking device admin: $e');
    }
  }

  Future<void> _showDeviceAdminDialog() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Admin Required'),
        content: const Text(
          'This app requires device administrator privileges to enforce payment compliance. Please enable it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await DeviceAdminService.requestDeviceAdmin();
              if (success && mounted) {
                setState(() {
                  _isAdminActive = true;
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('device_admin_active', true);
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPaymentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? '';
    
    if (deviceId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final status = await ApiClient.getPaymentStatus(deviceId);
      if (mounted) {
        context.read<PaymentProvider>().updateStatus(status);
      }
    } catch (e) {
      debugPrint('Error loading payment info: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZarFinance'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<PaymentProvider>(
              builder: (context, paymentProvider, _) {
                final status = paymentProvider.status;
                
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Remaining Balance',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₦${status?.remainingBalance.toStringAsFixed(2) ?? '0.00'}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Next Payment',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if (status?.nextPaymentDate != null)
                                    _buildCountdown(status!.nextPaymentDate),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                status?.nextPaymentDate != null
                                    ? _formatDate(status!.nextPaymentDate)
                                    : '--',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              if (status?.nextPaymentAmount != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Amount: ₦${status!.nextPaymentAmount!.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quick Actions Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAction(
                              context,
                              icon: Icons.payment,
                              label: 'Pay Now',
                              color: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PaymentScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickAction(
                              context,
                              icon: Icons.history,
                              label: 'History',
                              color: Colors.blue,
                              onTap: () {
                                // Navigate to payment history
                                _showPaymentHistory(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAction(
                              context,
                              icon: Icons.calendar_today,
                              label: 'Schedule',
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ScheduleScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickAction(
                              context,
                              icon: Icons.support_agent,
                              label: 'Support',
                              color: Colors.purple,
                              onTap: () {
                                // Navigate to support
                                _showSupport(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScheduleScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('View Payment Schedule'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      if (!_isAdminActive) ...[
                        const SizedBox(height: 24),
                        const Card(
                          color: Colors.orange,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Device Admin privileges required. Please enable in settings.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCountdown(int timestamp) {
    final dueDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'OVERDUE',
          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: days <= 1 ? Colors.orange : Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        days > 0 ? '$days day${days > 1 ? 's' : ''}' : '$hours hour${hours > 1 ? 's' : ''}',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const PaymentHistorySheet(),
    );
  }

  void _showSupport(BuildContext context) {
    Navigator.pushNamed(context, '/support');
  }
}

class PaymentHistorySheet extends StatelessWidget {
  const PaymentHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text('Payment history feature - to be implemented'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

