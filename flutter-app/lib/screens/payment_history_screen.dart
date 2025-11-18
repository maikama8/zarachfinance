import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../models/api_models.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<PaymentHistoryItem> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';
      
      if (deviceId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      try {
        final history = await ApiClient.getPaymentHistory(deviceId);
        setState(() {
          _payments = history.map((item) => PaymentHistoryItem(
            amount: item.amount,
            date: _formatDate(item.date),
            method: item.paymentMethod,
            status: item.status,
            transactionId: item.transactionId,
          )).toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _payments = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No payment history',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: payment.status == 'completed'
                              ? Colors.green
                              : payment.status == 'pending'
                                  ? Colors.orange
                                  : Colors.red,
                          child: Icon(
                            payment.status == 'completed'
                                ? Icons.check
                                : payment.status == 'pending'
                                    ? Icons.pending
                                    : Icons.error,
                            color: Colors.white,
                          ),
                        ),
                        title: Text('₦${payment.amount.toStringAsFixed(2)}'),
                        subtitle: Text(
                          '${payment.date} • ${payment.method ?? 'N/A'}',
                        ),
                        trailing: payment.transactionId != null
                            ? IconButton(
                                icon: const Icon(Icons.receipt),
                                onPressed: () => _showReceipt(payment),
                              )
                            : null,
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

  void _showReceipt(PaymentHistoryItem payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₦${payment.amount.toStringAsFixed(2)}'),
            Text('Date: ${payment.date}'),
            Text('Method: ${payment.method ?? 'N/A'}'),
            if (payment.transactionId != null)
              Text('Transaction ID: ${payment.transactionId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Share receipt
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

class PaymentHistoryItem {
  final double amount;
  final String date;
  final String? method;
  final String status;
  final String? transactionId;

  PaymentHistoryItem({
    required this.amount,
    required this.date,
    this.method,
    required this.status,
    this.transactionId,
  });
}

