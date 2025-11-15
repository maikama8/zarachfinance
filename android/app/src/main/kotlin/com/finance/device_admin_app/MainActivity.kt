package com.finance.device_admin_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var deviceAdminMethodChannel: DeviceAdminMethodChannel
    private lateinit var emergencyCallMethodChannel: EmergencyCallMethodChannel
    private lateinit var lockStateMethodChannel: LockStateMethodChannel
    private lateinit var launcherModeMethodChannel: LauncherModeMethodChannel
    private lateinit var tamperDetectionMethodChannel: TamperDetectionMethodChannel
    private lateinit var deviceIdentifierMethodChannel: DeviceIdentifierMethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register Device Admin method channel
        val adminChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DeviceAdminMethodChannel.CHANNEL_NAME
        )
        deviceAdminMethodChannel = DeviceAdminMethodChannel(this, adminChannel)
        
        // Register Emergency Call method channel
        val emergencyChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EmergencyCallMethodChannel.CHANNEL_NAME
        )
        emergencyCallMethodChannel = EmergencyCallMethodChannel(this, emergencyChannel)
        
        // Register Lock State method channel
        val lockStateChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LockStateMethodChannel.CHANNEL_NAME
        )
        lockStateMethodChannel = LockStateMethodChannel(this, lockStateChannel)
        
        // Register Launcher Mode method channel
        val launcherChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LauncherModeMethodChannel.CHANNEL_NAME
        )
        launcherModeMethodChannel = LauncherModeMethodChannel(this, launcherChannel)
        
        // Register Tamper Detection method channel
        val tamperChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TamperDetectionMethodChannel.CHANNEL_NAME
        )
        tamperDetectionMethodChannel = TamperDetectionMethodChannel(this, tamperChannel)
        
        // Register Device Identifier method channel
        val deviceIdentifierChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DeviceIdentifierMethodChannel.CHANNEL_NAME
        )
        deviceIdentifierMethodChannel = DeviceIdentifierMethodChannel(this, deviceIdentifierChannel)
    }
}
