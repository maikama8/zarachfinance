package com.zarfinance.admin

import android.app.Application
import android.content.Context
import androidx.work.Configuration
import androidx.work.WorkManager

class ZarFinanceApp : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize WorkManager
        val config = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
        WorkManager.initialize(this, config)
    }

    companion object {
        lateinit var instance: ZarFinanceApp
            private set
    }

    init {
        instance = this
    }
}

