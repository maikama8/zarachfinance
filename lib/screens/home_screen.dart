import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../services/payment_service.dart';
import '../models/payment_schedule.dart';
import '../models/payment_history.dart';
import 'payment_screen.dart';
import 'payment_schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final PaymentService _paymentService = PaymentService();
  
  PaymentSchedule? _nextPayment;
  double _remainingBalance = 0.0;
  String _deviceStatus = 'Active';
  List<String> _recentNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get next payment
      final upcomingPayments = await _db.getUpcomingPayments();
      if (upcomingPayments.isNotEmpty) {
        _nextPayment = upcomingPayments.first;
      }
      
      // Calculate remaining balance
      final allSchedules = await _db.getAllPaymentSchedules();
      _remainingBalance = allSchedules
          .where((s) => s.status != PaymentStatus.paid)
          .fold(0.0, (sum, s) => sum + s.amount);
      
      // Determine device status
      final isLocked = await _db.getLockState();
      if (isLocked) {
        _deviceStatus = 'Locked';
      } else if (_remainingBalance == 0.0) {
        _deviceStatus = 'Paid Off';
      } else {
        _deviceStatus = 'Active';
      }
      
      // Get recent notifications (mock for now)
      _recentNotifications = [
        'Payment reminder: Due in 3 days',
        'Payment received successfully',
      ];
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceStatusCard(),
              const SizedBox(height: 16),
              _buildPaymentStatusCard(),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildRecentNotifications(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceStatusCard() {
    Color statusColor;
    IconData statusIcon;
    
    switch (_deviceStatus) {
      case 'Locked':
        statusColor = Colors.red;
        statusIcon = Icons.lock;
        break;
      case 'Paid Off':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.phone_android;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, size: 48, color: statusColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _deviceStatus,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusCard() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (_nextPayment != null) ...[
              _buildInfoRow(
                'Next Payment Date',
                DateFormat('MMM dd, yyyy').format(_nextPayment!.dueDate),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Next Payment Amount',
                currencyFormat.format(_nextPayment!.amount),
              ),
              const SizedBox(height: 8),
            ] else ...[
              const Text('No upcoming payments'),
              const SizedBox(height: 8),
            ],
            _buildInfoRow(
              'Remaining Balance',
              currencyFormat.format(_remainingBalance),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.payment,
                label: 'Make Payment',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.calendar_today,
                label: 'View Schedule',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentScheduleScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            icon: Icons.support_agent,
            label: 'Contact Support',
            onTap: () {
              _showContactSupport();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildRecentNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Notifications',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (_recentNotifications.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent notifications'),
            ),
          )
        else
          ..._recentNotifications.map((notification) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(notification),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Handle notification tap
                },
              ),
            );
          }).toList(),
      ],
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: 1-800-FINANCE'),
            SizedBox(height: 8),
            Text('Email: support@devicefinance.com'),
            SizedBox(height: 8),
            Text('Hours: Mon-Fri 9AM-5PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
