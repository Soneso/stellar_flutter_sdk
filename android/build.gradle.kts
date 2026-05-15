// Stellar Flutter SDK Android plugin build script.
//
// Provides the native handlers backing the OpenZeppelin smart-account
// WebAuthn (Credential Manager) and secure-storage (EncryptedSharedPreferences)
// features of the Flutter SDK. Pure-Kotlin implementation with no third-party
// dependencies beyond AndroidX.
//
// Dependency pins (versions verified against `dl.google.com/dl/android/maven2`
// and Maven Central on 2026-05-15):
//   androidx.credentials:credentials                   = 1.6.0   (latest stable)
//   androidx.credentials:credentials-play-services-auth = 1.6.0   (matches train)
//   androidx.security:security-crypto                  = 1.1.0   (latest stable)
//   org.jetbrains.kotlinx:kotlinx-coroutines-android   = 1.11.0  (latest stable)
//   org.jetbrains.kotlinx:kotlinx-serialization-json   = 1.9.0   (latest stable)
//   io.mockk:mockk                                     = 1.14.3  (test only,
//                                                                  latest stable)
//
// Android Gradle Plugin and Kotlin Gradle Plugin are intentionally not
// pinned here; they are inherited from the consumer app's project-level
// build configuration so the plugin builds with whatever toolchain the
// consumer already uses. The serialization plugin tracks the same Kotlin
// version as `org.jetbrains.kotlin.android` (no explicit version needed).

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    // Pinned to match the Kotlin version range supported by the kotlin.android
    // plugin in current Flutter project templates (Kotlin 2.x). Consumers using
    // a wildly different Kotlin major version may need to override.
    id("org.jetbrains.kotlin.plugin.serialization") version "2.1.0"
}

group = "com.soneso.stellar_flutter_sdk"
version = "3.0.5"

android {
    namespace = "com.soneso.stellar_flutter_sdk"
    compileSdk = 34

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

    kotlinOptions {
        jvmTarget = "17"
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

dependencies {
    implementation("androidx.credentials:credentials:1.6.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.6.0")
    implementation("androidx.security:security-crypto:1.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("io.mockk:mockk:1.14.3")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.11.0")
}
