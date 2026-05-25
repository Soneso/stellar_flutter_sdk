# WebAuthn on iOS -- Flutter Setup Guide

Platform-specific guide for configuring WebAuthn passkey authentication in Flutter iOS applications using the Stellar SDK Smart Account Kit.

## Prerequisites

- iOS 16.0 or newer (passkey support in `AuthenticationServices`).
- Xcode 15 or newer.
- An Apple Developer account with the **Associated Domains** capability enabled for the App ID.
- A domain you control over HTTPS for hosting `apple-app-site-association`.
- A physical device with Face ID or Touch ID enrolled. The iOS Simulator does not back passkeys with a secure enclave; ceremonies on the simulator either fail or fall back to a synthetic authenticator depending on the iOS version.

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

The same `rpId` value MUST be passed to both `OZSmartAccountConfig` and `PlatformWebAuthnProvider`. A mismatch produces silent ceremony failures because the kit will surface the configured `rpId` to telemetry while the native code uses the provider's value to talk to `AuthenticationServices`.

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
| `rpId` | `String` | required | Relying-party domain. Must match the domain in the Associated Domains entitlement and in the hosted AASA file. |
| `rpName` | `String` | required | Display name shown to the user during the system passkey prompt. |
| `timeout` | `int` | `60000` | Ceremony timeout in milliseconds. Forwarded to `AuthenticationServices`. |
| `authenticatorAttachment` | `String?` | `null` | Ignored on iOS. Apple's `AuthenticationServices` framework does not expose this control; the field is preserved for the Android wiring. |

The provider must be constructed on the root isolate. Method-channel calls anchor system UI to the key window; calls from a background isolate produce `WebAuthnRegistrationFailed` or `WebAuthnAuthenticationFailed`.

## Step 3: Add the Associated Domains entitlement

The native iOS target needs an entitlements file declaring the `webcredentials` association with your domain.

Add a `<App>.entitlements` file (any name; Flutter projects conventionally use `ios/Runner/Runner.entitlements`) referenced from your iOS target's `CODE_SIGN_ENTITLEMENTS` build setting:

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

If the file is new, ensure both `Debug.xcconfig` and `Release.xcconfig` declare:

```
CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements
```

During development you can append `?mode=developer` to the entry so the simulator and locally signed builds bypass Apple's CDN-cached AASA fetch and ping your domain directly:

```xml
<string>webcredentials:app.example.com?mode=developer</string>
```

Remove `?mode=developer` before submitting to TestFlight or the App Store; production builds must rely on Apple's CDN.

In Xcode (Signing & Capabilities), add the **Associated Domains** capability and add the same `webcredentials:` entry. This also requires the Associated Domains service to be enabled for the App ID in the Apple Developer portal; automatic signing in Xcode usually handles the provisioning profile refresh, but manual signing requires a regenerated profile after enabling the capability.

## Step 4: Host `apple-app-site-association`

Serve a JSON file at:

```
https://app.example.com/.well-known/apple-app-site-association
```

Minimum content:

```json
{
  "webcredentials": {
    "apps": [
      "<TEAM_ID>.com.example.yourapp"
    ]
  }
}
```

- Replace `<TEAM_ID>` with your Apple Developer Team ID (found under Membership in the Apple Developer portal).
- Replace `com.example.yourapp` with the iOS app's bundle identifier exactly as configured in Xcode and the App ID.

Hosting requirements enforced by Apple:

- **HTTPS** with a valid TLS certificate.
- **Content-Type:** `application/json`.
- **No `.json` extension** on the URL.

After deploying or changing the file, Apple's CDN caches it for hours. For production builds you must wait for the cache to refresh; for development builds with `?mode=developer` the device fetches directly from your origin on every association check.

## Step 5: Build and test

Run on a physical device:

```bash
flutter run -d <device-id>
```

List devices with `flutter devices`. The first passkey registration triggers a Face ID or Touch ID prompt; subsequent registrations and authentications reuse the same biometric path.

For development builds with `?mode=developer`, the simulator can exercise the AASA fetch path but cannot register a real passkey because it lacks a hardware authenticator. Use a paired physical device for end-to-end testing.

## Storage Adapters

- **`PlatformStorageAdapter`**: production storage backed by the native iOS Keychain via method channel.
- **`InMemoryStorageAdapter`**: non-persistent process-memory storage. Suitable for unit tests and ephemeral dev flows.

## Common errors

### `ASAuthorizationError` code 1004 (failed)

`ASAuthorizationError.failed`. The most common causes are:

- The `rpId` does not match any entry in `com.apple.developer.associated-domains`.
- The AASA file is unreachable, returns the wrong `Content-Type`, or takes more than one redirect.
- The bundle ID or Team ID in AASA does not match the running app's signing identity.
- `?mode=developer` is missing during development and Apple's CDN has not yet picked up the production AASA file.

Surface in the SDK: `WebAuthnRegistrationFailed` or `WebAuthnAuthenticationFailed` with the underlying `PlatformException` attached as `cause`.

### `ASAuthorizationError.canceled` (code 1001)

The user dismissed the system prompt, or the prompt timed out. Maps to `WebAuthnCancelled`. This is also returned when no credential exists for the requested `rpId`; on Apple platforms the system silently dismisses the picker rather than reporting a separate "no credential" result.

### `Application is not associated with domain`

Logged by `swcd` (the Shared Web Credentials daemon) when the domain verification fails. Inspect the device console (`Console.app` filtered by `swcd` or `pkd`) for the underlying reason. Most occurrences trace back to an unreachable AASA URL or an HTTPS certificate chain the device cannot validate.

### Provisioning-profile mismatch

After enabling **Associated Domains** in the developer portal, the existing provisioning profile is invalidated. Xcode's automatic signing regenerates the profile on the next build; manual signing requires a manual download from the developer portal.

## Rotation and credential lifetime

A passkey created with `rpId = "app.example.com"` is bound to that domain for the lifetime of the credential. Changing the `rpId` later does not migrate existing passkeys; users would have to register new credentials against the new domain.

Apple stores passkeys in iCloud Keychain when the user is signed in to iCloud with Keychain enabled. The same passkey is then available across the user's Apple devices that share the iCloud account. Disabling iCloud Keychain confines the passkey to the device that created it.

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
