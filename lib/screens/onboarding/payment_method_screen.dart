import 'package:flutter/material.dart';

/// Screen for setting up payment method preferences
class PaymentMethodScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PaymentMethodScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedMethod = 'bank_transfer';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'value': 'bank_transfer',
      'label': 'Bank Transfer',
      'icon': Icons.account_balance,
      'description': 'Transfer directly from your bank account',
    },
    {
      'value': 'ussd',
      'label': 'USSD',
      'icon': Icons.dialpad,
      'description': 'Use USSD codes for quick payments',
    },
    {
      'value': 'card',
      'label': 'Debit/Credit Card',
      'icon': Icons.credit_card,
      'description': 'Pay with your debit or credit card',
    },
    {
      'value': 'mobile_money',
      'label': 'Mobile Money',
      'icon': Icons.phone_android,
      'description': 'Use mobile money services',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Payment Method'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              const Icon(
                Icons.payment,
                size: 80,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Choose Your Payment Method',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Select your preferred payment method. You can change this later in settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Payment methods list
              Expanded(
                child: ListView.builder(
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    final isSelected = _selectedMethod == method['value'];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMethod = method['value'];
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Colors.blue.withOpacity(0.05)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  method['icon'],
                                  color: isSelected ? Colors.blue : Colors.grey,
                                  size: 28,
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method['label'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.blue : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      method['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Radio indicator
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Continue button
              ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Continue'),
              ),
              
              const SizedBox(height: 8),
              
              // Info text
              const Text(
                'Your payment information is secure and encrypted',
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
}
