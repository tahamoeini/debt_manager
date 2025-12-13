# Flutter and Dart proguard rules

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom application classes
-keep class com.example.debt_manager.** { *; }

# Keep Kotlin-related classes
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# SQLCipher and database dependencies
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }

# Charts library
-keep class com.github.mikephil.charting.** { *; }

# Local auth
-keep class androidx.biometric.** { *; }

# Encryption libraries
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# QR code
-keep class com.google.zxing.** { *; }

# Prevent obfuscation of important classes
-dontobfuscate

# Remove logging in production
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
