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
        // Versões centralizadas de plugins usados no projeto
        id("com.android.application") version "8.1.1"
        id("org.jetbrains.kotlin.android") version "1.9.22"
        id("com.google.gms.google-services") version "4.4.2"
        // O plugin do Flutter é fornecido pela toolchain do Flutter; não precisa versão aqui.
        id("dev.flutter.flutter-gradle-plugin") apply false
    }
}

dependencyResolutionManagement {
    // Removemos repositoriesMode para compatibilidade com diferentes versões do Gradle
    repositories {
        google()
        mavenCentral()
    }
}