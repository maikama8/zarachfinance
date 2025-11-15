import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'device_admin_screen.dart';
import 'payment_method_screen.dart';
import 'terms_screen.dart';
import 'location_permission_screen.dart';
import 'notification_permission_screen.dart';
import 'dart:developer' as developer;

/// Onboarding flow coordinator that manages the sequence of onboarding screens
class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    developer.log('Moving to next page from $_currentPage', name: 'OnboardingFlow');
    if (_currentPage < 5) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      developer.log('Onboarding complete', name: 'OnboardingFlow');
      widget.onComplete();
    }
  }

  void _previousPage() {
    developer.log('Moving to previous page from $_currentPage', name: 'OnboardingFlow');
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Progress indicator
          if (_currentPage > 0)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (_currentPage) / 5,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_currentPage/5',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Page view
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // 1. Welcome screen
                WelcomeScreen(
                  onNext: _nextPage,
                ),
                
                // 2. Device Admin screen
                DeviceAdminScreen(
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
                
                // 3. Location Permission screen
                LocationPermissionScreen(
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
                
                // 4. Notification Permission screen
                NotificationPermissionScreen(
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
                
                // 5. Payment Method screen
                PaymentMethodScreen(
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
                
                // 6. Terms screen
                TermsScreen(
                  onAccept: _nextPage,
                  onBack: _previousPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
