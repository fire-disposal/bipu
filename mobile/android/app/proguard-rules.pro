## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## General code
-keep class com.bipupu.user.mobile.** { *; }
-dontwarn com.bipupu.user.mobile.**

## Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

## OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicstream.PublicStream

## Dex
-dontwarn dalvik.system.**

## Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.Unit
-dontwarn kotlin.collections.**
-dontwarn kotlin.jvm.functions.**
-dontwarn kotlin.internal.**
-keep class kotlin.jvm.** { *; }

## AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

## OkHttp
-keepnames class okhttp3.internal.publicstream.PublicStream {
    java.io.InputStream getInputStream();
}

## Bluetooth
-keep class io.flutter.plugins.flutter_blue_plus.** { *; }

## SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }
