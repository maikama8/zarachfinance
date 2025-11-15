package com.zarachtech.finance

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Method channel handler for launcher mode management
 * Enables/disables the app as a launcher to prevent bypass when locked
 */
class LauncherModeMethodChannel(
    private val context: Context,
    channel: MethodChannel
) {
    companion object {
        const val CHANNEL_NAME = "com.zarachtech.finance/launcher"
        private const val TAG = "LauncherModeChannel"
        private const val PREFS_NAME = "device_admin_prefs"
        private const val KEY_LAUNCHER_MODE = "launcher_mode_enabled"
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableLauncherMode" -> {
                    enableLauncherMode(result)
                }
                "disableLauncherMode" -> {
                    disableLauncherMode(result)
                }
                "isLauncherModeEnabled" -> {
                    isLauncherModeEnabled(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Enable launcher mode by enabling the HOME intent filter
     * This makes the app appear as a launcher option
     */
    private fun enableLauncherMode(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Enabling launcher mode")
            
            // Enable the launcher activity component
            val componentName = ComponentName(
                context,
                "${context.packageName}.LauncherActivity"
            )
            
            context.packageManager.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            
            // Save state to preferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean(KEY_LAUNCHER_MODE, true).apply()
            
            result.success(null)
            Log.d(TAG, "Launcher mode enabled successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling launcher mode", e)
            result.error("ERROR", "Failed to enable launcher mode: ${e.message}", null)
        }
    }

    /**
     * Disable launcher mode by disabling the HOME intent filter
     * This removes the app from launcher options
     */
    private fun disableLauncherMode(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Disabling launcher mode")
            
            // Disable the launcher activity component
            val componentName = ComponentName(
                context,
                "${context.packageName}.LauncherActivity"
            )
            
            context.packageManager.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
            
            // Save state to preferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean(KEY_LAUNCHER_MODE, false).apply()
            
            result.success(null)
            Log.d(TAG, "Launcher mode disabled successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error disabling launcher mode", e)
            result.error("ERROR", "Failed to disable launcher mode: ${e.message}", null)
        }
    }

    /**
     * Check if launcher mode is currently enabled
     */
    private fun isLauncherModeEnabled(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Checking launcher mode status")
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean(KEY_LAUNCHER_MODE, false)
            
            result.success(isEnabled)
            Log.d(TAG, "Launcher mode status: $isEnabled")
        } catch (e: Exception) {
            Log.e(TAG, "Error checking launcher mode", e)
            result.error("ERROR", "Failed to check launcher mode: ${e.message}", null)
        }
    }
}
