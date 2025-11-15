package com.finance.device_admin_app

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Device Admin Receiver for Finance Device Admin App
 * Handles device administrator events and enforces admin policies
 */
class FinanceDeviceAdminReceiver : DeviceAdminReceiver() {
    
    companion object {
        private const val TAG = "FinanceDeviceAdmin"
    }

    /**
     * Called when user attempts to disable device admin
     * Returns a message to block the deactivation unless device is released
     */
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        Log.w(TAG, "Admin deactivation attempted")
        
        // Check if device has been released
        val prefs = context.getSharedPreferences("device_admin_prefs", Context.MODE_PRIVATE)
        val isReleased = prefs.getBoolean("device_released", false)
        
        return if (isReleased) {
            Log.i(TAG, "Device is released - allowing admin deactivation")
            "Device has been released. You may now deactivate device admin."
        } else {
            Log.w(TAG, "Device not released - blocking admin deactivation")
            "Device admin cannot be disabled while payment is pending. Please complete all payments or contact the store."
        }
    }

    /**
     * Called when device admin is enabled
     * Initialize device policies here
     */
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Device admin enabled - initializing policies")
        
        // Initialize device policies
        // Additional policy setup can be done here if needed
    }

    /**
     * Called when device admin is disabled
     * This should only happen after full payment with release code
     */
    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.i(TAG, "Device admin disabled - device released")
        
        // Clean up any remaining restrictions
        // This is called after release code validation
    }

    /**
     * Called when password has changed
     */
    override fun onPasswordChanged(context: Context, intent: Intent) {
        super.onPasswordChanged(context, intent)
        Log.d(TAG, "Password changed")
    }

    /**
     * Called when password has failed
     */
    override fun onPasswordFailed(context: Context, intent: Intent) {
        super.onPasswordFailed(context, intent)
        Log.d(TAG, "Password failed")
    }

    /**
     * Called when password has succeeded
     */
    override fun onPasswordSucceeded(context: Context, intent: Intent) {
        super.onPasswordSucceeded(context, intent)
        Log.d(TAG, "Password succeeded")
    }
}
