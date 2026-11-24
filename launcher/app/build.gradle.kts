plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "org.bynex.retro"
    compileSdk = 34

    defaultConfig {
        applicationId = "org.bynex.retro"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0-skeleton"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

// Única dependencia del APK: FileProvider de AndroidX (androidx.core). El resto
// es framework Android. JUnit se usa únicamente en los tests JVM.
dependencies {
    implementation("androidx.core:core:1.13.1")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test:runner:1.6.2")
}
