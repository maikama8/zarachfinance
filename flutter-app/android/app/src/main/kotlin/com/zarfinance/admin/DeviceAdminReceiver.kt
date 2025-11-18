package com.zarfinance.admin

import android.app.admin.DeviceAdminReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

class DeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d(TAG, "Device Admin enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d(TAG, "Device Admin disabled")
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // Prevent deactivation during financing
        val prefs = context.getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        val isFullyPaid = prefs.getBoolean("is_fully_paid", false)
        
        if (!isFullyPaid) {
            return "Device Admin cannot be disabled until financing is fully paid. Please contact the store."
        }
        
        return super.onDisableRequested(context, intent) ?: ""
    }

    companion object {
        private const val TAG = "DeviceAdminReceiver"
        
        fun getComponentName(context: Context): ComponentName {
            return ComponentName(context, DeviceAdminReceiver::class.java)
        }
    }
}

