# ML Kit (IMPORTANT)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Prevent warnings
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**