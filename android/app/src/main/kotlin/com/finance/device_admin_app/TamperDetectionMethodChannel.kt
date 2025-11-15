package com.finance.device_admin_app

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Method channel for tamper detection operations
 * Provides Flutter interface to native tamper detection functionality
 */
class TamperDetectionMethodChannel(
    private val activity: Activity,
    private val channel: MethodChannel
) {
    companion object {
        const val CHANNEL_NAME = "com.finance.deviceadmin/tamper"
    }
    
    private val tamperDetector: TamperDetector by lazy {
        TamperDetector(activity.applicationContext)
    }
    
    init {
        channel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }
    
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isDeviceRooted" -> {
                try {
                    val isRooted = tamperDetector.isDeviceRooted()
                    result.success(isRooted)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to check root status: ${e.message}", null)
                }
            }
            
            "isAppTampered" -> {
                try {
                    val isTampered = tamperDetector.isAppTampered()
                    result.success(isTampered)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to check app tampering: ${e.message}", null)
                }
            }
            
            "isDebuggerAttached" -> {
                try {
                    val isDebugging = tamperDetector.isDebuggerAttached()
                    result.success(isDebugging)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to check debugger status: ${e.message}", null)
                }
            }
            
            "checkForXposedMagisk" -> {
                try {
                    val hasFramework = tamperDetector.checkForXposedMagisk()
                    result.success(hasFramework)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to check for Xposed/Magisk: ${e.message}", null)
                }
            }
            
            "performFullCheck" -> {
                try {
                    val isTampered = tamperDetector.performFullCheck()
                    result.success(isTampered)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to perform full tamper check: ${e.message}", null)
                }
            }
            
            "performQuickCheck" -> {
                try {
                    val isTampered = tamperDetector.performQuickCheck()
                    result.success(isTampered)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to perform quick check: ${e.message}", null)
                }
            }
            
            "detectDebuggingTools" -> {
                try {
                    val hasTools = tamperDetector.detectDebuggingTools()
                    result.success(hasTools)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to detect debugging tools: ${e.message}", null)
                }
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
}
