import 'package:flutter/material.dart';

/// Welcome screen explaining the app purpose and financing program
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeScreen({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // App icon/logo
              const Icon(
                Icons.phone_android,
                size: 100,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 32),
              
              // Welcome title
              const Text(
                'Welcome to Device Finance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Description
              const Text(
                'This app helps you manage your device financing plan. '
                'Make payments easily, track your balance, and stay on schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Features list
              _buildFeatureItem(
                Icons.payment,
                'Easy Payments',
                'Make payments through multiple methods',
              ),
              
              const SizedBox(height: 16),
              
              _buildFeatureItem(
                Icons.schedule,
                'Payment Schedule',
                'View and track your payment schedule',
              ),
              
              const SizedBox(height: 16),
              
              _buildFeatureItem(
                Icons.notifications_active,
                'Payment Reminders',
                'Get notified before payments are due',
              ),
              
              const Spacer(),
              
              // Get Started button
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Get Started'),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 28,
          ),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
