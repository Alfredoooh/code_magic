import org.gradle.api.tasks.Delete

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Atualizado para Kotlin 2.1.0 (combina com bibliotecas compiladas com Kotlin 2.1)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        // plug-in do Google Services para Firebase
        classpath("com.google.gms:google-services:4.4.3")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = file("../build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    afterEvaluate {
        val newSubprojectBuildDir = File(newBuildDir, project.name)
        project.layout.buildDirectory.set(newSubprojectBuildDir)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
