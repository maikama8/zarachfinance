package com.zarfinance.admin

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.zarfinance.admin/device_admin"
    private val FLASHING_PROTECTION_CHANNEL = "com.zarfinance.admin/flashing_protection"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName

    companion object {
        const val REQUEST_CODE_ENABLE_ADMIN = 1
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = ComponentName(this, DeviceAdminReceiver::class.java)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Device Admin channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isActive" -> {
                    result.success(devicePolicyManager.isAdminActive(componentName))
                }
                "requestDeviceAdmin" -> {
                    requestDeviceAdmin(result)
                }
                "lockDevice" -> {
                    if (devicePolicyManager.isAdminActive(componentName)) {
                        devicePolicyManager.lockNow()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "getDeviceId" -> {
                    result.success(getDeviceIdInternal())
                }
                "isFactoryResetBlocked" -> {
                    result.success(devicePolicyManager.isAdminActive(componentName))
                }
                "enableFactoryReset" -> {
                    val releaseCode = call.argument<String>("releaseCode")
                    if (releaseCode != null) {
                        val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
                        val storedCode = prefs.getString("release_code", null)
                        if (storedCode == releaseCode) {
                            prefs.edit().putBoolean("is_fully_paid", true).apply()
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Flashing Protection channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLASHING_PROTECTION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val intent = Intent(this, FlashingProtectionService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopService" -> {
                    val intent = Intent(this, FlashingProtectionService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "isServiceRunning" -> {
                    val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
                    val runningServices = activityManager.getRunningServices(Integer.MAX_VALUE)
                    val isRunning = runningServices.any { it.service.className == FlashingProtectionService::class.java.name }
                    result.success(isRunning)
                }
                "getTamperAttempts" -> {
                    val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
                    val attempts = prefs.getStringSet("tamper_attempts", mutableSetOf())?.toList() ?: emptyList()
                    result.success(attempts)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestDeviceAdmin(result: MethodChannel.Result) {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "This app requires device administrator privileges to enforce payment compliance.")
        startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
        result.success(true)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_ENABLE_ADMIN) {
            val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("device_admin_active", resultCode == android.app.Activity.RESULT_OK).apply()
        }
    }

    private fun getDeviceIdInternal(): String {
        val prefs = getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        var deviceId = prefs.getString("device_id", null)
        
        if (deviceId == null || deviceId.isEmpty()) {
            deviceId = android.provider.Settings.Secure.getString(contentResolver, android.provider.Settings.Secure.ANDROID_ID)
            if (deviceId != null && deviceId.isNotEmpty()) {
                prefs.edit().putString("device_id", deviceId).apply()
            } else {
                deviceId = "android_id_fallback_${System.currentTimeMillis()}"
                prefs.edit().putString("device_id", deviceId).apply()
            }
        }
        return deviceId
    }
}
