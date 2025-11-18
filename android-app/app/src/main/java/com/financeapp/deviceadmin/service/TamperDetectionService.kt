package com.zarfinance.admin.service

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.zarfinance.admin.Config
import com.zarfinance.admin.R
import com.zarfinance.admin.api.ApiClient
import com.zarfinance.admin.api.model.DeviceStatusReport
import com.zarfinance.admin.ui.LockScreenActivity
import kotlinx.coroutines.*
import java.security.MessageDigest
import java.util.concurrent.TimeUnit

class TamperDetectionService : Service() {
    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var originalAppSignature: String? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Store original app signature
        originalAppSignature = getAppSignature()
        
        // Start periodic integrity checks
        startIntegrityChecks()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Config.INTEGRITY_CHECK_ON_LAUNCH) {
            serviceScope.launch {
                checkIntegrity()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startIntegrityChecks() {
        serviceScope.launch {
            while (isActive) {
                delay(TimeUnit.MINUTES.toMillis(Config.TAMPER_CHECK_INTERVAL_MINUTES))
                checkIntegrity()
            }
        }
    }

    private suspend fun checkIntegrity() {
        try {
            val currentSignature = getAppSignature()
            
            // Check if signature changed
            if (originalAppSignature != null && currentSignature != originalAppSignature) {
                handleTampering("App signature mismatch detected")
                return
            }

            // Check if app is installed from unknown sources (if possible)
            if (isAppModified()) {
                handleTampering("App modification detected")
                return
            }

            // Check for root/jailbreak
            if (isDeviceRooted()) {
                handleTampering("Rooted device detected")
                return
            }

            // Check if device admin is still active
            if (!isDeviceAdminActive()) {
                handleTampering("Device admin privileges revoked")
                return
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error during integrity check", e)
        }
    }

    private fun getAppSignature(): String {
        return try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES
                )
            }

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            if (signatures.isNotEmpty()) {
                val md = MessageDigest.getInstance("SHA-256")
                md.update(signatures[0].toByteArray())
                md.digest().joinToString("") { "%02x".format(it) }
            } else {
                ""
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting app signature", e)
            ""
        }
    }

    private fun isAppModified(): Boolean {
        // Check if app is installed from Play Store or verified source
        // This is a simplified check - in production, use more sophisticated methods
        return try {
            val installer = packageManager.getInstallerPackageName(packageName)
            installer == null || installer != "com.android.vending"
        } catch (e: Exception) {
            false
        }
    }

    private fun isDeviceRooted(): Boolean {
        // Check for common root indicators
        val rootPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su"
        )

        return rootPaths.any { java.io.File(it).exists() }
    }

    private fun isDeviceAdminActive(): Boolean {
        val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as android.app.admin.DevicePolicyManager
        val componentName = com.zarfinance.admin.admin.DeviceAdminReceiver.getComponentName(this)
        return devicePolicyManager.isAdminActive(componentName)
    }

    private fun handleTampering(reason: String) {
        Log.e(TAG, "Tampering detected: $reason")
        
        // Lock device immediately
        val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as android.app.admin.DevicePolicyManager
        val componentName = com.zarfinance.admin.admin.DeviceAdminReceiver.getComponentName(this)
        
        if (devicePolicyManager.isAdminActive(componentName)) {
            try {
                devicePolicyManager.lockNow()
                
                // Start lock screen
                val intent = Intent(this, LockScreenActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("tamper_reason", reason)
                }
                startActivity(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to lock device after tampering", e)
            }
        }

        // Report to backend
        serviceScope.launch {
            try {
                val deviceId = getDeviceIdInternal()
                val report = DeviceStatusReport(
                    deviceId = deviceId,
                    isLocked = true,
                    appVersion = getAppVersion(),
                    batteryLevel = 0, // Can be enhanced
                    isCharging = false
                )
                ApiClient.deviceService.reportDeviceStatus(report)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to report tampering", e)
            }
        }
    }

    private fun getDeviceIdInternal(): String {
        val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        return prefs.getString("device_id", "") ?: ""
    }

    private fun getAppVersion(): String {
        return try {
            val packageInfo = packageManager.getPackageInfo(packageName, 0)
            packageInfo.versionName ?: "unknown"
        } catch (e: Exception) {
            "unknown"
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Security Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors app integrity"
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Security Monitoring Active")
            .setContentText("Monitoring app integrity")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
    }

    companion object {
        private const val TAG = "TamperDetectionService"
        private const val CHANNEL_ID = "tamper_detection_channel"
        private const val NOTIFICATION_ID = 1003

        fun startService(context: Context) {
            val intent = Intent(context, TamperDetectionService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}

