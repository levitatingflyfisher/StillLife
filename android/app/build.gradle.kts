plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.llcdomain.stilllife"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.llcdomain.stilllife"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    androidResources {
        // ML Kit image labeling ships its bundled .tflite model as an
        // asset; APK compression would corrupt the mmap'd model.
        noCompress += "tflite"
    }

    buildTypes {
        release {
            // Using debug keys for local builds. Configure a release signing config before publishing.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // llama.cpp runtime for the on-device VLM tier (SmolVLM2 via
    // llama_cpp_dart). CPU arm64 build from the plugin's v0.9.0-dev.9
    // release, sha256-verified against the published checksum
    // (73ab5e75…). The Dart side dlopens libllama.so from this AAR's
    // jniLibs. A -hexagon NPU variant exists upstream if ever wanted.
    implementation(files("libs/llama-cpp-dart.aar"))
    // camera_android_camerax depends on camera-core which references
    // CallbackToFutureAdapter at compile time but doesn't pull in the
    // concurrent-futures artifact transitively under AGP 8.7. Pin it here.
    implementation("androidx.concurrent:concurrent-futures:1.1.0")
    // Required for flutter_local_notifications (uses Java 8+ time APIs).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
