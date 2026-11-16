// Stellar Flutter SDK Android plugin build script.
//
// Provides the native handlers backing the OpenZeppelin smart-account
// WebAuthn (Credential Manager) and secure-storage (EncryptedSharedPreferences)
// features of the Flutter SDK. Pure-Kotlin implementation with no third-party
// dependencies beyond AndroidX.
//
// Dependency versions are pinned in the dependencies block below.
//
// Android Gradle Plugin and Kotlin Gradle Plugin are intentionally not
// pinned here; they are inherited from the consumer app's project-level
// build configuration so the plugin builds with whatever toolchain the
// consumer already uses. The serialization plugin is pinned below.

import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    // An explicit version is required because Flutter templates do not declare
    // the serialization plugin. The serialization compiler artifact follows the
    // host Kotlin plugin version.
    id("org.jetbrains.kotlin.plugin.serialization") version "2.1.0"
}

group = "com.soneso.stellar_flutter_sdk"
version = "3.0.5"

android {
    namespace = "com.soneso.stellar_flutter_sdk"
    compileSdk = 35

    defaultConfig {
        // minSdk 24 is required by androidx.security:security-crypto:1.1.0.
        // The WebAuthn provider additionally requires API 28; on API 24-27 the
        // provider throws WebAuthnNotSupported but the storage adapter
        // continues to function.
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation("androidx.credentials:credentials:1.6.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.6.0")
    implementation("androidx.security:security-crypto:1.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("io.mockk:mockk:1.14.11")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.11.0")
    testImplementation("org.robolectric:robolectric:4.18")
}
