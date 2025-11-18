package com.zarfinance.admin.service

import android.app.*
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.*
import com.zarfinance.admin.Config
import com.zarfinance.admin.R
import com.zarfinance.admin.admin.DeviceAdminReceiver
import com.zarfinance.admin.api.ApiClient
import com.zarfinance.admin.api.model.PaymentStatusResponse
import com.zarfinance.admin.ui.LockScreenActivity
import com.zarfinance.admin.service.PaymentReminderService
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit

class PaymentVerificationService : Service() {
    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName

    override fun onCreate() {
        super.onCreate()
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = DeviceAdminReceiver.getComponentName(this)
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Schedule periodic payment checks
        schedulePaymentCheck()
        
        // Schedule payment reminders
        PaymentReminderService.scheduleReminders(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        serviceScope.launch {
            checkPaymentStatus()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun schedulePaymentCheck() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val workRequest = PeriodicWorkRequestBuilder<PaymentCheckWorker>(
            Config.PAYMENT_CHECK_INTERVAL_HOURS, TimeUnit.HOURS
        )
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "payment_check",
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )
    }

    private suspend fun checkPaymentStatus() {
        try {
            val deviceId = getDeviceIdInternal()
            val response = ApiClient.paymentService.getPaymentStatus(deviceId)
            
            if (response.isSuccessful && response.body() != null) {
                val status = response.body()!!
                handlePaymentStatus(status)
            } else {
                Log.e(TAG, "Failed to check payment status: ${response.message()}")
                // On failure, check local cache
                checkLocalPaymentStatus()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking payment status", e)
            checkLocalPaymentStatus()
        }
    }

    private fun handlePaymentStatus(status: PaymentStatusResponse) {
        val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        val isLocked = prefs.getBoolean("device_locked", false)
        val lastPaymentDate = prefs.getLong("last_payment_date", 0)
        
        when {
            status.isFullyPaid -> {
                // Release device
                if (isLocked) {
                    unlockDevice()
                }
                prefs.edit()
                    .putBoolean("is_fully_paid", true)
                    .putBoolean("device_locked", false)
                    .apply()
            }
            status.isPaymentOverdue -> {
                // Lock device if not already locked
                if (!isLocked) {
                    lockDevice()
                }
                prefs.edit()
                    .putBoolean("device_locked", true)
                    .putLong("last_payment_date", System.currentTimeMillis())
                    .apply()
            }
            else -> {
                // Payment is current
                if (isLocked && status.lastPaymentDate > lastPaymentDate) {
                    // Payment was made, unlock device
                    unlockDevice()
                    prefs.edit()
                        .putBoolean("device_locked", false)
                        .putLong("last_payment_date", status.lastPaymentDate)
                        .apply()
                }
            }
        }
        
        // Store payment status locally
        storePaymentStatus(status)
    }

    private fun lockDevice() {
        if (devicePolicyManager.isAdminActive(componentName)) {
            try {
                devicePolicyManager.lockNow()
                // Start lock screen activity
                val intent = Intent(this, LockScreenActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                startActivity(intent)
                Log.d(TAG, "Device locked due to overdue payment")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to lock device", e)
            }
        }
    }

    private fun unlockDevice() {
        val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("device_locked", false).apply()
        
        // Stop lock screen activity if running
        val intent = Intent(this, LockScreenActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            action = "com.financeapp.UNLOCK"
        }
        startActivity(intent)
        Log.d(TAG, "Device unlocked after payment")
    }

    private fun checkLocalPaymentStatus() {
        val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        val lastCheck = prefs.getLong("last_payment_check", 0)
        val deadline = lastCheck + TimeUnit.HOURS.toMillis(Config.PAYMENT_DEADLINE_HOURS)
        
        if (System.currentTimeMillis() > deadline) {
            // Assume payment is overdue if we can't verify
            val isLocked = prefs.getBoolean("device_locked", false)
            if (!isLocked) {
                lockDevice()
            }
        }
    }

    private fun storePaymentStatus(status: PaymentStatusResponse) {
        val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        val history = prefs.getStringSet("payment_history", mutableSetOf()) ?: mutableSetOf()
        
        val entry = "${System.currentTimeMillis()}:${status.isPaymentOverdue}:${status.lastPaymentDate}"
        history.add(entry)
        
        // Keep only last 30 days
        val cutoff = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(Config.PAYMENT_HISTORY_DAYS.toLong())
        val filtered = history.filter { 
            it.split(":")[0].toLongOrNull() ?: 0 > cutoff 
        }.toSet()
        
        prefs.edit()
            .putStringSet("payment_history", filtered)
            .putLong("last_payment_check", System.currentTimeMillis())
            .apply()
    }

    private fun getDeviceIdInternal(): String {
        val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        var deviceId = prefs.getString("device_id", null)
        
        if (deviceId == null) {
            deviceId = android.provider.Settings.Secure.getString(
                contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            ) ?: ""
            prefs.edit().putString("device_id", deviceId).apply()
        }
        
        return deviceId ?: ""
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Payment Verification",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors payment status"
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Payment Verification Active")
            .setContentText("Monitoring payment status")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
    }

    companion object {
        private const val TAG = "PaymentVerificationService"
        private const val CHANNEL_ID = "payment_verification_channel"
        private const val NOTIFICATION_ID = 1001

        fun startService(context: Context) {
            val intent = Intent(context, PaymentVerificationService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}

class PaymentCheckWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        return try {
            PaymentVerificationService.startService(applicationContext)
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }
}

