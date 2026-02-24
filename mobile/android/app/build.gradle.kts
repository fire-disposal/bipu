plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bipupu.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bipupu.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }



    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    splits {
        // 基于 ABI（架构）进行拆分
        abi {
            isEnable = true // 开启拆分
            reset()     // 重置默认列表
            include("armeabi-v7a", "arm64-v8a", "x86_64") // 包含的架构
            isUniversalApk = true // 是否同时生成一个包含所有架构的"通用版"
        }
    }

    // 为每个ABI变体设置不同的版本代码
    // 这样每个APK在Google Play上都有唯一的版本代码
    applicationVariants.all {
        outputs.all {
            val abi = (this as com.android.build.gradle.internal.api.ApkVariantOutputImpl).getFilter(com.android.build.OutputFile.ABI)
            if (abi != null) {
                val abiVersionCodes = mapOf(
                    "armeabi-v7a" to 1,
                    "arm64-v8a" to 2,
                    "x86_64" to 3
                )
                this.versionCodeOverride =
                    defaultConfig.versionCode!! * 1000 + abiVersionCodes.getOrDefault(abi, 0)
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
