package com.zarfinance.admin.admin

import android.app.admin.DeviceAdminReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import com.zarfinance.admin.service.PaymentVerificationService

class DeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d(TAG, "Device Admin enabled")
        // Start payment verification service
        PaymentVerificationService.startService(context)
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d(TAG, "Device Admin disabled - this should not happen during financing")
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // Prevent deactivation during financing
        val prefs = context.getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        val isFullyPaid = prefs.getBoolean("is_fully_paid", false)
        
        if (!isFullyPaid) {
            // Block the deactivation
            return "Device Admin cannot be disabled until financing is fully paid. Please contact the store."
        }
        
        return super.onDisableRequested(context, intent) ?: ""
    }

    override fun onLockTaskModeEntering(context: Context, intent: Intent, pkg: String) {
        super.onLockTaskModeEntering(context, intent, pkg)
        Log.d(TAG, "Lock task mode entering")
    }

    override fun onLockTaskModeExiting(context: Context, intent: Intent) {
        super.onLockTaskModeExiting(context, intent)
        Log.d(TAG, "Lock task mode exiting")
    }

    companion object {
        private const val TAG = "DeviceAdminReceiver"
        
        fun getComponentName(context: Context): ComponentName {
            return ComponentName(context, DeviceAdminReceiver::class.java)
        }
    }
}

