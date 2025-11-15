package com.zarachtech.finance

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Method channel handler for lock state synchronization
 * Syncs lock state between Flutter database and native SharedPreferences
 * This allows BootReceiver to check lock state on device boot
 */
class LockStateMethodChannel(
    private val context: Context,
    channel: MethodChannel
) {
    companion object {
        const val CHANNEL_NAME = "com.zarachtech.finance/lockstate"
        private const val TAG = "LockStateChannel"
        private const val PREFS_NAME = "device_admin_prefs"
        private const val KEY_IS_LOCKED = "is_locked"
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "syncLockState" -> {
                    val isLocked = call.argument<Boolean>("isLocked")
                    if (isLocked != null) {
                        syncLockState(isLocked, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "isLocked is required", null)
                    }
                }
                "getLockState" -> {
                    getLockState(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Sync lock state to SharedPreferences
     * @param isLocked The lock state to save
     */
    private fun syncLockState(isLocked: Boolean, result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Syncing lock state: $isLocked")
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean(KEY_IS_LOCKED, isLocked).apply()
            
            result.success(null)
            Log.d(TAG, "Lock state synced successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error syncing lock state", e)
            result.error("ERROR", "Failed to sync lock state: ${e.message}", null)
        }
    }

    /**
     * Get lock state from SharedPreferences
     * @return The current lock state
     */
    private fun getLockState(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Getting lock state")
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val isLocked = prefs.getBoolean(KEY_IS_LOCKED, false)
            
            result.success(isLocked)
            Log.d(TAG, "Lock state retrieved: $isLocked")
        } catch (e: Exception) {
            Log.e(TAG, "Error getting lock state", e)
            result.error("ERROR", "Failed to get lock state: ${e.message}", null)
        }
    }
}
