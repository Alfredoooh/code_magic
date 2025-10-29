import java.util.Properties

pluginManagement {
    // Caminho do Flutter SDK a partir do local.properties
    val flutterSdkPath = run {
        val properties = Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Permite incluir o build do Flutter tools para projetos Flutter
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    // Evita repositórios por project se algo estranho for adicionado
    repositoriesMode.set(org.gradle.api.initialization.dsl.RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

// Opcional: nome do root project (ajusta se quiseres)
rootProject.name = "app"

// Inclui o módulo app
include(":app")