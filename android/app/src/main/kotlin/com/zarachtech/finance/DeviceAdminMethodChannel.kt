package com.zarachtech.finance

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channel handler for Device Admin operations
 * Bridges Flutter calls to native Android Device Policy Manager
 */
class DeviceAdminMethodChannel(
    private val activity: Activity,
    private val channel: MethodChannel
) {
    companion object {
        private const val TAG = "DeviceAdminChannel"
        const val CHANNEL_NAME = "com.zarachtech.finance/admin"
    }

    private val devicePolicyManager: DevicePolicyManager by lazy {
        activity.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    }

    private val adminComponent: ComponentName by lazy {
        ComponentName(activity, FinanceDeviceAdminReceiver::class.java)
    }

    init {
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "isAdminActive" -> {
                        val isActive = isAdminActive()
                        result.success(isActive)
                    }
                    "requestAdminPrivileges" -> {
                        requestAdminPrivileges()
                        result.success(null)
                    }
                    "lockDevice" -> {
                        lockDevice()
                        result.success(null)
                    }
                    "unlockDevice" -> {
                        unlockDevice()
                        result.success(null)
                    }
                    "disableFactoryReset" -> {
                        val disable = call.argument<Boolean>("disable") ?: true
                        disableFactoryReset(disable)
                        result.success(null)
                    }
                    "validateReleaseCode" -> {
                        val code = call.argument<String>("code") ?: ""
                        val isValid = validateReleaseCode(code)
                        result.success(isValid)
                    }
                    "isResetBlocked" -> {
                        val isBlocked = isResetBlocked()
                        result.success(isBlocked)
                    }
                    "allowAdminDeactivation" -> {
                        allowAdminDeactivation()
                        result.success(null)
                    }
                    "markDeviceAsReleased" -> {
                        markDeviceAsReleased()
                        result.success(null)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling method call: ${call.method}", e)
                result.error("ERROR", e.message, e.toString())
            }
        }
    }

    /**
     * Check if device admin is currently active
     */
    private fun isAdminActive(): Boolean {
        val isActive = devicePolicyManager.isAdminActive(adminComponent)
        Log.d(TAG, "isAdminActive: $isActive")
        return isActive
    }

    /**
     * Request device admin privileges from user
     * Opens system settings to enable device admin
     */
    private fun requestAdminPrivileges() {
        Log.i(TAG, "Requesting admin privileges")
        
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
            putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "This app requires device administrator privileges to enforce payment compliance and protect the device."
            )
        }
        
        activity.startActivity(intent)
    }

    /**
     * Lock the device immediately
     */
    private fun lockDevice() {
        if (!isAdminActive()) {
            Log.w(TAG, "Cannot lock device - admin not active")
            throw SecurityException("Device admin is not active")
        }
        
        Log.i(TAG, "Locking device")
        devicePolicyManager.lockNow()
    }

    /**
     * Unlock the device (remove password/restrictions)
     * Note: This resets the password to empty
     */
    private fun unlockDevice() {
        if (!isAdminActive()) {
            Log.w(TAG, "Cannot unlock device - admin not active")
            throw SecurityException("Device admin is not active")
        }
        
        Log.i(TAG, "Unlocking device")
        
        // Reset password to empty (effectively unlocking)
        // Note: This method is deprecated in API 26+ but still works
        // For newer APIs, we would need to use different approaches
        try {
            @Suppress("DEPRECATION")
            devicePolicyManager.resetPassword("", 0)
        } catch (e: Exception) {
            Log.e(TAG, "Error unlocking device", e)
            // On newer Android versions, password reset might not work
            // The app should handle this gracefully
        }
    }

    /**
     * Enable or disable factory reset protection
     * @param disable true to disable factory reset, false to enable it
     */
    private fun disableFactoryReset(disable: Boolean) {
        if (!isAdminActive()) {
            Log.w(TAG, "Cannot modify factory reset - admin not active")
            throw SecurityException("Device admin is not active")
        }
        
        Log.i(TAG, "Setting factory reset protection: disable=$disable")
        
        // Use the FactoryResetProtection class for comprehensive protection
        val protection = FactoryResetProtection(activity)
        
        if (disable) {
            protection.enableProtection()
        } else {
            protection.disableProtection()
        }
    }

    /**
     * Validate release code and enable factory reset if valid
     * @param code The release code to validate
     * @return true if code is valid
     */
    private fun validateReleaseCode(code: String): Boolean {
        Log.i(TAG, "Validating release code")
        
        val protection = FactoryResetProtection(activity)
        return protection.validateReleaseCode(code)
    }

    /**
     * Check if factory reset is currently blocked
     * @return true if factory reset is blocked
     */
    private fun isResetBlocked(): Boolean {
        val protection = FactoryResetProtection(activity)
        return protection.isResetBlocked()
    }

    /**
     * Allow device admin deactivation
     * This should only be called after full payment and release code validation
     */
    private fun allowAdminDeactivation() {
        Log.i(TAG, "Allowing device admin deactivation")
        
        // Open device admin settings so user can deactivate
        val intent = Intent(android.provider.Settings.ACTION_SECURITY_SETTINGS)
        activity.startActivity(intent)
    }

    /**
     * Mark device as released in shared preferences
     * This sets a flag that allows device admin deactivation
     */
    private fun markDeviceAsReleased() {
        Log.i(TAG, "Marking device as released")
        
        val prefs = activity.getSharedPreferences("device_admin_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("device_released", true).apply()
        
        Log.i(TAG, "Device marked as released successfully")
    }
}
