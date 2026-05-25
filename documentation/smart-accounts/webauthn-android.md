# WebAuthn on Android -- Flutter Setup Guide

Platform-specific guide for configuring WebAuthn passkey authentication in Flutter Android applications using the Stellar SDK Smart Account Kit.

## Prerequisites

- Android 9.0 (API level 28) or newer. Credential Manager's passkey surface requires API 28+; the SDK's `PlatformStorageAdapter` also requires API 28+ on Android because it uses `EncryptedSharedPreferences`.
- A physical device or an emulator image with Google Play Services (use a "Google APIs" or "Google Play" system image, not the bare AOSP image).
- A Google account signed in on the device.
- A domain you control over HTTPS for hosting `assetlinks.json`.
- The signing certificate (debug or release) whose SHA-256 fingerprint is declared in `assetlinks.json`.

## Step 1: Configure the kit

`OZSmartAccountConfig` stores `rpId` and `rpName` for documentation and for the case where downstream code reads them; the provider itself receives the values directly through its constructor and is the only component that actually uses them at the WebAuthn API surface.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: Network.TESTNET.networkPassphrase,
  accountWasmHash: '<account-wasm-hash-hex>',
  webauthnVerifierAddress: '<webauthn-verifier-c-address>',
  rpId: 'app.example.com',
  rpName: 'My Stellar Wallet',
  webauthnProvider: PlatformWebAuthnProvider(
    rpId: 'app.example.com',
    rpName: 'My Stellar Wallet',
  ),
);
```

The same `rpId` value MUST be passed to both `OZSmartAccountConfig` and `PlatformWebAuthnProvider`. The provider is the value Credential Manager actually uses at the platform layer.

## Step 2: Wire `PlatformWebAuthnProvider`

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final provider = PlatformWebAuthnProvider(
  rpId: 'app.example.com',
  rpName: 'My Stellar Wallet',
);
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `rpId` | `String` | required | Relying-party domain. Must match the domain hosting `assetlinks.json`. |
| `rpName` | `String` | required | Display name shown in the system credential picker. |
| `timeout` | `int` | `60000` | Ceremony timeout in milliseconds. Forwarded to Credential Manager. |
| `authenticatorAttachment` | `String?` | `null` | `"platform"` restricts to the device's built-in biometric authenticator, `"cross-platform"` restricts to roaming security keys, `null` allows both. |

`PlatformWebAuthnProvider` is the same class used on iOS; a single import statement covers both mobile targets. The Dart bridge is the same; the native plugin differs.

The provider must be constructed on the root isolate. Credential Manager anchors its system UI to the foreground Activity; calls from a background isolate fail with `WebAuthnRegistrationFailed` or `WebAuthnAuthenticationFailed`.

## Step 3: Set `minSdk` and required gradle wiring

In `android/app/build.gradle.kts` (or the Groovy equivalent), set:

```
android {
    defaultConfig {
        minSdk = 28
    }
}
```

API 28 is required by both the Credential Manager passkey path and by `EncryptedSharedPreferences`, which backs the SDK's `PlatformStorageAdapter` on Android. Setting `minSdk` lower than 28 will fail at runtime the first time the SDK tries to create or read a credential.

The native dependencies (Credential Manager, FIDO2 Play Services, security-crypto for `EncryptedSharedPreferences`) ship with the SDK's Android plugin. No additional dependency declarations are required in the consumer app's gradle files.

## Step 4: Host `assetlinks.json`

Serve a JSON file at:

```
https://app.example.com/.well-known/assetlinks.json
```

Minimum content:

```json
[
  {
    "relation": [
      "delegate_permission/common.get_login_creds",
      "delegate_permission/common.handle_all_urls"
    ],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.yourapp",
      "sha256_cert_fingerprints": [
        "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
      ]
    }
  }
]
```

- `package_name` is the application ID declared in `android/app/build.gradle.kts` (`applicationId`).
- Each entry in `sha256_cert_fingerprints` is the SHA-256 fingerprint of a signing certificate the app may be signed with. Colons are required.
- The `delegate_permission/common.get_login_creds` relation is the one Credential Manager checks for passkey ceremonies. The `handle_all_urls` relation is unrelated to WebAuthn but is commonly added for App Links and may coexist in the same statement.

Hosting requirements:

- **HTTPS** only.
- **Content-Type:** `application/json`.
- No authentication, no cookies.

### Obtaining the SHA-256 fingerprint

For the default debug keystore:

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

For a release keystore:

```bash
keytool -list -v \
  -keystore /path/to/your-release.keystore \
  -alias <your-alias>
```

Copy the line labelled `SHA256:` from the output. If you publish through Google Play and enabled **Play App Signing**, the certificate that ends up signing public installs is the one Google holds, not your upload key. Retrieve its fingerprint from the Play Console under **Setup > App integrity > App signing key certificate**, and add it to `assetlinks.json` alongside the upload key's fingerprint.

## Step 5: Verify the asset link

Verify the asset link by opening `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://app.example.com&relation=delegate_permission/common.get_login_creds` in a browser. A successful response includes a `statements` array containing your Android target.

The first verification done by Credential Manager on a device is cached locally; users may need to clear Google Play Services storage or wait for the cache to expire (~24 hours) to pick up changes during development.

## Emulator notes

- Use an emulator image labelled **Google APIs** or **Google Play**. AOSP-only images lack the FIDO2 module that Credential Manager delegates to and produce `NoCredentialException` on every call.
- Sign in with a real Google account inside the emulator. Anonymous emulators cannot complete passkey ceremonies.
- The emulator cannot complete asset-link verification against `localhost`. For local testing, host the `assetlinks.json` on a publicly reachable HTTPS domain (a temporary Cloudflare or ngrok tunnel works) and point `rpId` at that domain.
- API 33+ images typically support software-backed passkeys. Older Play-Services images may require a fingerprint to be enrolled in the emulator settings before the credential picker appears.

## Storage Adapters

- **`PlatformStorageAdapter`**: production storage backed by `EncryptedSharedPreferences` (AES-256-GCM via the Android Keystore). Requires API 28+.
- **`InMemoryStorageAdapter`**: non-persistent process-memory storage. Suitable for unit tests.

## Common errors

### `androidx.credentials.exceptions.NoCredentialException`

Surface in the SDK: `WebAuthnAuthenticationFailed`. Causes:

- No passkey exists for the requested `rpId` on the device.
- The Google account on the device has no synced passkey for the `rpId`.
- The asset-link verification has not completed; Credential Manager refuses to enumerate credentials for an unverified domain.

Distinguish this from a user cancellation by branching on `Platform.isAndroid`. On Android, missing credentials surface as `WebAuthnAuthenticationFailed`, while user cancellation surfaces as `WebAuthnCancelled`. On iOS and the web, both conditions collapse into `WebAuthnCancelled`.

### `CreateCredentialProviderConfigurationException`

Credential Manager could not locate a FIDO2 provider. Causes:

- The device lacks Google Play Services or has a stale version.
- The Play Services FIDO2 module has been disabled.
- The emulator image is AOSP rather than Google APIs / Play.

### `SecurityException` or `OriginNotAllowed`

The `rpId` does not match the asset-link statement Google fetched, or the signing-certificate fingerprint does not match any value in `sha256_cert_fingerprints`. Verify:

- The exact `rpId` string matches the host serving `assetlinks.json`.
- The app's actual signing fingerprint matches one of the declared fingerprints. Inspect with `keytool -printcert -jarfile <apk-path>` or `apksigner verify --print-certs <apk-path>`.

### `EncryptedSharedPreferences` initialization failure

The Android Keystore is unavailable. Common on rooted devices, custom ROMs without hardware keystore, or older emulator images. The SDK surfaces this as a `StorageWriteFailed`. Fall back to `InMemoryStorageAdapter` for testing; production deployments should require hardware keystore.

### `WebAuthnNotSupported`

Thrown when `Build.VERSION.SDK_INT < 28`. Guard the kit construction on `Platform.isAndroid && Build.VERSION.SDK_INT >= 28`, or catch `WebAuthnNotSupported` and present a fallback UI.

## Rotation and credential lifetime

A passkey created with `rpId = "app.example.com"` is bound to that domain for the lifetime of the credential. Changing the `rpId` later does not migrate existing passkeys.

When the user is signed in to Google Password Manager, the passkey is synced across devices linked to the same Google account. Revoking a passkey is the user's responsibility through device settings or `passwords.google.com`.

## Full Kit Initialization

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final storage = PlatformStorageAdapter();
final webauthnProvider = PlatformWebAuthnProvider(
  rpId: 'wallet.example.com',
  rpName: 'My Stellar App',
);

final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: Network.TESTNET.networkPassphrase,
  accountWasmHash: '<wasm-hash-hex>',
  webauthnVerifierAddress: '<verifier-c-address>',
  rpId: 'wallet.example.com',
  rpName: 'My Stellar App',
  webauthnProvider: webauthnProvider,
  storage: storage,
);

final kit = OZSmartAccountKit.create(config: config);
```
