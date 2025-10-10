import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// 🔥 Adiciona o buildscript para o Firebase funcionar
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Plugin Google Services (essencial para Firebase)
        classpath("com.google.gms:google-services:4.4.2")
        // Kotlin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔧 Reorganiza diretórios de build (seu código original)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// 🧹 Tarefa de limpeza
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}