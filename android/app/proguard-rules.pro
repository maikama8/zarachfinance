# ProGuard rules for Device Admin Finance App

# Keep Flutter wrapper classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Device Admin Receiver - CRITICAL for device admin functionality
-keep class com.finance.device_admin_app.FinanceDeviceAdminReceiver { *; }

# Keep all platform channel classes - required for Flutter-Native communication
-keep class com.finance.device_admin_app.DeviceAdminMethodChannel { *; }
-keep class com.finance.device_admin_app.TamperDetectionMethodChannel { *; }
-keep class com.finance.device_admin_app.TamperDetector { *; }
-keep class com.finance.device_admin_app.FactoryResetProtection { *; }
-keep class com.finance.device_admin_app.LockStateMethodChannel { *; }
-keep class com.finance.device_admin_app.LauncherModeMethodChannel { *; }
-keep class com.finance.device_admin_app.EmergencyCallMethodChannel { *; }
-keep class com.finance.device_admin_app.DeviceIdentifierMethodChannel { *; }

# Keep BroadcastReceiver for boot events
-keep class com.finance.device_admin_app.BootReceiver { *; }

# Keep MainActivity
-keep class com.finance.device_admin_app.MainActivity { *; }

# Keep data models (for JSON serialization)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep model classes
-keep class com.finance.device_admin_app.models.** { *; }

# Preserve line numbers for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable implementations
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Dio HTTP client
-keep class com.squareup.okhttp3.** { *; }
-keep interface com.squareup.okhttp3.** { *; }
-dontwarn com.squareup.okhttp3.**
-dontwarn okio.**

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# SQLCipher
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Remove logging in release builds - security measure to prevent info leakage
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

# Remove debug logging from Kotlin
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    public static void checkParameterIsNotNull(...);
    public static void checkNotNullParameter(...);
}

# Optimize and obfuscate aggressively
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*

# Obfuscate package names and class names
-repackageclasses 'o'
-allowaccessmodification

# Remove debug information but keep line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Additional security: Remove unused code
-dontwarn **
-ignorewarnings

# Encrypt string constants (makes reverse engineering harder)
-adaptclassstrings

# Obfuscate resource files
-adaptresourcefilenames
-adaptresourcefilecontents
