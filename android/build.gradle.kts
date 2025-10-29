import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

// Repositórios para todos os subprojetos
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Obtemos o Directory real com .get() para evitar mismatch Provider<Directory>
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()

// Define o buildDirectory do rootProject
rootProject.layout.buildDirectory.set(newBuildDir)

// Ajusta cada subproject para usar subdiretório dentro do newBuildDir
subprojects {
    // aqui `name` é o nome do subproject; Directory.dir(String) retorna Directory
    val newSubprojectBuildDir: Directory = newBuildDir.dir(name)
    layout.buildDirectory.set(newSubprojectBuildDir)
}

// Garante avaliação do módulo :app (se precisar de avaliação antecipada)
evaluationDependsOn(":app")

// Tarefa clean (apaga o buildDir real do root project)
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}