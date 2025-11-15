package com.finance.device_admin_app

import android.content.Context
import android.content.pm.PackageManager
import android.os.Debug
import java.io.File

/**
 * TamperDetector provides security checks to detect device rooting,
 * app tampering, debugging attempts, and framework modifications
 */
class TamperDetector(private val context: Context) {
    
    companion object {
        // Known root binary paths
        private val ROOT_PATHS = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        
        // Known root management apps
        private val ROOT_PACKAGES = arrayOf(
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.topjohnwu.magisk"
        )
        
        // Xposed/Magisk indicators
        private val XPOSED_PATHS = arrayOf(
            "/system/framework/XposedBridge.jar",
            "/system/lib/libxposed_art.so",
            "/system/lib64/libxposed_art.so"
        )
        
        private val MAGISK_PATHS = arrayOf(
            "/sbin/.magisk",
            "/system/xbin/magisk",
            "/data/adb/magisk"
        )
    }
    
    /**
     * Check if device is rooted
     * Checks for su binary, root management apps, and build tags
     * @return true if device appears to be rooted
     */
    fun isDeviceRooted(): Boolean {
        return checkForSuBinary() || 
               checkForRootApps() || 
               checkBuildTags() ||
               checkForRWPaths()
    }
    
    /**
     * Check for su binary in common locations
     */
    private fun checkForSuBinary(): Boolean {
        for (path in ROOT_PATHS) {
            if (File(path).exists()) {
                return true
            }
        }
        return false
    }
    
    /**
     * Check for known root management apps
     */
    private fun checkForRootApps(): Boolean {
        val packageManager = context.packageManager
        for (packageName in ROOT_PACKAGES) {
            try {
                packageManager.getPackageInfo(packageName, 0)
                return true
            } catch (e: PackageManager.NameNotFoundException) {
                // Package not found, continue checking
            }
        }
        return false
    }
    
    /**
     * Check build tags for test-keys (indicates custom ROM)
     */
    private fun checkBuildTags(): Boolean {
        val buildTags = android.os.Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }
    
    /**
     * Check if system directories are writable (shouldn't be on non-rooted device)
     */
    private fun checkForRWPaths(): Boolean {
        val paths = arrayOf("/system", "/system/bin", "/system/sbin", "/system/xbin")
        for (path in paths) {
            val file = File(path)
            if (file.exists() && file.canWrite()) {
                return true
            }
        }
        return false
    }
    
    /**
     * Check if app has been tampered with
     * Verifies app signature against expected signature
     * @return true if app signature doesn't match expected signature
     */
    fun isAppTampered(): Boolean {
        return !verifyAppSignature()
    }
    
    /**
     * Verify app signature matches expected signature
     * In production, this should compare against a hardcoded expected signature
     */
    private fun verifyAppSignature(): Boolean {
        try {
            val packageInfo = context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.GET_SIGNATURES
            )
            
            // Get current signature
            val signatures = packageInfo.signatures
            if (signatures == null || signatures.isEmpty()) {
                return false
            }
            
            // In production, compare against expected signature hash
            // For now, we just verify that a signature exists
            // TODO: Store expected signature hash and compare
            val currentSignature = signatures[0].toCharsString()
            
            // Placeholder: In production, compare with stored expected signature
            // Example: return currentSignature == EXPECTED_SIGNATURE_HASH
            
            // For development, we assume signature is valid if it exists
            return currentSignature.isNotEmpty()
            
        } catch (e: Exception) {
            // If we can't verify signature, assume tampering
            return false
        }
    }
    
    /**
     * Check if debugger is attached to the app
     * Uses multiple detection methods including timing checks
     * @return true if debugger is connected
     */
    fun isDebuggerAttached(): Boolean {
        // Direct debugger check
        if (Debug.isDebuggerConnected() || Debug.waitingForDebugger()) {
            return true
        }
        
        // Timing-based debugger detection
        if (detectDebuggerByTiming()) {
            return true
        }
        
        // Check for debug flags in ApplicationInfo
        if (isDebuggable()) {
            return true
        }
        
        return false
    }
    
    /**
     * Detect debugger using timing checks
     * Debuggers slow down execution significantly
     * @return true if timing anomaly detected
     */
    private fun detectDebuggerByTiming(): Boolean {
        val startTime = System.nanoTime()
        
        // Perform a simple operation
        var sum = 0
        for (i in 0..999) {
            sum += i
        }
        
        val endTime = System.nanoTime()
        val duration = endTime - startTime
        
        // If operation takes more than 10ms, likely being debugged
        // Normal execution should be < 1ms
        return duration > 10_000_000 // 10 milliseconds in nanoseconds
    }
    
    /**
     * Check if app is debuggable
     * @return true if app has debuggable flag set
     */
    private fun isDebuggable(): Boolean {
        return (context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }
    
    /**
     * Check for debugging tools and emulator
     * @return true if debugging tools or emulator detected
     */
    fun detectDebuggingTools(): Boolean {
        // Check for common debugging tools
        if (checkForFridaServer()) {
            return true
        }
        
        // Check if running on emulator
        if (isEmulator()) {
            return true
        }
        
        return false
    }
    
    /**
     * Check for Frida server (dynamic instrumentation tool)
     * @return true if Frida is detected
     */
    private fun checkForFridaServer(): Boolean {
        val fridaPorts = arrayOf(27042, 27043) // Default Frida ports
        
        try {
            for (port in fridaPorts) {
                val socket = java.net.Socket()
                try {
                    socket.connect(
                        java.net.InetSocketAddress("127.0.0.1", port),
                        100 // 100ms timeout
                    )
                    socket.close()
                    return true // Port is open, Frida likely running
                } catch (e: Exception) {
                    // Port not open, continue
                }
            }
        } catch (e: Exception) {
            // Error checking ports
        }
        
        return false
    }
    
    /**
     * Check if running on emulator
     * Emulators are often used for reverse engineering
     * @return true if running on emulator
     */
    private fun isEmulator(): Boolean {
        return (android.os.Build.FINGERPRINT.startsWith("generic")
                || android.os.Build.FINGERPRINT.startsWith("unknown")
                || android.os.Build.MODEL.contains("google_sdk")
                || android.os.Build.MODEL.contains("Emulator")
                || android.os.Build.MODEL.contains("Android SDK built for x86")
                || android.os.Build.MANUFACTURER.contains("Genymotion")
                || (android.os.Build.BRAND.startsWith("generic") && android.os.Build.DEVICE.startsWith("generic"))
                || "google_sdk" == android.os.Build.PRODUCT)
    }
    
    /**
     * Check for Xposed or Magisk framework
     * These frameworks allow runtime modification of apps
     * @return true if Xposed or Magisk is detected
     */
    fun checkForXposedMagisk(): Boolean {
        return checkForXposed() || checkForMagisk()
    }
    
    /**
     * Check for Xposed framework
     */
    private fun checkForXposed(): Boolean {
        // Check for Xposed files
        for (path in XPOSED_PATHS) {
            if (File(path).exists()) {
                return true
            }
        }
        
        // Check for Xposed-related system properties
        try {
            val xposedBridge = Class.forName("de.robv.android.xposed.XposedBridge")
            return true
        } catch (e: ClassNotFoundException) {
            // Xposed not found
        }
        
        return false
    }
    
    /**
     * Check for Magisk framework
     */
    private fun checkForMagisk(): Boolean {
        // Check for Magisk files
        for (path in MAGISK_PATHS) {
            if (File(path).exists()) {
                return true
            }
        }
        
        // Check for Magisk app
        try {
            context.packageManager.getPackageInfo("com.topjohnwu.magisk", 0)
            return true
        } catch (e: PackageManager.NameNotFoundException) {
            // Magisk not found
        }
        
        return false
    }
    
    /**
     * Perform comprehensive tamper check
     * Includes all security checks: root, tampering, debugging, frameworks
     * @return true if any tampering is detected
     */
    fun performFullCheck(): Boolean {
        return isDeviceRooted() || 
               isAppTampered() || 
               isDebuggerAttached() || 
               checkForXposedMagisk() ||
               detectDebuggingTools()
    }
    
    /**
     * Perform quick security check for critical operations
     * Focuses on immediate threats (debugger, timing)
     * @return true if immediate threat detected
     */
    fun performQuickCheck(): Boolean {
        return isDebuggerAttached() || detectDebuggerByTiming()
    }
}
