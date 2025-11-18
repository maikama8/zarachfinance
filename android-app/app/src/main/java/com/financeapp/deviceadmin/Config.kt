package com.zarfinance.admin

object Config {
    // API Configuration
    // Update this to your server URL
    // For local testing on real device: use your computer's IP (e.g., http://192.168.0.222:3000/api/)
    // For emulator: use http://10.0.2.2:3000/api/
    // For production: use your domain (e.g., https://yourdomain.com/api/)
    // API Configuration
    // For local testing on real device: use your computer's IP
    // For emulator: use http://10.0.2.2:3000/api/
    // For production: use your domain (e.g., https://yourdomain.com/api/)
    const val API_BASE_URL = "http://192.168.18.7:3000/api/"
    const val API_TIMEOUT_SECONDS = 30L
    
    // Payment Verification
    const val PAYMENT_CHECK_INTERVAL_HOURS = 6L
    const val PAYMENT_DEADLINE_HOURS = 24L
    const val UNLOCK_DELAY_MINUTES = 5L
    
    // Location Tracking
    const val LOCATION_UPDATE_INTERVAL_HOURS = 12L
    
    // Notifications
    const val PAYMENT_REMINDER_24H = 24L
    const val PAYMENT_REMINDER_6H = 6L
    
    // Security
    const val TAMPER_CHECK_INTERVAL_MINUTES = 15L
    const val INTEGRITY_CHECK_ON_LAUNCH = true
    
    // Storage
    const val PAYMENT_HISTORY_DAYS = 30
}

