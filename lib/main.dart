import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/database_helper.dart';
import 'services/lock_service.dart';
import 'services/tamper_detection_service.dart';
import 'services/crash_reporting_service.dart';
import 'screens/lock_screen.dart';
import 'screens/safe_mode_screen.dart';
import 'navigation/main_navigation.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize crash reporting
  final crashReporting = CrashReportingService();
  await crashReporting.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Run app with error handling
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stackTrace) {
    // Handle errors that escape the Flutter framework
    developer.log(
      'Uncaught error',
      name: 'main',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseHelper _db = DatabaseHelper();
  final LockService _lockService = LockService();
  final TamperDetectionService _tamperService = TamperDetectionService();
  final CrashReportingService _crashReporting = CrashReportingService();
  bool _isLocked = false;
  bool _isLoading = true;
  bool _isSafeMode = false;
  Timer? _tamperCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app with security checks
  Future<void> _initializeApp() async {
    // Check if in safe mode
    await _checkSafeMode();
    
    // Run tamper check on startup (skip if in safe mode)
    if (!_isSafeMode) {
      await _runStartupTamperCheck();
    }
    
    // Check lock state
    await _checkLockState();
    
    // Start monitoring services (skip non-essential if in safe mode)
    if (!_isSafeMode) {
      _startLockMonitoring();
      _startPeriodicTamperChecks();
    }
  }

  /// Check if app is in safe mode
  Future<void> _checkSafeMode() async {
    try {
      final isInSafeMode = await _crashReporting.isInSafeMode();
      setState(() {
        _isSafeMode = isInSafeMode;
      });
      
      if (isInSafeMode) {
        developer.log('App is running in safe mode', name: 'main');
      }
    } catch (e) {
      developer.log(
        'Error checking safe mode',
        name: 'main',
        error: e,
      );
    }
  }

  /// Run tamper check on app startup
  Future<void> _runStartupTamperCheck() async {
    try {
      developer.log('Running startup tamper check', name: 'main');
      final isTampered = await _tamperService.checkForTampering();
      
      if (isTampered) {
        developer.log('Tampering detected on startup', name: 'main');
        // Device will be locked by tamper service
        setState(() {
          _isLocked = true;
        });
      }
    } catch (e) {
      developer.log(
        'Error during startup tamper check',
        name: 'main',
        error: e,
      );
      // Continue app initialization even if tamper check fails
    }
  }

  /// Check lock state on app startup
  Future<void> _checkLockState() async {
    try {
      final isLocked = await _db.getLockState();
      setState(() {
        _isLocked = isLocked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Start lock service monitoring
  void _startLockMonitoring() {
    _lockService.startMonitoring();
  }

  /// Start periodic tamper checks (every 30 minutes)
  void _startPeriodicTamperChecks() {
    developer.log('Starting periodic tamper checks', name: 'main');
    
    // Cancel existing timer if any
    _tamperCheckTimer?.cancel();
    
    // Set up periodic check (every 30 minutes)
    _tamperCheckTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) async {
        developer.log('Running periodic tamper check', name: 'main');
        try {
          final isTampered = await _tamperService.checkForTampering();
          if (isTampered) {
            developer.log('Tampering detected during periodic check', name: 'main');
            // Device will be locked by tamper service
            setState(() {
              _isLocked = true;
            });
          }
        } catch (e) {
          developer.log(
            'Error during periodic tamper check',
            name: 'main',
            error: e,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _lockService.dispose();
    _tamperCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set global navigator key for LockService
    final navigatorKey = GlobalKey<NavigatorState>();
    LockService.navigatorKey = navigatorKey;

    return MaterialApp(
      title: 'Device Admin Finance',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Show loading or initial route based on lock state
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _isSafeMode
              ? SafeModeScreen(
                  isLocked: _isLocked,
                  onExitSafeMode: () async {
                    await _crashReporting.exitSafeMode();
                    setState(() {
                      _isSafeMode = false;
                    });
                    _startLockMonitoring();
                    _startPeriodicTamperChecks();
                  },
                )
              : _isLocked
                  ? const LockScreen()
                  : const MainNavigation(),
      routes: {
        '/lock': (context) => const LockScreen(),
      },
    );
  }
}
