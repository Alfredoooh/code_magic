pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
    // Opcional: resolução de versões de plugins se precisares forçar versões concretas
    resolutionStrategy {
        eachPlugin {
            // Exemplo (descomentar se precisares forçar um plugin):
            // if (requested.id.id == "com.android.application") {
            //     useModule("com.android.tools.build:gradle:8.4.0")
            // }
        }
    }
}

dependencyResolutionManagement {
    // Preferir repositórios definidos aqui em vez dos repos de subprojectos
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)

    repositories {
        google()
        mavenCentral()
    }
}

// Nome do projecto (altera se quiseres outro nome)
rootProject.name = "madeeasy"

// Ativa tiposafe project accessors (opcional, útil em builds Kotlin DSL)
enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

// Inclui o módulo app (padrão Flutter)
include(":app")

// Se tiveres módulos adicionais (ex.: plugins/custom), inclui-os aqui:
// include(":plugin_a")
// include(":module_shared")