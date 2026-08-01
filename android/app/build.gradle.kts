// `java` resolves to Gradle's java extension inside a .kts script and
// shadows the java.* package, so these must be imported by name.
import java.net.URI
import java.security.MessageDigest

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

// The on-device llama.cpp runtime, fetched from the plugin's own release
// and verified against its published sha256. Fail-closed: a mismatch deletes
// the file and stops the build rather than linking bytes we cannot vouch for.
//
// Pinned deliberately. Upstream is on -dev.12; moving costs a re-verified
// checksum and a VLM regression pass, so it is a decision, not a default.
val llamaAarTag = "v0.9.0-dev.9"
val llamaAarSha256 = "73ab5e755c57ae4c3e06fc728c9e649152e89db99e2b2deba99f3a5fcff41028"

val fetchLlamaAar = tasks.register("fetchLlamaAar") {
    val target = layout.buildDirectory.file("deps/llama-cpp-dart.aar")
    outputs.file(target)
    // Cacheable across builds: the pinned tag and hash fully determine it.
    inputs.property("tag", llamaAarTag)
    inputs.property("sha256", llamaAarSha256)
    doLast {
        val out = target.get().asFile
        if (!out.exists()) {
            out.parentFile.mkdirs()
            val url = "https://github.com/netdur/llama_cpp_dart/releases/" +
                "download/$llamaAarTag/llama-cpp-dart.aar"
            URI(url).toURL().openStream().use { input ->
                out.outputStream().use { input.copyTo(it) }
            }
        }
        val actual = MessageDigest.getInstance("SHA-256")
            .digest(out.readBytes())
            .joinToString("") { byte -> "%02x".format(byte) }
        if (actual != llamaAarSha256) {
            out.delete()
            throw GradleException(
                "llama-cpp-dart.aar checksum mismatch: expected " +
                "$llamaAarSha256, got $actual. Refusing to link it."
            )
        }
    }
}

dependencies {
    // llama.cpp runtime for the on-device VLM tier (SmolVLM2 via
    // llama_cpp_dart). FETCHED at build time and checksum-verified, rather
    // than committed: a 2.4 MB binary in the source tree is a build ERROR
    // for F-Droid's scanner, and a binary in git is a thing nobody can
    // review. The Dart side dlopens libllama.so from this AAR's jniLibs.
    // A -hexagon NPU variant exists upstream if ever wanted.
    implementation(files(fetchLlamaAar))
    // camera_android_camerax depends on camera-core which references
    // CallbackToFutureAdapter at compile time but doesn't pull in the
    // concurrent-futures artifact transitively under AGP 8.7. Pin it here.
    implementation("androidx.concurrent:concurrent-futures:1.1.0")
    // Required for flutter_local_notifications (uses Java 8+ time APIs).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
