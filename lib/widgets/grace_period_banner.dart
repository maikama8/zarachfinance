import 'package:flutter/material.dart';
import '../services/grace_period_manager.dart';

/// Banner widget to display grace period warning
class GracePeriodBanner extends StatefulWidget {
  const GracePeriodBanner({super.key});

  @override
  State<GracePeriodBanner> createState() => _GracePeriodBannerState();
}

class _GracePeriodBannerState extends State<GracePeriodBanner> {
  final GracePeriodManager _gracePeriodManager = GracePeriodManager();
  GracePeriodStatus? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGracePeriodStatus();
  }

  Future<void> _loadGracePeriodStatus() async {
    final status = await _gracePeriodManager.getGracePeriodStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _status == null || !_status!.isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _status!.hasExpired ? Colors.red.shade100 : Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(
            color: _status!.hasExpired ? Colors.red : Colors.orange,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _status!.hasExpired ? Icons.error : Icons.warning,
            color: _status!.hasExpired ? Colors.red : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _status!.hasExpired 
                      ? 'Grace Period Expired'
                      : 'Payment Verification Issue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _status!.hasExpired ? Colors.red.shade900 : Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _status!.getDisplayMessage(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _status!.hasExpired ? Colors.red.shade800 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGracePeriodStatus,
            tooltip: 'Refresh status',
            color: _status!.hasExpired ? Colors.red.shade900 : Colors.orange.shade900,
          ),
        ],
      ),
    );
  }
}
