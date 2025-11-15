import 'package:flutter/material.dart';
import 'lock_screen.dart';
import 'payment_screen.dart';

/// Safe mode screen - basic lock/unlock functionality only
/// Shown when app crashes repeatedly to prevent crash loops
class SafeModeScreen extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onExitSafeMode;

  const SafeModeScreen({
    super.key,
    required this.isLocked,
    required this.onExitSafeMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Mode'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Safe Mode',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'The app has entered safe mode due to repeated crashes. '
              'Only basic lock/unlock functionality is available.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isLocked) ...[
              const Text(
                'Device Status: LOCKED',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
                label: const Text('Make Payment to Unlock'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              const Text(
                'Device Status: UNLOCKED',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Basic functionality is available. Contact support if issues persist.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _showExitSafeModeDialog(context);
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Exit Safe Mode'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _showSafeModeInfoDialog(context);
              },
              child: const Text('What is Safe Mode?'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitSafeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Safe Mode?'),
        content: const Text(
          'Exiting safe mode will restore full app functionality. '
          'If the app continues to crash, it will re-enter safe mode automatically.\n\n'
          'Do you want to exit safe mode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onExitSafeMode();
            },
            child: const Text('Exit Safe Mode'),
          ),
        ],
      ),
    );
  }

  void _showSafeModeInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Safe Mode'),
        content: const Text(
          'Safe Mode is activated when the app crashes multiple times in a short period. '
          'This prevents crash loops and ensures you can still access basic functionality.\n\n'
          'In Safe Mode:\n'
          '• Only essential lock/unlock features are available\n'
          '• Background services are disabled\n'
          '• You can still make payments\n'
          '• Device remains secure\n\n'
          'If you continue experiencing issues, please contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
