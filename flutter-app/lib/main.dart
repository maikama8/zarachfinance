import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:workmanager/workmanager.dart';  // Temporarily disabled
import 'package:shared_preferences/shared_preferences.dart';
import 'services/payment_verification_service.dart';
import 'services/location_tracking_service.dart';
import 'services/payment_reminder_service.dart';
import 'services/flashing_protection_service.dart';
import 'screens/main_screen.dart';
import 'screens/lock_screen.dart';
import 'providers/payment_provider.dart';
import 'providers/device_provider.dart';

// Temporarily disabled - will use flutter_background_service instead
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     switch (task) {
//       case 'paymentCheck':
//         await PaymentVerificationService.checkPaymentStatus();
//         break;
//       case 'locationUpdate':
//         await LocationTrackingService.updateLocation();
//         break;
//       case 'paymentReminder':
//         await PaymentReminderService.checkAndSendReminders();
//         break;
//     }
//     return Future.value(true);
//   });
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start flashing protection service
  try {
    await FlashingProtectionService.startService();
  } catch (e) {
    debugPrint('Error starting flashing protection: $e');
  }
  
  // WorkManager temporarily disabled - using flutter_background_service instead
  // Background services will be initialized via flutter_background_service
  // await _initializeServices();
  
  runApp(const ZarFinanceApp());
}

// Temporarily disabled - will implement with flutter_background_service
// Future<void> _initializeServices() async {
//   final prefs = await SharedPreferences.getInstance();
//   final isFullyPaid = prefs.getBool('is_fully_paid') ?? false;
//   
//   if (!isFullyPaid) {
//     // Schedule periodic payment checks
//     await Workmanager().registerPeriodicTask(
//       'paymentCheck',
//       'paymentCheck',
//       frequency: const Duration(hours: 6),
//     );
//     
//     // Schedule location updates
//     await Workmanager().registerPeriodicTask(
//       'locationUpdate',
//       'locationUpdate',
//       frequency: const Duration(hours: 12),
//     );
//     
//     // Schedule payment reminders
//     await Workmanager().registerPeriodicTask(
//       'paymentReminder',
//       'paymentReminder',
//       frequency: const Duration(hours: 1),
//     );
//   }
// }

class ZarFinanceApp extends StatelessWidget {
  const ZarFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
      ],
      child: MaterialApp(
        title: 'ZarFinance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        routes: {
          '/': (context) => const AppNavigator(),
          '/main': (context) => const MainScreen(),
        },
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  bool _isLocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLocked = prefs.getBool('is_locked') ?? false;
    
    setState(() {
      _isLocked = isLocked;
      _isLoading = false;
    });
    
    // Check payment status on startup
    await PaymentVerificationService.checkPaymentStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return _isLocked ? const LockScreen() : const MainScreen();
  }
}

