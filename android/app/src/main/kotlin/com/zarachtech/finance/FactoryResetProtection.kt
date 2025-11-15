package com.zarachtech.finance

import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log

/**
 * Factory Reset Protection Manager
 * Handles blocking and enabling factory reset operations
 */
class FactoryResetProtection(private val context: Context) {
    
    companion object {
        private const val TAG = "FactoryResetProtection"
        private const val PREF_NAME = "factory_reset_prefs"
        private const val KEY_RESET_BLOCKED = "reset_blocked"
        private const val KEY_RELEASE_CODE_VALIDATED = "release_code_validated"
    }

    private val devicePolicyManager: DevicePolicyManager by lazy {
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    }

    private val adminComponent: ComponentName by lazy {
        ComponentName(context, FinanceDeviceAdminReceiver::class.java)
    }

    private val prefs by lazy {
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }

    /**
     * Enable factory reset protection
     * Blocks factory reset attempts when payment is pending
     */
    fun enableProtection() {
        Log.i(TAG, "Enabling factory reset protection")
        
        if (!isAdminActive()) {
            Log.w(TAG, "Cannot enable protection - admin not active")
            return
        }

        // Store state
        prefs.edit().putBoolean(KEY_RESET_BLOCKED, true).apply()

        // Add user restriction to disable factory reset
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                devicePolicyManager.addUserRestriction(
                    adminComponent,
                    android.os.UserManager.DISALLOW_FACTORY_RESET
                )
                Log.d(TAG, "Factory reset user restriction added")
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Cannot add factory reset restriction - requires device owner mode", e)
            // This is expected in device admin mode
            // Full protection requires device owner mode
        }

        // For API 28+, we can use setFactoryResetProtectionPolicy
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                // This requires device owner mode
                // In device admin mode, this will throw SecurityException
                // We catch it and continue with limited protection
                Log.d(TAG, "Attempting to set factory reset protection policy (requires device owner)")
            } catch (e: SecurityException) {
                Log.w(TAG, "Cannot set FRP policy - requires device owner mode", e)
            }
        }
    }

    /**
     * Disable factory reset protection
     * Allows factory reset after full payment and release code validation
     */
    fun disableProtection() {
        Log.i(TAG, "Disabling factory reset protection")
        
        if (!isAdminActive()) {
            Log.w(TAG, "Cannot disable protection - admin not active")
            return
        }

        // Store state
        prefs.edit()
            .putBoolean(KEY_RESET_BLOCKED, false)
            .putBoolean(KEY_RELEASE_CODE_VALIDATED, true)
            .apply()

        // Remove user restriction
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                devicePolicyManager.clearUserRestriction(
                    adminComponent,
                    android.os.UserManager.DISALLOW_FACTORY_RESET
                )
                Log.d(TAG, "Factory reset user restriction removed")
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Cannot remove factory reset restriction", e)
        }
    }

    /**
     * Check if factory reset is currently blocked
     */
    fun isResetBlocked(): Boolean {
        return prefs.getBoolean(KEY_RESET_BLOCKED, false)
    }

    /**
     * Check if release code has been validated
     */
    fun isReleaseCodeValidated(): Boolean {
        return prefs.getBoolean(KEY_RELEASE_CODE_VALIDATED, false)
    }

    /**
     * Validate release code and enable factory reset if valid
     * @param code The release code to validate
     * @return true if code is valid and reset is now enabled
     */
    fun validateReleaseCode(code: String): Boolean {
        Log.i(TAG, "Validating release code")
        
        // TODO: Implement actual validation logic with backend
        // For now, this is a placeholder
        // In production, this should:
        // 1. Send code to backend for validation
        // 2. Verify payment is complete
        // 3. Only then disable protection
        
        // Placeholder validation (should be replaced with real backend call)
        if (code.isNotEmpty() && code.length >= 12) {
            disableProtection()
            return true
        }
        
        return false
    }

    /**
     * Check if device admin is active
     */
    private fun isAdminActive(): Boolean {
        return devicePolicyManager.isAdminActive(adminComponent)
    }
}

/**
 * Broadcast receiver to intercept factory reset attempts
 * Note: This has limited effectiveness without device owner mode
 */
class FactoryResetInterceptor : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "FactoryResetInterceptor"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.w(TAG, "Factory reset attempt detected: ${intent.action}")
        
        val protection = FactoryResetProtection(context)
        
        if (protection.isResetBlocked() && !protection.isReleaseCodeValidated()) {
            Log.w(TAG, "Blocking factory reset attempt - payment pending")
            
            // Attempt to abort the broadcast
            // Note: This may not work for all factory reset methods
            abortBroadcast()
            
            // Show notification to user
            // TODO: Implement notification to inform user that reset is blocked
        } else {
            Log.i(TAG, "Factory reset allowed - release code validated")
        }
    }
}
