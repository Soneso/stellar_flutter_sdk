# WebAuthn Setup: Web (Browser)

This guide describes how to wire the OpenZeppelin smart-account kit into a
Flutter web application using WebAuthn passkeys, the browser's
`localStorage`, and IndexedDB.

## Prerequisites

- Modern browser with WebAuthn (`navigator.credentials`) support:
  - Chrome 67 or newer
  - Firefox 60 or newer
  - Safari 14 or newer
  - Edge 79 or newer
- The page must be served over HTTPS. The only exception is local
  development on `http://localhost`. `127.0.0.1` is treated as a
  different origin by browsers and is not equivalent to `localhost` for
  WebAuthn purposes.
- Flutter SDK 3.8.0 or newer (already required by `stellar_flutter_sdk`).

## Relying Party Configuration

WebAuthn binds every passkey to a relying party identifier (RP-ID). The
RP-ID must be:

- The exact origin domain (e.g. `app.example.com`), or
- A registrable suffix of the origin (e.g. `example.com` from
  `app.example.com`).

The RP-ID must NOT be a public suffix (such as `co.uk`). The browser
rejects out-of-scope RP-IDs with a `SecurityError`.

The display name (`rpName`) is shown to the user during the platform
prompt. Keep it short and recognisable.

## WebAuthn Provider — `BrowserWebAuthnProvider`

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webauthn = BrowserWebAuthnProvider(
  rpId: 'app.example.com',
  rpName: 'My Stellar App',
);
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `rpId` | `String` | required | Relying party identifier. |
| `rpName` | `String` | required | Display name shown during prompts. |
| `timeoutMs` | `int` | `60000` | WebAuthn ceremony timeout in milliseconds. |

The provider is browser-only. On non-web targets (iOS, macOS, Android,
desktop), importing the same symbol resolves to a stub whose `register`
and `authenticate` methods throw `UnsupportedError`. Construction itself
never throws on any target, so wiring code can declare the provider
unconditionally and select platform-specific providers at runtime.

## Storage Adapters

### `IndexedDBStorageAdapter` (recommended)

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final storage = IndexedDBStorageAdapter();
// ...
await storage.close();
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `dbName` | `String` | `'stellar_smart_account'` | IndexedDB database name. |

Additional adapter-only methods (not part of the `StorageAdapter`
interface):

- `Future<void> close()` — closes the database connection. Safe to call
  multiple times. The next storage call reopens the connection.
- `Future<void> deleteDatabase({String? name})` — destructive: removes
  the entire database. When `name` is omitted, deletes the configured
  `dbName`.

### `LocalStorageAdapter` (fallback)

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final storage = LocalStorageAdapter();
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `keyPrefix` | `String` | `'stellar_sa_'` | Prefix applied to every storage key. |

Trade-offs versus IndexedDB:

- Storage cap: most browsers cap `localStorage` at approximately 5 MB
  per origin. IndexedDB allows hundreds of megabytes or more.
- API shape: `localStorage` is synchronous (`Future` is used purely to
  match the `StorageAdapter` contract). IndexedDB is asynchronous
  end-to-end.
- Encryption: neither store is encrypted at rest. Both are accessible to
  any same-origin script.
- Indexing: IndexedDB ships native indexes on `contractId`, `createdAt`,
  and `isPrimary`. `LocalStorageAdapter` maintains a single in-band
  credential index, so contract-ID lookups iterate every credential.

Recommendation: prefer `IndexedDBStorageAdapter` for production. Reach
for `LocalStorageAdapter` only when IndexedDB is unavailable (older
private-browsing modes, web workers without IDB access).

## Full Kit Initialization

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kit = OZSmartAccountKit(
  OZSmartAccountConfig(
    network: Network.testnet,
    rpcUrl: 'https://soroban-testnet.stellar.org',
    smartAccountFactoryContractId: 'CABCDEF...',
    webauthnProvider: BrowserWebAuthnProvider(
      rpId: 'app.example.com',
      rpName: 'My Stellar App',
    ),
    storage: IndexedDBStorageAdapter(),
  ),
);
```

## HTTPS Requirement

Browsers reject WebAuthn calls in non-secure contexts. The SDK does not
duplicate this check; the rejection surfaces as a `WebAuthnException`
whose message begins with `Security error:`. Production deployments
must serve every page over HTTPS.

`localhost` is the only exception. `127.0.0.1` is treated as a
different origin and will not work, even when it resolves to the same
host as `localhost`.

For custom-domain local development, terminate TLS at a proxy
(`mkcert`, `caddy`, etc.) and serve the Flutter app behind it so the
browser sees an HTTPS origin.

## Localhost Development

```dart
final webauthn = BrowserWebAuthnProvider(
  rpId: 'localhost',
  rpName: 'My Stellar App (Dev)',
);
```

Run the app via `flutter run -d chrome --web-hostname=localhost
--web-port=8080`. The browser treats `http://localhost:<port>` as a
secure context for WebAuthn purposes.

## Browser Version Matrix

| Browser | Minimum | Sync notes |
|---|---|---|
| Chrome | 67 | Synced to the user's Google account via Google Password Manager. |
| Firefox | 60 | Local to the device unless backed by an external authenticator. |
| Safari | 14 | Synced via iCloud Keychain across Apple devices. |
| Edge | 79 | Chromium-based; same sync behaviour as Chrome. |

Sync availability changes the user experience but not the SDK contract:
the same credential, signed by the same passkey, produces a valid
authorisation on every device that holds it.

## IndexedDB-vs-LocalStorage Trade-off

| Concern | IndexedDB | LocalStorage |
|---|---|---|
| Cap | ~hundreds of MB | ~5 MB |
| API | Asynchronous | Synchronous |
| Encryption at rest | Not encrypted | Not encrypted |
| Indexing | Native indexes | Manual in-band index |
| Concurrency | Transactional | Single-threaded same-origin |

## HTTPS Deployment Checklist

WebAuthn is server-driven from the relying party's perspective. The
Flutter web SDK ships no `.well-known/` files because validation runs
server-side. Your deployment must:

1. Serve every page over HTTPS (or `http://localhost` for development
   only).
2. Set `BrowserWebAuthnProvider.rpId` to your origin's domain (e.g.
   `app.example.com`) or a registrable suffix (e.g. `example.com`).
   Never use a public suffix.
3. Use the same `rpId` across registration and authentication for the
   same passkey; passkeys are bound to the RP-ID.
4. If hosting under multiple subdomains, set `rpId` to the registrable
   suffix so passkeys work across all subdomains; configure each
   subdomain to serve
   `Permissions-Policy: publickey-credentials-create=(self),
   publickey-credentials-get=(self)` headers if embedding via iframe.
5. For local development, use `rpId: 'localhost'` and
   `http://localhost:<port>`. Note that `127.0.0.1` is treated as a
   different origin and will not work.
6. Do NOT publish `.well-known/webauthn` or any other client-side
   trust-anchor document; the WebAuthn protocol does not require one.

## Troubleshooting

### `SecurityError`: rpId does not match the current origin

The browser rejects the ceremony because the configured `rpId` is not
the origin's domain or a registrable suffix of it. Valid examples for
`https://app.example.com`:

- `rpId: 'app.example.com'`
- `rpId: 'example.com'`

Invalid examples:

- `rpId: 'co.uk'` (public suffix)
- `rpId: 'other-app.example.com'` (different subdomain)
- `rpId: 'app.example.com:443'` (port not part of RP-ID)

### `NotAllowedError` (user cancellation)

Maps to `WebAuthnCancelled`. Common causes:

- The user clicked Cancel on the prompt.
- The user did not respond before the timeout elapsed.
- The browser's window lost focus during the ceremony.
- A browser extension intercepted and blocked the prompt.

Wait a moment before retrying; retrying immediately produces a second
cancellation when the previous prompt was still resolving.

### `WebAuthnNotSupported` in Node.js or non-web targets

`BrowserWebAuthnProvider` is browser-only. On non-web targets the
conditional export selects a stub that throws `UnsupportedError` from
each method. Use the platform-specific provider that ships with the
target instead (Apple-backed on iOS/macOS, Android Credential Manager
on Android).

### Cross-origin iframe restrictions

Browsers disable WebAuthn inside iframes by default. To enable a
credential ceremony from inside an `<iframe>`:

1. The parent page must serve
   `Permissions-Policy: publickey-credentials-create=(self
   "https://embedded.example.com"),
   publickey-credentials-get=(self "https://embedded.example.com")`.
2. The `<iframe>` element must include
   `allow="publickey-credentials-create; publickey-credentials-get"`.

If either step is missing, the browser raises `SecurityError`, which
the SDK surfaces as `WebAuthnException` with a `Security error:`
prefix.

### IndexedDB not available

Some browser configurations disable IndexedDB (older private-browsing
modes, web workers without IDB access). The SDK raises
`StorageReadFailed` with a message about IndexedDB unavailability.
Fall back to `LocalStorageAdapter` in those environments:

```dart
StorageAdapter storage;
try {
  final idb = IndexedDBStorageAdapter();
  // Trigger the open path to detect availability up front.
  await idb.getAll();
  storage = idb;
} on StorageReadFailed {
  storage = LocalStorageAdapter();
}
```

### Passkeys not syncing across devices

Sync behaviour is determined by the browser and operating system, not
the SDK:

- Safari (iCloud Keychain): syncs across the user's Apple devices when
  iCloud Keychain is enabled.
- Chrome (Google Password Manager): syncs across devices signed in to
  the same Google account.
- Firefox: stores credentials locally on the current device.
- Edge: same Chromium sync behaviour as Chrome when signed in to a
  Microsoft account.

If a user reports a missing passkey on a second device, verify their
browser is signed in to the same account.
