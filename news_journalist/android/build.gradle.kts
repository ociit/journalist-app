// android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Ini adalah Android Gradle Plugin (AGP). PASTIKAN VERSI INI SESUAI
        // DENGAN compileSdk ATAU TARGET SDK ANDA.
        // Anda punya compileSdk 35, jadi mungkin AGP 8.7.3 cocok.
        classpath("com.android.tools.build:gradle:8.7.3") // <--- PASTI ADA DAN SESUAI VERSI AGP ANDA

        // Tidak perlu lagi classpath("com.google.gms:google-services:...") di sini
        // karena sudah dikelola di settings.gradle.kts
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Baris ini harus tetap dikomentari/dihapus agar tidak menyebabkan masalah evaluasi awal
// subprojects {
//     project.evaluationDependsOn(":app")
// }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}