import java.io.File
import org.gradle.api.tasks.Delete

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
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

// Move root build output to ../build
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