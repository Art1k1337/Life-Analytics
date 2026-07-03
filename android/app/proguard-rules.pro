# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Hive
-keep class hive.** { *; }

# Usage Stats
-keep class com.appusagestats.** { *; }

# Pedometer
-keep class com.example.pedometer.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# R8 missing classes
-dontwarn javax.annotation.**
-dontwarn sun.misc.Unsafe
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
