// android/build.gradle.kts (root project)
import org.gradle.api.tasks.Delete

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    // Mantive vazio o classpath aqui porque usamos pluginManagement no settings.gradle.kts
    dependencies {
        // Se preferir usar classpath ao invés de pluginManagement, adicione aqui:
        // classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Tarefa de limpeza compartilhada
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}