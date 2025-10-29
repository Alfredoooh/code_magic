plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    // não aplicamos com apply false aqui; plugin aplicado diretamente
    id("com.google.gms.google-services")
}

android {
    namespace = "com.nexa.madeeasy"
    // As variáveis `flutter.*` são providas pelo plugin flutter gradle; mantive tal como tinhas
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // atualizar para Java 17 — compatível com AGP 8.x + Kotlin 2.2
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.nexa.madeeasy"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}

repositories {
    // redundante se já estiver setado no root, mas não faz mal — garante resolução de dependências
    google()
    mavenCentral()
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.2.21")
    // adiciona outras libs que o teu app use aqui (Firebase libs, etc).
    // Exemplo (se usares analytics ou firestore):
    // implementation("com.google.firebase:firebase-analytics-ktx:22.0.0")
    // implementation("com.google.firebase:firebase-firestore-ktx:24.5.0")
}

// Aplica o plugin google-services explicitamente (Kotlin DSL)
// (se já tens id("com.google.gms.google-services") no plugins block, isto é redundante — mantive para robustez)
apply(plugin = "com.google.gms.google-services")