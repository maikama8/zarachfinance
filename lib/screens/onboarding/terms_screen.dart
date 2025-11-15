import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Screen for displaying and accepting terms of service and privacy policy
class TermsScreen extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onBack;

  const TermsScreen({
    Key? key,
    required this.onAccept,
    required this.onBack,
  }) : super(key: key);

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  bool get _canProceed => _acceptedTerms && _acceptedPrivacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Terms & Privacy'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              const Icon(
                Icons.description,
                size: 80,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Terms & Conditions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Please review and accept our terms of service and privacy policy to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Terms content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Device Financing Agreement',
                        'By using this app, you agree to the device financing terms including:\n\n'
                        '• Regular payment obligations as per your payment schedule\n'
                        '• Device administrator privileges required for payment enforcement\n'
                        '• Device lock functionality when payments are overdue\n'
                        '• Factory reset protection until financing is complete\n'
                        '• Location tracking for device management purposes',
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Payment Terms',
                        '• Payments must be made according to the agreed schedule\n'
                        '• Device will be locked 24 hours after a missed payment\n'
                        '• Device will be unlocked within 5 minutes of payment confirmation\n'
                        '• Payment reminders will be sent before due dates\n'
                        '• All restrictions will be removed upon full payment',
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Device Administrator Permissions',
                        '• The app requires device administrator privileges\n'
                        '• These permissions cannot be revoked during financing\n'
                        '• Permissions are used to enforce payment compliance\n'
                        '• Factory reset is disabled until financing is complete\n'
                        '• App cannot be uninstalled until full payment',
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Privacy Policy',
                        '• Device location is collected every 12 hours\n'
                        '• Payment history and device status are stored securely\n'
                        '• All communication with backend is encrypted\n'
                        '• Personal data is protected according to data protection laws\n'
                        '• Data is only used for financing management purposes',
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Your Rights',
                        '• Emergency calls are always available, even when locked\n'
                        '• You can view your payment schedule and history anytime\n'
                        '• You will receive payment reminders before due dates\n'
                        '• Upon full payment, you will receive a release code\n'
                        '• All restrictions are removed after entering the release code',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Checkboxes
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    children: [
                      const TextSpan(text: 'I accept the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showTermsDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              
              CheckboxListTile(
                value: _acceptedPrivacy,
                onChanged: (value) {
                  setState(() {
                    _acceptedPrivacy = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    children: [
                      const TextSpan(text: 'I accept the '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showPrivacyDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Accept button
              ElevatedButton(
                onPressed: _canProceed ? widget.onAccept : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Accept & Continue'),
              ),
              
              const SizedBox(height: 8),
              
              // Info text
              const Text(
                'You must accept both terms and privacy policy to continue',
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

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Full terms of service document would be displayed here. '
            'This would include detailed legal terms, conditions, '
            'obligations, and rights related to the device financing program.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Full privacy policy document would be displayed here. '
            'This would include detailed information about data collection, '
            'storage, usage, sharing, and user rights regarding their personal data.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
