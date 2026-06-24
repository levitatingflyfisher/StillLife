allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// camera_android_camerax 0.6.x uses camera-core:1.5.x which references
// CallbackToFutureAdapter at compile time. concurrent-futures is not pulled
// in transitively under AGP 8.7, so inject it after all projects are evaluated
// (configurations are still unresolved at this point, so deps can be added).
gradle.projectsEvaluated {
    subprojects {
        if (project.plugins.hasPlugin("com.android.library")) {
            project.dependencies.add(
                "implementation",
                "androidx.concurrent:concurrent-futures:1.1.0"
            )
        }
    }
}

// Force JVM 17 on all subproject Kotlin + Java compile tasks. Some Flutter
// plugins (e.g. receive_sharing_intent) ship with Kotlin 21 while defaulting
// Java to 1.8, which fails Gradle's "Inconsistent JVM Target" check.
// Force Kotlin JVM target to match each plugin's Java target.
// Some Flutter plugins (receive_sharing_intent ships with Kotlin 21 + Java 1.8,
// speech_to_text with Kotlin JVM default + Java 11) trip Gradle's
// "Inconsistent JVM Target" check. We bend Kotlin to match each plugin's
// own Android `compileOptions` instead of forcing Java upward, because
// forcing Java via tasks.withType<JavaCompile> removes the Android
// bootclasspath, and forcing via the Android extension hits "already
// finalized" once projects are evaluated.
gradle.projectsEvaluated {
    subprojects {
        // Read whatever Java target the Android plugin landed on for this
        // subproject and bend Kotlin to match.
        val androidExt = extensions.findByName("android")
        val javaTarget: JavaVersion = when (androidExt) {
            is com.android.build.gradle.LibraryExtension -> androidExt.compileOptions.sourceCompatibility
            is com.android.build.gradle.AppExtension -> androidExt.compileOptions.sourceCompatibility
            else -> JavaVersion.VERSION_17
        }
        val kotlinJvmTarget = when (javaTarget) {
            JavaVersion.VERSION_1_8 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
            JavaVersion.VERSION_11 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
            JavaVersion.VERSION_17 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            JavaVersion.VERSION_21 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
            else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(kotlinJvmTarget)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
