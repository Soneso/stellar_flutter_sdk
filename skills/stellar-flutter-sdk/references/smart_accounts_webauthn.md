# Smart Accounts — WebAuthn Providers and Storage Adapters

Platform-specific classes that supply a `WebAuthnProvider` and a `StorageAdapter` to `OZSmartAccountConfig`. Kit API and transaction flows live in [smart_accounts.md](./smart_accounts.md); signer, context-rule, policy, and multi-signer flows live in [smart_accounts_policies.md](./smart_accounts_policies.md).

Every class documented here is exported from the package barrel, so a single import covers them all:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

## Table of contents

- [Overview](#overview)
- [Common interfaces](#common-interfaces)
- [Android](#android)
- [iOS](#ios)
- [Web](#web)
- [Choosing a StorageAdapter](#choosing-a-storageadapter)
- [Implementing a custom StorageAdapter](#implementing-a-custom-storageadapter)
- [Implementing a custom WebAuthnProvider](#implementing-a-custom-webauthnprovider)
- [Cross-platform checklist](#cross-platform-checklist)

---

## Overview

A smart-account wallet authenticates with WebAuthn passkeys. Two pluggable
pieces are injected into `OZSmartAccountConfig`:

- **`WebAuthnProvider`** — runs the platform passkey ceremony (register a new
  passkey, authenticate with an existing one).
- **`StorageAdapter`** — persists credential and session records so a user can
  reconnect without a fresh ceremony.

Both are platform-specific because passkeys are a platform capability. The SDK
ships:

| Platform | WebAuthn provider | WebAuthn API | Min version | Storage (production) |
|----------|-------------------|--------------|-------------|----------------------|
| Android | `PlatformWebAuthnProvider` (method channel → Credential Manager) | `androidx.credentials` | API 28 (Android 9) | `PlatformStorageAdapter` (`EncryptedSharedPreferences`) |
| iOS | `PlatformWebAuthnProvider` (method channel → AuthenticationServices) | `AuthenticationServices` | iOS 16 | `PlatformStorageAdapter` (Keychain) |
| Web | `BrowserWebAuthnProvider` (`navigator.credentials`) | Web Authentication API | Chrome 67+, Firefox 60+, Safari 14+, Edge 79+ | `IndexedDBStorageAdapter` |
| Any (tests / ephemeral) | — | — | — | `InMemoryStorageAdapter` |

> `PlatformWebAuthnProvider` and `PlatformStorageAdapter` drive a native plugin
> (AuthenticationServices + Keychain on iOS, Credential Manager on Android).
> WebAuthn is supported on Android, iOS, and Web only — there is no macOS native
> plugin, so the platform providers raise `MissingPluginException` on macOS.

### How Flutter selects the implementation

- **Mobile (Android / iOS)** — `PlatformWebAuthnProvider` and
  `PlatformStorageAdapter` dispatch over a Flutter method channel to a native
  plugin. The Dart class is identical across these targets; only the native
  handler differs.
- **Web** — `BrowserWebAuthnProvider`, `IndexedDBStorageAdapter`, and
  `LocalStorageAdapter` are public facades wired with a conditional export:

  ```dart
  // Inside the SDK (browser_webauthn_provider.dart):
  export 'web/browser_webauthn_provider_stub.dart'
      if (dart.library.js_interop) 'web/browser_webauthn_provider_web.dart';
  ```

  On Flutter web the real `navigator.credentials` implementation is compiled
  in; on every other target a stub with the **same constructor and method
  signatures** is compiled in. Consumer code constructs the same class name on
  all targets and never branches at the call site.

```dart
// WRONG: importing the web/native files directly
// import 'package:stellar_flutter_sdk/src/smartaccount/oz/web/browser_webauthn_provider_web.dart';
// CORRECT: import only the package barrel; the conditional export picks the impl
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

A `webauthnProvider` is required for every operation that creates or signs
with a passkey (`createWallet`, `connectWallet(prompt: true)`,
`authenticatePasskey`, and any passkey-signing flow). Without one those calls
throw `WebAuthnNotSupported`. Pure read flows and a silent `connectWallet()`
with a live session do not need a provider.

```dart
// WRONG: building a config without a provider, then calling createWallet()
// Result: WebAuthnNotSupported at the first ceremony
// CORRECT: set config.webauthnProvider whenever a passkey ceremony can run
```

---

## Common interfaces

All of the following live in `core/web_authn_provider.dart`,
`core/allow_credential.dart`, and `oz/oz_storage_adapter.dart`, and are
exported from the package barrel. Custom providers and adapters implement
these.

### `WebAuthnProvider`

```dart
abstract class WebAuthnProvider {
  const WebAuthnProvider();

  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,   // typically 32 bytes; passed to the authenticator as-is
    required Uint8List userId,      // discoverable-credential user handle
    required String userName,       // shown during the passkey prompt
  });

  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,             // auth payload hash; passed as-is
    List<AllowCredential>? allowCredentials,  // optional credential descriptors + transport hints
  });
}
```

```dart
// WRONG: provider.register(challenge: 'some-string', ...)  — challenge is Uint8List, not String
// CORRECT: provider.register(challenge: challengeBytes, userId: userIdBytes, userName: 'Alice')

// WRONG: provider.authenticate(challenge: c, allowCredentialIds: [idBytes])  — no such param
// CORRECT: provider.authenticate(
//   challenge: c,
//   allowCredentials: AllowCredential.fromIds([idBytes]),
// )
```

### `WebAuthnRegistrationResult`

```dart
class WebAuthnRegistrationResult {
  const WebAuthnRegistrationResult({
    required this.credentialId,      // Uint8List: raw bytes (NOT Base64URL)
    required this.publicKey,         // Uint8List: 65 bytes uncompressed secp256r1 (0x04 + X + Y)
    required this.attestationObject, // Uint8List: raw CBOR attestation object
    this.transports,                 // List<String>?  e.g. ['internal'], ['hybrid', 'usb']
    this.deviceType,                 // String?  'singleDevice' | 'multiDevice'
    this.backedUp,                   // bool?    true if the passkey is cloud-synced
  });
  // fields are final and named identically to the constructor params
}
```

```dart
// WRONG: result.publicKey.length == 33  — that is the compressed point form
// CORRECT: result.publicKey.length == 65 && result.publicKey[0] == 0x04
//   If the platform returns COSE/SPKI, pass the raw bytes in publicKey and the
//   SDK's 3-strategy extraction recovers the 65-byte point during deployment.
```

### `WebAuthnAuthenticationResult`

```dart
class WebAuthnAuthenticationResult {
  const WebAuthnAuthenticationResult({
    required this.credentialId,      // Uint8List
    required this.authenticatorData, // Uint8List: >= 37 bytes (rpIdHash[32] + flags[1] + signCount[4] + ...)
    required this.clientDataJSON,    // Uint8List: contains challenge as base64url, no padding
    required this.signature,         // Uint8List: DER-encoded ECDSA P-256 — the SDK normalises it
  });
}
```

The kit normalises the DER signature to the 64-byte compact `r || s` low-S form
that Soroban requires. A provider returns the DER bytes exactly as the platform
delivers them; it must **not** pre-normalise.

### `AllowCredential`

```dart
class AllowCredential {
  const AllowCredential({required this.id, this.transports});
  final Uint8List id;               // raw credential ID bytes
  final List<String>? transports;   // 'internal' | 'hybrid' | 'usb' | 'ble' | 'nfc'

  static AllowCredential fromId(Uint8List id);
  static List<AllowCredential> fromIds(List<Uint8List> ids);
}
```

Transport hints drive cross-device behaviour. Including `'hybrid'` lets the
browser/OS offer the "use a passkey on another device" QR flow; `'internal'`
restricts to the current device's platform authenticator. When `transports` is
`null` the authenticator picks defaults.

Registration captures transports (`WebAuthnRegistrationResult.transports`), the
SDK stores them on the `StoredCredential`, and a later `authenticate` looks
them up to build the `AllowCredential` list — so cross-device hints survive
across sessions automatically.

```dart
// Build a constrained allow-list with a transport hint:
final allow = [
  AllowCredential(id: credentialIdBytes, transports: ['hybrid', 'internal']),
];
final result = await provider.authenticate(
  challenge: payloadHash,
  allowCredentials: allow,
);
```

### `StorageAdapter`

Method names are short (`save` / `get` / `delete`), not
`saveCredential` / `getCredential`.

```dart
abstract class StorageAdapter {
  // Credentials
  Future<void> save(StoredCredential credential);
  Future<StoredCredential?> get(String credentialId);          // null if absent
  Future<List<StoredCredential>> getByContract(String contractId);
  Future<List<StoredCredential>> getAll();
  Future<void> delete(String credentialId);                    // no-op if absent
  Future<void> update(String credentialId, StoredCredentialUpdate updates); // throws CredentialNotFound if absent
  Future<void> clear();
  // Sessions
  Future<void> saveSession(StoredSession session);
  Future<StoredSession?> getSession();                         // null if absent OR expired
  Future<void> clearSession();
}
```

```dart
// WRONG: storage.saveCredential(cred)   — method is save(cred)
// CORRECT: storage.save(cred)
// WRONG: storage.getAllCredentials()    — method is getAll()
// CORRECT: storage.getAll()
// WRONG: storage.deleteCredential(id)   — method is delete(id)
// CORRECT: storage.delete(id)
```

`update` applies a partial `StoredCredentialUpdate`: non-null fields overwrite,
null fields are left unchanged. There is no way to reset a field to null via
`update` — `save` a full replacement credential for that.

`getSession()` returns null when no session exists **and when a stored session
has expired** (the adapter auto-clears expired sessions on read). After app
restart, always check the return value.

### `StoredCredential` and `StoredCredentialUpdate`

```dart
class StoredCredential {
  StoredCredential({
    required this.credentialId,   // String, Base64URL-encoded
    required Uint8List publicKey, // 65-byte uncompressed secp256r1
    this.contractId,              // String?  smart-account C-address once derived
    this.deploymentStatus = CredentialDeploymentStatus.pending,
    this.deploymentError,
    int? createdAt,               // ms since epoch; defaults to now
    this.lastUsedAt,
    this.nickname,
    this.isPrimary = false,
    this.transports,              // List<String>?  carried forward to allowCredentials
    this.deviceType,              // 'singleDevice' | 'multiDevice'
    this.backedUp,
  });
  StoredCredential applyUpdate(StoredCredentialUpdate updates); // null = no change
}

enum CredentialDeploymentStatus { pending, failed }  // success removes the record from storage
```

```dart
class StoredCredentialUpdate {
  const StoredCredentialUpdate({
    this.deploymentStatus, this.deploymentError, this.contractId,
    this.lastUsedAt, this.nickname, this.isPrimary,
    this.transports, this.deviceType, this.backedUp,
  });
  // every field is nullable; null means "no change"
}
```

### `StoredSession`

```dart
class StoredSession {
  const StoredSession({
    required this.credentialId, // String
    required this.contractId,   // String, smart-account C-address
    required this.connectedAt,  // int, ms since epoch
    required this.expiresAt,    // int, ms since epoch
  });
  bool get isExpired; // true once wall-clock >= expiresAt
}
```

### `InMemoryStorageAdapter`

Tests and ephemeral flows only. It is the **default** when
`OZSmartAccountConfig.storage` is omitted. Every instance compares equal to
every other instance, so config copies that fall back to the default keep
structural equality.

```dart
final storage = InMemoryStorageAdapter(); // not persisted; lost on restart
```

```dart
// WRONG: shipping production with InMemoryStorageAdapter — credentials lost on restart
// CORRECT: wire a platform adapter (PlatformStorageAdapter / IndexedDBStorageAdapter)
```

### Injecting into `OZSmartAccountConfig`

The config takes the provider and adapter directly. The provider parameter is
`webauthnProvider` (all lowercase after `web`); `storage` defaults to a fresh
`InMemoryStorageAdapter` when omitted.

```dart
final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: Network.TESTNET.networkPassphrase,
  accountWasmHash: '<account-wasm-hash-hex>',          // 64-char hex (SHA-256 of WASM)
  webauthnVerifierAddress: '<webauthn-verifier-c-address>', // C-address
  rpId: 'app.example.com',
  rpName: 'My Stellar Wallet',
  webauthnProvider: provider,   // a WebAuthnProvider
  storage: storage,             // a StorageAdapter; omit for InMemoryStorageAdapter
);
```

```dart
// WRONG: OZSmartAccountConfig(..., webAuthnProvider: provider)  — capital A is wrong
// CORRECT: OZSmartAccountConfig(..., webauthnProvider: provider)
```

The same `rpId` MUST be passed to both the config and the provider; the
provider's value is the one the platform actually uses at the WebAuthn API.

---

## Android

`PlatformWebAuthnProvider` dispatches over a method channel to the native
plugin, which uses `androidx.credentials.CredentialManager`.
`PlatformStorageAdapter` stores credentials in `EncryptedSharedPreferences`
(AES-256-GCM values / AES-256-SIV keys) backed by the Android Keystore.

### Prerequisites

- Android 9.0 (API 28) or newer. The Credential Manager passkey surface and
  `EncryptedSharedPreferences` both require API 28+.
- A physical device or an emulator image with **Google Play Services** (a
  "Google APIs" or "Google Play" system image — not bare AOSP).
- A Google account signed in on the device.
- A domain you control over HTTPS for `assetlinks.json`.
- The signing certificate (debug or release) whose SHA-256 fingerprint is
  declared in `assetlinks.json`.

### Gradle / plugin dependencies

The native dependencies (Credential Manager, FIDO2 Play Services, and
`security-crypto` for `EncryptedSharedPreferences`) ship with the SDK's Android
plugin. **No extra dependency declarations are required in the app's gradle
files.** Only `minSdk` must be raised.

In `android/app/build.gradle.kts`:

```kotlin
android {
    defaultConfig {
        minSdk = 28
    }
}
```

```kotlin
// WRONG: minSdk = 24  — Credential Manager passkeys + EncryptedSharedPreferences need 28
// CORRECT: minSdk = 28  — anything lower fails at the first credential create/read
```

No manifest permission is needed for WebAuthn itself. The SDK's RPC traffic
needs the usual `<uses-permission android:name="android.permission.INTERNET" />`.

### `assetlinks.json` (Digital Asset Links)

The `rpId` passed to `PlatformWebAuthnProvider` must match a domain that
publishes a Digital Asset Links statement for the app.

Host at `https://app.example.com/.well-known/assetlinks.json`:

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

- `package_name` is the `applicationId` from `android/app/build.gradle.kts`.
- `delegate_permission/common.get_login_creds` is the relation Credential
  Manager checks for passkeys. `handle_all_urls` is for App Links and may
  coexist.
- Serve over **HTTPS** with `Content-Type: application/json`, no auth, no
  cookies.

Obtain the SHA-256 fingerprint of the signing key:

```bash
# Debug keystore (default path on macOS / Linux)
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android

# Release keystore
keytool -list -v -keystore /path/to/your-release.keystore -alias <your-alias>
```

Copy the line labelled `SHA256:`. If the app ships through Google Play with
**Play App Signing** enabled, public installs are signed by Google's key, not
the upload key — add Google's fingerprint from **Play Console → Setup → App
integrity → App signing key certificate** alongside the upload key's.

```jsonc
// WRONG: "sha256_cert_fingerprints": ["AABBCCDD..."]   — colons stripped
// CORRECT: colon-separated uppercase hex exactly as keytool prints it
```

```dart
// WRONG: rpId: 'https://app.example.com'   — scheme included
// CORRECT: rpId: 'app.example.com'         — bare host, no scheme, no path
```

Verify the statement resolves:

```
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://app.example.com&relation=delegate_permission/common.get_login_creds
```

If the `rpId` or the fingerprint mismatch, ceremonies fail with a
`SecurityException` mapped to `WebAuthnRegistrationFailed` /
`WebAuthnAuthenticationFailed`. Credential Manager caches the first
verification locally (~24 h); clear Google Play Services storage to pick up
changes during development.

### `PlatformWebAuthnProvider`

```dart
PlatformWebAuthnProvider({
  required String rpId,
  required String rpName,
  int timeout = 60000,                 // ms; forwarded to Credential Manager
  String? authenticatorAttachment,     // 'platform' | 'cross-platform' | null
});
```

`authenticatorAttachment = null` (default) allows both built-in biometric and
roaming security-key authenticators. `'platform'` restricts to the device's
built-in authenticator; `'cross-platform'` restricts to security keys.

The provider must be constructed on the root isolate — Credential Manager
anchors its system UI to the foreground Activity. Calls from a background
isolate fail with `WebAuthnRegistrationFailed` / `WebAuthnAuthenticationFailed`.

### Storage adapters (Android)

- **`PlatformStorageAdapter`** — production; `EncryptedSharedPreferences` +
  Android Keystore. Requires API 28+.
- **`InMemoryStorageAdapter`** — non-persistent; unit tests only.

```dart
final storage = PlatformStorageAdapter(); // no constructor arguments
```

### Full kit initialization (Android)

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

### Troubleshooting (Android)

- **`NoCredentialException`** → surfaces as `WebAuthnAuthenticationFailed`. No
  passkey exists for the `rpId`, the device account has no synced passkey for
  it, or asset-link verification has not completed. On Android, a missing
  credential is `WebAuthnAuthenticationFailed`; a user cancel is
  `WebAuthnCancelled` — branch on `Platform.isAndroid` to distinguish the two
  (iOS and web collapse both into `WebAuthnCancelled`).
- **`CreateCredentialProviderConfigurationException`** → no FIDO2 provider
  found. Device lacks/has a stale Google Play Services, the FIDO2 module is
  disabled, or the emulator is AOSP rather than Google APIs / Play.
- **`SecurityException` / `OriginNotAllowed`** → the `rpId` does not match the
  asset-link statement Google fetched, or the signing fingerprint matches no
  value in `sha256_cert_fingerprints`. Inspect the APK with
  `apksigner verify --print-certs <apk>`.
- **`EncryptedSharedPreferences` init failure** → Android Keystore unavailable
  (rooted / custom ROM / old emulator). Surfaces as `StorageWriteFailed`. Fall
  back to `InMemoryStorageAdapter` for testing only.
- **`WebAuthnNotSupported`** → `Build.VERSION.SDK_INT < 28`. Guard kit
  construction on the API level and present a fallback UI.

---

## iOS

`PlatformWebAuthnProvider` is the same class as on Android; the native plugin
differs and uses Apple's `AuthenticationServices`. `PlatformStorageAdapter`
stores credentials in the iOS Keychain.

### Prerequisites

- iOS 16.0 or newer (passkey support in `AuthenticationServices`).
- Xcode 15 or newer.
- An Apple Developer account with the **Associated Domains** capability enabled
  for the App ID.
- A domain you control over HTTPS for `apple-app-site-association`.
- A physical device with Face ID or Touch ID enrolled. The Simulator does not
  back passkeys with a Secure Enclave.

### `PlatformWebAuthnProvider`

```dart
PlatformWebAuthnProvider({
  required String rpId,
  required String rpName,
  int timeout = 60000,                 // ms; forwarded to AuthenticationServices
  String? authenticatorAttachment,     // ignored on iOS (no Apple equivalent)
});
```

`authenticatorAttachment` is accepted but ignored on iOS — Apple's framework
exposes no equivalent control. Construct the provider on the root isolate;
method-channel calls anchor system UI to the key window.

### Associated Domains entitlement

The native iOS target needs an entitlements file declaring the `webcredentials`
association. Flutter projects conventionally use `ios/Runner/Runner.entitlements`,
referenced from the target's `CODE_SIGN_ENTITLEMENTS` build setting:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.associated-domains</key>
  <array>
    <string>webcredentials:app.example.com</string>
  </array>
</dict>
</plist>
```

If the file is new, ensure both `ios/Flutter/Debug.xcconfig` and
`Release.xcconfig` (or the target build settings) declare:

```
CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements
```

In Xcode → Signing & Capabilities, add the **Associated Domains** capability
with the same `webcredentials:` entry. The Associated Domains service must also
be enabled for the App ID in the Apple Developer portal. With manual signing,
regenerate the provisioning profile after enabling it.

```xml
<!-- WRONG: webcredentials:https://app.example.com  — scheme included -->
<!-- CORRECT: webcredentials:app.example.com         — bare domain -->
```

#### `?mode=developer` (Simulator / local builds only)

During development, append `?mode=developer` so the Simulator and locally
signed builds bypass Apple's CDN-cached AASA fetch and query the origin
directly:

```xml
<string>webcredentials:app.example.com?mode=developer</string>
```

```xml
<!-- WRONG: shipping ?mode=developer to TestFlight / App Store -->
<!-- CORRECT: strip the suffix for production; release builds rely on Apple's CDN -->
```

Enforce removal with a release-config guard (for example, fail the build script
if a Release configuration's entitlements still contain `?mode=developer`).

The team-prefixed app identifier inside AASA must match the running app's
signing identity, or association fails silently.

### `apple-app-site-association`

Serve at `https://app.example.com/.well-known/apple-app-site-association`
(no `.json` extension):

```json
{
  "webcredentials": {
    "apps": [
      "<TEAM_ID>.com.example.yourapp"
    ]
  }
}
```

- `<TEAM_ID>` is the Apple Developer Team ID (Apple Developer portal →
  Membership).
- `com.example.yourapp` is the iOS bundle identifier exactly as configured in
  Xcode and the App ID.
- Serve over **HTTPS** with a valid certificate, `Content-Type: application/json`,
  and **no `.json` extension** in the URL.

```json
// WRONG: "apps": ["com.example.yourapp"]            — missing the Team ID prefix
// CORRECT: "apps": ["ABCDE12345.com.example.yourapp"] — TEAM_ID prefix is required
```

After deploying, Apple's CDN caches the file for hours. Production builds must
wait for the cache to refresh; `?mode=developer` builds fetch directly each
time.

### Storage adapters (iOS)

- **`PlatformStorageAdapter`** — production; native iOS Keychain via the method
  channel.
- **`InMemoryStorageAdapter`** — non-persistent; unit tests and ephemeral dev
  flows.

A normally code-signed iOS app needs no extra entitlement to use the Keychain
through `PlatformStorageAdapter`; the Associated Domains entitlement above is
the only WebAuthn-related entitlement required. A custom keychain access group
(for sharing storage with an app extension or sibling app) is the only case
that needs an additional `keychain-access-groups` entitlement.

```dart
final storage = PlatformStorageAdapter(); // no constructor arguments
```

### Build and test

```bash
flutter devices                 # list connected devices
flutter run -d <device-id>      # run on a physical device
```

The Simulator can exercise the AASA fetch path under `?mode=developer` but
cannot register a real passkey (no hardware authenticator). Use a physical
device for end-to-end testing.

### Full kit initialization (iOS)

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

### Troubleshooting (iOS)

- **`ASAuthorizationError` code 1004 (failed)** → surfaces as
  `WebAuthnRegistrationFailed` / `WebAuthnAuthenticationFailed` with the
  `PlatformException` attached as `cause`. Common causes: `rpId` not in the
  `com.apple.developer.associated-domains` array; AASA unreachable, wrong
  `Content-Type`, or more than one redirect; bundle ID or Team ID in AASA does
  not match the signing identity; `?mode=developer` missing during development
  while Apple's CDN has not picked up the file yet.
- **`ASAuthorizationError.canceled` (code 1001)** → maps to `WebAuthnCancelled`.
  Also returned when no credential exists for the `rpId` (the system silently
  dismisses the picker). Surface as a neutral UI state.
- **`Application is not associated with domain`** (logged by `swcd`) → domain
  verification failed. Inspect `Console.app` filtered by `swcd` or `pkd`;
  usually an unreachable AASA URL or an untrusted certificate chain.
- **Provisioning-profile mismatch** → enabling Associated Domains invalidates
  the existing profile. Automatic signing regenerates it on the next build;
  manual signing requires a fresh download.

---

## Web

`BrowserWebAuthnProvider` drives `navigator.credentials.create()` and
`navigator.credentials.get()` directly. It is selected on Flutter web via the
conditional export; on every other target the compiled-in stub throws
`UnsupportedError`. Construction itself never throws — the availability check
runs at the first `register` / `authenticate` call.

### Prerequisites

- A WebAuthn-capable browser: Chrome 67+, Firefox 60+, Safari 14+, Edge 79+.
- **HTTPS** in any non-local deployment; `localhost` is the only plaintext
  exception.
- No extra dependency beyond `stellar_flutter_sdk` — WebAuthn is a
  browser-native API.

### RP-ID / origin rules

The browser enforces the `rpId` against the page origin:

| Page origin | Valid `rpId` | Invalid `rpId` |
|-------------|--------------|----------------|
| `https://app.example.com` | `app.example.com`, `example.com` | `other.example.com` (different subdomain), `co.uk` (public suffix), `app.example.com:443` (port) |
| `http://localhost:8080` | `localhost` | `127.0.0.1` (separate origin) |

```dart
// WRONG: rpId: 'https://app.example.com'   — scheme included
// CORRECT: rpId: 'app.example.com'

// WRONG: page at https://app.example.com using rpId: 'other.example.com'
//   — not a registrable suffix → SecurityError at the ceremony
// CORRECT: rpId is the exact host OR a registrable parent (example.com)
```

### `BrowserWebAuthnProvider`

```dart
BrowserWebAuthnProvider({
  required String rpId,
  required String rpName,
  int timeoutMs = 60000,   // note: timeoutMs here, not timeout
});
```

```dart
// WRONG: BrowserWebAuthnProvider(rpId: 'x', rpName: 'y', timeout: 30000)
//   — the web provider's param is timeoutMs (the native provider uses timeout)
// CORRECT: BrowserWebAuthnProvider(rpId: 'x', rpName: 'y', timeoutMs: 30000)
```

### Cross-device passkeys (QR flow via transports)

When `authenticate` receives `AllowCredential`s with transport hints, the
browser provider forwards them into the `allowCredentials` descriptors of
`navigator.credentials.get(...)`. Including `'hybrid'` is what makes the
browser offer the cross-device "use a passkey on another device" QR-code flow.
The SDK stores transports captured at registration and replays them on later
authentications, so this works without extra wiring once a passkey is
registered with hybrid support.

```dart
// Offer the cross-device QR flow explicitly:
final result = await provider.authenticate(
  challenge: payloadHash,
  allowCredentials: [
    AllowCredential(id: credentialIdBytes, transports: ['hybrid', 'internal']),
  ],
);
```

An empty `allowCredentials` list and an omitted one behave differently in the
spec; the provider omits the descriptor field entirely when no hints are
present, so pass a non-empty list (or `null`) — never `[]`.

### Storage adapters (Web)

```dart
class IndexedDBStorageAdapter implements StorageAdapter {
  IndexedDBStorageAdapter({String dbName = 'stellar_smart_account'});
  Future<void> close(); // releases the connection; reopens lazily on the next op
}

class LocalStorageAdapter implements StorageAdapter {
  LocalStorageAdapter({String keyPrefix = 'stellar_sa_'});
}
```

- **`IndexedDBStorageAdapter`** — production; structured, large quota, async,
  with a `contractId` index. The version-1 schema (object stores `credentials`
  and `sessions`) is managed by the adapter — do not open the database yourself
  with a different version.
- **`LocalStorageAdapter`** — backed by synchronous `window.localStorage`
  (~5 MB per origin); exposes the same `Future`-returning `StorageAdapter`
  interface. Use for smaller payloads or where IndexedDB is unavailable.

Both are browser-only facades. On non-web targets the conditional export routes
to a stub that throws `UnsupportedError` from storage operations.

```dart
// Fallback pattern (private browsing can disable IndexedDB):
StorageAdapter storage;
try {
  final idb = IndexedDBStorageAdapter();
  await idb.getAll(); // forces the open; throws StorageReadFailed if IndexedDB is unavailable
  storage = idb;
} on StorageReadFailed {
  storage = LocalStorageAdapter();
}
```

### Localhost development

Browsers treat `http://localhost` as a secure context. Use `rpId: 'localhost'`:

```dart
final provider = BrowserWebAuthnProvider(
  rpId: 'localhost',          // works for http://localhost:<port>
  rpName: 'Dev Stellar Wallet',
);
```

```bash
flutter run -d chrome --web-hostname=localhost --web-port=8080
```

A common pattern parameterises the `rpId` so one source tree builds for
`localhost` and a production domain unchanged:

```dart
const _rpId = String.fromEnvironment('RP_ID', defaultValue: 'localhost');
const _rpName = String.fromEnvironment('RP_NAME', defaultValue: 'Stellar Wallet (Dev)');

final provider = BrowserWebAuthnProvider(rpId: _rpId, rpName: _rpName);
```

```bash
flutter build web \
  --dart-define=RP_ID=app.example.com \
  --dart-define=RP_NAME='My Stellar Wallet'
```

```dart
// WRONG: visiting http://127.0.0.1:8080 with rpId: 'localhost'
//   — the browser treats 127.0.0.1 as a different origin and rejects WebAuthn
// CORRECT: visit http://localhost:8080 so the hostname matches rpId
```

Passkeys created against `localhost` work only on `localhost`; create separate
passkeys per environment, or use a real HTTPS domain (mkcert + caddy/nginx)
locally.

### HTTP vs HTTPS

```dart
// WRONG: serving the app over plain http:// on a non-localhost origin
//   — navigator.credentials.create/get reject the insecure context
//     → WebAuthnException with a message starting "Security error:"
// CORRECT: serve over HTTPS in production (localhost is the only http exception)
```

### Full kit initialization (Web)

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final storage = IndexedDBStorageAdapter();
final webauthnProvider = BrowserWebAuthnProvider(
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

### Troubleshooting (Web)

- **`SecurityError: rpId does not match the current origin`** → the `rpId` is
  neither the origin host nor a registrable suffix. Surfaces as a
  `WebAuthnException` whose message starts with `Security error:`.
- **`NotAllowedError`** → maps to `WebAuthnCancelled`. User dismissed the
  prompt, the tab lost focus mid-ceremony, the timeout elapsed, or an extension
  intercepted the request. On the web this also covers "no credential
  available" (gate on `Platform.isAndroid` to distinguish, where the native
  exception is `WebAuthnAuthenticationFailed`).
- **Insecure-origin error on HTTP** → serve over HTTPS, or use
  `http://localhost:<port>` with `rpId: 'localhost'` for dev.
- **`WebAuthnNotSupported` outside the browser** → `BrowserWebAuthnProvider`
  needs `navigator.credentials`; the non-web stub throws `UnsupportedError`,
  and a browserless context (Node-driven test harness) throws
  `WebAuthnNotSupported`. Mock the `WebAuthnProvider` interface for SSR / server
  tests.
- **Cross-origin iframe blocked** → the parent must send a `Permissions-Policy`
  header (`publickey-credentials-create=(self "<origin>"),
  publickey-credentials-get=(self "<origin>")`) and the `<iframe>` must carry
  `allow="publickey-credentials-create; publickey-credentials-get"`. CSP
  `connect-src` must additionally permit the Soroban RPC and any indexer/relayer
  URLs.
- **IndexedDB unavailable** → `IndexedDBStorageAdapter` raises
  `StorageReadFailed`; fall back to `LocalStorageAdapter` (see the fallback
  pattern above).

---

## Choosing a StorageAdapter

| Platform | Recommended (production) | Fallback | Never in production |
|----------|--------------------------|----------|---------------------|
| Android | `PlatformStorageAdapter` (`EncryptedSharedPreferences` + Keystore) | `InMemoryStorageAdapter` for unit tests | `InMemoryStorageAdapter` in release builds |
| iOS | `PlatformStorageAdapter` (Keychain) | `InMemoryStorageAdapter` for tests | `InMemoryStorageAdapter` |
| Web | `IndexedDBStorageAdapter` | `LocalStorageAdapter` (small data, private-mode fallback) | `InMemoryStorageAdapter` |

`StoredCredential` holds **public keys only** (no secret material), so the
security bar is lower than for private-key storage — but session tokens and
contract IDs are privacy-sensitive. Use platform encryption where it exists.

---

## Implementing a custom StorageAdapter

For unusual platforms or server-side persistence, implement the `StorageAdapter`
interface directly. Minimal skeleton:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class MyDatabaseStorageAdapter implements StorageAdapter {
  MyDatabaseStorageAdapter(this._db);
  final MyDatabase _db;

  // Serialise concurrent calls so an interleaved read-modify-write never
  // observes a partially-applied update.
  Future<void> _tail = Future<void>.value();
  Future<T> _withLock<T>(Future<T> Function() body) {
    final previous = _tail;
    final result = previous.then((_) => body());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<void> save(StoredCredential credential) => _withLock(() async {
        try {
          await _db.upsertCredential(credential);
        } catch (e) {
          throw StorageException.writeFailed('save:${credential.credentialId}', cause: e);
        }
      });

  @override
  Future<StoredCredential?> get(String credentialId) =>
      _withLock(() => _db.loadCredential(credentialId));

  @override
  Future<List<StoredCredential>> getByContract(String contractId) =>
      _withLock(() => _db.loadCredentialsByContract(contractId));

  @override
  Future<List<StoredCredential>> getAll() => _withLock(() => _db.loadAllCredentials());

  @override
  Future<void> delete(String credentialId) =>
      _withLock(() => _db.deleteCredential(credentialId));

  @override
  Future<void> update(String credentialId, StoredCredentialUpdate updates) =>
      _withLock(() async {
        final existing = await _db.loadCredential(credentialId);
        if (existing == null) {
          throw CredentialException.notFound(credentialId);
        }
        await _db.upsertCredential(existing.applyUpdate(updates)); // partial: null = no change
      });

  @override
  Future<void> clear() => _withLock(() => _db.clearCredentials());

  @override
  Future<void> saveSession(StoredSession session) => _withLock(() => _db.saveSession(session));

  @override
  Future<StoredSession?> getSession() => _withLock(() async {
        final s = await _db.loadSession();
        if (s == null) return null;
        if (s.isExpired) {           // auto-clear expired sessions on read
          await _db.deleteSession();
          return null;
        }
        return s;
      });

  @override
  Future<void> clearSession() => _withLock(() => _db.clearSession());
}
```

Contracts to satisfy:

- **Concurrency safety** — multiple calls may arrive before earlier ones
  complete; serialise read-modify-write sequences.
- **Expired-session read** — `getSession()` returns null and clears the row
  when `StoredSession.isExpired` is true.
- **`update` partial semantics** — apply non-null fields only via
  `StoredCredential.applyUpdate(updates)`; never overwrite with null.
- **Exceptions** — wrap underlying errors in `StorageException.readFailed` /
  `writeFailed`, and throw `CredentialException.notFound(id)` from `update` for
  unknown IDs.

---

## Implementing a custom WebAuthnProvider

Most apps use the shipped providers. Implement your own for unusual platforms,
external FIDO2 middleware, custom hardware tokens, or deterministic CI test
doubles.

`register()` and `authenticate()` must produce output the on-chain WebAuthn
verifier accepts:

| Field | Requirement |
|-------|-------------|
| `WebAuthnRegistrationResult.publicKey` | 65 bytes uncompressed secp256r1 (`0x04 + X + Y`). If the platform returns COSE / SPKI, pass the raw bytes and let the SDK's extraction strategies recover the point. |
| `WebAuthnRegistrationResult.credentialId` | Raw bytes. The SDK Base64URL-encodes for storage. |
| `WebAuthnRegistrationResult.attestationObject` | Raw CBOR object as delivered by the authenticator. Used by SDK fallback extraction. |
| `WebAuthnAuthenticationResult.signature` | DER-encoded ECDSA P-256. The SDK normalises to compact 64-byte low-S `r \|\| s`. Do **not** pre-normalise. |
| `WebAuthnAuthenticationResult.authenticatorData` | ≥ 37 bytes; the User-Verified flag must be set or the verifier rejects the assertion. |
| `WebAuthnAuthenticationResult.clientDataJSON` | Must embed the supplied `challenge` as base64url **without** padding (WebAuthn spec). |

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class MyCustomWebAuthnProvider extends WebAuthnProvider {
  MyCustomWebAuthnProvider({required this.rpId, required this.rpName});
  final String rpId;
  final String rpName;

  @override
  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  }) async {
    try {
      // 1. Call your native WebAuthn stack, passing challenge as-is.
      // 2. Extract credentialId, the 65-byte uncompressed pubkey, the full
      //    attestation object, and optional transports/deviceType/backedUp.
      return WebAuthnRegistrationResult(
        credentialId: Uint8List(0),       // raw bytes
        publicKey: Uint8List(65),         // 0x04 + X + Y
        attestationObject: Uint8List(0),  // CBOR
        transports: const ['internal'],
        deviceType: 'singleDevice',
        backedUp: false,
      );
    } catch (e) {
      throw WebAuthnException.registrationFailed('custom register failed', cause: e);
    }
  }

  @override
  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<AllowCredential>? allowCredentials,
  }) async {
    try {
      // 1. Call your native assertion API, passing challenge as-is.
      // 2. If allowCredentials is non-null, constrain the picker to those IDs
      //    and honour their transport hints.
      // 3. Return the raw DER signature (no normalisation here).
      return WebAuthnAuthenticationResult(
        credentialId: Uint8List(0),
        authenticatorData: Uint8List(37),
        clientDataJSON: Uint8List(0),
        signature: Uint8List(0),          // DER
      );
    } catch (e) {
      throw WebAuthnException.authenticationFailed('custom authenticate failed', cause: e);
    }
  }
}
```

```dart
// WRONG: returning a 33-byte compressed point, or a 64-byte X||Y without 0x04
// CORRECT: 65 bytes starting 0x04 — or pass raw COSE/SPKI and let the SDK extract

// WRONG: normalising the DER signature to compact form inside the provider
// CORRECT: return DER as produced by the authenticator; the SDK normalises once
```

Wrap native errors into `WebAuthnException.registrationFailed` /
`authenticationFailed` / `cancelled` / `notSupported` so the kit's
error-handling paths work.

---

## Cross-platform checklist

| Step | Android | iOS | Web |
|------|---------|-----|-----|
| Choose `rpId` (bare host, no scheme) | `example.com` | `example.com` | `example.com` (or `localhost` for dev) |
| Publish domain-association file | `.well-known/assetlinks.json` | `.well-known/apple-app-site-association` | — |
| App capability / build config | `keytool` SHA-256 in `assetlinks.json`; `minSdk = 28` | Associated Domains entitlement `webcredentials:...`; `<TEAM_ID>.bundleId` in AASA | — |
| Extra dependencies | none (ship with the plugin) | none | none |
| WebAuthn provider | `PlatformWebAuthnProvider` | `PlatformWebAuthnProvider` | `BrowserWebAuthnProvider` |
| Timeout parameter | `timeout` | `timeout` | `timeoutMs` |
| Storage adapter | `PlatformStorageAdapter` | `PlatformStorageAdapter` | `IndexedDBStorageAdapter` / `LocalStorageAdapter` |
| Minimum runtime | API 28 | iOS 16 | Chrome 67+, Firefox 60+, Safari 14+, Edge 79+ |
| Localhost development | not supported | not supported | supported (`rpId: 'localhost'` over `http://localhost`) |
| Missing-credential error | `WebAuthnAuthenticationFailed` | `WebAuthnCancelled` | `WebAuthnCancelled` |

After per-platform setup, the kit API is identical across targets. See
[smart_accounts.md](./smart_accounts.md) for kit operations and
[smart_accounts_policies.md](./smart_accounts_policies.md) for signer,
context-rule, policy, and multi-signer flows.
