import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/database_helper.dart';
import '../services/device_api_service.dart';
import '../platform_channels/device_identifier_channel.dart';
import 'release_code_screen.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final DeviceApiService _deviceApi = DeviceApiService();
  
  String _appVersion = '';
  String _deviceId = '';
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      
      // Get device ID
      try {
        final channel = DeviceIdentifierChannel();
        _deviceId = await channel.getAndroidId();
      } catch (e) {
        _deviceId = 'Unknown';
      }
      
      // Get last sync time from device config
      final lastSyncConfig = await _db.getDeviceConfig('last_sync_time');
      if (lastSyncConfig != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(lastSyncConfig.value),
        );
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forceSync() async {
    setState(() => _isSyncing = true);
    
    try {
      // Trigger sync with backend
      await _deviceApi.updateDeviceStatus(
        deviceId: _deviceId,
        statusUpdate: DeviceStatusUpdate(
          status: 'ACTIVE',
          timestamp: DateTime.now(),
        ),
      );
      
      // Update last sync time
      _lastSyncTime = DateTime.now();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
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
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'App Information',
            children: [
              _buildInfoTile(
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: _appVersion,
              ),
              _buildInfoTile(
                icon: Icons.phone_android,
                title: 'Device ID',
                subtitle: _deviceId,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Store Contact',
            children: [
              _buildInfoTile(
                icon: Icons.phone,
                title: 'Phone',
                subtitle: '1-800-FINANCE',
                onTap: () {
                  // TODO: Launch phone dialer
                },
              ),
              _buildInfoTile(
                icon: Icons.email,
                title: 'Email',
                subtitle: 'support@devicefinance.com',
                onTap: () {
                  // TODO: Launch email client
                },
              ),
              _buildInfoTile(
                icon: Icons.location_on,
                title: 'Address',
                subtitle: '123 Finance St, City, State 12345',
                onTap: () {
                  // TODO: Launch maps
                },
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Synchronization',
            children: [
              _buildInfoTile(
                icon: Icons.sync,
                title: 'Last Sync',
                subtitle: _lastSyncTime != null
                    ? DateFormat('MMM dd, yyyy hh:mm a').format(_lastSyncTime!)
                    : 'Never',
              ),
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: const Text('Force Sync'),
                subtitle: const Text('Manually synchronize with server'),
                trailing: _isSyncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _isSyncing ? null : _forceSync,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Device Management',
            children: [
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: const Text('Enter Release Code'),
                subtitle: const Text('Unlock device with release code'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReleaseCodeScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Legal',
            children: [
              _buildInfoTile(
                icon: Icons.description,
                title: 'Terms of Service',
                onTap: () {
                  _showTermsOfService();
                },
              ),
              _buildInfoTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () {
                  _showPrivacyPolicy();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service\n\n'
            '1. Device Financing Agreement\n'
            'By using this device, you agree to the payment terms outlined in your financing agreement.\n\n'
            '2. Payment Obligations\n'
            'You must make timely payments according to the agreed schedule.\n\n'
            '3. Device Lock Policy\n'
            'Failure to make payments may result in device lock.\n\n'
            '4. Data Collection\n'
            'We collect device usage and location data as outlined in our Privacy Policy.\n\n'
            'For full terms, visit: www.devicefinance.com/terms',
          ),
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            '1. Information We Collect\n'
            '- Device identifier\n'
            '- Location data\n'
            '- Payment information\n'
            '- Usage statistics\n\n'
            '2. How We Use Your Information\n'
            '- Process payments\n'
            '- Enforce financing agreement\n'
            '- Improve our services\n\n'
            '3. Data Security\n'
            'We use encryption and secure storage to protect your data.\n\n'
            '4. Your Rights\n'
            'You have the right to access and request deletion of your data.\n\n'
            'For full policy, visit: www.devicefinance.com/privacy',
          ),
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
