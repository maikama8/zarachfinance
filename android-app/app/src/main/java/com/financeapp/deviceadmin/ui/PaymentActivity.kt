package com.zarfinance.admin.ui

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import com.zarfinance.admin.R
import com.zarfinance.admin.api.ApiClient
import com.zarfinance.admin.api.model.PaymentInitializeRequest
import com.zarfinance.admin.api.model.PaymentVerifyRequest
import kotlinx.coroutines.*

class PaymentActivity : AppCompatActivity() {
    private val activityScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private lateinit var amountEditText: EditText
    private lateinit var emailEditText: EditText
    private lateinit var submitButton: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var statusText: TextView
    private var paymentReference: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_payment)

        amountEditText = findViewById(R.id.amount_edit)
        emailEditText = findViewById(R.id.email_edit)
        submitButton = findViewById(R.id.btn_submit_payment)
        progressBar = findViewById(R.id.payment_progress)
        statusText = findViewById(R.id.payment_status_text)

        setupSubmitButton()
        
        // Check if returning from payment gateway
        val intent = intent
        val reference = intent.getStringExtra("payment_reference")
        if (reference != null) {
            verifyPayment(reference)
        }
    }

    private fun setupSubmitButton() {
        submitButton.setOnClickListener {
            val amount = amountEditText.text.toString().toDoubleOrNull()
            val email = emailEditText.text.toString().trim()
            
            if (amount == null || amount <= 0) {
                statusText.text = "Please enter a valid amount"
                return@setOnClickListener
            }
            
            if (email.isEmpty() || !android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
                statusText.text = "Please enter a valid email address"
                return@setOnClickListener
            }
            
            initializePayment(amount, email)
        }
    }

    private fun initializePayment(amount: Double, email: String) {
        progressBar.visibility = ProgressBar.VISIBLE
        submitButton.isEnabled = false
        statusText.text = "Initializing payment..."

        activityScope.launch {
            try {
                val deviceId = getDeviceIdInternal()
                val request = PaymentInitializeRequest(
                    deviceId = deviceId,
                    amount = amount,
                    email = email
                )

                val response = ApiClient.paymentService.initializePayment(request)
                
                if (response.isSuccessful && response.body() != null) {
                    val result = response.body()!!
                    if (result.success) {
                        paymentReference = result.reference
                        // Open payment gateway URL in browser
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(result.authorizationUrl))
                        startActivity(intent)
                        statusText.text = "Redirecting to payment gateway..."
                    } else {
                        statusText.text = "Failed to initialize payment"
                        submitButton.isEnabled = true
                    }
                } else {
                    statusText.text = "Failed to initialize payment. Please try again."
                    submitButton.isEnabled = true
                }
            } catch (e: Exception) {
                statusText.text = "Error: ${e.message}. Please check your connection and try again."
                submitButton.isEnabled = true
            } finally {
                progressBar.visibility = ProgressBar.GONE
            }
        }
    }

    private fun verifyPayment(reference: String) {
        progressBar.visibility = ProgressBar.VISIBLE
        submitButton.isEnabled = false
        statusText.text = "Verifying payment..."

        activityScope.launch {
            try {
                val deviceId = getDeviceIdInternal()
                val request = PaymentVerifyRequest(
                    reference = reference,
                    deviceId = deviceId
                )

                val response = ApiClient.paymentService.verifyPayment(request)
                
                if (response.isSuccessful && response.body() != null) {
                    val result = response.body()!!
                    if (result.success) {
                        statusText.text = "Payment successful! New balance: ₦${String.format("%.2f", result.newBalance)}"
                        
                        // Show payment confirmation notification
                        // Note: We don't have the original amount here, so we'll use a placeholder
                        com.zarfinance.admin.service.PaymentReminderService.showPaymentConfirmation(
                            this@PaymentActivity,
                            0.0, // Amount will be shown in notification
                            result.newBalance
                        )
                        
                        // Delay to show message, then finish
                        delay(3000)
                        finish()
                    } else {
                        statusText.text = "Payment verification failed: ${result.message}"
                        submitButton.isEnabled = true
                    }
                } else {
                    statusText.text = "Payment verification failed. Please try again."
                    submitButton.isEnabled = true
                }
            } catch (e: Exception) {
                statusText.text = "Error: ${e.message}. Please check your connection and try again."
                submitButton.isEnabled = true
            } finally {
                progressBar.visibility = ProgressBar.GONE
            }
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

