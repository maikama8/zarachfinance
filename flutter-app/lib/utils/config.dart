class Config {
  // API Configuration
  // Update this to your server URL
  // For local testing on real device: use your computer's IP
  // For emulator: use http://10.0.2.2:3000/api/
  // For production: use your domain (e.g., https://yourdomain.com/api/)
  static const String apiBaseUrl = 'http://192.168.18.7:3000/api/';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Payment Verification
  static const Duration paymentCheckInterval = Duration(hours: 6);
  static const Duration paymentDeadlineHours = Duration(hours: 24);
  static const Duration unlockDelayMinutes = Duration(minutes: 5);
  
  // Location Tracking
  static const Duration locationUpdateInterval = Duration(hours: 12);
  
  // Notifications
  static const Duration paymentReminder24H = Duration(hours: 24);
  static const Duration paymentReminder6H = Duration(hours: 6);
  
  // Security
  static const Duration tamperCheckInterval = Duration(minutes: 15);
  static const bool integrityCheckOnLaunch = true;
  
  // Storage
  static const int paymentHistoryDays = 30;
}

