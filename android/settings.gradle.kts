// android/settings.gradle.kts
rootProject.name = "madeeasy"
include(":app")

pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }

    plugins {
        id("com.android.application") version "8.1.1"
        id("org.jetbrains.kotlin.android") version "1.9.22"
        id("com.google.gms.google-services") version "4.4.2"
        // REMOVIDO: id("dev.flutter.flutter-gradle-plugin")
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}