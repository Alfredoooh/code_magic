import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

// Repositórios para todos os subprojetos
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirecionamento do buildDirectory para ../../build (mantive sua intenção)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build")
rootProject.layout.buildDirectory.set(newBuildDir)

// Ajusta cada subproject para usar subdiretório dentro do newBuildDir
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(name)
    layout.buildDirectory.set(newSubprojectBuildDir)
}

// Garante avaliação do módulo :app (se precisar de avaliação antecipada)
evaluationDependsOn(":app")

// Tarefa clean (apaga o buildDir real do root project)
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}