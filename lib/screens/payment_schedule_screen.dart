import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_schedule.dart';
import '../models/payment_history.dart';
import '../services/database_helper.dart';
import '../services/payment_service.dart';

/// Screen to display payment schedule and history
class PaymentScheduleScreen extends StatefulWidget {
  const PaymentScheduleScreen({super.key});

  @override
  State<PaymentScheduleScreen> createState() => _PaymentScheduleScreenState();
}

class _PaymentScheduleScreenState extends State<PaymentScheduleScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final PaymentService _paymentService = PaymentService();
  
  List<PaymentSchedule> _schedules = [];
  List<PaymentHistory> _history = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final schedules = await _db.getAllPaymentSchedules();
      final history = await _db.getPaymentHistory(limit: 30);

      setState(() {
        _schedules = schedules;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load payment data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      // Sync with backend
      await _paymentService.syncPaymentHistory();
      
      // Reload local data
      await _loadData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sync with server: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Schedule'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_schedules.isEmpty && _history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No payment schedule available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),
        _buildNextPaymentCard(),
        const SizedBox(height: 24),
        _buildScheduleSection(),
        const SizedBox(height: 24),
        _buildHistorySection(),
      ],
    );
  }

  Widget _buildNextPaymentCard() {
    // Find the next upcoming payment
    final upcomingPayments = _schedules
        .where((s) => s.status == PaymentStatus.pending && s.dueDate.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (upcomingPayments.isEmpty) {
      return Card(
        elevation: 4,
        color: Colors.green.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'All payments up to date!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final nextPayment = upcomingPayments.first;
    final daysUntilDue = nextPayment.dueDate.difference(DateTime.now()).inDays;

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Next Payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '₦${nextPayment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Due Date',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(nextPayment.dueDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      daysUntilDue == 0
                          ? 'Due today'
                          : daysUntilDue == 1
                              ? 'Due tomorrow'
                              : 'In $daysUntilDue days',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysUntilDue <= 1 ? Colors.orange : Colors.grey,
                        fontWeight: daysUntilDue <= 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Schedule',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_schedules.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No scheduled payments'),
            ),
          )
        else
          ..._schedules.map((schedule) => _buildScheduleItem(schedule)),
      ],
    );
  }

  Widget _buildScheduleItem(PaymentSchedule schedule) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (schedule.status) {
      case PaymentStatus.paid:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Paid';
        break;
      case PaymentStatus.overdue:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Overdue';
        break;
      case PaymentStatus.pending:
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor, size: 32),
        title: Text(
          '₦${schedule.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Due: ${DateFormat('MMM dd, yyyy').format(schedule.dueDate)}',
              style: const TextStyle(fontSize: 14),
            ),
            if (schedule.paidDate != null)
              Text(
                'Paid: ${DateFormat('MMM dd, yyyy').format(schedule.paidDate!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._history.map((transaction) => _buildHistoryItem(transaction)),
      ],
    );
  }

  Widget _buildHistoryItem(PaymentHistory transaction) {
    Color statusColor;
    IconData statusIcon;

    switch (transaction.status) {
      case TransactionStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case TransactionStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      case TransactionStatus.pending:
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_outlined;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor, size: 28),
        title: Text(
          '₦${transaction.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy HH:mm').format(transaction.timestamp),
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Method: ${transaction.method}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          transaction.status.toString().split('.').last.toUpperCase(),
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
