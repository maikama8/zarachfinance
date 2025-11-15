import 'package:flutter/material.dart';
import 'package:zaracfinance/services/payment_service.dart';
import 'package:zaracfinance/services/payment_api_service.dart';
import 'package:zaracfinance/services/database_helper.dart';
import 'package:zaracfinance/services/exceptions/api_exceptions.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final DatabaseHelper _db = DatabaseHelper();
  
  String _selectedMethod = 'bank_transfer';
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;
  double _remainingBalance = 0.0;
  double _nextPaymentAmount = 0.0;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'bank_transfer', 'label': 'Bank Transfer'},
    {'value': 'ussd', 'label': 'USSD'},
    {'value': 'card', 'label': 'Debit/Credit Card'},
    {'value': 'mobile_money', 'label': 'Mobile Money'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentInfo() async {
    try {
      final balanceConfig = await _db.getDeviceConfig('remaining_balance');
      if (balanceConfig != null) {
        setState(() {
          _remainingBalance = double.tryParse(balanceConfig.value) ?? 0.0;
        });
      }

      // Get next payment amount from upcoming payments
      final upcomingPayments = await _db.getUpcomingPayments();
      if (upcomingPayments.isNotEmpty) {
        setState(() {
          _nextPaymentAmount = upcomingPayments.first.amount;
          _amountController.text = _nextPaymentAmount.toStringAsFixed(2);
        });
      }
    } catch (e) {
      print('Error loading payment info: $e');
    }
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text);
    
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid payment amount');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await _paymentService.processPayment(
        amount: amount,
        method: _selectedMethod,
      );

      setState(() {
        _isProcessing = false;
      });

      if (response.status == 'SUCCESS') {
        _showSuccessDialog(response);
      } else if (response.status == 'PENDING') {
        _showPendingDialog(response);
      }
    } on PaymentException catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog(
        e.failureReason ?? 'Payment failed. Please try again.',
        canRetry: true,
      );
    } on NetworkException catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog(
        'Network error. Your payment has been queued and will be processed when connection is restored.',
        canRetry: true,
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog(
        'An error occurred: ${e.toString()}',
        canRetry: true,
      );
    }
  }

  void _showSuccessDialog(PaymentSubmissionResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₦${response.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Transaction ID: ${response.transactionId}'),
            const SizedBox(height: 8),
            if (response.newBalance != null)
              Text(
                'New Balance: ₦${response.newBalance!.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (response.message != null) ...[
              const SizedBox(height: 8),
              Text(response.message!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPendingDialog(PaymentSubmissionResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pending, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Payment Pending'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your payment is being processed.'),
            const SizedBox(height: 8),
            Text('Transaction ID: ${response.transactionId}'),
            const SizedBox(height: 8),
            const Text('You will receive a confirmation once the payment is complete.'),
          ],
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

  void _showErrorDialog(String message, {bool canRetry = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          if (canRetry)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processPayment();
              },
              child: const Text('Retry'),
            ),
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
        title: const Text('Make Payment'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remaining Balance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₦${_remainingBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '₦',
                border: const OutlineInputBorder(),
                helperText: _nextPaymentAmount > 0
                    ? 'Next payment: ₦${_nextPaymentAmount.toStringAsFixed(2)}'
                    : null,
                suffixIcon: _nextPaymentAmount > 0
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          _amountController.text = _nextPaymentAmount.toStringAsFixed(2);
                        },
                        tooltip: 'Use next payment amount',
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Selection
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._paymentMethods.map((method) {
              return RadioListTile<String>(
                title: Text(method['label']!),
                value: method['value']!,
                groupValue: _selectedMethod,
                onChanged: _isProcessing
                    ? null
                    : (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
            const SizedBox(height: 32),

            // Make Payment Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Make Payment'),
            ),
            const SizedBox(height: 16),

            // View History Button
            OutlinedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      Navigator.pushNamed(context, '/payment-history');
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('View Payment History'),
            ),
          ],
        ),
      ),
    );
  }
}
