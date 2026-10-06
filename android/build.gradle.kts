allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val customBuildDir = File("C:/EgeMM_build")
rootProject.layout.buildDirectory.set(customBuildDir)

subprojects {
    project.layout.buildDirectory.set(File(customBuildDir, project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
