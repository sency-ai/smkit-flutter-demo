allprojects {
    repositories {
        google()
        mavenCentral()
        // Published SMKit Android releases (flutter_smkit 1.1.8 uses 1.9.9).
        maven { url = uri("https://artifacts.sency.ai/artifactory/release") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
