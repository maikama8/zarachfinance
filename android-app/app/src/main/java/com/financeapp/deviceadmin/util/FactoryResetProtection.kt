package com.zarfinance.admin.util

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.zarfinance.admin.admin.DeviceAdminReceiver
import com.zarfinance.admin.ui.LockScreenActivity

object FactoryResetProtection {
    private const val TAG = "FactoryResetProtection"

    fun interceptFactoryReset(context: Context, intent: Intent?): Boolean {
        val prefs = context.getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        val isFullyPaid = prefs.getBoolean("is_fully_paid", false)
        
        if (isFullyPaid) {
            // Allow factory reset if fully paid
            return false
        }

        // Check if this is a factory reset attempt
        val action = intent?.action
        if (action == "android.intent.action.FACTORY_RESET" ||
            action == "android.intent.action.MASTER_CLEAR_NOTIFICATION" ||
            action?.contains("FACTORY_RESET") == true ||
            action?.contains("MASTER_CLEAR") == true) {
            
            Log.w(TAG, "Factory reset attempt blocked")
            
            // Show message to user
            showResetBlockedMessage(context)
            
            // Block the reset
            return true
        }

        return false
    }

    fun checkRecoveryModeReset(context: Context): Boolean {
        val prefs = context.getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        val isFullyPaid = prefs.getBoolean("is_fully_paid", false)
        
        if (isFullyPaid) {
            return false
        }

        // On boot, check if we're in recovery mode
        // This is a simplified check - full implementation would require
        // monitoring recovery partition or using device-specific methods
        val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = DeviceAdminReceiver.getComponentName(context)
        
        if (devicePolicyManager.isAdminActive(componentName)) {
            // Use device admin to prevent wipe
            try {
                // This will be called on boot to ensure protection is maintained
                Log.d(TAG, "Factory reset protection active")
            } catch (e: Exception) {
                Log.e(TAG, "Error maintaining factory reset protection", e)
            }
        }

        return false
    }

    private fun showResetBlockedMessage(context: Context) {
        val intent = Intent(context, LockScreenActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("message", "Factory reset is disabled until financing is fully paid. Please contact the store.")
        }
        context.startActivity(intent)
    }

    fun enableFactoryReset(context: Context, releaseCode: String): Boolean {
        val prefs = context.getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        val storedCode = prefs.getString("release_code", null)
        
        if (storedCode == releaseCode) {
            prefs.edit().putBoolean("is_fully_paid", true).apply()
            return true
        }
        
        return false
    }
}

