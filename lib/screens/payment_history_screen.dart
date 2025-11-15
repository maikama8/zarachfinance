import 'package:flutter/material.dart';
import 'package:zaracfinance/services/database_helper.dart';
import 'package:zaracfinance/models/payment_history.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<PaymentHistory> _paymentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _db.getPaymentHistory();
      setState(() {
        _paymentHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment history: $e')),
        );
      }
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.error;
      case TransactionStatus.pending:
        return Icons.pending;
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return 'Success';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.pending:
        return 'Pending';
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'ussd':
        return 'USSD';
      case 'card':
        return 'Card';
      case 'mobile_money':
        return 'Mobile Money';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment history',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPaymentHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _paymentHistory.length,
                    itemBuilder: (context, index) {
                      final payment = _paymentHistory[index];
                      final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(payment.status).withOpacity(0.1),
                            child: Icon(
                              _getStatusIcon(payment.status),
                              color: _getStatusColor(payment.status),
                            ),
                          ),
                          title: Text(
                            '₦${payment.amount.toStringAsFixed(2)}',
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
                                _formatPaymentMethod(payment.method),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(payment.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${payment.transactionId}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(payment.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(payment.status),
                              style: TextStyle(
                                color: _getStatusColor(payment.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
