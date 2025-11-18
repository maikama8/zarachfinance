package com.zarfinance.admin.ui

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.zarfinance.admin.R
import com.zarfinance.admin.api.ApiClient
import kotlinx.coroutines.*

class LockScreenActivity : AppCompatActivity() {
    private val activityScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private lateinit var messageText: TextView
    private lateinit var contactButton: Button
    private lateinit var emergencyCallButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_lock_screen)
        
        messageText = findViewById(R.id.lock_message)
        contactButton = findViewById(R.id.btn_contact_store)
        emergencyCallButton = findViewById(R.id.btn_emergency_call)

        // Check if unlock was requested
        if (intent.action == "com.financeapp.UNLOCK") {
            finish()
            return
        }

        setupLockScreen()
    }

    private fun setupLockScreen() {
        val prefs = getSharedPreferences("finance_prefs", MODE_PRIVATE)
        val storeContact = prefs.getString("store_contact", "Contact Store")
        val customMessage = prefs.getString("custom_message", null)
        
        val message = customMessage ?: "Your device is locked due to overdue payment. Please make your payment to unlock the device."
        messageText.text = message
        
        contactButton.text = storeContact
        contactButton.setOnClickListener {
            val phoneNumber = prefs.getString("store_phone", "") ?: ""
            if (phoneNumber.isNotEmpty()) {
                val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phoneNumber"))
                startActivity(intent)
            }
        }

        emergencyCallButton.setOnClickListener {
            val intent = Intent(Intent.ACTION_DIAL)
            startActivity(intent)
        }

        // Check payment status periodically
        activityScope.launch {
            while (isActive) {
                delay(60000) // Check every minute
                checkPaymentStatus()
            }
        }
    }

    private suspend fun checkPaymentStatus() {
        try {
            val deviceId = getDeviceIdInternal()
            val response = ApiClient.paymentService.getPaymentStatus(deviceId)
            
            if (response.isSuccessful && response.body() != null) {
                val status = response.body()!!
                if (!status.isPaymentOverdue && !status.isFullyPaid) {
                    // Payment made, unlock device
                    finish()
                }
            }
        } catch (e: Exception) {
            // Ignore errors, will retry
        }
    }

    override fun onBackPressed() {
        // Prevent back button
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Allow only emergency calls
        if (keyCode == KeyEvent.KEYCODE_POWER) {
            return super.onKeyDown(keyCode, event)
        }
        return true
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // Keep screen on
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
    }

    private fun getDeviceIdInternal(): String {
        val prefs = getSharedPreferences("finance_prefs", MODE_PRIVATE)
        return prefs.getString("device_id", "") ?: ""
    }

    override fun onDestroy() {
        super.onDestroy()
        activityScope.cancel()
    }
}

