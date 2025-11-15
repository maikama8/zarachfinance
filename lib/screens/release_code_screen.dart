import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaracfinance/services/payment_service.dart';
import 'package:zaracfinance/services/payment_api_service.dart';
import 'package:zaracfinance/services/exceptions/api_exceptions.dart';
import 'package:zaracfinance/services/device_release_service.dart';

/// Screen for entering and validating release code after full payment
class ReleaseCodeScreen extends StatefulWidget {
  const ReleaseCodeScreen({Key? key}) : super(key: key);

  @override
  State<ReleaseCodeScreen> createState() => _ReleaseCodeScreenState();
}

class _ReleaseCodeScreenState extends State<ReleaseCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Validate release code format (12 alphanumeric characters)
  String? _validateCodeFormat(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a release code';
    }

    // Remove any whitespace
    final cleanCode = value.replaceAll(RegExp(r'\s+'), '');

    // Check if it's exactly 12 alphanumeric characters
    if (cleanCode.length != 12) {
      return 'Release code must be 12 characters';
    }

    // Check if it contains only alphanumeric characters
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(cleanCode)) {
      return 'Release code must contain only letters and numbers';
    }

    return null;
  }

  /// Submit release code for validation
  Future<void> _submitReleaseCode() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Clean the code (remove whitespace)
      final cleanCode = _codeController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();

      // Validate with backend
      final response = await _paymentService.validateReleaseCode(cleanCode);

      if (response.isValid && response.deviceReleased) {
        // Navigate to device release success screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DeviceReleaseSuccessScreen(
                message: response.message ?? 'Device successfully released!',
              ),
            ),
          );
        }
      } else {
        // Show error message
        setState(() {
          _errorMessage = response.message ?? 'Invalid or expired release code';
          _isLoading = false;
        });
      }
    } on NetworkException catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection and try again.';
        _isLoading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed. Please contact support.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again or contact support.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Release Code'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Icon
                Icon(
                  Icons.lock_open,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Release Your Device',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Text(
                  'Congratulations on completing your payments! Enter the release code provided to you to unlock all device restrictions.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Release code input field
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Release Code',
                    hintText: 'Enter 12-character code',
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    errorMaxLines: 2,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: _validateCodeFormat,
                  enabled: !_isLoading,
                  style: const TextStyle(
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_errorMessage != null) const SizedBox(height: 24),
                
                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitReleaseCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Validate Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Help text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Important Information',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Release codes are provided after full payment\n'
                        '• Codes are valid for 7 days\n'
                        '• Contact support if you haven\'t received your code',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Success screen shown after device is released
class DeviceReleaseSuccessScreen extends StatefulWidget {
  final String message;

  const DeviceReleaseSuccessScreen({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  State<DeviceReleaseSuccessScreen> createState() => _DeviceReleaseSuccessScreenState();
}

class _DeviceReleaseSuccessScreenState extends State<DeviceReleaseSuccessScreen> {
  final DeviceReleaseService _releaseService = DeviceReleaseService();
  bool _isProcessing = false;
  bool _releaseCompleted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Automatically start the release process
    _performDeviceRelease();
  }

  /// Perform the device release process
  Future<void> _performDeviceRelease() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Execute the release process
      await _releaseService.releaseDevice();

      setState(() {
        _isProcessing = false;
        _releaseCompleted = true;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to complete release process: ${e.toString()}';
      });
    }
  }

  /// Open device admin settings to deactivate
  Future<void> _openAdminSettings() async {
    try {
      await _releaseService.openAdminDeactivationSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show instructions for uninstalling
  void _showUninstallInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Instructions'),
        content: const Text(
          'To uninstall this app:\n\n'
          '1. First, deactivate device admin using the button above\n'
          '2. Go to Settings > Apps\n'
          '3. Find "Device Admin App"\n'
          '4. Tap "Uninstall"\n\n'
          'Note: You must deactivate device admin before you can uninstall.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success icon or loading indicator
                if (_isProcessing)
                  const CircularProgressIndicator()
                else if (_releaseCompleted)
                  Icon(
                    Icons.check_circle,
                    size: 100,
                    color: Colors.green[600],
                  )
                else if (_errorMessage != null)
                  Icon(
                    Icons.error_outline,
                    size: 100,
                    color: Colors.red[600],
                  ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  _isProcessing
                      ? 'Releasing Device...'
                      : _releaseCompleted
                          ? 'Device Released!'
                          : 'Release Failed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isProcessing
                        ? Colors.blue[700]
                        : _releaseCompleted
                            ? Colors.green[700]
                            : Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Message
                Text(
                  _isProcessing
                      ? 'Please wait while we remove all restrictions...'
                      : _errorMessage ?? widget.message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Information card (only show when release is completed)
                if (_releaseCompleted)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What has been done:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem('✓', 'All device restrictions removed'),
                        _buildInfoItem('✓', 'Factory reset enabled'),
                        _buildInfoItem('✓', 'Local data cleared'),
                        _buildInfoItem('✓', 'Device unregistered from backend'),
                      ],
                    ),
                  ),
                
                if (_releaseCompleted) const SizedBox(height: 24),
                
                // Next steps card
                if (_releaseCompleted)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Next Steps',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '1. Deactivate device admin\n'
                          '2. Uninstall this app\n'
                          '3. Your device is now fully yours!',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Action buttons
                if (_releaseCompleted) ...[
                  ElevatedButton.icon(
                    onPressed: _openAdminSettings,
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Deactivate Device Admin'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _showUninstallInstructions,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('How to Uninstall'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  ElevatedButton(
                    onPressed: _performDeviceRelease,
                    child: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
