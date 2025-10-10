plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.nexa.madeeasy"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.nexa.madeeasy"
        minSdk = 23
        targetSdk = 34
        versionCode = 3
        versionName = "3.0.0"
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // BOM para gerir versões firebase
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))

    // Firebase que realmente vais usar (Auth + Realtime Database)
    implementation("com.google.firebase:firebase-analytics-ktx") // opcional — remove se não quiseres
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-database-ktx") // Realtime Database

    // Se for preciso no futuro para FCM:
    // implementation("com.google.firebase:firebase-messaging-ktx")

    // AndroidX e multidex
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.multidex:multidex:2.0.1")
}