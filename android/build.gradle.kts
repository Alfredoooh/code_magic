import org.gradle.api.tasks.Delete
import java.io.File

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // AGP deve ser compatível com a tua versão do Gradle wrapper (ver gradle-wrapper.properties)
        classpath("com.android.tools.build:gradle:8.1.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Move root build output para ../build (mantive o teu comportamento)
val newBuildDir: File = file("../build")
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