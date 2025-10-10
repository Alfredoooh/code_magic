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
        // plugin flutter: a versão é fornecida pelo Flutter tooling, sem declarar versão aqui
        id("dev.flutter.flutter-gradle-plugin") version "0.0.0" apply false
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(org.gradle.api.initialization.dsl.RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}