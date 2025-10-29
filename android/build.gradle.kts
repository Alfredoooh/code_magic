buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

plugins {
    // declarar versões no root e aplicar false; módulos aplicam os plugins
    id("com.android.application") version "8.1.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.10" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}