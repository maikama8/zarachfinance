package com.zarfinance.admin.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.zarfinance.admin.service.PaymentVerificationService
import com.zarfinance.admin.service.LocationTrackingService
import com.zarfinance.admin.service.TamperDetectionService

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            Log.d(TAG, "Boot completed, starting services")
            
            // Start all services on boot
            PaymentVerificationService.startService(context)
            LocationTrackingService.startService(context)
            TamperDetectionService.startService(context)
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}

