import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

plugins {
    // declaramos com apply false para que módulos apliquem localmente
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.21" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // classpath para plugin google-services (Firebase)
        classpath("com.google.gms:google-services:4.4.0")
        // se o teu projeto usa AGP em classpath style, podes adicionar:
        // classpath("com.android.tools.build:gradle:8.7.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- opcional: mudar buildDir para fora do project (mantenho, mas com try/catch para segurança) ---
try {
    val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
    rootProject.layout.buildDirectory.set(newBuildDir)

    subprojects {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(this.name)
        this.layout.buildDirectory.set(newSubprojectBuildDir)
    }
} catch (e: Exception) {
    println("Aviso: não foi possível reconfigurar buildDir: ${e.message}")
}

// garante que :app é avaliado quando necessário
subprojects {
    evaluationDependsOn(":app")
}

// tarefa clean global
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}