package com.zarachtech.finance

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Method channel handler for emergency call functionality
 * Allows launching emergency dialer even when device is locked
 */
class EmergencyCallMethodChannel(
    private val context: Context,
    channel: MethodChannel
) {
    companion object {
        const val CHANNEL_NAME = "com.zarachtech.finance/emergency"
        private const val TAG = "EmergencyCallChannel"
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "launchEmergencyDialer" -> {
                    launchEmergencyDialer(result)
                }
                "launchEmergencyDialerWithNumber" -> {
                    val number = call.argument<String>("number")
                    if (number != null) {
                        launchEmergencyDialerWithNumber(number, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Number is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Launch emergency dialer without specific number
     * Opens the dialer app for user to dial emergency numbers
     */
    private fun launchEmergencyDialer(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Launching emergency dialer")
            
            // Create intent to open dialer
            val intent = Intent(Intent.ACTION_DIAL).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            context.startActivity(intent)
            result.success(null)
            
            Log.d(TAG, "Emergency dialer launched successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error launching emergency dialer", e)
            result.error("ERROR", "Failed to launch emergency dialer: ${e.message}", null)
        }
    }

    /**
     * Launch emergency dialer with specific number
     * @param number The emergency number to dial (e.g., "112", "911")
     */
    private fun launchEmergencyDialerWithNumber(
        number: String,
        result: MethodChannel.Result
    ) {
        try {
            Log.d(TAG, "Launching emergency dialer with number: $number")
            
            // Create intent to open dialer with specific number
            val intent = Intent(Intent.ACTION_DIAL).apply {
                data = Uri.parse("tel:$number")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            context.startActivity(intent)
            result.success(null)
            
            Log.d(TAG, "Emergency dialer launched successfully with number: $number")
        } catch (e: Exception) {
            Log.e(TAG, "Error launching emergency dialer with number", e)
            result.error("ERROR", "Failed to launch emergency dialer: ${e.message}", null)
        }
    }
}
