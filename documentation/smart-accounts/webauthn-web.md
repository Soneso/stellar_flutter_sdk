# WebAuthn on Web -- Flutter Setup Guide

Platform-specific guide for configuring WebAuthn passkey authentication in Flutter web applications using the Stellar SDK Smart Account Kit.

## Prerequisites

- A modern browser with WebAuthn support:
  - Chrome 67+
  - Firefox 60+
  - Safari 14+
  - Edge 79+
- HTTPS in any non-local deployment. The `localhost` origin is the only exception (see Step 3).

No additional dependencies are needed on top of `stellar_flutter_sdk`.

## Step 1: Set the RP-ID and RP-Name

WebAuthn binds every passkey to a relying-party identifier. On the web the browser enforces the RP-ID against the page's origin:

- The RP-ID may be the exact origin host (e.g. `app.example.com`).
- The RP-ID may be a registrable suffix of the origin (e.g. `example.com` when the page is served from `app.example.com`). Use this when passkeys should work across multiple subdomains of the same site.
- The RP-ID must NOT be a public suffix such as `com` or `co.uk`. The browser rejects such values with a `SecurityError`.
- For local development, use `localhost`. See Step 3.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: Network.TESTNET.networkPassphrase,
  accountWasmHash: '<account-wasm-hash-hex>',
  webauthnVerifierAddress: '<webauthn-verifier-c-address>',
  rpId: 'app.example.com',
  rpName: 'My Stellar Wallet',
  webauthnProvider: BrowserWebAuthnProvider(
    rpId: 'app.example.com',
    rpName: 'My Stellar Wallet',
  ),
  storage: IndexedDBStorageAdapter(),
);
```

The same `rpId` value MUST be passed to both `OZSmartAccountConfig` and `BrowserWebAuthnProvider`. The provider is the value the browser actually receives in the WebAuthn ceremony.

The `rpName` is a display name shown to the user during the system prompt. Keep it short and recognisable.

## Step 2: Wire `BrowserWebAuthnProvider`

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final provider = BrowserWebAuthnProvider(
  rpId: 'app.example.com',
  rpName: 'My Stellar Wallet',
);
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `rpId` | `String` | required | Relying-party identifier. Must equal the page origin's host or a registrable suffix of it. |
| `rpName` | `String` | required | Display name shown during the platform prompt. |
| `timeoutMs` | `int` | `60000` | Ceremony timeout in milliseconds. Forwarded to the browser. |

Construction is safe on every target. The `navigator.credentials` availability check runs the first time `register` or `authenticate` is called; on non-web targets the stub throws `UnsupportedError` immediately.

## Step 3: HTTPS requirement and the localhost exception

Browsers reject WebAuthn calls in non-secure contexts. The `BrowserWebAuthnProvider` does not duplicate this check; the rejection surfaces as `WebAuthnException` with a message that starts with `Security error:`.

- Production: every page that initiates a WebAuthn ceremony MUST be served over HTTPS with a certificate the browser trusts.
- Development: `http://localhost:<port>` is treated as a secure context by all WebAuthn-capable browsers when paired with `rpId: 'localhost'`.
- `http://127.0.0.1:<port>` is **not** equivalent. The browser treats `127.0.0.1` as a different origin and rejects WebAuthn ceremonies against the loopback IP.

For local development with a custom domain, terminate TLS at a local proxy such as `mkcert` and `caddy`/`nginx` so the browser sees an HTTPS origin.

## RP-ID dev workflow (`--dart-define`)

A typical workflow is to parameterise the `rpId` so the same source tree can build for `localhost` development and a production domain without code changes:

```dart
const _rpId = String.fromEnvironment('RP_ID', defaultValue: 'localhost');
const _rpName = String.fromEnvironment('RP_NAME', defaultValue: 'Stellar Wallet (Dev)');

final provider = BrowserWebAuthnProvider(
  rpId: _rpId,
  rpName: _rpName,
);
```

Local development:

```bash
flutter run -d chrome --web-hostname=localhost --web-port=8080
```

Production build pinned to the deployment domain:

```bash
flutter build web \
  --dart-define=RP_ID=app.example.com \
  --dart-define=RP_NAME='My Stellar Wallet'
```

Passkeys registered against `localhost` are usable only on `localhost`; production passkeys must be created against the production `rpId`. Plan separate registrations for each environment.

## Storage Adapters

- **`IndexedDBStorageAdapter`**: production storage backed by IndexedDB. Structured, large quotas, async operations.
- **`LocalStorageAdapter`**: backed by synchronous `window.localStorage`; the adapter exposes the standard `Future`-returning `StorageAdapter` interface. Suitable for smaller payloads or environments where IndexedDB is unavailable; limited to ~5 MB per origin.

## Common errors

### `SecurityError`: rpId does not match the current origin

The configured `rpId` is neither the origin's host nor a registrable suffix of it. For a page served from `https://app.example.com`:

- `rpId: 'app.example.com'` is valid.
- `rpId: 'example.com'` is valid (registrable suffix).
- `rpId: 'co.uk'` fails (public suffix).
- `rpId: 'other-app.example.com'` fails (different subdomain).
- `rpId: 'app.example.com:443'` fails (port is never part of an RP-ID).

### `NotAllowedError`

Maps to `WebAuthnCancelled`. Common causes:

- The user dismissed the system prompt.
- The user did not respond before the timeout elapsed.
- The browser tab lost focus mid-ceremony.
- A browser extension intercepted and blocked the prompt.

On the web and on iOS, this error also covers the "no credential available" case; the browser silently dismisses the picker rather than reporting a distinct missing-credential result. To distinguish missing-credential from user-cancellation, gate on Android instead (`Platform.isAndroid`), where the equivalent native exception is mapped to `WebAuthnAuthenticationFailed`.

### `WebAuthnNotSupported` outside the browser

`BrowserWebAuthnProvider` requires `navigator.credentials`. On non-web targets the conditional export selects a stub that throws `UnsupportedError` from `register` and `authenticate`; on server-side Dart (or in a web context without `navigator.credentials`, such as Node-driven test harnesses) the provider throws `WebAuthnException.notSupported`.

### Cross-origin iframe restrictions

The browser disables WebAuthn inside iframes by default. To enable a ceremony from inside an `<iframe>`, the parent page must serve a `Permissions-Policy` header (`publickey-credentials-create=(self "<origin>"), publickey-credentials-get=(self "<origin>")`) and the iframe element must include `allow="publickey-credentials-create; publickey-credentials-get"`. Missing either piece raises `SecurityError`, surfaced as `WebAuthnException` with a `Security error:` prefix. CSP `connect-src` must additionally permit your Soroban RPC and any indexer/relayer URLs configured in `OZSmartAccountConfig`; the WebAuthn call itself is not governed by `connect-src`.

### IndexedDB unavailable

`IndexedDBStorageAdapter` raises `StorageReadFailed` when IndexedDB is disabled (older private-browsing modes, some web-worker contexts). Fall back to `LocalStorageAdapter`:

```dart
StorageAdapter storage;
try {
  final idb = IndexedDBStorageAdapter();
  await idb.getAll();
  storage = idb;
} on StorageReadFailed {
  storage = LocalStorageAdapter();
}
```

## Rotation and credential lifetime

A passkey created with `rpId = "app.example.com"` is bound to that domain for the lifetime of the credential. Changing the `rpId` (for example, moving the app from `app.example.com` to a bare `example.com` registrable suffix) does not migrate existing passkeys; users must register new credentials against the new RP-ID.

Sync depends on the browser and operating system: Safari uses iCloud Keychain, Chrome uses Google Password Manager, Edge inherits Chrome's sync when signed in to a Microsoft account, and Firefox stores credentials locally.

## Full Kit Initialization

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
