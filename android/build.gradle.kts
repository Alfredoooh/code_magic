buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        classpath("com.google.gms:google-services:4.4.3")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

def newBuildDir = file("../build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    afterEvaluate {
        def newSubprojectBuildDir = new File(newBuildDir, project.name)
        project.layout.buildDirectory.set(newSubprojectBuildDir)
    }
}

tasks.register("clean", Delete) {
    delete rootProject.layout.buildDirectory
}