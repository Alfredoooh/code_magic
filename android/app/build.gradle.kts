plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")            // kotlin plugin id correto para Kotlin DSL
    id("com.google.gms.google-services")          // google services plugin (Firebase)
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
        vectorDrawables.useSupportLibrary = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Kotlin options
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            // Em produção deves usar um signingConfig apropriado (keystore)
            // Aqui mantive o debug signing para evitar falhas se não tiveres keystore configurado no CI.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            // debug defaults
        }
    }

    packagingOptions {
        resources {
            excludes.addAll(listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            ))
        }
    }
}

dependencies {
    // BOM para coordenar versões Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))

    // Firebase (Auth + Realtime DB). Analytics é opcional — remove se não quiseres.
    implementation("com.google.firebase:firebase-analytics-ktx") // opcional
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-database-ktx")

    // AndroidX + multidex
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.multidex:multidex:2.0.1")
}