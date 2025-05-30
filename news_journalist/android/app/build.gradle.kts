// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android") // Atau "org.jetbrains.kotlin.android"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android") // Pastikan ini ada jika menggunakan Kotlin
    id("com.google.gms.google-services") // Tanpa 'version' atau 'apply false'
}

android {
    namespace = "com.example.news_journalist"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.news_journalist"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// --- TAMBAHKAN BLOK DEPENDENCIES INI DI SINI ---
dependencies {
    // Dependensi inti Flutter embedding
    debugImplementation("io.flutter:flutter_embedding_debug:${project.properties["flutter.build.version"]}")
    releaseImplementation("io.flutter:flutter_embedding_release:${project.properties["flutter.build.version"]}")
    profileImplementation("io.flutter:flutter_embedding_profile:${project.properties["flutter.build.version"]}")

    // Dependensi Kotlin Standard Library
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8") // Atau 'kotlin-stdlib-jdk7'

    // --- FIREBASE DEPENDENCIES ---
    // Import the Firebase BoM (Bill of Materials) - Pastikan versi terbaru
    implementation(platform("com.google.firebase:firebase-bom:32.7.4")) // <--- VERSI FIREBASE BOM TERBARU

    // Tambahkan dependensi untuk produk Firebase yang Anda gunakan
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-analytics") // Jika Anda menggunakannya
    // ... dependensi aplikasi Anda lainnya
}
// --- AKHIR BLOK DEPENDENCIES ---

flutter {
    source = "../.."
}