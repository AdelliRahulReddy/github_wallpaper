# ============================================================================
# GitWall - Production ProGuard Rules
# Focus: Stability, FCM, Platform Channels
# Compatible with Flutter 3.38.x + R8
# ============================================================================

# ──────────────────────────────────────────────────────────────────────────
# 1. FLUTTER FRAMEWORK (REQUIRED)
# ──────────────────────────────────────────────────────────────────────────

# Flutter embedding & engine (required)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods used by Flutter
-keepclasseswithmembernames class * {
    native <methods>;
}

# ──────────────────────────────────────────────────────────────────────────
# 2. PLATFORM CHANNEL (CRITICAL)
# ──────────────────────────────────────────────────────────────────────────

# Keep MainActivity and channel handlers
-keep class com.rahulreddy.githubwallpaper.MainActivity { *; }

# ──────────────────────────────────────────────────────────────────────────
# 3. ✅ PLAY CORE (FIX FOR MISSING CLASSES ERROR)
# ──────────────────────────────────────────────────────────────────────────

# Play Core library (used by Flutter internally)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Play Core split install
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# ──────────────────────────────────────────────────────────────────────────
# 4. ANDROID SYSTEM APIs
# ──────────────────────────────────────────────────────────────────────────

# Wallpaper API
-keep class android.app.WallpaperManager { *; }

# AndroidX Core
-keep class androidx.core.** { *; }
-dontwarn androidx.**

# ──────────────────────────────────────────────────────────────────────────
# 5. FIREBASE CLOUD MESSAGING (FCM)
# ──────────────────────────────────────────────────────────────────────────

# Keep FCM and Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Keep Background Handler entry point
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService { *; }

# Keep classes for data-only messages to ensure they aren't stripped
-keep class com.google.firebase.messaging.RemoteMessage { *; }
-keep class com.google.firebase.messaging.RemoteMessage$Builder { *; }

# ──────────────────────────────────────────────────────────────────────────
# 6. HTTP / NETWORKING
# ──────────────────────────────────────────────────────────────────────────

# OkHttp / Okio (used internally by http package)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ──────────────────────────────────────────────────────────────────────────
# 7. KOTLIN & COROUTINES
# ──────────────────────────────────────────────────────────────────────────

-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Keep Coroutines (Important for background tasks/plugins)
-keep class kotlinx.coroutines.** { *; }
-keepclassmembers class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ──────────────────────────────────────────────────────────────────────────
# 8. PARCELABLE / SERIALIZABLE SAFETY
# ──────────────────────────────────────────────────────────────────────────

# Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ──────────────────────────────────────────────────────────────────────────
# 9. REFLECTION SAFETY
# ──────────────────────────────────────────────────────────────────────────

# Keep attributes for reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ──────────────────────────────────────────────────────────────────────────
# 10. LOGGING (RELEASE OPTIMIZATION)
# ──────────────────────────────────────────────────────────────────────────

# Strip verbose/debug logs (Keep Info for breadcrumbs)
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
}

# Keep warnings & errors
-keep class android.util.Log {
    public static int w(...);
    public static int e(...);
}

# ──────────────────────────────────────────────────────────────────────────
# 11. CRASH REPORTING SUPPORT
# ──────────────────────────────────────────────────────────────────────────

# Preserve line numbers for Play Console stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ──────────────────────────────────────────────────────────────────────────
# 12. ENUM SAFETY
# ──────────────────────────────────────────────────────────────────────────

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ──────────────────────────────────────────────────────────────────────────
# 13. MISCELLANEOUS
# ──────────────────────────────────────────────────────────────────────────

# Keep BuildConfig
-keep class **.BuildConfig { *; }

# Keep R class
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Suppress warnings
-dontwarn com.google.android.play.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# ──────────────────────────────────────────────────────────────────────────
# 14. FLUTTER SECURE STORAGE (CRITICAL)
# ──────────────────────────────────────────────────────────────────────────
# Prevents KeyStore crash in release mode
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep interface com.it_nomads.fluttersecurestorage.** { *; }