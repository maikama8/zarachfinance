import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/payment_history_screen.dart';
import '../screens/payment_schedule_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/lock_screen.dart';
import '../services/database_helper.dart';

class AppRouter {
  final DatabaseHelper _db = DatabaseHelper();

  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      initialLocation: '/',
      redirect: _handleRedirect,
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/payments',
          name: 'payments',
          builder: (context, state) => const PaymentHistoryScreen(),
        ),
        GoRoute(
          path: '/schedule',
          name: 'schedule',
          builder: (context, state) => const PaymentScheduleScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/payment',
          name: 'payment',
          builder: (context, state) => const PaymentScreen(),
        ),
        GoRoute(
          path: '/lock',
          name: 'lock',
          builder: (context, state) => const LockScreen(),
        ),
      ],
    );
  }

  Future<String?> _handleRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    // Check if device is locked
    final isLocked = await _db.getLockState();
    
    // If locked and not already on lock screen, redirect to lock screen
    if (isLocked && state.matchedLocation != '/lock') {
      return '/lock';
    }
    
    // If not locked and on lock screen, redirect to home
    if (!isLocked && state.matchedLocation == '/lock') {
      return '/';
    }
    
    return null;
  }
}
