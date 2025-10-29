plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
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

        // Necessário se você usar notificações exatas (SCHEDULE_EXACT_ALARM)
        // Evita crashes em Android 12+
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
            // Desativa shrink/obfuscation para evitar problemas com plugins Flutter
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

    // Dependência essencial para compatibilidade com Android 13+ permissões
    implementation("androidx.core:core-ktx:1.12.0")

    // Kotlin - atualizado para 2.2.0 (coerente com share_plus compilado)
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.2.0")

    // Suporte multidex (caso use muitos plugins, evita erro de limite de métodos)
    implementation("androidx.multidex:multidex:2.0.1")
}