package com.zarfinance.admin

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class FlashingProtectionService : Service() {
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val TAG = "FlashingProtection"
    private var notificationId = 1
    
    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                    Log.w(TAG, "USB device attached - potential flashing attempt")
                    handleUsbConnection(context, true)
                }
                UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                    Log.d(TAG, "USB device detached")
                }
            }
        }
    }
    
    private val bootReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_BOOT_COMPLETED,
                "android.intent.action.QUICKBOOT_POWERON" -> {
                    Log.d(TAG, "Device booted - checking for tampering")
                    checkForTampering(context)
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Flashing Protection Service started")
        
        // Start as foreground service
        startForeground(notificationId, createNotification())
        
        // Register USB connection receiver
        val usbFilter = IntentFilter().apply {
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        registerReceiver(usbReceiver, usbFilter)
        
        // Register boot receiver
        val bootFilter = IntentFilter().apply {
            addAction(Intent.ACTION_BOOT_COMPLETED)
            addAction("android.intent.action.QUICKBOOT_POWERON")
        }
        registerReceiver(bootReceiver, bootFilter)
        
        // Start monitoring
        startMonitoring()
    }
    
    private fun createNotification(): android.app.Notification {
        val channelId = "flashing_protection_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                channelId,
                "Flashing Protection",
                android.app.NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors device for flashing attempts"
            }
            val notificationManager = getSystemService(android.app.NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
        
        return android.app.Notification.Builder(this, channelId)
            .setContentTitle("ZarFinance Protection")
            .setContentText("Device protection active")
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setOngoing(true)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY // Restart if killed
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startMonitoring() {
        serviceScope.launch {
            while (true) {
                try {
                    // Check USB debugging status
                    checkUsbDebugging()
                    
                    // Check for download mode / fastboot
                    checkDownloadMode()
                    
                    // Check for ADB connections
                    checkAdbConnections()
                    
                    // Check bootloader status
                    checkBootloaderStatus()
                    
                    delay(30000) // Check every 30 seconds
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring loop", e)
                    delay(60000) // Wait longer on error
                }
            }
        }
    }

    private fun checkUsbDebugging() {
        try {
            val usbDebugging = Settings.Global.getInt(
                contentResolver,
                Settings.Global.ADB_ENABLED,
                0
            )
            
            if (usbDebugging == 1) {
                Log.w(TAG, "USB debugging is enabled - potential security risk")
                // Report to backend
                reportTamperAttempt("usb_debugging_enabled")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking USB debugging", e)
        }
    }

    private fun checkDownloadMode() {
        try {
            // Check if device is in download mode (Samsung) or fastboot (others)
            val downloadMode = try {
                Runtime.getRuntime().exec("getprop ro.bootmode").inputStream.bufferedReader().use { it.readLine() }
            } catch (e: Exception) {
                null
            }
            
            if (downloadMode?.contains("download", ignoreCase = true) == true ||
                downloadMode?.contains("fastboot", ignoreCase = true) == true) {
                Log.w(TAG, "Device in download/fastboot mode detected")
                reportTamperAttempt("download_mode_detected")
                // Lock device immediately
                lockDevice()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking download mode", e)
        }
    }

    private fun checkAdbConnections() {
        try {
            // Check for active ADB connections
            val adbCheck = Runtime.getRuntime().exec("getprop service.adb.tcp.port").inputStream.bufferedReader().use { it.readLine() }
            
            if (adbCheck != null && adbCheck != "-1" && adbCheck.isNotEmpty()) {
                Log.w(TAG, "ADB connection detected on port: $adbCheck")
                reportTamperAttempt("adb_connection_detected")
            }
        } catch (e: Exception) {
            // ADB check might fail on some devices, that's okay
        }
    }

    private fun checkBootloaderStatus() {
        try {
            // Check if bootloader is unlocked
            val bootloaderStatus = try {
                Runtime.getRuntime().exec("getprop ro.boot.verifiedbootstate").inputStream.bufferedReader().use { it.readLine() }
            } catch (e: Exception) {
                null
            }
            
            if (bootloaderStatus == "orange" || bootloaderStatus == "yellow") {
                Log.w(TAG, "Bootloader appears to be unlocked")
                reportTamperAttempt("bootloader_unlocked")
            }
        } catch (e: Exception) {
            // Bootloader check might not work on all devices
        }
    }

    private fun handleUsbConnection(context: Context?, connected: Boolean) {
        if (connected) {
            // Check if USB debugging is enabled
            val usbDebugging = try {
                Settings.Global.getInt(
                    context?.contentResolver ?: contentResolver,
                    Settings.Global.ADB_ENABLED,
                    0
                ) == 1
            } catch (e: Exception) {
                false
            }
            
            if (usbDebugging) {
                Log.w(TAG, "USB connected with debugging enabled - potential flashing attempt")
                reportTamperAttempt("usb_connection_with_debugging")
                
                // Show warning notification
                showWarningNotification()
                
                // Optionally lock device
                val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
                val isFullyPaid = prefs.getBoolean("is_fully_paid", false)
                if (!isFullyPaid) {
                    lockDevice()
                }
            }
        }
    }

    private fun checkForTampering(context: Context?) {
        serviceScope.launch {
            delay(5000) // Wait for system to stabilize
            
            // Check if device was factory reset
            val prefs = (context ?: this@FlashingProtectionService).getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
            val deviceId = prefs.getString("device_id", null)
            val isFullyPaid = prefs.getBoolean("is_fully_paid", false)
            
            if (deviceId == null && !isFullyPaid) {
                Log.w(TAG, "Device ID missing after boot - possible factory reset")
                reportTamperAttempt("possible_factory_reset")
            }
            
            // Check for system modifications
            checkSystemIntegrity(context ?: this@FlashingProtectionService)
        }
    }

    private fun checkSystemIntegrity(context: Context) {
        try {
            // Check if device is rooted
            val rootCheck = checkRoot()
            if (rootCheck) {
                Log.w(TAG, "Root detected")
                reportTamperAttempt("root_detected")
            }
            
            // Check for custom recovery
            val customRecovery = checkCustomRecovery()
            if (customRecovery) {
                Log.w(TAG, "Custom recovery detected")
                reportTamperAttempt("custom_recovery_detected")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking system integrity", e)
        }
    }

    private fun checkRoot(): Boolean {
        val rootPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        
        return rootPaths.any { path ->
            try {
                java.io.File(path).exists()
            } catch (e: Exception) {
                false
            }
        }
    }

    private fun checkCustomRecovery(): Boolean {
        return try {
            val recovery = Runtime.getRuntime()
                .exec("getprop ro.recovery")
                .inputStream.bufferedReader()
                .use { it.readLine() }
            
            recovery != null && recovery.isNotEmpty() && !recovery.contains("stock", ignoreCase = true)
        } catch (e: Exception) {
            false
        }
    }

    private fun lockDevice() {
        try {
            val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as android.app.admin.DevicePolicyManager
            val adminComponent = android.content.ComponentName(this, DeviceAdminReceiver::class.java)
            
            if (devicePolicyManager.isAdminActive(adminComponent)) {
                devicePolicyManager.lockNow()
                Log.d(TAG, "Device locked due to flashing protection")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error locking device", e)
        }
    }

    private fun showWarningNotification() {
        // TODO: Implement notification
        Log.w(TAG, "Warning: Potential flashing attempt detected")
    }

    private fun reportTamperAttempt(type: String) {
        serviceScope.launch {
            try {
                val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
                val deviceId = prefs.getString("device_id", null) ?: return@launch
                
                // Report to backend API
                // This would be implemented with your API client
                Log.d(TAG, "Reporting tamper attempt: $type for device: $deviceId")
                
                // Store tamper attempt locally
                val tamperAttempts = prefs.getStringSet("tamper_attempts", mutableSetOf()) ?: mutableSetOf()
                tamperAttempts.add("${System.currentTimeMillis()}:$type")
                prefs.edit().putStringSet("tamper_attempts", tamperAttempts).apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error reporting tamper attempt", e)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(usbReceiver)
            unregisterReceiver(bootReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receivers", e)
        }
    }
}

