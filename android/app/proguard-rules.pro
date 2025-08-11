# Flutter specific keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Provider rules
-keep class ** implements androidx.lifecycle.LifecycleOwner { *; }

# Local notifications
-keep class com.dexterous.** { *; }

# HTTP client
-dontwarn okio.**
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
