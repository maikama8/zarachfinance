package com.finance.device_admin_app

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

/**
 * Launcher activity that intercepts HOME button presses when device is locked
 * Redirects to MainActivity which will show the lock screen
 */
class LauncherActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Immediately redirect to MainActivity
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        
        startActivity(intent)
        finish()
    }
}
