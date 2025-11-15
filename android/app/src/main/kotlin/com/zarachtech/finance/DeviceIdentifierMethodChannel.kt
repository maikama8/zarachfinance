package com.zarachtech.finance

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DeviceIdentifierMethodChannel(
    private val context: Context,
    channel: MethodChannel
) {
    companion object {
        const val CHANNEL_NAME = "com.zarachtech.finance/device_identifier"
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    try {
                        val deviceInfo = getDeviceInfo()
                        result.success(deviceInfo)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get device info: ${e.message}", null)
                    }
                }
                "getIMEI" -> {
                    try {
                        val imei = getIMEI()
                        result.success(imei)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get IMEI: ${e.message}", null)
                    }
                }
                "getAndroidId" -> {
                    try {
                        val androidId = getAndroidId()
                        result.success(androidId)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get Android ID: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Get comprehensive device information
     * Returns a map with device identifiers and hardware info
     */
    private fun getDeviceInfo(): Map<String, String> {
        val deviceInfo = mutableMapOf<String, String>()

        // Get IMEI (or fallback identifier)
        deviceInfo["imei"] = getIMEI()

        // Get Android ID
        deviceInfo["androidId"] = getAndroidId()

        // Get device model
        deviceInfo["model"] = Build.MODEL

        // Get device manufacturer
        deviceInfo["manufacturer"] = Build.MANUFACTURER

        // Get device brand
        deviceInfo["brand"] = Build.BRAND

        // Get device product name
        deviceInfo["product"] = Build.PRODUCT

        // Get Android version
        deviceInfo["osVersion"] = Build.VERSION.RELEASE

        // Get SDK version
        deviceInfo["sdkVersion"] = Build.VERSION.SDK_INT.toString()

        // Get device hardware
        deviceInfo["hardware"] = Build.HARDWARE

        // Get device board
        deviceInfo["board"] = Build.BOARD

        return deviceInfo
    }

    /**
     * Get IMEI or alternative unique identifier
     * For Android 10+, IMEI requires READ_PRIVILEGED_PHONE_STATE which is only for system apps
     * Falls back to Android ID if IMEI is unavailable
     */
    @SuppressLint("HardwareIds")
    private fun getIMEI(): String {
        // Check if we have permission to read phone state
        val hasPermission = ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED

        if (hasPermission) {
            try {
                val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

                // For Android 10 (API 29) and above, IMEI access is restricted
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    // Use Android ID as primary identifier for Android 10+
                    return getAndroidId()
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    // For Android 8.0 (API 26) to Android 9 (API 28)
                    @Suppress("DEPRECATION")
                    val imei = telephonyManager.imei
                    if (!imei.isNullOrEmpty()) {
                        return imei
                    }
                } else {
                    // For Android 7.x and below (API 25 and below)
                    @Suppress("DEPRECATION")
                    val deviceId = telephonyManager.deviceId
                    if (!deviceId.isNullOrEmpty()) {
                        return deviceId
                    }
                }
            } catch (e: Exception) {
                // If any error occurs, fall back to Android ID
                android.util.Log.w("DeviceIdentifier", "Failed to get IMEI: ${e.message}")
            }
        }

        // Fallback to Android ID
        return getAndroidId()
    }

    /**
     * Get Android ID (unique identifier for the device)
     * This is available on all Android versions and doesn't require permissions
     */
    @SuppressLint("HardwareIds")
    private fun getAndroidId(): String {
        return Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID
        ) ?: "UNKNOWN"
    }
}
