import java.util.Properties

pluginManagement {
    // ler local.properties para obter flutter.sdk
    val flutterSdkPath = run {
        val properties = Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // necessário para plugins (AGP, Kotlin plugin, etc)
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(org.gradle.api.initialization.dsl.RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        // necessário para dependências do Firebase/Google
        google()
        mavenCentral()
    }
}

// mantém o nome do root project (opcional)
rootProject.name = "app"

// inclui o módulo app
include(":app")