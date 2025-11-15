package com.zarachtech.finance

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver that handles device boot events
 * Checks lock state and starts app on lock screen if device is locked
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
        private const val PREFS_NAME = "device_admin_prefs"
        private const val KEY_IS_LOCKED = "is_locked"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot completed")
            
            try {
                // Check lock state from shared preferences
                // Note: We use SharedPreferences here as a fallback since we can't
                // easily access the encrypted database from the receiver
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val isLocked = prefs.getBoolean(KEY_IS_LOCKED, false)
                
                Log.d(TAG, "Lock state: $isLocked")
                
                if (isLocked) {
                    Log.d(TAG, "Device is locked, starting app on lock screen")
                    
                    // Start the main activity
                    val launchIntent = Intent(context, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        putExtra("start_locked", true)
                    }
                    
                    context.startActivity(launchIntent)
                    
                    Log.d(TAG, "App started successfully")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling boot completed", e)
            }
        }
    }
}
