import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

plugins {
    // Devemos declarar os plugins aqui com apply false para que módulos os apliquem
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.21" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
    id("dev.flutter.flutter-plugin-loader") version "1.0.0" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // classpath para o plugin do Google Services (Firebase)
        classpath("com.google.gms:google-services:4.4.0")
        // Se usa Android Gradle Plugin em classpath style (opcional)
        // classpath("com.android.tools.build:gradle:8.7.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- Opcional: mover o buildDir para raiz/fora do projeto (como fazias) ---
try {
    val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
    rootProject.layout.buildDirectory.set(newBuildDir)

    subprojects {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(this.name)
        this.layout.buildDirectory.set(newSubprojectBuildDir)
    }
} catch (e: Exception) {
    // Se por algum motivo não funcionar no ambiente, não falha o configuration phase.
    println("Aviso: não foi possível reconfigurar buildDir: ${e.message}")
}

// Garantir que o app é avaliado quando necessário
subprojects {
    evaluationDependsOn(":app")
}

// Tarefa clean global
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}