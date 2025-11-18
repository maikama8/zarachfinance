package com.zarfinance.admin.ui

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.zarfinance.admin.R
import com.zarfinance.admin.admin.DeviceAdminReceiver
import com.zarfinance.admin.api.ApiClient
import kotlinx.coroutines.*

class MainActivity : AppCompatActivity() {
    private val activityScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private lateinit var balanceText: TextView
    private lateinit var nextPaymentText: TextView
    private lateinit var paymentButton: Button
    private lateinit var scheduleButton: Button
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        devicePolicyManager = getSystemService(DevicePolicyManager::class.java)
        componentName = DeviceAdminReceiver.getComponentName(this)

        balanceText = findViewById(R.id.balance_text)
        nextPaymentText = findViewById(R.id.next_payment_text)
        paymentButton = findViewById(R.id.btn_make_payment)
        scheduleButton = findViewById(R.id.btn_view_schedule)

        // Request device admin if not already active
        if (!devicePolicyManager.isAdminActive(componentName)) {
            requestDeviceAdmin()
        }

        setupUI()
        loadPaymentInfo()
    }

    private fun requestDeviceAdmin() {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
            "This app requires device administrator privileges to enforce payment compliance.")
        startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
    }

    private fun setupUI() {
        paymentButton.setOnClickListener {
            startActivity(Intent(this, PaymentActivity::class.java))
        }

        scheduleButton.setOnClickListener {
            // Show payment schedule
            activityScope.launch {
                try {
                    val deviceId = getDeviceIdInternal()
                    val response = ApiClient.paymentService.getPaymentSchedule(deviceId)
                    if (response.isSuccessful && response.body() != null) {
                        showPaymentSchedule(response.body()!!)
                    }
                } catch (e: Exception) {
                    // Handle error
                }
            }
        }
    }

    private fun loadPaymentInfo() {
        activityScope.launch {
            try {
                val deviceId = getDeviceIdInternal()
                val statusResponse = ApiClient.paymentService.getPaymentStatus(deviceId)
                
                if (statusResponse.isSuccessful && statusResponse.body() != null) {
                    val status = statusResponse.body()!!
                    updateUI(status)
                }
            } catch (e: Exception) {
                // Handle error
            }
        }
    }

    private fun updateUI(status: com.zarfinance.admin.api.model.PaymentStatusResponse) {
        balanceText.text = "Remaining Balance: ₦${String.format("%.2f", status.remainingBalance)}"
        
        if (status.isPaymentOverdue) {
            nextPaymentText.text = "Payment Overdue! Please make payment immediately."
            nextPaymentText.setTextColor(getColor(android.R.color.holo_red_dark))
        } else {
            val nextPaymentDate = java.text.SimpleDateFormat("MMM dd, yyyy", java.util.Locale.getDefault())
                .format(java.util.Date(status.nextPaymentDate))
            nextPaymentText.text = "Next Payment: $nextPaymentDate"
            nextPaymentText.setTextColor(getColor(android.R.color.holo_green_dark))
        }
    }

    private fun showPaymentSchedule(schedule: com.zarfinance.admin.api.model.PaymentSchedule) {
        // Create dialog or activity to show schedule
        // Implementation depends on UI preference
    }

    private fun getDeviceIdInternal(): String {
        val prefs = getSharedPreferences("finance_prefs", MODE_PRIVATE)
        var deviceId = prefs.getString("device_id", null)
        
        if (deviceId == null) {
            deviceId = android.provider.Settings.Secure.getString(
                contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            ) ?: ""
            prefs.edit().putString("device_id", deviceId).apply()
        }
        
        return deviceId ?: ""
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_ENABLE_ADMIN) {
            if (resultCode == RESULT_OK) {
                // Device admin enabled
            } else {
                // User declined, but we can't proceed without it
                finish()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        loadPaymentInfo()
    }

    override fun onDestroy() {
        super.onDestroy()
        activityScope.cancel()
    }

    companion object {
        private const val REQUEST_CODE_ENABLE_ADMIN = 1001
    }
}

