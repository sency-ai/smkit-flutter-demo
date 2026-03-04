allprojects {
    repositories {
        google()
        mavenCentral()
        mavenLocal()
        // Sency Artifactory (same as smkit_ui_bridge_lib) — smkit + smbase at 1.5.0
        maven { url = uri("https://artifacts.sency.ai/artifactory/release") }
        // SMKit Android SDK: clone smkit_android into this project and publish to repo/
        maven { url = rootProject.file("../../smkit_android/repo").toURI() }
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
