import org.gradle.api.tasks.Delete

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10")
        // Adicione o plug-in do Google Services para Firebase
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
// ============================================
// ARQUIVO 2: android/app/build.gradle
// Copie TODO este conteúdo para: android/app/build.gradle
// ============================================

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Aplica o plug-in do Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.nexa.madeeasy"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.nexa.madeeasy"
        minSdk = 21
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Import the Firebase BoM (gerencia versões automaticamente)
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))
    
    // Firebase dependencies (sem especificar versão, usa o BoM)
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    
    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    
    // Dependências existentes
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")
    implementation("androidx.multidex:multidex:2.0.1")
}


