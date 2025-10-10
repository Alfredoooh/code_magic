def localProperties = new Properties()
def localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader("UTF-8") { reader -> localProperties.load(reader) }
}

def flutterRoot = localProperties.getProperty('flutter.sdk') ?: System.getenv("FLUTTER_ROOT")
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define flutter.sdk in local.properties or set FLUTTER_ROOT env.")
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.nexa.madeeasy"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }

    packagingOptions {
        resources {
            excludes += ["/META-INF/{AL2.0,LGPL2.1}"]
        }
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib:$kotlin_version"
    implementation 'androidx.multidex:multidex:2.0.1'

    // Firebase (mantém as versões que você já tem ou ajuste se desejar)
    implementation "com.google.firebase:firebase-auth-ktx:23.0.0"
    implementation "com.google.firebase:firebase-database-ktx:21.0.0"
    implementation "com.google.firebase:firebase-firestore-ktx:25.0.0"
}