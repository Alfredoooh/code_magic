import org.gradle.api.tasks.Delete

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // 👈 Necessário para o Firebase
}

android {
    namespace = "com.nexa.madeeasy"
    compileSdk = 34 // 35+ pode causar incompatibilidade em alguns plugins

    defaultConfig {
        applicationId = "com.nexa.madeeasy"
        minSdk = 21
        targetSdk = 34
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

    implementation("androidx.core:core-ktx:1.12.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")
    implementation("androidx.multidex:multidex:2.0.1")

    // 👇 Dependências Firebase necessárias para login por e-mail e dados em tempo real
    implementation("com.google.firebase:firebase-auth-ktx:23.0.0")        // Autenticação
    implementation("com.google.firebase:firebase-database-ktx:21.0.0")   // Realtime Database
    implementation("com.google.firebase:firebase-firestore-ktx:25.0.0")  // Firestore (opcional)
}