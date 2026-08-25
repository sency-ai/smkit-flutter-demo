allprojects {
    repositories {
        google()
        mavenCentral()
        // Locally built SMKit 1.8.0 artifacts from the adjacent Android SDK checkout.
        maven { url = uri("../smkit_android/repo") }
        // Published releases, used once the 1.8.0 artifacts are available there.
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
