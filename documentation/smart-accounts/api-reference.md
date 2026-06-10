# Smart Accounts API Reference

OpenZeppelin Smart Account Kit for Stellar/Soroban. This reference documents all public APIs for creating, managing, and operating smart accounts with WebAuthn/passkey authentication.

**Location**: `package:stellar_flutter_sdk` (barrel export)

**Platform Support**: iOS, Android, Web

All public symbols listed here are re-exported from the top-level package barrel. Imports throughout this document assume the consumer pulls everything from the barrel.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

The kit requires Dart `>= 3.x` for `dart:js_interop` conditional imports used by the web facades, and `package:dio` for the optional `dio.CancelToken` parameter present on every cancellable async method.

```dart
import 'package:dio/dio.dart' as dio;
```

---

## Table of Contents

- [Quick Start](#quick-start)
- [OZSmartAccountKit (Main Entry Point)](#ozsmartaccountkit-main-entry-point)
- [OZSmartAccountConfig](#ozsmartaccountconfig)
- [Wallet Operations](#wallet-operations)
- [Transaction Operations](#transaction-operations)
- [Credential Management](#credential-management)
- [Signer Types](#signer-types)
- [Signer Management](#signer-management)
- [Multi-Signer Operations](#multi-signer-operations)
- [External Signer Management](#external-signer-management)
- [Context Rule Management](#context-rule-management)
- [Policy Management](#policy-management)
- [Events](#events)
- [Errors](#errors)
- [Constants](#constants)
- [WebAuthn Provider](#webauthn-provider)
- [Storage Adapter](#storage-adapter)
- [Indexer Client](#indexer-client)
- [Relayer Client](#relayer-client)
- [Auth Helpers](#auth-helpers)
- [Builder Helpers](#builder-helpers)
- [Utilities](#utilities)
- [Selected Signer](#selected-signer)
  - [OZSelectedSignerPasskey](#ozselectedsignerpasskey)
  - [OZSelectedSignerWallet](#ozselectedsignerwallet)
  - [OZSelectedSignerEd25519](#ozselectedsignered25519)
- [Error Handling Example](#error-handling-example)

---

## Quick Start

See the [Quick Start in the README](README.md#quick-start) for an end-to-end example covering kit configuration, wallet creation, token transfer, and the reconnection patterns. The sections below document each public symbol in detail.

---

## OZSmartAccountKit (Main Entry Point)

The `OZSmartAccountKit` class is the central facade for OpenZeppelin smart-account operations. It wires together the configuration, RPC and HTTP transports, storage, events, and every manager so the consumer holds a single live handle.

The kit's library-private constructor (`OZSmartAccountKit._`) is not callable from consumer code. Instances must be obtained through the static `create` factory or, in tests, through the `@visibleForTesting` `OZSmartAccountKit.forTesting` constructor.

### Factory Method

```dart
static OZSmartAccountKit create({required OZSmartAccountConfig config})
```

Creates a new `OZSmartAccountKit` bound to the supplied configuration.

The factory eagerly allocates network resources without performing any network call:

- A `SorobanServer` is always constructed and bound to `config.rpcUrl`.
- An `OZRelayerClient` is constructed when `config.relayerUrl` is non-null, with `OZConstants.defaultRelayerTimeoutMs` as the per-request timeout.
- An `OZIndexerClient` is constructed when `config.effectiveIndexerUrl()` resolves to a non-null URL (either an explicit `config.indexerUrl` override or the well-known default URL for the configured network), with `OZConstants.defaultIndexerTimeoutMs` as the per-request timeout.

Every required input has already been validated by the `OZSmartAccountConfig` constructor, so no additional invariants are checked here.

**Parameters:**

- `config`: Configuration carrying the RPC endpoint, network passphrase, contract WASM hash, WebAuthn verifier contract address, optional relayer / indexer URLs, optional WebAuthn provider, optional storage adapter, optional external-wallet adapter, and optional Ed25519 adapter for out-of-process Ed25519 signing. The kit constructs one `OZExternalSignerManager` from these adapters and exposes it as `externalSigners`.

**Returns:** A new, unconnected `OZSmartAccountKit`. Restore a previously-saved session via `kit.walletOperations.connectWallet()`.

### Properties

#### config

```dart
final OZSmartAccountConfig config
```

The configuration captured at construction time. Defines network endpoints, contract addresses, and operational parameters.

#### events

```dart
final OZSmartAccountEventEmitter events
```

The shared event emitter. Subscribers receive lifecycle events for wallet connection / disconnection, credential creation / deletion, session expiry, credential sync failures, transaction signing, and transaction submission. The emitter is callback-based, not `Stream`-based; see [Events](#events).

#### isConnected

```dart
bool get isConnected
```

`true` when both `credentialId` and `contractId` are set. `false` after `disconnect()` or before any wallet has been created or connected.

#### credentialId

```dart
String? get credentialId
```

Base64URL-encoded WebAuthn credential ID (no padding) of the currently connected wallet, or `null` when no wallet is connected.

#### contractId

```dart
String? get contractId
```

Smart account contract address (`C…`) of the currently connected wallet, or `null` when no wallet is connected.

#### requireConnected

```dart
Future<OZConnectedState> requireConnected()
```

Returns the connected wallet's credential ID and contract address together as an `OZConnectedState`, or throws `SmartAccountWalletException.notConnected` when no wallet is connected. Use this when both values are required non-null; the individual `credentialId` / `contractId` getters return `null` while disconnected.

`OZConnectedState` is an immutable value type with two `String` fields:

- `credentialId`: Base64URL-encoded WebAuthn credential ID.
- `contractId`: smart account contract address (`C…`).

### Manager Properties

The kit exposes its managers as identity-preserving properties; every property returns the same instance for the lifetime of the kit. The seven core managers below are lazy `late final` fields; `externalSigners` is a getter over a manager constructed at initialization.

#### walletOperations

```dart
late final OZWalletOperations walletOperations
```

Wallet lifecycle: create, connect, deploy a pending credential, and standalone passkey authentication. See [Wallet Operations](#wallet-operations).

#### transactionOperations

```dart
late final OZTransactionOperations transactionOperations
```

Transaction pipeline: token transfer, direct contract call, smart-account-mediated `execute`, low-level `submit`, testnet wallet funding. See [Transaction Operations](#transaction-operations).

#### signerManager

```dart
late final OZSignerManager signerManager
```

Signer management on context rules: add a new passkey, add an existing passkey, add a delegated signer, add an Ed25519 signer, remove by ID, remove by signer value. See [Signer Management](#signer-management).

#### contextRuleManager

```dart
late final OZContextRuleManager contextRuleManager
```

Context-rule add / update / remove operations, plus rule iteration and parsing utilities. See [Context Rule Management](#context-rule-management).

#### policyManager

```dart
late final OZPolicyManager policyManager
```

Policy attach / detach operations with convenience helpers for the built-in `SimpleThreshold`, `WeightedThreshold`, and `SpendingLimit` policy types. See [Policy Management](#policy-management).

#### credentialManager

```dart
late final OZCredentialManager credentialManager
```

Credential storage lifecycle: create / save / sync / delete pending credentials. See [Credential Management](#credential-management).

#### multiSignerManager

```dart
late final OZMultiSignerManager multiSignerManager
```

Multi-signature operations across passkey and external-wallet signers. See [Signer Management](#signer-management).

#### externalSigners

```dart
OZExternalSignerManager get externalSigners
```

The unified external-signer manager, constructed by the kit from the supplied configuration. Non-null for the lifetime of the kit. Provides in-memory keypair registration and adapter-backed signing for both G-address wallet signers and Ed25519 external signers.

- **Wallet signers (G-address):** supply `config.externalWallet` at kit construction for out-of-process signing, or call `kit.externalSigners.addFromSecret(secretKey)` at runtime to register an in-memory keypair.
- **Ed25519 signers:** supply `config.externalEd25519Adapter` at kit construction for out-of-process signing, or call `kit.externalSigners.addEd25519FromRawKey(...)` at runtime to register an in-memory key.

See [External Signer Management](#external-signer-management).

### Client Properties

#### indexerClient

```dart
final OZIndexerClient? indexerClient
```

The credential-to-contract indexer client. `null` when neither `config.indexerUrl` is set nor a network-default URL is registered for the configured passphrase. Use for direct credential or address lookups, contract-detail retrieval, and indexer statistics. See [Indexer Client](#indexer-client).

#### relayerClient

```dart
final OZRelayerClient? relayerClient
```

The fee-sponsoring relayer client. `null` when `config.relayerUrl` is unset. The kit uses this internally to submit transactions when present; direct access is available for advanced submission flows. See [Relayer Client](#relayer-client).

### Lifecycle Methods

#### disconnect

```dart
Future<void> disconnect() async
```

Disconnects the currently-connected wallet, clearing the in-memory connection state and removing the persisted session via `OZStorageAdapter.clearSession`. When a wallet was connected at the time of the call, emits an `OZSmartAccountEventWalletDisconnected` event. Stored credential entries remain in storage and can be reconnected later via `walletOperations.connectWallet`. Safe to call when no wallet is connected; the call is a no-op aside from the storage-clear request.

#### close

```dart
Future<void> close() async
```

Releases every held HTTP-client resource and removes every registered event listener. Closes the shared `sorobanServer` transport first, then the optional `indexerClient` and `relayerClient` HTTP clients, tears down the kit's event subscriptions, and clears any in-memory external signers (registered keypairs and Ed25519 keys). Idempotent: a second invocation is a no-op. Storage and connection state are not touched — persisted external-wallet connections are retained; call `disconnect()` first to end an active session. The kit is not usable for new operations after `close()` returns.

#### getDeployer

```dart
Future<KeyPair> getDeployer() async
```

Returns the deployer keypair, resolving to the deterministic default when `config.deployerKeypair` is unset. The first call resolves the deployer via `OZSmartAccountConfig.effectiveDeployer` and caches the result; subsequent calls return the cached keypair.

---

## OZSmartAccountConfig

Configuration for the OpenZeppelin smart-account kit. Carries network endpoints, contract addresses, optional service URLs, and the pluggable provider / storage / external-wallet adapters. All validation runs in the constructor so a successfully constructed config is guaranteed to be well-formed.

### Constructor

```dart
OZSmartAccountConfig({
  required String rpcUrl,
  required String networkPassphrase,
  required String accountWasmHash,
  required String webauthnVerifierAddress,
  KeyPair? deployerKeypair,
  int sessionExpiryMs = OZConstants.defaultSessionExpiryMs,
  int signatureExpirationLedgers = Util.ledgersPerHour,
  int timeoutInSeconds = OZConstants.defaultTimeoutSeconds,
  String? relayerUrl,
  String? indexerUrl,
  WebAuthnProvider? webauthnProvider,
  OZStorageAdapter? storage,
  OZExternalWalletAdapter? externalWallet,
  OZExternalEd25519SignerAdapter? externalEd25519Adapter,
  int maxContextRuleScanId = 50,
})
```

**Required fields:**

- `rpcUrl`: Soroban RPC endpoint, e.g. `https://soroban-testnet.stellar.org`. Must be non-empty.
- `networkPassphrase`: Stellar network passphrase. Examples: `Test SDF Network ; September 2015`, `Public Global Stellar Network ; September 2015`. Must be non-empty.
- `accountWasmHash`: SHA-256 hash of the smart-account contract WASM as a 64-character hex string. Validated against `^[0-9a-fA-F]{64}$`.
- `webauthnVerifierAddress`: Contract address (`C…`) of the WebAuthn signature verifier. Validated with `StrKey.isValidContractId`.

**Optional fields and defaults:**

- `deployerKeypair`: Keypair used to deploy and submit transactions. Defaults to the deterministic default derived from `SHA-256("openzeppelin-smart-account-kit")`. Production apps typically supply a custom keypair for attribution.
- `sessionExpiryMs`: Session validity in milliseconds. Default `OZConstants.defaultSessionExpiryMs` (7 days).
- `signatureExpirationLedgers`: Auth-entry expiration in ledgers. Default `Util.ledgersPerHour` (720). Must be `>= 1`. No upper bound is enforced client-side; the network's configurable `maxEntryTTL` (CAP-0046-11) is the real ceiling, checked by the host at submission.
- `timeoutInSeconds`: Sets each transaction's TimeBounds (`max_time = now + timeoutInSeconds`, `min_time = 0`), bounding how long a signed transaction stays valid for submission. A value of `0` sets `max_time = 0` (Stellar's "no upper bound", i.e. no expiry / infinite validity). Default `OZConstants.defaultTimeoutSeconds` (30). Must be `>= 0`.
- `relayerUrl`: Optional relayer endpoint. When set, transactions can be fee-sponsored via the relayer pipeline.
- `indexerUrl`: Optional indexer endpoint. When unset, `effectiveIndexerUrl()` falls back to the well-known default URL for the configured network when available.
- `webauthnProvider`: Platform-specific WebAuthn provider. Required for any passkey-driven operation; an absent provider causes `createWallet`, `connectWallet(prompt: true)`, `authenticatePasskey`, and signer / transaction WebAuthn flows to throw `WebAuthnNotSupported`.
- `storage`: Storage adapter for credentials and sessions. Defaults to a fresh `OZInMemoryStorageAdapter()` when omitted. All `OZInMemoryStorageAdapter` instances compare equal, so two configs with the default storage are structurally equal.
- `externalWallet`: Optional adapter for out-of-process wallet signing (for example WalletConnect). The kit injects this into the internally-constructed `OZExternalSignerManager`. In-memory G-address keypairs can also be registered at runtime via `kit.externalSigners.addFromSecret(secretKey)` without an adapter.
- `externalEd25519Adapter`: Optional adapter for out-of-process Ed25519 signing (for example hardware wallets and remote signing services). The kit injects this into the internally-constructed `OZExternalSignerManager`. In-memory Ed25519 keys can also be registered at runtime via `kit.externalSigners.addEd25519FromRawKey(...)` without an adapter.
- `maxContextRuleScanId`: Upper bound on rule IDs to scan when iterating context rules. Default `50`. Increase if the account has had many add / remove cycles. Must be non-negative.

Throws `SmartAccountConfigurationException.missingConfig` when a required parameter is blank, and `SmartAccountConfigurationException.invalidConfig` when `accountWasmHash`, `webauthnVerifierAddress`, `signatureExpirationLedgers`, `timeoutInSeconds`, or `maxContextRuleScanId` fails validation.

Every constructor parameter is also exposed as a public `final` field with the same name and type.

### Platform-specific provider integration

See [WebAuthn Provider](#webauthn-provider), [Storage Adapter](#storage-adapter), and [OZExternalWalletAdapter](#ozexternalwalletadapter-abstract-class) for the platform-specific implementations and the abstract contracts.

### Static Factories

#### createDefaultDeployer

```dart
static Future<KeyPair> createDefaultDeployer() async
```

Derives the deterministic deployer keypair from `SHA-256("openzeppelin-smart-account-kit")`. The seed string is fixed by the contract spec so the derived account ID is reproducible. The deployer only pays deployment fees; it does not control user wallets. Throws `SmartAccountConfigurationException.invalidConfig` on derivation failure.

#### builder

```dart
static OZSmartAccountConfigBuilder builder({
  required String rpcUrl,
  required String networkPassphrase,
  required String accountWasmHash,
  required String webauthnVerifierAddress,
})
```

Creates a fluent builder pre-populated with the four required fields. Use `OZSmartAccountConfigBuilder` setters to override defaults, then call `build()` to obtain a validated `OZSmartAccountConfig`. See [OZSmartAccountConfigBuilder](#ozsmartaccountconfigbuilder).

### Instance Methods

#### effectiveDeployer

```dart
Future<KeyPair> effectiveDeployer() async
```

Returns `deployerKeypair` when set; otherwise resolves to the deterministic default. Throws `SmartAccountConfigurationException` if default derivation fails.

#### effectiveIndexerUrl

```dart
String? effectiveIndexerUrl()
```

Returns `indexerUrl` when set; otherwise the well-known default URL for `networkPassphrase` (testnet and mainnet) when one exists, or `null`.

#### copyWith

`copyWith(...)` returns a modified copy. For nullable optional fields, pass the matching `set...` flag (for example `setRelayerUrl: true, relayerUrl: null`) to clear the field; otherwise `null` means "no change". Constructor validation runs on the copy.

### OZSmartAccountConfigBuilder

Fluent builder returned by `OZSmartAccountConfig.builder`.

```dart
OZSmartAccountConfigBuilder({
  required String rpcUrl,
  required String networkPassphrase,
  required String accountWasmHash,
  required String webauthnVerifierAddress,
})
```

Setter methods (each returns the builder for chaining):

- `deployerKeypair(KeyPair? value)`
- `sessionExpiryMs(int value)`
- `signatureExpirationLedgers(int value)`
- `timeoutInSeconds(int value)`
- `relayerUrl(String? value)`
- `indexerUrl(String? value)`
- `webauthnProvider(WebAuthnProvider? value)`
- `storage(OZStorageAdapter value)`
- `externalWallet(OZExternalWalletAdapter? value)`
- `externalEd25519Adapter(OZExternalEd25519SignerAdapter? value)`
- `maxContextRuleScanId(int value)`

#### build

```dart
OZSmartAccountConfig build()
```

Constructs the `OZSmartAccountConfig`, applying constructor validation. Throws `SmartAccountConfigurationException` on failure.

---

## Wallet Operations

### OZWalletOperations

Manages the wallet lifecycle: passkey registration, contract derivation, deployment, session restoration, indexer-driven discovery, and standalone authentication. Accessed via `kit.walletOperations`.

```dart
final walletOps = kit.walletOperations;
```

#### createWallet

```dart
Future<OZCreateWalletResult> createWallet({
  String userName = 'Smart Account User',
  bool autoSubmit = false,
  bool autoFund = false,
  String? nativeTokenContract,
  OZSubmissionMethod? forceMethod,
  dio.CancelToken? cancelToken,
}) async
```

Creates a new smart-account wallet with a fresh WebAuthn passkey.

Flow:

1. Require a configured `WebAuthnProvider` and validate auto-fund preconditions.
2. Generate a 32-byte random challenge and a 32-byte random user ID; trigger the WebAuthn registration ceremony.
3. Extract the uncompressed secp256r1 public key from the registration result via `SmartAccountUtils.extractPublicKeyFromRegistration`.
4. Derive the deterministic smart-account contract address from the credential ID and the effective deployer.
5. Persist the credential as pending via the credential manager and emit an `OZSmartAccountEventCredentialCreated` event.
6. Set the kit's connected state and emit `OZSmartAccountEventWalletConnected`; save the session.
7. Build and sign the deploy transaction unconditionally so the caller can submit externally when `autoSubmit` is `false`.
8. When `autoSubmit` is `true`, submit the deploy transaction. When `autoFund` is also `true`, wait briefly for RPC visibility and then fund the wallet via Friendbot (testnet only). On success the pending credential is deleted.

**Parameters:**

- `userName`: Display name passed to WebAuthn and stored as the credential's nickname.
- `autoSubmit`: When `true`, submit the deploy transaction. When `false`, return the unsubmitted signed XDR in `signedTransactionXdr` so a consumer can submit it externally.
- `autoFund`: When `true`, fund the deployed wallet via Friendbot after a 5 s ledger-close delay. Requires `autoSubmit == true`, `nativeTokenContract != null`, and testnet.
- `nativeTokenContract`: Native-token Soroban contract address required when `autoFund` is `true`.
- `forceMethod`: Optional submission-method override. Defaults to auto-detection (relayer when configured, otherwise direct RPC).
- `cancelToken`: Optional Dio cancel token. Cancellation surfaces as `SmartAccountTransactionException.submissionFailed` with the underlying `DioException.cancel` preserved as the cause.

**Returns:** An `OZCreateWalletResult` carrying the credential ID, contract address, 65-byte public key, signed transaction XDR (always populated), optional transaction hash, and the nickname used for the credential.

**Throws:** `WebAuthnException.notSupported` when no provider is configured; `SmartAccountValidationException.invalidInput` for missing auto-fund prerequisites; `WebAuthnException.registrationFailed` when the ceremony fails or is cancelled; `SmartAccountCredentialException.alreadyExists` when a duplicate credential ID is encountered; `SmartAccountStorageException.writeFailed` on persistence failures; `SmartAccountTransactionException` for build, sign, simulation, or submission failures.

#### connectWallet

```dart
Future<OZConnectWalletResult?> connectWallet({
  OZConnectWalletOptions options = const OZConnectWalletOptions(),
  dio.CancelToken? cancelToken,
}) async
```

Connects to an existing smart-account wallet.

Options decision matrix:

| Options | Behaviour |
| --- | --- |
| Default (`prompt: false`, `fresh: false`) | Silent session restore. Returns `null` when no valid session exists. |
| `credentialId` and / or `contractId` set | Direct connection via the credentials cascade. |
| `fresh: true` | Skip the session and always trigger WebAuthn. |
| `prompt: true` | Session restore with WebAuthn fallback when no session exists. |
| `fresh: true, prompt: true` | `fresh` takes priority and always triggers WebAuthn. |

Connection cascade (when a credential ID is available, either supplied or freshly obtained from WebAuthn):

1. Storage: a `pending` entry is trusted; a `failed` entry throws with a hint to call `deployPendingCredential`.
2. Deterministic derivation under the configured deployer, with on-chain verification.
3. Indexer lookup: zero results throw `SmartAccountWalletException.notFound`; one result is verified and returned as `OZConnectWalletConnected`; multiple results are returned as `OZConnectWalletAmbiguous` without setting the connected state.

**Returns:** `null` when no session exists and `prompt` is `false`; otherwise an `OZConnectWalletConnected` (single-contract success, state set and session saved) or `OZConnectWalletAmbiguous` (caller must let the user pick a contract and reconnect with `credentialId` + the chosen `contractId`).

**Throws:** `SmartAccountValidationException.invalidInput` when `contractId` is supplied without `credentialId`; `WebAuthnException` family on WebAuthn failures; `SmartAccountWalletException.notFound` when no on-chain contract is resolved; `SmartAccountTransactionException` on XDR or simulation failures during derivation / verification.

#### authenticatePasskey

```dart
Future<OZAuthenticatePasskeyResult> authenticatePasskey({
  Uint8List? challenge,
  List<String>? credentialIds,
  dio.CancelToken? cancelToken,
}) async
```

Triggers a WebAuthn authentication ceremony without modifying the kit's connection state. Useful for indexer-driven discovery, pre-authentication, or multi-signer flows that need a fresh signature before a wallet is selected.

**Parameters:**

- `challenge`: Optional challenge bytes. When omitted, a 32-byte secure random challenge is generated.
- `credentialIds`: Optional list of Base64URL-encoded credential IDs. When supplied, the authenticator is restricted to these credentials (the WebAuthn `allowCredentials` constraint). Padded and unpadded forms are accepted interchangeably; transport hints from local storage are forwarded into each `WebAuthnAllowCredential` entry.

**Returns:** An `OZAuthenticatePasskeyResult` carrying the credential ID, the normalised (64-byte compact, low-S) `OZWebAuthnSignature`, and the 65-byte public key when the credential is in local storage (empty otherwise).

**Throws:** `WebAuthnException.notSupported` when no provider is configured; `WebAuthnException.authenticationFailed` on ceremony failure; `SmartAccountCredentialException.invalid` when the provider returns a signature for a credential outside the requested allow-list; `SmartAccountValidationException.invalidInput` when signature normalisation fails.

#### deployPendingCredential

```dart
Future<OZDeployPendingResult> deployPendingCredential({
  required String credentialId,
  bool autoSubmit = true,
  bool autoFund = false,
  String? nativeTokenContract,
  OZSubmissionMethod? forceMethod,
  dio.CancelToken? cancelToken,
}) async
```

Deploys a wallet from a previously-created pending credential. Use this to retry a failed deployment, or to submit a wallet that was created with `autoSubmit: false`. The credential must exist in local storage with a non-empty `publicKey` and `contractId`.

Sets the kit's connected state on success so the kit is ready immediately after deployment. Always returns the signed transaction XDR, regardless of `autoSubmit`.

**Parameters:**

- `credentialId`: Base64URL-encoded credential ID of the pending credential. Padded forms are accepted and normalised internally.
- `autoSubmit`: When `true` (default), submit the deploy transaction. When `false`, return the unsubmitted signed XDR.
- `autoFund`: When `true`, fund the wallet via Friendbot after submission. Requires `nativeTokenContract != null`.
- `nativeTokenContract`: Native-token Soroban contract address required when `autoFund` is `true`.
- `forceMethod`: Optional submission-method override.

**Returns:** An `OZDeployPendingResult` carrying the contract address, the signed transaction XDR, and the optional transaction hash when submitted.

**Throws:** `SmartAccountValidationException.invalidInput` when the auto-fund prerequisites are unmet; `SmartAccountCredentialException.notFound` when the credential is missing from storage; `SmartAccountCredentialException.invalid` when required fields are absent; `SmartAccountTransactionException` on build, sign, simulation, or submission failure.

### Result Types

#### OZCreateWalletResult

```dart
class OZCreateWalletResult {
  const OZCreateWalletResult({
    required String credentialId,
    required String contractId,
    required Uint8List publicKey,
    required String signedTransactionXdr,
    String? transactionHash,
    String? nickname,
  });

  final String credentialId;
  final String contractId;
  final Uint8List publicKey;
  final String signedTransactionXdr;
  final String? transactionHash;
  final String? nickname;
}
```

- `credentialId`: Base64URL-encoded WebAuthn credential ID (no padding).
- `contractId`: Smart account contract address (`C…`).
- `publicKey`: Uncompressed secp256r1 public key (65 bytes starting with `0x04`).
- `signedTransactionXdr`: Base64-encoded signed deploy-transaction envelope. Always populated.
- `transactionHash`: Transaction hash when auto-submitted, `null` otherwise.
- `nickname`: User-supplied display name stored with the credential.

Equality compares `publicKey` in constant time; `hashCode` is byte-content-derived.

#### OZConnectWalletResult (sealed)

```dart
sealed class OZConnectWalletResult {
  const OZConnectWalletResult();
  String get credentialId;
}
```

`OZConnectWalletResult` is the base class for connect outcomes. Two concrete arms:

##### OZConnectWalletConnected

```dart
final class OZConnectWalletConnected extends OZConnectWalletResult {
  const OZConnectWalletConnected({
    required String credentialId,
    required String contractId,
    required bool restoredFromSession,
  });

  final String credentialId;
  final String contractId;
  final bool restoredFromSession;

  OZConnectWalletConnected copyWith({...});
}
```

- `credentialId`: Base64URL-encoded credential ID.
- `contractId`: Resolved smart-account contract address.
- `restoredFromSession`: `true` when the connection came from a saved session; `false` otherwise.

##### OZConnectWalletAmbiguous

```dart
final class OZConnectWalletAmbiguous extends OZConnectWalletResult {
  const OZConnectWalletAmbiguous({
    required String credentialId,
    required List<String> candidates,
  });

  final String credentialId;
  final List<String> candidates;
}
```

- `credentialId`: Base64URL-encoded credential ID. Reuse for the disambiguation reconnect to avoid a second WebAuthn ceremony.
- `candidates`: Contract addresses returned by the indexer. Let the user pick one and call `connectWallet` again with `OZConnectWalletOptions(credentialId: …, contractId: chosen)`.

#### OZDeployPendingResult

```dart
class OZDeployPendingResult {
  const OZDeployPendingResult({
    required String contractId,
    required String signedTransactionXdr,
    String? transactionHash,
  });

  final String contractId;
  final String signedTransactionXdr;
  final String? transactionHash;
}
```

- `contractId`: Smart account contract address.
- `signedTransactionXdr`: Base64-encoded signed deploy-transaction envelope.
- `transactionHash`: Present when `autoSubmit` was `true`, `null` otherwise.

#### OZAuthenticatePasskeyResult

```dart
class OZAuthenticatePasskeyResult {
  const OZAuthenticatePasskeyResult({
    required String credentialId,
    required OZWebAuthnSignature signature,
    required Uint8List publicKey,
  });

  final String credentialId;
  final OZWebAuthnSignature signature;
  final Uint8List publicKey;
}
```

- `credentialId`: Base64URL-encoded credential ID of the authenticated passkey.
- `signature`: Normalised (64-byte compact, low-S) `OZWebAuthnSignature`.
- `publicKey`: 65-byte uncompressed secp256r1 public key when present locally; otherwise an empty `Uint8List`.

#### OZConnectWalletOptions

```dart
class OZConnectWalletOptions {
  const OZConnectWalletOptions({
    String? credentialId,
    String? contractId,
    bool fresh = false,
    bool prompt = false,
  });

  final String? credentialId;
  final String? contractId;
  final bool fresh;
  final bool prompt;
}
```

---

## Transaction Operations

### OZTransactionOperations

High-level transaction building, signing, and submission for smart-account operations. Accessed via `kit.transactionOperations`.

#### transfer

```dart
Future<OZTransactionResult> transfer({
  required String tokenContract,
  required String recipient,
  required String amount,
  int? decimals,
  OZSubmissionMethod? forceMethod,
  dio.CancelToken? cancelToken,
}) async
```

SEP-41 token transfer from the connected smart account to `recipient`. The decimal `amount` is converted to the token's base units and the transaction is built as a direct `transfer(from, to, amount)` invocation on the token contract; authorisation runs against the matching `CallContract(tokenContract)` context rule.

**Parameters:**

- `tokenContract`: Token contract address (`C…`). Use the SAC address for XLM or the contract address for any SEP-41 custom token.
- `recipient`: Recipient address (`G…` or `C…`). Validated against Stellar address format.
- `amount`: Decimal amount, e.g. `"100"` or `"10.5"`. Converted to the token's base units.
- `decimals`: Token decimal scale used to convert `amount`. When `null` (default), the token's on-chain `decimals()` is fetched via `fetchTokenDecimals`.
- `forceMethod`: Optional `OZSubmissionMethod` override.

**Returns:** An `OZTransactionResult` carrying the submission outcome.

**Throws:** `SmartAccountWalletNotConnected`; `SmartAccountValidationException.invalidAddress` for malformed recipients; `SmartAccountValidationException.invalidInput` for self-transfer or invalid amount; downstream `SmartAccountTransactionException`, `WebAuthnException`, `SmartAccountCredentialException`.

#### fetchTokenDecimals

```dart
Future<int> fetchTokenDecimals(String tokenContract) async
```

Simulates the SEP-41 token contract's `decimals()` function and returns the reported `u32` scale.

**Parameters:**

- `tokenContract`: Token contract address (`C…`).

**Returns:** The token's decimal scale as an `int`.

**Throws:** `SmartAccountValidationException.invalidAddress` when `tokenContract` is malformed; `SmartAccountTransactionException` when the simulation fails or the contract does not return a valid `u32`.

#### amountToBaseUnits

```dart
static BigInt amountToBaseUnits(String amount, {required int decimals})
```

Converts a positive decimal `amount` string to its base-units `BigInt` value scaled by `decimals` decimal places. Rejects scientific notation, empty or non-numeric strings, values less than or equal to zero, and values with more fractional digits than `decimals` allows.

**Parameters:**

- `amount`: Positive decimal string, e.g. `"100"` or `"10.5"`.
- `decimals`: Token decimal scale, in `0..OZTransactionOperations.maxTokenDecimals` (`38`). A value of `0` accepts only integer amounts.

**Returns:** The amount expressed in base units as a `BigInt`.

**Throws:** `SmartAccountValidationException.invalidAmount` when `amount` is invalid or `decimals` is out of range.

#### contractCall

```dart
Future<OZTransactionResult> contractCall({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
  dio.CancelToken? cancelToken,
}) async
```

Invokes an arbitrary function on an external contract directly from the smart account. The host function calls `target.targetFn(targetArgs)` without going through the smart account's `execute()` entry point. The matching `CallContract(target)` context rule is used for authorisation.

**Parameters:**

- `target`: Target contract address (`C…`).
- `targetFn`: Function name to invoke on `target`.
- `targetArgs`: Pre-encoded XDR arguments. Construct via `XdrSCVal.forU32`, `XdrSCVal.forAddress`, `Util.bigIntToI128ScVal`, etc.
- `forceMethod`: Optional submission-method override.
- `resolveContextRuleIds`: Optional callback supplying per-entry context-rule IDs when auto-resolution is ambiguous.

#### executeAndSubmit

```dart
Future<OZTransactionResult> executeAndSubmit({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
  dio.CancelToken? cancelToken,
}) async
```

Executes a contract call through the smart account's `execute(target, target_fn, target_args)` entry point. The smart account becomes the direct invoker of the target contract, which is required by contracts that check their caller (for example policy contracts that verify the smart account is the caller).

The auth context is `CallContract(smartAccountAddress)`, so only `Default` rules, or rules targeting the smart account address explicitly, match. For external-contract calls with contract-specific rules use `contractCall` instead.

#### submit

```dart
Future<OZTransactionResult> submit({
  required XdrHostFunction hostFunction,
  required List<XdrSorobanAuthorizationEntry> auth,
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
  dio.CancelToken? cancelToken,
}) async
```

Low-level submission. Accepts a pre-built host function and handles the full authorisation lifecycle: simulation, auth-entry extraction, context-rule resolution, WebAuthn signing, re-simulation for accurate resource fees, source-account or deployer signing as required, relayer-or-RPC dispatch, and on-chain polling.

This is the primitive that `transfer`, `contractCall`, and `executeAndSubmit` build on. Use it directly when fine-grained control over host-function construction is required (multi-operation invocations, custom auth entries from external signers, and so on).

#### fundWallet

```dart
Future<String> fundWallet({
  required String nativeTokenContract,
  OZSubmissionMethod? forceMethod,
  dio.CancelToken? cancelToken,
}) async
```

Funds the connected smart-account wallet on testnet using Friendbot. Creates a temporary keypair, funds it via Friendbot, transfers all but `OZConstants.friendbotReserveXlm` to the smart account using the native-token contract, and returns the amount funded as a decimal XLM string.

**Throws:** `SmartAccountValidationException.invalidAddress` for malformed `nativeTokenContract`; `SmartAccountTransactionException` on any step failure.

### Result Types

#### OZTransactionResult

```dart
class OZTransactionResult {
  const OZTransactionResult({
    required bool success,
    String? hash,
    int? ledger,
    String? error,
  });

  final bool success;
  final String? hash;
  final int? ledger;
  final String? error;
}
```

- `success`: Whether the transaction succeeded.
- `hash`: Transaction hash when submission succeeded.
- `ledger`: Ledger number where the transaction was confirmed.
- `error`: Error message when `success` is `false`.

#### OZResolveContextRuleIds (typedef)

```dart
typedef OZResolveContextRuleIds = Future<List<int>> Function(
  XdrSorobanAuthorizationEntry entry,
  int index,
);
```

Optional callback invoked during signing for each authorisation entry that matches the connected smart account. Receives the entry and its index in the auth-entries list and returns the context-rule IDs to use for the entry. When no callback is supplied the SDK auto-resolves the rule IDs from the connected signer and the active context rules.

#### OZSubmissionMethod

```dart
enum OZSubmissionMethod {
  relayer,
  rpc,
}
```

- `relayer`: Submit via the configured relayer. Fails when no relayer is configured.
- `rpc`: Submit directly via Soroban RPC. Always available.

---

## Credential Management

### OZCredentialManager

Manages the lifecycle of stored smart-account credentials (WebAuthn passkeys). Accessed via `kit.credentialManager`.

Credential state machine:

- `pending` → deploy success → credential **deleted from storage**.
- `pending` → deploy failure → `failed` (with `deploymentError`).
- `pending` → sync discovers contract on-chain → credential **deleted from storage**.
- `failed` → `deleteCredential` → credential **deleted from storage**.

After successful deployment (or successful sync) the credential is removed rather than transitioned to a terminal "deployed" state; reconnection is then handled via sessions or the indexer.

#### createPendingCredential

```dart
Future<OZStoredCredential> createPendingCredential({
  required String credentialId,
  required Uint8List publicKey,
  required String contractId,
  String? nickname,
  List<String>? transports,
  String? deviceType,
  bool? backedUp,
}) async
```

Creates a credential with `deploymentStatus = pending` and `isPrimary = false`. Validates that `publicKey` is exactly 65 bytes, that `credentialId` is non-empty, and that no credential with the same ID already exists.

Throws `SmartAccountValidationException.invalidInput`, `SmartAccountCredentialException.alreadyExists`, `SmartAccountStorageException.writeFailed`.

#### saveCredential

```dart
Future<OZStoredCredential> saveCredential({
  required String credentialId,
  required Uint8List publicKey,
  String? nickname,
  String? contractId,
}) async
```

Persists a credential with `deploymentStatus = pending` and `isPrimary = false` using upsert semantics. Unlike `createPendingCredential`, no duplicate check is performed; any existing credential with the same ID is silently overwritten, and deployment metadata (`transports`, `deviceType`, `backedUp`) is not retained. A `null` `contractId` is stored as the empty string.

#### sync

```dart
Future<bool> sync(String credentialId) async
```

Checks whether the smart-account contract for this credential exists on-chain. When found, deletes the credential from storage and returns `true`. When not found or on transient RPC failure, returns `false`; swallowed exceptions are emitted as `OZSmartAccountEventCredentialSyncFailed` so consumers can observe them without losing the stable-return contract.

Throws `SmartAccountCredentialException.notFound` when the credential is absent from storage; `SmartAccountStorageException.readFailed` on storage failure.

#### syncAll

```dart
Future<OZSyncResult> syncAll() async
```

Runs `sync` against every stored credential and returns an `OZSyncResult` carrying the counts of credentials confirmed as deployed (and removed), credentials still pending, and credentials marked failed.

#### deleteCredential

```dart
Future<void> deleteCredential({required String credentialId}) async
```

Deletes the credential after verifying via `sync` that the corresponding contract is not on-chain. Refusing to delete a deployed credential prevents the user from removing a wallet that still exists on-chain. Emits `OZSmartAccountEventCredentialDeleted` on success.

Throws `SmartAccountCredentialException.notFound`, `SmartAccountCredentialException.invalid` (when the credential is on-chain), `SmartAccountStorageException`.

#### getCredential

```dart
Future<OZStoredCredential?> getCredential(String credentialId) async
```

Returns the stored credential or `null` when not present.

#### getCredentialsByContract

```dart
Future<List<OZStoredCredential>> getCredentialsByContract(String contractId) async
```

Returns all stored credentials whose `contractId` equals the supplied value.

#### getAllCredentials

```dart
Future<List<OZStoredCredential>> getAllCredentials() async
```

Returns every stored credential.

#### getForConnectedWallet

```dart
Future<List<OZStoredCredential>> getForConnectedWallet() async
```

Returns all credentials whose `contractId` matches `kit.contractId`. Returns an empty list when no wallet is connected.

#### getPendingCredentials

```dart
Future<List<OZStoredCredential>> getPendingCredentials() async
```

Returns every stored credential whose `deploymentStatus` is `pending` or `failed`. Useful for surfacing wallets that still need attention (retry, sync, or delete).

#### updateNickname

```dart
Future<void> updateNickname(String credentialId, String? nickname) async
```

Updates the credential's nickname. Throws `SmartAccountCredentialException.notFound` when the credential is absent.

#### clearAll

```dart
Future<void> clearAll() async
```

Removes every credential from storage. Irreversible; intended for account-deletion or reset flows.

### OZSyncResult

```dart
class OZSyncResult {
  const OZSyncResult({
    required int deployed,
    required int pending,
    required int failed,
  });

  final int deployed;
  final int pending;
  final int failed;
}
```

- `deployed`: Number of credentials confirmed deployed and removed from storage.
- `pending`: Number still pending deployment.
- `failed`: Number marked as failed.

---

## Signer Types

`OZSmartAccountSigner` is the central signer abstraction. It identifies *who* may authorise a transaction under a context rule and appears across the API: rule signer lists, [`removeSignerBySigner`](#removesignerbysigner), weighted-threshold maps (`Map<OZSmartAccountSigner, int>`), the auth-payload `signers` map, and the [`OZSmartAccountBuilders`](#ozsmartaccountbuilders) signer helpers.

### OZSmartAccountSigner (sealed)

```dart
sealed class OZSmartAccountSigner {
  const OZSmartAccountSigner();

  XdrSCVal toScVal();
  String get uniqueKey;
}
```

Base type with two concrete arms: [`OZDelegatedSigner`](#ozdelegatedsigner) and [`OZExternalSigner`](#ozexternalsigner).

- `toScVal()`: Converts the signer to its on-chain `XdrSCVal` representation for contract calls. Throws `SmartAccountValidationException.invalidInput` when the underlying address or key data cannot be encoded.
- `uniqueKey`: Stable identifier used for deduplication. Delegated signers yield `"delegated:<address>"`; external signers yield `"external:<verifierAddress>:<keyDataHex>"` (lowercase hex of the key data).

### OZDelegatedSigner

```dart
final class OZDelegatedSigner extends OZSmartAccountSigner {
  OZDelegatedSigner(String address);

  final String address;
}
```

A delegated signer using a Soroban address with the built-in `require_auth` verification mechanism. `address` is a Stellar account ID (`G…`) or contract ID (`C…`). The constructor throws `SmartAccountValidationException.invalidAddress` when the address is neither a valid account ID nor a valid contract ID.

`toScVal()` returns `Vec([Symbol("Delegated"), Address(address)])`.

### OZExternalSigner

```dart
final class OZExternalSigner extends OZSmartAccountSigner {
  OZExternalSigner(String verifierAddress, Uint8List keyData);

  final String verifierAddress;
  final Uint8List keyData;

  static OZExternalSigner webAuthn({
    required String verifierAddress,
    required Uint8List publicKey,
    required Uint8List credentialId,
  });

  static OZExternalSigner ed25519({
    required String verifierAddress,
    required Uint8List publicKey,
  });
}
```

An external signer that delegates signature verification to a Soroban verifier contract, enabling non-native schemes such as WebAuthn (secp256r1) and Ed25519.

- `verifierAddress`: Contract address (`C…`) of the signature verifier.
- `keyData`: Public-key bytes plus any additional authentication data (for WebAuthn this is `publicKey || credentialId`). Copied defensively on construction.

The unnamed constructor throws `SmartAccountValidationException.invalidAddress` when `verifierAddress` is not a valid contract ID, and `SmartAccountValidationException.invalidInput` when `keyData` is empty.

`toScVal()` returns `Vec([Symbol("External"), Address(verifierAddress), Bytes(keyData)])`.

**Static factories:**

- `webAuthn({required verifierAddress, required publicKey, required credentialId})`: Builds a WebAuthn signer. `publicKey` must be exactly `SmartAccountConstants.secp256r1PublicKeySize` (65) bytes starting with `SmartAccountConstants.uncompressedPubkeyPrefix` (`0x04`), and `credentialId` must be non-empty; the resulting `keyData` is `publicKey || credentialId`. Throws `SmartAccountValidationException.invalidInput` when any precondition fails.
- `ed25519({required verifierAddress, required publicKey})`: Builds an Ed25519 signer. `publicKey` must be exactly `SmartAccountConstants.ed25519PublicKeySize` (32) bytes; `keyData` is the public key itself. Throws `SmartAccountValidationException.invalidInput` when the length is wrong.

`OZExternalSigner` uses constant-time byte equality across `verifierAddress` and `keyData`, with a content-derived `hashCode`, so logically equal signers compare and hash equally.

---

## Signer Management

### OZSignerManager

Manages signers attached to context rules. Accessed via `kit.signerManager`. See [Signer Types](#signer-types) for the `OZSmartAccountSigner` hierarchy these methods operate on.

Each context rule may carry up to `OZConstants.maxSigners` signers (15). The signer manager supports three signer kinds:

- WebAuthn passkeys (secp256r1 via the WebAuthn verifier contract).
- Delegated signers (Stellar accounts or contracts authorising via Soroban's native `require_auth`).
- Ed25519 signers (32-byte Ed25519 keys verified by a deployed Ed25519 verifier contract).

Every state-changing method accepts an optional `List<OZSelectedSigner>`; an empty list (the default) routes through the single-signer pipeline that authorises with the connected passkey, while a non-empty list routes through `OZMultiSignerManager.submitWithMultipleSigners`.

#### addNewPasskeySigner

```dart
Future<OZAddPasskeySignerResult> addNewPasskeySigner({
  required int contextRuleId,
  required String userName,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Registers a new WebAuthn passkey and adds it as a signer to `contextRuleId` in one flow. Triggers a WebAuthn registration ceremony, stores the credential locally as pending, emits `OZSmartAccountEventCredentialCreated`, then delegates to `addPasskey` for the on-chain signer addition.

Returns an `OZAddPasskeySignerResult` carrying the new credential ID, the 65-byte uncompressed public key, and the on-chain `OZTransactionResult`.

#### addPasskey

```dart
Future<OZTransactionResult> addPasskey({
  required int contextRuleId,
  required Uint8List publicKey,
  required Uint8List credentialId,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Adds a previously-registered WebAuthn passkey as a signer to `contextRuleId`. Validates that `publicKey` is exactly 65 bytes starting with `0x04` and that `credentialId` is non-empty, constructs an `OZExternalSigner.webAuthn` against `config.webauthnVerifierAddress`, and submits the signer-addition transaction.

#### addDelegated

```dart
Future<OZTransactionResult> addDelegated({
  required int contextRuleId,
  required String address,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Adds a delegated signer (Stellar G-address or C-address) to `contextRuleId`. Address validation runs in `OZDelegatedSigner`.

#### addEd25519

```dart
Future<OZTransactionResult> addEd25519({
  required int contextRuleId,
  required String verifierAddress,
  required Uint8List publicKey,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Adds an Ed25519 signer to `contextRuleId`. Validates that `verifierAddress` is a contract address and that `publicKey` is exactly 32 bytes.

#### removeSigner

```dart
Future<OZTransactionResult> removeSigner({
  required int contextRuleId,
  required int signerId,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Removes a signer from `contextRuleId` by its on-chain signer ID.

The contract rejects removing the last signer from a rule that has no policies. Callers must ensure either at least one signer remains or that policies provide an authorisation path.

#### removeSignerBySigner

```dart
Future<OZTransactionResult> removeSignerBySigner({
  required int contextRuleId,
  required OZSmartAccountSigner signer,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Removes a signer from `contextRuleId` by matching the [`OZSmartAccountSigner`](#signer-types) value. Fetches the rule, parses it, finds the matching signer index via `OZSmartAccountBuilders.signersEqual`, and delegates to the ID-based `removeSigner`. Throws `SmartAccountValidationException.invalidInput` when the signer is not on the rule.

### Result Types

#### OZAddPasskeySignerResult

```dart
class OZAddPasskeySignerResult {
  const OZAddPasskeySignerResult({
    required String credentialId,
    required Uint8List publicKey,
    required OZTransactionResult transactionResult,
  });

  final String credentialId;
  final Uint8List publicKey;
  final OZTransactionResult transactionResult;
}
```

---

## Multi-Signer Operations

### OZMultiSignerManager

Manages multi-signature smart-account operations. Accessed via `kit.multiSignerManager`.

Signatures are collected sequentially in the order supplied via `selectedSigners`, enabling fail-fast behaviour on user cancellation. Each `OZSelectedSignerPasskey` triggers one WebAuthn authentication prompt; each `OZSelectedSignerWallet` signs via the configured `OZExternalWalletAdapter`; each `OZSelectedSignerEd25519` calls `OZExternalSignerManager.signEd25519AuthDigest(...)` using the signing source registered for that `(verifierAddress, publicKey)` pair. The connected passkey is not added implicitly; include an `OZSelectedSignerPasskey` referencing it when it should sign.

`submitWithMultipleSigners` hoists external-signer reconstruction outside the per-entry loop, so every `OZSelectedSignerPasskey` in the list must carry a non-null `keyData` before the call; the hoist throws once at the top if any entry omits it.

#### multiSignerTransfer

```dart
Future<OZTransactionResult> multiSignerTransfer({
  required String tokenContract,
  required String recipient,
  required String amount,
  int? decimals,
  required List<OZSelectedSigner> selectedSigners,
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
}) async
```

SEP-41 transfer signed by the explicit list of signers in `selectedSigners`. The decimal `amount` is converted to the token's base units, then the `transfer(from, to, amount)` host function is built and routed through `submitWithMultipleSigners`. `decimals` is the token decimal scale used to convert `amount`; when `null` (default), the token's on-chain `decimals()` is fetched via `fetchTokenDecimals`.

#### multiSignerContractCall

```dart
Future<OZTransactionResult> multiSignerContractCall({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  required List<OZSelectedSigner> selectedSigners,
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
}) async
```

Calls an arbitrary function on an external contract directly, with multi-signer authorisation. The smart account's matching `CallContract(target)` context rule is used for authorisation.

#### multiSignerExecuteAndSubmit

```dart
Future<OZTransactionResult> multiSignerExecuteAndSubmit({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  required List<OZSelectedSigner> selectedSigners,
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
}) async
```

Executes a contract call through the smart account's `execute()` entry point with multi-signer authorisation.

#### submitWithMultipleSigners

```dart
Future<OZTransactionResult> submitWithMultipleSigners({
  required XdrHostFunction hostFunction,
  required List<OZSelectedSigner> selectedSigners,
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
}) async
```

Shared low-level multi-signer signing pipeline. Validates the complete signer set, simulates the host function to discover authorization entries, signs every matching entry with every supplied signer (passkey signatures via WebAuthn, wallet and Ed25519 signatures via `kit.externalSigners`), re-simulates so the resource fees reflect the real signature payload size, and submits the final envelope via relayer or RPC. The three higher-level entry points (`multiSignerTransfer`, `multiSignerContractCall`, `multiSignerExecuteAndSubmit`) delegate here.

---

## External Signer Management

### OZExternalSignerManager

Manager for non-passkey signers used by multi-signer smart-account operations. Coordinates Stellar account signers that originate from Ed25519 secret keys (memory-only) or from external wallet connections through an `OZExternalWalletAdapter`, and Ed25519 external signers identified by a `(verifierAddress, publicKey)` tuple.

The kit constructs one `OZExternalSignerManager` at creation time, injecting the wallet and Ed25519 adapters from the config, and exposes it as `kit.externalSigners`. Access this instance to register in-memory keys at runtime or inspect registered signers. The manager can also be instantiated directly when needed outside a kit context.

```dart
OZExternalSignerManager({
  required String networkPassphrase,
  OZExternalWalletAdapter? walletAdapter,
  OZExternalEd25519SignerAdapter? ed25519Adapter,
})
```

**Constructor parameters** (stored internally; not exposed as readable properties):

- `networkPassphrase`: Network passphrase used when delegating to `walletAdapter`.
- `walletAdapter`: Optional external-wallet adapter. When `null`, only keypair-backed wallet signers are supported.
- `ed25519Adapter`: Optional adapter for out-of-process Ed25519 signing. Takes adapter-first precedence over in-memory keypairs when set.

#### hasWalletAdapter

```dart
bool get hasWalletAdapter
```

`true` when an external-wallet adapter is configured.

#### addFromSecret

```dart
Future<String> addFromSecret(String secretKey) async
```

Adds an Ed25519 keypair signer derived from `secretKey`. The keypair is held in memory only and never persisted. Returns the derived G-address. When a signer with the same address already exists, the keypair entry takes precedence.

Throws `SmartAccountSignerException.invalid` when the secret key is invalid.

#### canSignFor

```dart
Future<bool> canSignFor(String address) async
```

`true` when any managed signer (keypair or wallet) can sign for `address`. Keypair signers are checked first.

#### get

```dart
Future<OZExternalSignerInfo?> get(String address) async
```

Returns the signer info for `address`, preferring keypair entries over wallet entries.

#### getAll

```dart
Future<List<OZExternalSignerInfo>> getAll() async
```

Lists every managed signer. Keypair signers come first; wallet signers whose addresses overlap with keypair signers are skipped.

#### hasSigners

```dart
Future<bool> hasSigners() async
```

`true` when at least one signer is registered.

#### signAuthEntry

```dart
Future<OZSignAuthEntryResult> signAuthEntry(
  String address,
  String authEntry,
) async
```

Signs an authorisation-entry preimage for `address`. For keypair signers the base64-encoded preimage is decoded, SHA-256-hashed, and signed with the in-memory Ed25519 keypair. For wallet signers the call is delegated to `OZExternalWalletAdapter.signAuthEntry`. Keypair signers take precedence over wallet signers for the same address.

Throws `SmartAccountSignerException.notFound` when no signer is available for `address`; `SmartAccountTransactionException.signingFailed` on signing failure.

#### remove

```dart
Future<void> remove(String address) async
```

Removes the signer registered for `address`. Removes the keypair entry and asks the wallet adapter to release per-address state via `disconnectByAddress`.

#### removeAll

```dart
Future<void> removeAll() async
```

Removes every managed signer. Clears the keypair map, all Ed25519 keypair registrations, and disconnects every external wallet connection via `OZExternalWalletAdapter.disconnect`. The `ed25519Adapter` is immutable and is not affected by this call.

---

### Ed25519 Signing

The following methods and types support Ed25519 external signers identified by a `(verifierAddress, publicKey)` tuple. They complement the wallet-based signing methods above. See also [`OZSelectedSignerEd25519`](#ozselectedsignered25519) for how to reference these signers in multi-signer calls.

#### addEd25519FromRawKey

```dart
Uint8List addEd25519FromRawKey({
  required Uint8List secretKeyBytes,
  required String verifierAddress,
})
```

Derives an Ed25519 keypair from raw 32-byte seed material and registers it in memory under the `(verifierAddress, publicKey)` tuple. The keypair is never persisted to storage; it is cleared when `removeEd25519(...)` is called or when `removeAll()` runs.

If a keypair is already registered for the same tuple, it is silently overwritten.

For hardware wallets, HSMs, or remote signing services, supply an `OZExternalEd25519SignerAdapter` via `config.externalEd25519Adapter` at kit construction — the raw secret never enters process memory.

**Parameters:**

- `secretKeyBytes`: Exactly 32 bytes of raw Ed25519 seed material. This is not a Stellar S-strkey; it is the raw seed.
- `verifierAddress`: C-strkey of the Ed25519 verifier contract under which this key is registered on-chain.

**Returns:** The derived 32-byte Ed25519 public key as a `Uint8List`. Pass this as the `publicKey` argument of `OZSelectedSignerEd25519(verifierAddress: ..., publicKey: ...)` to route multi-signer signing through this keypair.

**Throws:** `SmartAccountValidationException.invalidInput` when `secretKeyBytes` is not exactly 32 bytes. `SmartAccountSignerException.invalid` when keypair construction fails.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const ed25519VerifierAddress =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

// 1. Construct the kit.
final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: 'Test SDF Network ; September 2015',
  accountWasmHash:
      '86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28',
  webauthnVerifierAddress:
      'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
);
final kit = OZSmartAccountKit.create(config: config);

// 2. Register the in-memory signing source at runtime.
// Raw 32-byte seed obtained from secure storage or a key derivation function.
final rawSeed = Uint8List.fromList([
  0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
  0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
  0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
  0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
]);

final ed25519PublicKey = kit.externalSigners.addEd25519FromRawKey(
  secretKeyBytes: rawSeed,
  verifierAddress: ed25519VerifierAddress,
);

// 3. Pass the identifier to the multi-signer call.
final signer = OZSelectedSignerEd25519(
  verifierAddress: ed25519VerifierAddress,
  publicKey: ed25519PublicKey,
);
```

See also: [`OZSelectedSignerEd25519`](#ozselectedsignered25519).

#### canSignEd25519For

```dart
bool canSignEd25519For({
  required String verifierAddress,
  required Uint8List publicKey,
})
```

Returns `true` when a signing source is available for the given `(verifierAddress, publicKey)` tuple. Checks the adapter first (adapter-first precedence rule): if `ed25519Adapter?.canSignFor(verifierAddress, publicKey)` returns `true`, this method returns `true` without consulting the in-memory registry. Falls back to checking whether an in-memory keypair is registered for the tuple.

**Parameters:**

- `verifierAddress`: C-strkey of the Ed25519 verifier contract.
- `publicKey`: 32-byte Ed25519 public key identifying the signer slot.

**Returns:** `true` when a signing source (adapter or in-memory keypair) can sign for this tuple.

#### signEd25519AuthDigest

```dart
Future<Uint8List> signEd25519AuthDigest({
  required String verifierAddress,
  required Uint8List publicKey,
  required Uint8List authDigest,
}) async
```

Produces a 64-byte Ed25519 signature over the supplied auth digest. Resolves the signing source using adapter-first precedence: the adapter is consulted first; if it claims it can sign, it signs. Otherwise the in-memory keypair registry is used. Throws when neither source is available.

The multi-signer pipeline calls this method automatically for each `OZSelectedSignerEd25519` entry in `selectedSigners`. Direct calls are available for advanced integrations that need to produce signatures outside the pipeline.

After the signing source returns the 64-byte signature, the pipeline locally verifies it against `publicKey` via `KeyPair.fromPublicKey(publicKey).verify(authDigest, signature)` before incorporating it into the authorization payload. A wrong signature throws `SmartAccountTransactionException.signingFailed`.

**Parameters:**

- `verifierAddress`: C-strkey of the Ed25519 verifier contract.
- `publicKey`: 32-byte Ed25519 public key identifying the signer slot.
- `authDigest`: 32-byte auth digest to sign, computed as `SHA-256(signaturePayload || contextRuleIds.toXDR())`.

**Returns:** 64-byte raw Ed25519 signature over `authDigest`.

**Throws:** `SmartAccountValidationException.invalidInput` (field `"selectedSigners"`) when no signing source is registered for the tuple; `SmartAccountTransactionException.signingFailed` when the adapter or in-memory keypair fails to produce a valid signature.

> **Quirk — adapter-first precedence**: when `ed25519Adapter` is set and its `canSignFor(verifierAddress, publicKey)` returns `true`, the adapter always signs, even if an in-memory keypair is also registered for the same tuple. To use only the in-memory keypair, construct the manager without supplying an `ed25519Adapter`.

> **Quirk — tuple-keyed storage**: the same 32-byte public key registered under two different verifier addresses is stored as two distinct entries. This matches the on-chain signer identity, where an `External(verifierAddress, publicKey)` entry is uniquely identified by both fields. Passing the wrong `verifierAddress` results in `SmartAccountValidationException.invalidInput` even when the public key is correct.

See also: [`OZExternalEd25519SignerAdapter`](#ozexternaled25519signeradapter), [`OZSelectedSignerEd25519`](#ozselectedsignered25519).

#### removeEd25519

```dart
void removeEd25519({
  required String verifierAddress,
  required Uint8List publicKey,
})
```

Removes the keypair registered under `(verifierAddress, publicKey)` from the in-memory registry. No-op when no keypair is registered for that tuple. The `ed25519Adapter` is not affected by this call.

**Parameters:**

- `verifierAddress`: C-strkey of the Ed25519 verifier contract.
- `publicKey`: 32-byte Ed25519 public key identifying the signer slot to remove.

---

### OZExternalEd25519SignerAdapter

```dart
abstract class OZExternalEd25519SignerAdapter {
  const OZExternalEd25519SignerAdapter();

  bool canSignFor(String verifierAddress, Uint8List publicKey);
  Future<Uint8List> signAuthDigest(Uint8List authDigest, Uint8List publicKey);
}
```

Adapter for out-of-process Ed25519 signing sources such as hardware wallets and remote signing services. Supply a conforming instance via `config.externalEd25519Adapter` at kit construction to intercept Ed25519 signing requests before the in-memory keypair registry is consulted.

`canSignFor(verifierAddress, publicKey)`:

- Called synchronously by the pipeline before every Ed25519 sign request.
- `verifierAddress` — C-strkey of the Ed25519 verifier contract.
- `publicKey` — 32-byte Ed25519 public key identifying the signer slot.
- Return `true` if and only if a subsequent `signAuthDigest(authDigest, publicKey)` call for the same key will succeed without error. The pipeline trusts this return value.

`signAuthDigest(authDigest, publicKey)`:

- Called only when `canSignFor` returned `true` for the same `publicKey`.
- `authDigest` — 32-byte digest computed as `SHA-256(signaturePayload || contextRuleIds.toXDR())`.
- `publicKey` — the same 32-byte Ed25519 public key passed to `canSignFor`.
- Returns a 64-byte raw Ed25519 signature over `authDigest`. The pipeline locally verifies the returned signature before incorporating it; a wrong signature throws `SmartAccountTransactionException.signingFailed`.
- Throws any error that prevents signing (hardware unavailable, user cancelled, etc.).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Example adapter for a hypothetical hardware wallet.
class MyHardwareWalletAdapter implements OZExternalEd25519SignerAdapter {
  const MyHardwareWalletAdapter();

  @override
  bool canSignFor(String verifierAddress, Uint8List publicKey) {
    // Check whether the hardware wallet holds the key for this public key.
    return _wallet.hasSigner(publicKey);
  }

  @override
  Future<Uint8List> signAuthDigest(
      Uint8List authDigest, Uint8List publicKey) async {
    // Request a 64-byte Ed25519 signature from the hardware wallet.
    return _wallet.sign(authDigest, publicKey);
  }
}

// Supply the adapter via config at kit construction.
final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: 'Test SDF Network ; September 2015',
  accountWasmHash:
      '86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28',
  webauthnVerifierAddress:
      'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
  externalEd25519Adapter: const MyHardwareWalletAdapter(),
);
final kit = OZSmartAccountKit.create(config: config);
```

> **Quirk — adapter-first precedence**: the adapter always signs when `canSignFor` returns `true`, even when an in-memory keypair is registered for the same `(verifierAddress, publicKey)` pair. To use only the in-memory keypair, construct the kit without supplying an `externalEd25519Adapter`.

See also: [`OZExternalSignerManager.signEd25519AuthDigest`](#signed25519authdigest).

### Supporting types

#### OZExternalSignerInfo

```dart
class OZExternalSignerInfo {
  const OZExternalSignerInfo({
    required String address,
    required OZExternalSignerType type,
    String? walletName,
    String? walletId,
  });
}
```

- `address`: Stellar G-address.
- `type`: `keypair` or `wallet`.
- `walletName`, `walletId`: Only meaningful when `type == wallet`.

#### OZExternalSignerType

```dart
enum OZExternalSignerType { keypair, wallet }
```

---

## Context Rule Management

### OZContextRuleManager

Manages context rules on the connected smart account. Accessed via `kit.contextRuleManager`.

A context rule pairs an `OZContextRuleType` match (default, call-contract, or create-contract) with a signer list and a policy list. When a transaction matches a rule, the smart account authorises it only if the rule's signer and policy requirements are met. Per-rule limits: at most `OZConstants.maxSigners` (15) signers, at most `OZConstants.maxPolicies` (5) policies.

Every state-changing method accepts an optional `List<OZSelectedSigner>` with the same semantics as on [OZSignerManager](#ozsignermanager): an empty list (the default) authorises with the connected passkey; a non-empty list routes through `OZMultiSignerManager.submitWithMultipleSigners`.

#### addContextRule

```dart
Future<OZTransactionResult> addContextRule({
  required OZContextRuleType contextType,
  required String name,
  int? validUntil,
  required List<OZSmartAccountSigner> signers,
  Map<String, OZPolicyInstallParams> policies =
      const <String, OZPolicyInstallParams>{},
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Adds a new context rule.

**Parameters:**

- `contextType`: The `OZContextRuleType` (default, call-contract, or create-contract).
- `name`: Human-readable rule name. Must be non-empty.
- `validUntil`: Optional expiration ledger. `null` means no expiration.
- `signers`: Signers attached to the rule. Must obey the per-rule maximum.
- `policies`: Map from policy contract address to its installation parameters as an `OZPolicyInstallParams`. Use a typed subclass such as `OZSimpleThresholdPolicyParams`, or `OZRawPolicyParams` to wrap a pre-encoded `XdrSCVal` for custom policies. Validated and ordered deterministically before submission.

Throws `SmartAccountValidationException.invalidInput` when the name is empty, when both `signers` and `policies` are empty, when the signer or policy limits are exceeded, or when any policy address is malformed.

#### getContextRule

```dart
Future<XdrSCVal> getContextRule(int id) async
```

Returns the raw `XdrSCVal` for the rule with the supplied on-chain `id`. Use `listContextRules` to obtain parsed `OZParsedContextRule` objects directly.

#### getContextRulesCount

```dart
Future<int> getContextRulesCount() async
```

Returns the number of currently active context rules on the connected smart account.

#### getAllContextRules

```dart
Future<List<XdrSCVal>> getAllContextRules({int? maxScanId}) async
```

Returns the raw `XdrSCVal` representation of every active context rule. Iterates monotonic IDs from 0 to `maxScanId` (defaulting to `config.maxContextRuleScanId`), skipping gaps from removed rules, and stops once the resolved count equals the on-chain reported active count.

#### listContextRules

```dart
Future<List<OZParsedContextRule>> listContextRules({int? maxScanId}) async
```

Returns every active context rule parsed into an `OZParsedContextRule`.

#### updateName

```dart
Future<OZTransactionResult> updateName({
  required int id,
  required String name,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Updates the human-readable name of a context rule. Throws `SmartAccountValidationException.invalidInput` for an empty name.

#### updateValidUntil

```dart
Future<OZTransactionResult> updateValidUntil({
  required int id,
  int? validUntil,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Updates the expiration ledger of a context rule. Pass `null` to remove the expiration (encoded on-chain as `Option::None`).

#### removeContextRule

```dart
Future<OZTransactionResult> removeContextRule({
  required int id,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Removes a context rule.

### Supporting types

See [Builder Helpers](#builder-helpers) for `OZContextRuleType` (sealed: `OZContextRuleTypeDefault`, `OZContextRuleTypeCallContract`, `OZContextRuleTypeCreateContract`), `OZParsedContextRule`, and `OZBuilders`.

---

## Policy Management

### OZPolicyManager

Manages policies on context rules. Accessed via `kit.policyManager`.

A context rule may carry up to `OZConstants.maxPolicies` (5) policies. Every policy must be satisfied for the rule to authorise a transaction. Three convenience helpers are provided for the built-in policy types; custom policy contracts use `addPolicy` directly with an `OZPolicyInstallParams` (a typed subclass, or `OZRawPolicyParams` wrapping a pre-encoded `XdrSCVal`).

Every state-changing method accepts an optional `List<OZSelectedSigner>` with the same semantics as on [OZSignerManager](#ozsignermanager).

#### addSimpleThreshold

```dart
Future<OZTransactionResult> addSimpleThreshold({
  required int contextRuleId,
  required String policyAddress,
  required int threshold,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Installs an `OZSimpleThresholdPolicyParams` policy at `policyAddress` requiring at least `threshold` equal-weight signers from the rule's signer list.

#### addWeightedThreshold

```dart
Future<OZTransactionResult> addWeightedThreshold({
  required int contextRuleId,
  required String policyAddress,
  required Map<OZSmartAccountSigner, int> signerWeights,
  required int threshold,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Installs an `OZWeightedThresholdPolicyParams` policy where each signer carries a vote weight and the sum of approving-signer weights must reach `threshold`.

#### addSpendingLimit

```dart
Future<OZTransactionResult> addSpendingLimit({
  required int contextRuleId,
  required String policyAddress,
  required String spendingLimit,
  required int periodLedgers,
  int decimals = 7,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Installs an `OZSpendingLimitPolicyParams` policy capping the total amount spent within a rolling ledger window. The decimal `spendingLimit` string is converted to the token's base units using `decimals`. `decimals` defaults to `7`; this method has no token-contract parameter and does not fetch the scale automatically.

#### addPolicy

```dart
Future<OZTransactionResult> addPolicy({
  required int contextRuleId,
  required String policyAddress,
  required OZPolicyInstallParams installParams,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Adds a policy with custom installation parameters. This is the generic entry point used by `addSimpleThreshold`, `addWeightedThreshold`, and `addSpendingLimit`. Call directly for custom policy contracts whose installation parameters are not covered by the convenience helpers.

**Parameters:**

- `contextRuleId`: On-chain id of the rule the policy is installed on.
- `policyAddress`: Policy contract C-address.
- `installParams`: The policy's installation parameters as an `OZPolicyInstallParams`. Use a typed subclass such as `OZSimpleThresholdPolicyParams`, or `OZRawPolicyParams` to wrap a pre-encoded `XdrSCVal` for custom policies.
- `selectedSigners`: Empty routes the single-signer passkey path; non-empty routes the multi-signer pipeline.
- `forceMethod`: Overrides direct-vs-relayer submission.

#### removePolicy

```dart
Future<OZTransactionResult> removePolicy({
  required int contextRuleId,
  required int policyId,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Removes a policy by its on-chain policy ID.

#### removePolicyByAddress

```dart
Future<OZTransactionResult> removePolicyByAddress({
  required int contextRuleId,
  required String policyAddress,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
}) async
```

Removes a policy by matching the policy contract address. Fetches the rule, parses it, finds the policy index, and delegates to the ID-based `removePolicy`.

#### Static helpers

```dart
static List<XdrSCMapEntry> sortMapByKeyXdr(List<XdrSCMapEntry> entries)
// Test utility; consumer flows typically do not need this.
static List<int> scValToXdrBytes(XdrSCVal scVal)
```

`sortMapByKeyXdr` sorts a list of `XdrSCMapEntry` lexicographically by the XDR-byte representation of their keys, matching the Soroban deterministic-encoding requirement. `scValToXdrBytes` encodes an `XdrSCVal` to its raw XDR byte representation; exposed for tests verifying deterministic ordering.

### Policy parameter types

The policy parameter classes are exposed as a sealed hierarchy under `OZPolicyInstallParams`. `toScVal()` encodes a parameter set to its on-chain `XdrSCVal` map. Pass an instance to `OZContextRuleManager.addContextRule` or `OZPolicyManager.addPolicy`; the manager encodes it internally. The convenience helpers (`addSimpleThreshold`, `addWeightedThreshold`, `addSpendingLimit`) build the typed parameters for you.

#### OZPolicyInstallParams (sealed)

```dart
sealed class OZPolicyInstallParams {
  const OZPolicyInstallParams();
  XdrSCVal toScVal();
}
```

#### OZSimpleThresholdPolicyParams

```dart
final class OZSimpleThresholdPolicyParams extends OZPolicyInstallParams {
  const OZSimpleThresholdPolicyParams({required int threshold});
  final int threshold;
}
```

#### OZWeightedThresholdPolicyParams

```dart
final class OZWeightedThresholdPolicyParams extends OZPolicyInstallParams {
  OZWeightedThresholdPolicyParams({
    required Map<OZSmartAccountSigner, int> signerWeights,
    required int threshold,
  });
  final Map<OZSmartAccountSigner, int> signerWeights;
  final int threshold;
}
```

#### OZSpendingLimitPolicyParams

```dart
final class OZSpendingLimitPolicyParams extends OZPolicyInstallParams {
  const OZSpendingLimitPolicyParams({
    required BigInt spendingLimit,
    required int periodLedgers,
  });
  final BigInt spendingLimit;
  final int periodLedgers;
}
```

`spendingLimit` is expressed in the token's base units. To construct from a decimal string, use the convenience helper `OZPolicyManager.addSpendingLimit`.

#### OZRawPolicyParams

```dart
final class OZRawPolicyParams extends OZPolicyInstallParams {
  const OZRawPolicyParams(XdrSCVal installParams);
  final XdrSCVal installParams;
}
```

Escape hatch for policy contracts whose install parameters are not modelled by a dedicated subclass. Wraps a pre-encoded `XdrSCVal`, which `toScVal()` returns unchanged.

---

## Events

> **Scope: SDK lifecycle events only.** `kit.events` emits **kit-level** events (wallet connected/disconnected, credential created/deleted, session expired, transaction signed/submitted). It does **not** emit on-chain smart-account contract events such as `SignerAdded`, `SignerRemoved`, `PolicyInstalled`, `PolicyRemoved`, `ContextRuleAdded`, or `ContextRuleRemoved`. Those are emitted by the OpenZeppelin smart-account contract and must be queried directly via Soroban RPC, filtering on the account's contract ID:
>
> ```dart
> final response = await kit.sorobanServer.getEvents(GetEventsRequest(
>   startLedger: fromLedger,
>   filters: [EventFilter(type: 'contract', contractIds: [contractId])],
> ));
> // Each event's topic and value are base64-XDR-encoded SCVal entries.
> ```

The kit emits lifecycle events through `kit.events`, an `OZSmartAccountEventEmitter`. Event subscription is callback-based, not `Stream`-based. Consumers wanting `Stream` semantics can wrap `addListener` into a `StreamController`.

### OZSmartAccountEventEmitter

```dart
class OZSmartAccountEventEmitter {
  OZSmartAccountEventEmitter();

  void setErrorHandler(OZSmartAccountEventErrorHandler? handler);
  void Function() addListener(OZSmartAccountEventListener listener);
  void Function() on<E extends OZSmartAccountEvent>(void Function(E event) listener);
  void Function() once<E extends OZSmartAccountEvent>(void Function(E event) listener);
  void removeAllListeners([String? eventType]);
  int listenerCount(String eventType);
  void emit(OZSmartAccountEvent event);
}
```

- `setErrorHandler`: Sets a handler invoked when a listener throws. Pass `null` to silently swallow listener errors.
- `addListener`: Subscribes a global listener that receives every event. Returns an idempotent unsubscribe function.
- `on<E>`: Subscribes a typed listener for events whose runtime type is `E`. Returns an idempotent unsubscribe function.
- `once<E>`: Subscribes a typed listener for the first matching event; auto-unsubscribes after firing.
- `removeAllListeners`: Removes typed listeners for `eventType` when supplied; removes both typed and global listeners when `null`.
- `listenerCount`: Number of listeners registered for `eventType` (typed plus global).
- `emit`: Dispatches `event` to matching listeners. Used by managers; not normally called by consumers.

### Typedefs

```dart
typedef OZSmartAccountEventListener = void Function(OZSmartAccountEvent event);
typedef OZSmartAccountEventErrorHandler = void Function(
  OZSmartAccountEvent event,
  Object error,
  StackTrace stackTrace,
);
```

### Event hierarchy

```dart
sealed class OZSmartAccountEvent {
  const OZSmartAccountEvent();
  String get eventTypeName;
}
```

All concrete event arms are `final class` subclasses.

#### OZSmartAccountEventWalletConnected

```dart
final class OZSmartAccountEventWalletConnected extends OZSmartAccountEvent {
  const OZSmartAccountEventWalletConnected({
    required String contractId,
    required String credentialId,
  });
  final String contractId;
  final String credentialId;
  // eventTypeName: 'WalletConnected'
}
```

Emitted by wallet creation, connection, and deploy-pending paths after the kit's state is set.

#### OZSmartAccountEventWalletDisconnected

```dart
final class OZSmartAccountEventWalletDisconnected extends OZSmartAccountEvent {
  const OZSmartAccountEventWalletDisconnected({required String contractId});
  final String contractId;
  // eventTypeName: 'WalletDisconnected'
}
```

Emitted by `kit.disconnect()` when a wallet was connected at the time of the call.

#### OZSmartAccountEventCredentialCreated

```dart
final class OZSmartAccountEventCredentialCreated extends OZSmartAccountEvent {
  const OZSmartAccountEventCredentialCreated({required OZStoredCredential credential});
  final OZStoredCredential credential;
  // eventTypeName: 'CredentialCreated'
}
```

Emitted by `createWallet` and `addNewPasskeySigner` after the pending credential is persisted.

#### OZSmartAccountEventCredentialDeleted

```dart
final class OZSmartAccountEventCredentialDeleted extends OZSmartAccountEvent {
  const OZSmartAccountEventCredentialDeleted({required String credentialId});
  final String credentialId;
  // eventTypeName: 'CredentialDeleted'
}
```

Emitted by `credentialManager.deleteCredential` on successful removal.

#### OZSmartAccountEventSessionExpired

```dart
final class OZSmartAccountEventSessionExpired extends OZSmartAccountEvent {
  const OZSmartAccountEventSessionExpired({
    required String contractId,
    required String credentialId,
  });
  final String contractId;
  final String credentialId;
  // eventTypeName: 'SessionExpired'
}
```

Emitted by `connectWallet` when an expired session is found and auto-cleared.

#### OZSmartAccountEventCredentialSyncFailed

```dart
final class OZSmartAccountEventCredentialSyncFailed extends OZSmartAccountEvent {
  const OZSmartAccountEventCredentialSyncFailed({
    required String credentialId,
    required Object error,
    StackTrace? stackTrace,
  });
  final String credentialId;
  final Object error;
  final StackTrace? stackTrace;
  // eventTypeName: 'CredentialSyncFailed'
}
```

Emitted by `credentialManager.sync` when a non-fatal exception is swallowed. Programmer errors (`Error` subclasses such as `StateError`, `ArgumentError`) are not routed through this event and continue to propagate.

#### OZSmartAccountEventTransactionSigned

```dart
final class OZSmartAccountEventTransactionSigned extends OZSmartAccountEvent {
  const OZSmartAccountEventTransactionSigned({
    required String contractId,
    required String? credentialId,
  });
  final String contractId;
  final String? credentialId;
  // eventTypeName: 'TransactionSigned'
}
```

Emitted by `transactionOperations.submit` after every required signature has been collected. `credentialId` is `null` when only external signers were involved.

#### OZSmartAccountEventTransactionSubmitted

```dart
final class OZSmartAccountEventTransactionSubmitted extends OZSmartAccountEvent {
  const OZSmartAccountEventTransactionSubmitted({
    required String hash,
    required bool success,
  });
  final String hash;
  final bool success;
  // eventTypeName: 'TransactionSubmitted'
}
```

Emitted after sending the signed transaction to Soroban RPC or the relayer. `success` indicates only that the network node accepted the submission, not on-chain inclusion.

### Subscription patterns

```dart
// Assuming `kit` is constructed as in Quick Start.
// Global subscription: receive every event.
final unsubscribeAll = kit.events.addListener((event) {
  if (event is OZSmartAccountEventWalletConnected) {
    print('Connected to ${event.contractId}');
  }
});

// Typed subscription: receive a single arm.
final unsubscribeTx = kit.events.on<OZSmartAccountEventTransactionSubmitted>(
  (event) => print('tx ${event.hash} submitted (success=${event.success})'),
);

// One-shot subscription.
kit.events.once<OZSmartAccountEventWalletDisconnected>(
  (event) => print('disconnected once: ${event.contractId}'),
);

// Always release subscriptions in a finally block.
unsubscribeAll();
unsubscribeTx();
```

---

## Errors

Every smart-account exception lives in `core/smart_account_errors.dart` and is sealed under `SmartAccountException`. Every exception carries a categorised `SmartAccountErrorCode`, a human-readable `message`, and an optional underlying `cause` preserved from the originating throwable.

### SmartAccountErrorCode

> **Two independent namespaces share the 3xxx range.** `SmartAccountErrorCode` (SDK, surfaced via `SmartAccountException.code`) and the on-chain OpenZeppelin smart-account contract enum (surfaced in simulation / result XDR, typically wrapped in `SmartAccountTransactionSimulationFailed`) both use 3xxx codes. They arrive through different channels and do not collide at runtime: check the exception type first to determine which namespace a code belongs to.
>
> | Numeric code | SDK meaning (`SmartAccountErrorCode`) | On-chain meaning (OZ contract) |
> |---|---|---|
> | 3002 | `credentialAlreadyExists` | `UnvalidatedContext` |
> | 3003 | `credentialInvalid` | `ExternalVerificationFailed` |
>
> Reference constants for a subset of these on-chain contract codes are declared in [`OZContractErrorCodes`](#oz-contract-error-codes); the SDK surfaces the raw error and callers compare the extracted code against them.


```dart
enum SmartAccountErrorCode {
  invalidConfig(1001),
  missingConfig(1002),
  walletNotConnected(2001),
  walletAlreadyExists(2002),
  walletNotFound(2003),
  credentialNotFound(3001),
  credentialAlreadyExists(3002),
  credentialInvalid(3003),
  credentialDeploymentFailed(3004),
  webauthnRegistrationFailed(4001),
  webauthnAuthenticationFailed(4002),
  webauthnNotSupported(4003),
  webauthnCancelled(4004),
  transactionSimulationFailed(5001),
  transactionSigningFailed(5002),
  transactionSubmissionFailed(5003),
  transactionTimeout(5004),
  signerNotFound(6001),
  signerInvalid(6002),
  invalidAddress(7001),
  invalidAmount(7002),
  invalidInput(7003),
  storageReadFailed(8001),
  storageWriteFailed(8002),
  sessionExpired(9001),
  sessionInvalid(9002),
  indexerRequestFailed(10001),
  indexerTimeout(10002);

  const SmartAccountErrorCode(this.code);
  final int code;
}
```

Codes are range-partitioned: `1xxx` configuration, `2xxx` wallet state, `3xxx` credential, `4xxx` WebAuthn, `5xxx` transaction, `6xxx` signer, `7xxx` validation, `8xxx` storage, `9xxx` session, `10xxx` indexer.

### Exception hierarchy

```dart
sealed class SmartAccountException implements Exception {
  const SmartAccountException(SmartAccountErrorCode code, String message, [Object? cause]);
  final SmartAccountErrorCode code;
  final String message;
  final Object? cause;

  static SmartAccountException wrapError(
    Object err, {
    SmartAccountErrorCode defaultCode = SmartAccountErrorCode.invalidInput,
  });
}
```

`wrapError` is the boundary helper that wraps any throwable into the corresponding subclass. If `err` is already a `SmartAccountException` it is returned unchanged; otherwise the message (or `toString()`) is wrapped in the `SmartAccountException` subclass corresponding to `defaultCode`, preserving the original throwable as `cause`.

Catch `SmartAccountException` for general handling and switch on concrete subtypes when fine-grained recovery is required.

### SmartAccountConfigurationException

```dart
sealed class SmartAccountConfigurationException extends SmartAccountException {
  static SmartAccountConfigurationException invalidConfig(String details, {Object? cause});
  static SmartAccountConfigurationException missingConfig(String param, {Object? cause});
}

final class SmartAccountInvalidConfig extends SmartAccountConfigurationException { }
final class SmartAccountMissingConfig extends SmartAccountConfigurationException { }
```

**Error Codes**: 1001 (invalidConfig), 1002 (missingConfig)

---

### SmartAccountWalletException

```dart
sealed class SmartAccountWalletException extends SmartAccountException {
  static SmartAccountWalletException notConnected({String? details, Object? cause});
  static SmartAccountWalletException alreadyExists(String identifier, {Object? cause});
  static SmartAccountWalletException notFound(String identifier, {Object? cause});
}

final class SmartAccountWalletNotConnected extends SmartAccountWalletException { }
final class SmartAccountWalletAlreadyExists extends SmartAccountWalletException { }
final class SmartAccountWalletNotFound extends SmartAccountWalletException { }
```

**Error Codes**: 2001 (walletNotConnected), 2002 (walletAlreadyExists), 2003 (walletNotFound)

---

### SmartAccountCredentialException

```dart
sealed class SmartAccountCredentialException extends SmartAccountException {
  static SmartAccountCredentialException notFound(String credentialId, {Object? cause});
  static SmartAccountCredentialException alreadyExists(String credentialId, {Object? cause});
  static SmartAccountCredentialException invalid(String details, {Object? cause});
  static SmartAccountCredentialException deploymentFailed(String details, {Object? cause});
}

final class SmartAccountCredentialNotFound extends SmartAccountCredentialException { }
final class SmartAccountCredentialAlreadyExists extends SmartAccountCredentialException { }
final class SmartAccountCredentialInvalid extends SmartAccountCredentialException { }
final class SmartAccountCredentialDeploymentFailed extends SmartAccountCredentialException { }
```

**Error Codes**: 3001-3004

---

### WebAuthnException

```dart
sealed class WebAuthnException extends SmartAccountException {
  static WebAuthnException registrationFailed(String details, {Object? cause});
  static WebAuthnException authenticationFailed(String details, {Object? cause});
  static WebAuthnException notSupported({String? details, Object? cause});
  static WebAuthnException cancelled({Object? cause});
}

final class WebAuthnRegistrationFailed extends WebAuthnException { }
final class WebAuthnAuthenticationFailed extends WebAuthnException { }
final class WebAuthnNotSupported extends WebAuthnException { }
final class WebAuthnCancelled extends WebAuthnException { }
```

**Error Codes**: 4001-4004

---

### SmartAccountTransactionException

```dart
sealed class SmartAccountTransactionException extends SmartAccountException {
  static SmartAccountTransactionException simulationFailed(String details, {Object? cause});
  static SmartAccountTransactionException signingFailed(String details, {Object? cause});
  static SmartAccountTransactionException submissionFailed(String details, {Object? cause});
  static SmartAccountTransactionException timeout({String? details, Object? cause});
}

final class SmartAccountTransactionSimulationFailed extends SmartAccountTransactionException { }
final class SmartAccountTransactionSigningFailed extends SmartAccountTransactionException { }
final class SmartAccountTransactionSubmissionFailed extends SmartAccountTransactionException { }
final class SmartAccountTransactionTimeout extends SmartAccountTransactionException { }
```

**Error Codes**: 5001-5004

---

### SmartAccountSignerException

```dart
sealed class SmartAccountSignerException extends SmartAccountException {
  static SmartAccountSignerException notFound(String identifier, {Object? cause});
  static SmartAccountSignerException invalid(String details, {Object? cause});
}

final class SmartAccountSignerNotFound extends SmartAccountSignerException { }
final class SmartAccountSignerInvalid extends SmartAccountSignerException { }
```

**Error Codes**: 6001 (signerNotFound), 6002 (signerInvalid)

---

### SmartAccountValidationException

```dart
sealed class SmartAccountValidationException extends SmartAccountException {
  static SmartAccountValidationException invalidAddress(String address, {Object? cause});
  static SmartAccountValidationException invalidAmount(String value, {String? reason, Object? cause});
  static SmartAccountValidationException invalidInput(String field, String reason, {Object? cause});
}

final class SmartAccountInvalidAddress extends SmartAccountValidationException { }
final class SmartAccountInvalidAmount extends SmartAccountValidationException { }
final class SmartAccountInvalidInput extends SmartAccountValidationException { }
```

**Error Codes**: 7001 (invalidAddress), 7002 (invalidAmount), 7003 (invalidInput)

---

### SmartAccountStorageException

```dart
sealed class SmartAccountStorageException extends SmartAccountException {
  static SmartAccountStorageException readFailed(String key, {Object? cause});
  static SmartAccountStorageException writeFailed(String key, {Object? cause});
}

final class SmartAccountStorageReadFailed extends SmartAccountStorageException { }
final class SmartAccountStorageWriteFailed extends SmartAccountStorageException { }
```

**Error Codes**: 8001-8002

---

### SmartAccountSessionException

```dart
sealed class SmartAccountSessionException extends SmartAccountException { }

final class SmartAccountSessionExpired extends SmartAccountSessionException { }
final class SmartAccountSessionInvalid extends SmartAccountSessionException { }
```

**Error Codes**: 9001 (sessionExpired), 9002 (sessionInvalid)

---

### SmartAccountIndexerException

```dart
sealed class SmartAccountIndexerException extends SmartAccountException { }

final class SmartAccountIndexerRequestFailed extends SmartAccountIndexerException { }
final class SmartAccountIndexerTimeout extends SmartAccountIndexerException { }
```

**Error Codes**: 10001-10002

### OZ contract error codes

```dart
class OZContractErrorCodes {
  static const int mathOverflow = 3012;
  static const int keyDataTooLarge = 3013;
  static const int contextRuleIdsLengthMismatch = 3014;
  static const int nameTooLong = 3015;
  static const int unauthorizedSigner = 3016;
}
```

Reference constants for a subset of the numeric error codes the OpenZeppelin smart-account contract returns for failed on-chain calls. The raw error is surfaced in the `error` field on `OZTransactionResult`; the SDK does not parse the code, so extract it from the message and compare against these constants.

### Cancellation semantics

Every cancellable async method accepts an optional `dio.CancelToken`. Cancellation surfaces as:

- `SmartAccountTransactionException.submissionFailed('Operation cancelled', cause: <DioException of type cancel>)` for kit-level transaction operations.
- `OZRelayerResponse(success: false, error: 'Request cancelled')` for the relayer client; the relayer never throws after construction.
- `SmartAccountIndexerException.requestFailed('Request cancelled')` for the indexer client.

---

## Constants

### SmartAccountConstants

```dart
class SmartAccountConstants {
  static const int ed25519PublicKeySize = 32;
  static const int secp256r1PublicKeySize = 65;
  static const int uncompressedPubkeyPrefix = 0x04;
}
```

Cryptographic and protocol-level constants for smart-account operations.

### OZConstants

```dart
class OZConstants {
  static const int defaultSessionExpiryMs = 604800000;          // 7 days
  static const int defaultIndexerTimeoutMs = 10000;             // 10 s
  static const int defaultRelayerTimeoutMs = 360000;            // 6 min
  static const int friendbotReserveXlm = 5;
  static const int defaultTimeoutSeconds = 30;
  static const int maxSigners = 15;                             // per context rule
  static const int maxPolicies = 5;                             // per context rule
  static const String clientNameHeader = 'X-Client-Name';
  static const String clientVersionHeader = 'X-Client-Version';
  static const String clientName = 'flutter-stellar-sdk';
  static const int maxIndexerResponseBytes = 1 * 1024 * 1024;   // 1 MiB
  static const int maxRelayerResponseBytes = 256 * 1024;        // 256 KiB
  static const int maxIndexerConnectTimeoutMs = 10000;
  static const int maxRelayerConnectTimeoutMs = 30000;
}
```

Tuning constants for HTTP timeouts, response-size caps, client identification headers, and on-chain limits.

### Default indexer URLs

`OZIndexerClient.defaultIndexerUrls` ships well-known indexer URLs for the two standard Stellar networks:

- Testnet (`Test SDF Network ; September 2015`): `https://smart-account-indexer.sdf-ecosystem.workers.dev`
- Mainnet (`Public Global Stellar Network ; September 2015`): `https://smart-account-indexer-mainnet.sdf-ecosystem.workers.dev`

No default relayer URL ships; the relayer is opt-in via `config.relayerUrl`.

### Platform channel names

The platform-bridge classes use the following Flutter method-channel names:

- WebAuthn: `com.soneso.stellar_flutter_sdk/smartaccount/webauthn`
- Storage: `com.soneso.stellar_flutter_sdk/smartaccount/storage`

These names are part of the public contract between the SDK and consumers who supply their own native overlays.

### OZLocalStorageAdapter and OZIndexedDBStorageAdapter defaults

The web storage facades expose the following static defaults:

- `OZLocalStorageAdapter.defaultKeyPrefix`: `'stellar_sa_'`
- `OZIndexedDBStorageAdapter.defaultDbName`: `'stellar_smart_account'`

---

## WebAuthn Provider

### WebAuthnProvider abstract class

```dart
abstract class WebAuthnProvider {
  const WebAuthnProvider();

  /// Default operation timeout in milliseconds (60 s), used by the shipped
  /// providers when no explicit timeout is supplied.
  static const int defaultTimeoutMs = 60000;

  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  });

  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<WebAuthnAllowCredential>? allowCredentials,
  });
}
```

Pluggable interface for WebAuthn ceremonies. The kit calls `register` during `createWallet` / `addNewPasskeySigner` and `authenticate` during `connectWallet(prompt: true)` / `authenticatePasskey` and the transaction signing pipeline.

**Conformance requirements:**

- The `challenge` parameter must be used as-is in the WebAuthn request. For registration it carries the deployment binding; for authentication it carries the authorisation payload hash.
- Implementations should throw `WebAuthnException` subclasses (`WebAuthnRegistrationFailed`, `WebAuthnAuthenticationFailed`, `WebAuthnNotSupported`, `WebAuthnCancelled`) on failure, unsupported environment, or user cancellation.
- Implementations performing native platform calls (Apple AuthenticationServices, Android Credential Manager, browser WebAuthn) typically must run on the platform's UI thread. Such implementations should declare any isolate-affinity restrictions in their own dartdoc.

### Result types

#### WebAuthnAuthenticationResult

```dart
class WebAuthnAuthenticationResult {
  const WebAuthnAuthenticationResult({
    required Uint8List credentialId,
    required Uint8List authenticatorData,
    required Uint8List clientDataJSON,
    required Uint8List signature,
  });

  final Uint8List credentialId;
  final Uint8List authenticatorData;
  final Uint8List clientDataJSON;
  final Uint8List signature;
}
```

- `credentialId`: Raw WebAuthn credential ID bytes.
- `authenticatorData`: Raw authenticator data.
- `clientDataJSON`: Raw client data (UTF-8 bytes).
- `signature`: ECDSA signature in DER format. The SDK normalises this to a 64-byte compact `r || s` low-S form before submitting on-chain.

#### WebAuthnRegistrationResult

```dart
class WebAuthnRegistrationResult {
  const WebAuthnRegistrationResult({
    required Uint8List credentialId,
    required Uint8List publicKey,
    required Uint8List attestationObject,
    List<String>? transports,
    String? deviceType,
    bool? backedUp,
  });

  final Uint8List credentialId;
  final Uint8List publicKey;
  final Uint8List attestationObject;
  final List<String>? transports;
  final String? deviceType;
  final bool? backedUp;
}
```

- `credentialId`: Raw credential ID.
- `publicKey`: Uncompressed secp256r1 public key (65 bytes, starting with `0x04`). Primary extraction path; providers should populate this directly when possible.
- `attestationObject`: Raw attestation object; used by `SmartAccountUtils.extractPublicKeyFromRegistration` when the public key needs three-strategy fallback decoding.
- `transports`: Optional transport hints (`usb`, `nfc`, `ble`, `internal`, `hybrid`).
- `deviceType`: `singleDevice` for hardware keys, `multiDevice` for synced passkeys.
- `backedUp`: Whether the passkey is backed up or synced.

### WebAuthnAllowCredential

```dart
class WebAuthnAllowCredential {
  const WebAuthnAllowCredential({required Uint8List id, List<String>? transports});

  final Uint8List id;
  final List<String>? transports;

  static WebAuthnAllowCredential fromId(Uint8List id);
  static List<WebAuthnAllowCredential> fromIds(List<Uint8List> ids);
}
```

Credential descriptor pairing a raw credential ID with optional transport hints, used to constrain which passkeys the authenticator offers during `authenticate`. When `transports` is `null` the authenticator picks the transport.

### PlatformWebAuthnProvider (mobile)

```dart
class PlatformWebAuthnProvider implements WebAuthnProvider {
  PlatformWebAuthnProvider({
    required String rpId,
    required String rpName,
    int timeout = WebAuthnProvider.defaultTimeoutMs,
    String? authenticatorAttachment,
    MethodChannel? methodChannel,
  });

  final String rpId;
  final String rpName;
  final int timeout;
  final String? authenticatorAttachment;
}
```

Dispatches WebAuthn calls to the native platform's plugin via the `com.soneso.stellar_flutter_sdk/smartaccount/webauthn` method channel. The Android side uses the AndroidX Credential Manager API (Android 9+); the Apple side uses the `AuthenticationServices` framework on supported Apple platforms (Apple WebAuthn requires recent OS versions).

**Constructor parameters:**

- `rpId`: Relying-party identifier (domain name). Must match the domain declared in the platform's associated-domains configuration.
- `rpName`: Human-readable relying-party name shown in the system passkey prompt.
- `timeout`: WebAuthn ceremony timeout in milliseconds. Defaults to `WebAuthnProvider.defaultTimeoutMs` (60 s).
- `authenticatorAttachment`: Optional `"platform"` or `"cross-platform"` hint. `null` (the default) allows both. Currently ignored by the Apple-side implementation.
- `methodChannel`: Test-only override of the method channel.

**Platform requirements:**

- On Android targets, consumers must host a Digital Asset Links file at `https://<rpId>/.well-known/assetlinks.json` linking the relying-party domain to the consumer app's signing certificate.
- On Apple targets, consumers must declare the relying-party domain in their app's `.entitlements` under `com.apple.developer.associated-domains` with a `webcredentials:<rpId>` entry, and serve the matching Apple App Site Association file at `https://<rpId>/.well-known/apple-app-site-association`.

**Isolate affinity:** must be invoked from the root isolate. Background isolates do not have a foreground activity or window and any call from such an isolate fails with `WebAuthnRegistrationFailed` or `WebAuthnAuthenticationFailed`.

### BrowserWebAuthnProvider (web)

```dart
class BrowserWebAuthnProvider extends WebAuthnProvider {
  BrowserWebAuthnProvider({
    required String rpId,
    required String rpName,
    int timeoutMs = WebAuthnProvider.defaultTimeoutMs,
  });
}
```

Bridges through `navigator.credentials.create()` / `.get()` to the browser's WebAuthn API. Requests COSE algorithm `-7` (ES256, secp256r1) during registration and applies a three-strategy public-key extraction.

The class facade is selected by conditional export: on web the real implementation is used; on non-web targets a stub is selected so cross-target code that holds a typed handle compiles. Every method on the stub throws `UnsupportedError` with guidance to use `PlatformWebAuthnProvider` on mobile.

---

## Storage Adapter

### OZStorageAdapter abstract class

```dart
abstract class OZStorageAdapter {
  Future<void> save(OZStoredCredential credential);
  Future<OZStoredCredential?> get(String credentialId);
  Future<List<OZStoredCredential>> getByContract(String contractId);
  Future<List<OZStoredCredential>> getAll();
  Future<void> delete(String credentialId);
  Future<void> update(String credentialId, OZStoredCredentialUpdate updates);
  Future<void> clear();
  Future<void> saveSession(OZStoredSession session);
  Future<OZStoredSession?> getSession();
  Future<void> clearSession();
}
```

Pluggable persistence layer for smart-account credentials and sessions. Implementations must be safe for concurrent calls from a single Dart isolate; cross-isolate or cross-process implementations are responsible for any additional synchronisation.

`save` has upsert semantics. `delete` is silently a no-op when no credential matches. `update` throws `SmartAccountCredentialException.notFound` when the target credential does not exist. `getSession` auto-clears expired sessions and returns `null`, so callers always observe "valid session or none".

### Supporting types

#### OZStoredCredential

```dart
class OZStoredCredential {
  OZStoredCredential({
    required String credentialId,
    required Uint8List publicKey,
    String? contractId,
    OZCredentialDeploymentStatus deploymentStatus = OZCredentialDeploymentStatus.pending,
    String? deploymentError,
    int? createdAt,
    int? lastUsedAt,
    String? nickname,
    bool isPrimary = false,
    List<String>? transports,
    String? deviceType,
    bool? backedUp,
  });

  final String credentialId;
  final Uint8List publicKey;
  final String? contractId;
  final OZCredentialDeploymentStatus deploymentStatus;
  final String? deploymentError;
  final int createdAt;
  final int? lastUsedAt;
  final String? nickname;
  final bool isPrimary;
  final List<String>? transports;
  final String? deviceType;
  final bool? backedUp;

  OZStoredCredential copyWith({...});
  OZStoredCredential applyUpdate(OZStoredCredentialUpdate updates);
}
```

Equality compares `publicKey` in constant time so credential lookups cannot leak partial-key match information through timing differences.

#### OZStoredCredentialUpdate

```dart
class OZStoredCredentialUpdate {
  const OZStoredCredentialUpdate({
    OZCredentialDeploymentStatus? deploymentStatus,
    String? deploymentError,
    String? contractId,
    int? lastUsedAt,
    String? nickname,
    bool? isPrimary,
    List<String>? transports,
    String? deviceType,
    bool? backedUp,
  });
}
```

Partial update spec. Only non-null fields are applied; a `null` value means "no change" and does not clear the field. To clear a field, save a full replacement `OZStoredCredential` via `OZStorageAdapter.save`.

#### OZStoredSession

```dart
class OZStoredSession {
  const OZStoredSession({
    required String credentialId,
    required String contractId,
    required int connectedAt,
    required int expiresAt,
  });

  final String credentialId;
  final String contractId;
  final int connectedAt;
  final int expiresAt;

  bool get isExpired;
}
```

#### OZCredentialDeploymentStatus

```dart
enum OZCredentialDeploymentStatus {
  pending,
  failed,
}
```

On successful deployment the credential is removed from storage rather than transitioned to a terminal "deployed" state, so the only persisted statuses are `pending` and `failed`.

### OZInMemoryStorageAdapter

```dart
class OZInMemoryStorageAdapter implements OZStorageAdapter {
  OZInMemoryStorageAdapter();
}
```

Default fallback when `config.storage` is omitted. Stores all data in a Dart-isolate-local map and does not persist across application restarts. Concurrent calls are serialised through an internal Future-based lock so interleaved reads and writes never observe a partially-applied update.

**Security:** this adapter stores credential public-key bytes and session metadata in plain process memory. Suitable only for testing and development. Production apps must supply a platform-backed secure storage adapter.

All `OZInMemoryStorageAdapter` instances compare equal because two freshly-created instances are functionally identical (both empty); this makes the adapter usable as the default value of an enclosing data class without breaking that data class's structural equality.

### OZPlatformStorageAdapter (mobile)

```dart
class OZPlatformStorageAdapter implements OZStorageAdapter {
  OZPlatformStorageAdapter({MethodChannel? methodChannel});
}
```

Dispatches to the native platform's secure-storage plugin via the `com.soneso.stellar_flutter_sdk/smartaccount/storage` method channel.

- The Android side is backed by `EncryptedSharedPreferences` over the Android Keystore (AES-256-GCM for values, AES-256-SIV for keys).
- The Apple side is backed by the platform Keychain via the Security framework's `SecItem*` primitives.

Method-channel calls are dispatched in arrival order. The native handlers serialise concurrent operations using a platform-specific mutex on each side. Callers do not need to wrap calls in a Dart-side lock.

**Asymmetric corruption handling:**

- `get` returns `null` if the stored payload is corrupt or unreadable; the corruption is logged on the native side but not surfaced to Dart.
- `getAll` skips corrupted entries (logged) and returns the valid subset.
- `update` throws `SmartAccountStorageReadFailed` when the entry is corrupt, because the read-modify-write sequence cannot proceed safely without a known prior state. Callers wanting lossy semantics should `delete` the corrupt entry and `save` a replacement.

The optional `methodChannel` parameter exists for testing only; production code must omit it so the shared channel name is used.

### OZIndexedDBStorageAdapter (web)

```dart
class OZIndexedDBStorageAdapter implements OZStorageAdapter {
  OZIndexedDBStorageAdapter({String dbName = defaultDbName});

  static const String defaultDbName = 'stellar_smart_account';

  Future<void> close();
  Future<void> deleteDatabase({String? name});
}
```

Browser IndexedDB-backed storage adapter; the recommended option for production web. The database name defaults to `stellar_smart_account` and can be overridden for test isolation. Stores credentials in a `credentials` object store with indices on `contractId`, `createdAt`, and `isPrimary`; sessions live in a `sessions` store keyed by `'current'`.

In addition to the `OZStorageAdapter` interface, exposes `close()` to release the database connection and `deleteDatabase({String? name})` to remove the database (useful in tests and account-deletion flows).

The class is a conditional-export facade: on web the real `IDBDatabase`-backed implementation is used; on non-web targets a stub is selected so cross-target code compiles. Construction succeeds and `close()` is a no-op on non-web; every other operation throws `UnsupportedError`.

### OZLocalStorageAdapter (web)

```dart
class OZLocalStorageAdapter implements OZStorageAdapter {
  OZLocalStorageAdapter({String keyPrefix = defaultKeyPrefix});

  static const String defaultKeyPrefix = 'stellar_sa_';
}
```

Browser `localStorage`-backed storage adapter. Approximately 5 MB capacity per origin, unencrypted. Inferior to `OZIndexedDBStorageAdapter` for production: prefer `OZIndexedDBStorageAdapter` unless you have a specific reason to use `localStorage` (for example synchronous compatibility with another stack).

The class is a conditional-export facade: on web the real `Storage`-backed implementation is used; on non-web targets a stub is selected. Construction succeeds on non-web; every storage operation throws `UnsupportedError`.

### OZExternalWalletAdapter abstract class

```dart
abstract class OZExternalWalletAdapter {
  const OZExternalWalletAdapter();

  Future<OZConnectedWallet?> connect();
  Future<void> disconnect();
  Future<void> disconnectByAddress(String address) async {}

  Future<OZSignAuthEntryResult> signAuthEntry(
    String preimageXdr, {
    OZSignAuthEntryOptions? options,
  });

  List<OZConnectedWallet> getConnectedWallets();
  bool canSignFor(String address);
  OZConnectedWallet? getWalletForAddress(String address) => null;
}
```

Protocol for integrating external wallets (Freighter, LOBSTR, and so on) into the multi-signer pipeline. Concrete adapters extend this class so they inherit the no-op defaults for `disconnectByAddress` and `getWalletForAddress`.

**signAuthEntry contract:** the SDK supplies a base64-encoded `HashIDPreimage` XDR. The wallet must base64-decode the preimage bytes, SHA-256 hash them, Ed25519-sign the 32-byte hash, and return the 64-byte raw signature base64-encoded. The SDK handles auth-entry construction and signature framing. Adapters that omit the SHA-256 step, sign a different payload, or return a non-canonical encoding produce a signature that the Soroban host rejects at submission time, surfacing as `SmartAccountTransactionException.simulationFailed` during the post-sign re-simulation.

### Supporting types

#### OZConnectedWallet

```dart
class OZConnectedWallet {
  const OZConnectedWallet({
    required String address,
    required String walletId,
    required String walletName,
  });

  final String address;
  final String walletId;
  final String walletName;
}
```

- `address`: Stellar G-address of the connected wallet.
- `walletId`: Unique wallet identifier (for example `freighter`, `lobstr`).
- `walletName`: Human-readable display name.

#### OZSignAuthEntryOptions

```dart
class OZSignAuthEntryOptions {
  const OZSignAuthEntryOptions({String? networkPassphrase, String? address});

  final String? networkPassphrase;
  final String? address;
}
```

#### OZSignAuthEntryResult

```dart
class OZSignAuthEntryResult {
  const OZSignAuthEntryResult({
    required String signedAuthEntry,
    String? signerAddress,
  });

  final String signedAuthEntry;
  final String? signerAddress;
}
```

- `signedAuthEntry`: Base64-encoded raw Ed25519 signature (64 bytes).
- `signerAddress`: Stellar G-address that produced the signature. May be `null` if the wallet does not report the signer address; callers can then assume the signature came from the requested address.

---

## Indexer Client

The SDK includes an indexer client for reverse lookups from signer credentials to smart account contracts. The indexer is auto-configured for testnet and mainnet when no explicit URL is provided.

### Using via OZSmartAccountKit (Recommended)

```dart
final kit = OZSmartAccountKit.create(config: config);

// indexerClient is null when no indexer URL is configured
// (no explicit indexerUrl and no default for the network).

// Discover contracts by credential ID
final contracts = await kit.indexerClient?.lookupByCredentialId(credentialId);

// Discover contracts by signer address
final byAddress = await kit.indexerClient?.lookupByAddress('GABC...');

// Get full contract details (rules, signers, policies)
final details = await kit.indexerClient?.getContract('CABC...');

// Health and stats
final healthy = await kit.indexerClient?.isHealthy();
final stats = await kit.indexerClient?.getStats();
```

### Using OZIndexerClient Directly

```dart
// Create a client for a specific network (uses the default indexer URL).
// Returns null when no default URL is configured for the network.
final indexer =
    OZIndexerClient.forNetwork('Test SDF Network ; September 2015');

// Or with a custom URL
final custom = OZIndexerClient(
  'https://smart-account-indexer.sdf-ecosystem.workers.dev',
  timeout: Duration(seconds: 10),
);
```

### Constructor

```dart
OZIndexerClient(String indexerUrl, {Duration? timeout});
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `indexerUrl` | `String` | Indexer service URL. Must be HTTPS, or `http://localhost…` for local development. |
| `timeout` | `Duration?` | Per-request timeout (default: `OZConstants.defaultIndexerTimeoutMs`, 10 s). The connect timeout is capped at `OZConstants.maxIndexerConnectTimeoutMs`. |

**Throws**: `SmartAccountConfigurationException.invalidConfig` for blank, non-HTTPS, or host-less URLs.

The injected-Dio test-only constructor `OZIndexerClient.withDio` is `@visibleForTesting`; the injected client is not closed by `close`.

### Factory Methods

#### forNetwork

```dart
static OZIndexerClient? forNetwork(
  String networkPassphrase, {
  Duration? timeout,
});
```

Creates an `OZIndexerClient` using the default indexer URL for a known network. Returns `null` when no default URL is configured for the network. The optional `timeout` is forwarded to the constructor.

#### getDefaultUrl

```dart
static String? getDefaultUrl(String networkPassphrase);
```

Returns the default indexer URL for the given network passphrase, or `null` when unknown. The companion static getter `defaultIndexerUrls` exposes the full passphrase-to-URL map as an unmodifiable view.

### Methods

#### lookupByCredentialId

```dart
Future<OZCredentialLookupResponse> lookupByCredentialId(
  String credentialId, {
  dio.CancelToken? cancelToken,
});
```

Finds all smart account contracts where the given credential is registered as a signer. `credentialId` must be Base64URL-encoded (RFC 4648, no padding); it is decoded and re-encoded as lowercase hex for the indexer API. The optional `cancelToken` aborts the in-flight request.

**Returns**: `OZCredentialLookupResponse`

**Throws**: `SmartAccountValidationException.invalidInput` when `credentialId` is not valid base64url; `SmartAccountIndexerException.requestFailed` for network or non-2xx errors (cancellation surfaces here with a `Request cancelled` message); `SmartAccountIndexerException.timeout` when the request exceeds the configured timeout.

---

#### lookupByAddress

```dart
Future<OZAddressLookupResponse> lookupByAddress(
  String address, {
  dio.CancelToken? cancelToken,
});
```

Finds all smart account contracts where the given address is registered as a signer. Accepts both G-addresses (Stellar accounts) and C-addresses (contracts). The optional `cancelToken` aborts the in-flight request.

**Returns**: `OZAddressLookupResponse`

**Throws**: `SmartAccountValidationException` when the address format is invalid; `SmartAccountIndexerException.requestFailed` for network or non-2xx errors; `SmartAccountIndexerException.timeout` on timeout.

---

#### getContract

```dart
Future<OZContractDetailsResponse> getContract(
  String contractId, {
  dio.CancelToken? cancelToken,
});
```

Retrieves full details for a smart account contract including all context rules, signers, and policies. `contractId` must be a `C...` contract address. The optional `cancelToken` aborts the in-flight request.

**Returns**: `OZContractDetailsResponse`

**Throws**: `SmartAccountValidationException` when the contract ID format is invalid; `SmartAccountIndexerException.requestFailed` for network or non-2xx errors; `SmartAccountIndexerException.timeout` on timeout.

---

#### getStats

```dart
Future<OZIndexerStatsResponse> getStats({dio.CancelToken? cancelToken});
```

Returns indexer service statistics (total events, unique contracts, unique credentials, ledger range, per-event-type breakdown). The optional `cancelToken` aborts the in-flight request.

**Returns**: `OZIndexerStatsResponse`

**Throws**: `SmartAccountIndexerException.requestFailed` for network or non-2xx errors; `SmartAccountIndexerException.timeout` on timeout.

---

#### isHealthy

```dart
Future<bool> isHealthy({dio.CancelToken? cancelToken});
```

Returns `true` only when the indexer responds with HTTP 2xx and a JSON body whose `status` field equals `ok`. Any network failure, timeout, non-2xx status, cancellation, or malformed body returns `false`. This method never throws.

---

#### close

```dart
Future<void> close();
```

Closes the underlying HTTP client and is idempotent. The client must not be used after calling this. When using via `kit.indexerClient`, the kit's `close()` handles this automatically. A client created via `withDio` does not close the injected Dio instance.

---

### Response Types

All response types carry `fromJson` / `toJson` for cross-process serialisation.

#### OZCredentialLookupResponse

```dart
class OZCredentialLookupResponse {
  final String credentialId;
  final List<OZIndexedContractSummary> contracts;
  final int count;
}
```

Result of a credential-ID lookup: the queried credential, the matching contracts, and their total count.

#### OZAddressLookupResponse

```dart
class OZAddressLookupResponse {
  final String signerAddress;
  final List<OZIndexedContractSummary> contracts;
  final int count;
}
```

Result of a signer-address lookup: the queried address, the matching contracts, and their total count.

#### OZContractDetailsResponse

```dart
class OZContractDetailsResponse {
  final String contractId;
  final OZIndexedContractSummary summary;
  final List<OZIndexedContextRule> contextRules;
}
```

Full details for a single contract: its summary plus every context rule with the rule's signers and policies.

#### OZIndexedContractSummary

```dart
class OZIndexedContractSummary {
  final String contractId;
  final int contextRuleCount;
  final int externalSignerCount;
  final int delegatedSignerCount;
  final int nativeSignerCount;
  final int firstSeenLedger;
  final int lastSeenLedger;
  final List<int> contextRuleIds;
}
```

Aggregate counts and metadata for a contract, including per-signer-kind tallies and the ledger range over which it was observed.

#### OZIndexedContextRule

```dart
class OZIndexedContextRule {
  final int contextRuleId;
  final List<OZIndexedSigner> signers;
  final List<OZIndexedPolicy> policies;
}
```

A single context rule as reported by the indexer, with its registered signers and attached policies.

#### OZIndexedSigner

```dart
class OZIndexedSigner {
  final String signerType;      // "External", "Delegated", or "Native"
  final String? signerAddress;  // Stellar address (Delegated signers)
  final String? credentialId;   // Hex-encoded credential ID (External signers)
}
```

A signer within a context rule. `signerAddress` is populated for delegated signers; `credentialId` for external (WebAuthn) signers.

#### OZIndexedPolicy

```dart
class OZIndexedPolicy {
  final String policyAddress;
  final Object? installParams;  // Policy-specific parameters (untyped JSON)
}
```

A policy attached to a context rule. `installParams` preserves whatever JSON shape (object, array, primitive, or `null`) the indexer reports.

#### OZIndexerStatsResponse

```dart
class OZIndexerStatsResponse {
  final OZIndexerStats stats;
}
```

Wrapper around the indexer's `/api/stats` payload.

#### OZIndexerStats

```dart
class OZIndexerStats {
  final int totalEvents;
  final int uniqueContracts;
  final int uniqueCredentials;
  final int firstLedger;
  final int lastLedger;
  final List<OZEventTypeCount> eventTypes;
}
```

Aggregate indexer statistics: total events processed, unique contract and credential counts, the indexed ledger range, and a per-event-type breakdown.

#### OZEventTypeCount

```dart
class OZEventTypeCount {
  final String eventType;  // e.g. "signer_added"
  final int count;
}
```

Number of events observed for a single event type, embedded in `OZIndexerStats`.

#### OZIndexerHealthCheckResponse

```dart
class OZIndexerHealthCheckResponse {
  final String status;  // typically "ok"
}
```

Health-check payload returned by the indexer root endpoint and consumed internally by `isHealthy`.

---

## Relayer Client

The SDK includes a relayer client for fee-sponsored transaction submission. When configured, the SDK automatically routes transactions through the relayer so users don't need XLM to pay fees.

### Using via OZSmartAccountKit (Recommended)

When the relayer is configured, transaction submissions use it automatically:

```dart
final config = OZSmartAccountConfig(
  // ... other config
  relayerUrl: 'https://my-relayer-proxy.example.com',
);
final kit = OZSmartAccountKit.create(config: config);

// Transactions automatically use the relayer when configured.
await kit.transactionOperations.transfer(
  tokenContract: tokenContract,
  recipient: recipient,
  amount: '10',
);

// Bypass the relayer for a specific operation.
await kit.transactionOperations.transfer(
  tokenContract: tokenContract,
  recipient: recipient,
  amount: '10',
  forceMethod: OZSubmissionMethod.rpc,
);

// Access the relayer client directly. relayerClient is null when no
// relayer URL is configured.
await kit.relayerClient?.sendXdr(transactionEnvelope);
```

### Constructor

```dart
OZRelayerClient(String relayerUrl, {Duration? timeout});
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `relayerUrl` | `String` | Relayer endpoint URL. Must be HTTPS, or `http://localhost…` for local development. |
| `timeout` | `Duration?` | Default per-request timeout (default: `OZConstants.defaultRelayerTimeoutMs`, 6 min). The connect timeout is capped at `OZConstants.maxRelayerConnectTimeoutMs`. |

**Throws**: `SmartAccountConfigurationException.invalidConfig` if `relayerUrl` is blank or not HTTPS.

The injected-Dio test-only constructor `OZRelayerClient.withDio` is `@visibleForTesting`; the injected client is not closed by `close`.

Whether a relayer is in use is determined by `kit.relayerClient` being non-`null`, which the kit sets from the configured `relayerUrl`. A constructed `OZRelayerClient` is always configured, since the constructor rejects invalid URLs.

### Methods

#### send

```dart
Future<OZRelayerResponse> send(
  XdrHostFunction hostFunction,
  List<XdrSorobanAuthorizationEntry> authEntries, {
  int? perRequestTimeoutMs,
  dio.CancelToken? cancelToken,
});
```

Submits a host function with signed authorization entries for fee sponsoring. The relayer assembles, fee-bumps, and submits the transaction from its components. Used when no source-account auth entry exists. XDR-to-base64 encoding is handled internally. The optional `perRequestTimeoutMs` overrides the client-level timeout for this call; `cancelToken` aborts the in-flight request.

This method does not throw. All error conditions, including encoding failures, timeouts, and cancellation, are returned in the `OZRelayerResponse`.

**Returns**: `OZRelayerResponse`

---

#### sendXdr

```dart
Future<OZRelayerResponse> sendXdr(
  XdrTransactionEnvelope transactionEnvelope, {
  int? perRequestTimeoutMs,
  dio.CancelToken? cancelToken,
});
```

Submits a complete signed transaction envelope for fee-bumping, preserving the inner signature. Used when the transaction contains source-account auth entries that require the deployer signature (for example wallet deployment). XDR-to-base64 encoding is handled internally. The optional `perRequestTimeoutMs` overrides the client-level timeout for this call; `cancelToken` aborts the in-flight request.

This method does not throw. All error conditions are returned in the `OZRelayerResponse`.

**Returns**: `OZRelayerResponse`

---

#### close

```dart
Future<void> close();
```

Closes the underlying HTTP client and is idempotent. When using via `kit.relayerClient`, the kit's `close()` handles this automatically. A client created via `withDio` does not close the injected Dio instance.

---

### Response and Error Types

#### OZRelayerResponse

```dart
class OZRelayerResponse {
  const OZRelayerResponse({
    required bool success,
    String? transactionId,
    String? hash,
    String? status,
    String? error,
    String? errorCode,
    Object? details,
  });

  final bool success;
  final String? transactionId;
  final String? hash;
  final String? status;
  final String? error;
  final String? errorCode;
  final Object? details;
}
```

| Property | Type | Description |
|----------|------|-------------|
| `success` | `bool` | Whether the relayer reported the submission as successful. |
| `transactionId` | `String?` | Transaction ID assigned by the relayer, when reported. |
| `hash` | `String?` | Transaction hash on the Stellar network if submission succeeded. |
| `status` | `String?` | Transaction status (e.g. `PENDING`, `SUCCESS`, `ERROR`). |
| `error` | `String?` | Error message if the request failed. Not further truncated; the body is bounded by `maxRelayerResponseBytes`. |
| `errorCode` | `String?` | Error code for programmatic handling (see `OZRelayerErrorCodes`). Cancellation yields a `null` `errorCode`. |
| `details` | `Object?` | Additional error details (JSON object or value) from the relayer. |

#### OZRelayerErrorCodes

```dart
class OZRelayerErrorCodes {
  static const String invalidParams = 'INVALID_PARAMS';
  static const String invalidXdr = 'INVALID_XDR';
  static const String poolCapacity = 'POOL_CAPACITY';
  static const String simulationFailed = 'SIMULATION_FAILED';
  static const String onchainFailed = 'ONCHAIN_FAILED';
  static const String invalidTimeBounds = 'INVALID_TIME_BOUNDS';
  static const String feeLimitExceeded = 'FEE_LIMIT_EXCEEDED';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String timeout = 'TIMEOUT';
}
```

String constants identifying known relayer failure conditions. The string value of each constant equals the constant name so it can be compared directly against the `errorCode` field of an `OZRelayerResponse`.

---

## Auth Helpers

### OZSmartAccountAuth

Static helpers for building authorisation payload hashes and attaching pre-computed signatures to authorisation entries. Used internally by the transaction pipeline; exposed for advanced flows that build and sign auth entries by hand.

```dart
abstract class OZSmartAccountAuth {
  static Future<Uint8List> buildAuthDigest(
    Uint8List signaturePayload,
    List<int> contextRuleIds,
  );

  static Future<Uint8List> buildAuthPayloadHash(
    XdrSorobanAuthorizationEntry entry,
    int expirationLedger,
    String networkPassphrase,
  );

  static Future<Uint8List> buildSourceAccountAuthPayloadHash(
    XdrSorobanAuthorizationEntry entry,
    XdrInt64 nonce,
    int expirationLedger,
    String networkPassphrase,
  );

  static Future<XdrSorobanAuthorizationEntry> signAuthEntry({
    required XdrSorobanAuthorizationEntry entry,
    required OZSmartAccountSigner signer,
    required OZSmartAccountSignature signature,
    required int expirationLedger,
    List<int> contextRuleIds = const <int>[],
  });

  static XdrSorobanAuthorizationEntry addRawSignatureMapEntry({
    required XdrSorobanAuthorizationEntry entry,
    required XdrSCVal signerKey,
    required XdrSCVal signatureValue,
    List<int> contextRuleIds = const <int>[],
  });
}
```

- `buildAuthDigest`: Computes `SHA-256(signaturePayload || contextRuleIds.toXDR())`.
- `buildAuthPayloadHash`: Builds the authorisation payload hash for an entry with address credentials. The hash is the WebAuthn challenge when collecting biometric signatures.
- `buildSourceAccountAuthPayloadHash`: Variant for source-account credentials, typically used when converting them to address credentials for relayer fee sponsoring.
- `signAuthEntry`: Attaches a pre-computed `signature` to an authorisation entry. Does not perform cryptographic signing. Returns a fresh entry; when `contextRuleIds` is non-empty it overrides any existing identifiers in the payload.
- `addRawSignatureMapEntry`: Adds a raw key/value entry to an auth entry's signature map. Used for delegated-signer placeholders where the value is `Bytes` rather than a signature.

### OZSmartAccountAuthPayload

```dart
class OZSmartAccountAuthPayload {
  OZSmartAccountAuthPayload({
    required Map<OZSmartAccountSigner, Uint8List> signers,
    required List<int> contextRuleIds,
  });

  final Map<OZSmartAccountSigner, Uint8List> signers;
  final List<int> contextRuleIds;
}
```

In-memory representation of the smart-account contract `AuthPayload` named struct: `context_rule_ids` (a `Vec<U32>`) and `signers` (a map from signer `ScVal` to `Bytes(sig)`). The `signers` map is mutable so the codec and signer pipeline can upsert in place.

### OZSmartAccountAuthPayloadCodec

```dart
abstract class OZSmartAccountAuthPayloadCodec {
  static OZSmartAccountAuthPayload read(XdrSCVal signatureScVal);
  static XdrSCVal write(OZSmartAccountAuthPayload payload);
  static void upsertSigner(
    OZSmartAccountAuthPayload payload,
    OZSmartAccountSigner signer,
    Uint8List signatureBytes,
  );
  static OZSmartAccountSigner signerFromScVal(XdrSCVal scVal);
}
```

Codec for reading and writing `OZSmartAccountAuthPayload` to and from `XdrSCVal`. Inner signer entries are sorted by lowercase-hex of their XDR-encoded keys for deterministic encoding.

- `read`: Accepts `SCV_VOID` (returns an empty payload) and `SCV_MAP` (the full payload).
- `write`: Encodes the payload with alphabetically ordered outer keys and sorted inner signer entries.
- `upsertSigner`: Mutates `payload.signers` to add or replace the entry for `signer`.
- `signerFromScVal`: Decodes a signer-key `ScVal` back into the matching `OZSmartAccountSigner` value.

### Signature types

#### OZSmartAccountSignature (sealed)

```dart
sealed class OZSmartAccountSignature {
  const OZSmartAccountSignature();
  XdrSCVal toScVal();
  Uint8List toAuthPayloadBytes();
}
```

Base for the three concrete signature types.

**`toScVal()`** — converts the signature to its `XdrSCVal` representation. Keys are in alphabetical order where applicable.

**`toAuthPayloadBytes()`** — returns the raw bytes to embed in the on-wire signers map of `OZSmartAccountAuthPayload`. Content is verifier-dependent:

| Signature type | Content |
|---|---|
| `OZWebAuthnSignature` | XDR-encoded `XdrSCVal` (3-field Map) |
| `OZEd25519Signature` | Raw 64-byte signature (no XDR wrapper) |
| `OZPolicySignature` | XDR-encoded `XdrSCVal` (empty Map) |

For `OZEd25519Signature` the Ed25519 verifier contract expects `BytesN<64>` — exactly 64 raw bytes. XDR-wrapping inflates beyond 64 bytes and causes the contract to reject the signature.

#### OZWebAuthnSignature

```dart
final class OZWebAuthnSignature extends OZSmartAccountSignature {
  OZWebAuthnSignature({
    required Uint8List authenticatorData,
    required Uint8List clientData,
    required Uint8List signature,
  });

  final Uint8List authenticatorData;
  final Uint8List clientData;
  final Uint8List signature;
}
```

WebAuthn signature from a passkey authentication ceremony.

- `signature` must be in compact 64-byte format (`r || s`) with a normalised low-S value to prevent malleability. Constructor throws `SmartAccountValidationException.invalidInput` otherwise.
- The on-chain map field is named `client_data` (not `client_data_json`) and keys are emitted in alphabetical order: `authenticator_data`, `client_data`, `signature`.
- `toAuthPayloadBytes()` returns the XDR-encoded 3-field map.
- Equality uses constant-time byte comparison.

#### OZEd25519Signature

```dart
final class OZEd25519Signature extends OZSmartAccountSignature {
  OZEd25519Signature({
    required Uint8List publicKey,
    required Uint8List signature,
  });

  final Uint8List publicKey;
  final Uint8List signature;
}
```

Ed25519 signature with a 32-byte public key and a 64-byte signature. Constructor throws `SmartAccountValidationException.invalidInput` when either length is wrong.

`toScVal()` returns the raw 64-byte signature as `XdrSCVal.forBytes(...)`. `toAuthPayloadBytes()` also returns the raw 64-byte signature — no XDR wrapper — because the Ed25519 verifier contract expects `BytesN<64>` directly. The public key is supplied separately from the smart account's on-chain `External(verifier, key_data)` storage and is NOT transmitted in the auth payload. The `publicKey` field is retained on the struct for local Ed25519 signature verification before submission.

#### OZPolicySignature

```dart
final class OZPolicySignature extends OZSmartAccountSignature {
  static const OZPolicySignature instance;
}
```

Singleton policy-authorisation signature, encoded as an empty `ScMap`. Indicates the rule's policy stack determines authorisation (for example spending limits, threshold signatures, or time-based restrictions). Obtain the canonical value via `OZPolicySignature.instance`. `toAuthPayloadBytes()` returns the XDR-encoded empty map.

---

## Builder Helpers

### OZBuilders

Static helpers for `OZContextRuleType` and parsed-rule utilities.

```dart
class OZBuilders {
  static OZContextRuleType createDefaultContextType();
  static OZContextRuleType createCallContractContextType(String contractAddress);
  static OZContextRuleType createCreateContractContextTypeFromHex(String wasmHashHex);
  static OZContextRuleType createCreateContractContextTypeFromBytes(Uint8List wasmHash);

  static List<OZSmartAccountSigner> collectUniqueSignersFromRules(
    List<OZParsedContextRule> rules,
  );
}
```

- `createDefaultContextType`: Returns `OZContextRuleTypeDefault`. Matches any operation that does not match a more specific rule.
- `createCallContractContextType`: Returns `OZContextRuleTypeCallContract` for the supplied contract address. Validates the address.
- `createCreateContractContextTypeFromHex`: Returns `OZContextRuleTypeCreateContract` from a hex-encoded WASM hash (optionally `0x`-prefixed); must decode to 32 bytes.
- `createCreateContractContextTypeFromBytes`: Returns `OZContextRuleTypeCreateContract` from raw WASM-hash bytes; must be exactly 32 bytes.
- `collectUniqueSignersFromRules`: Returns the unique signers from `rules`, removing duplicates across rules. First occurrence wins.

### OZContextRuleType (sealed)

```dart
sealed class OZContextRuleType {
  const OZContextRuleType();
  XdrSCVal toScVal();
}

final class OZContextRuleTypeDefault extends OZContextRuleType {
  const OZContextRuleTypeDefault();
}

final class OZContextRuleTypeCallContract extends OZContextRuleType {
  const OZContextRuleTypeCallContract(String contractAddress);
  final String contractAddress;
}

final class OZContextRuleTypeCreateContract extends OZContextRuleType {
  OZContextRuleTypeCreateContract(Uint8List wasmHash);
  final Uint8List wasmHash;
}
```

`toScVal` produces:

- `OZContextRuleTypeDefault` → `Vec([Symbol("Default")])`
- `OZContextRuleTypeCallContract` → `Vec([Symbol("CallContract"), Address(contractAddress)])`
- `OZContextRuleTypeCreateContract` → `Vec([Symbol("CreateContract"), Bytes(wasmHash)])`

`OZContextRuleTypeCreateContract` defensively copies the supplied `wasmHash` and uses constant-time byte equality.

### OZParsedContextRule

```dart
class OZParsedContextRule {
  const OZParsedContextRule({
    required int id,
    required OZContextRuleType contextType,
    required String name,
    required List<OZSmartAccountSigner> signers,
    required List<int> signerIds,
    required List<String> policies,
    required List<int> policyIds,
    int? validUntil,
  });
}
```

Parsed representation of a context rule loaded from on-chain storage. `signers` and `signerIds` are positionally aligned, as are `policies` and `policyIds`.

### OZSmartAccountBuilders

Static helpers for OpenZeppelin smart-account signers and policy parameters.

```dart
abstract class OZSmartAccountBuilders {
  // Signer builders
  static OZDelegatedSigner createDelegatedSigner(String publicKey);
  static OZExternalSigner createExternalSigner(String verifierAddress, Uint8List keyData);
  static OZExternalSigner createWebAuthnSigner({
    required String webauthnVerifierAddress,
    required Uint8List publicKey,
    required Uint8List credentialId,
  });
  static OZExternalSigner createEd25519Signer({
    required String ed25519VerifierAddress,
    required Uint8List publicKey,
  });

  // Signer inspection
  static Uint8List? getCredentialIdFromSigner(OZSmartAccountSigner signer);
  static Uint8List? getPublicKeyFromSigner(OZSmartAccountSigner signer);
  static String? getCredentialIdStringFromSigner(OZSmartAccountSigner signer);
  static bool isDelegatedSigner(OZSmartAccountSigner signer);
  static bool isExternalSigner(OZSmartAccountSigner signer);

  // Signer matching
  static bool signerMatchesCredential(OZSmartAccountSigner signer, Uint8List credentialId);
  static bool signerMatchesCredentialId(OZSmartAccountSigner signer, String credentialId);
  static bool signerMatchesAddress(OZSmartAccountSigner signer, String address);

  // Signer comparison and deduplication
  static bool signersEqual(OZSmartAccountSigner a, OZSmartAccountSigner b);
  static String getSignerKey(OZSmartAccountSigner signer);
  static List<OZSmartAccountSigner> collectUniqueSigners(List<OZSmartAccountSigner> signers);
}
```

**Notes on individual helpers:**

- `getCredentialIdStringFromSigner` returns the Base64URL-encoded credential ID without trailing `=` padding, matching the canonical form produced by the connect path.
- `getPublicKeyFromSigner` returns the 65-byte uncompressed secp256r1 public key for WebAuthn signers, and `null` for delegated or Ed25519 signers.
- `signerMatchesCredentialId` ignores trailing `=` padding on either side so padded and unpadded forms compare interchangeably.
- `signersEqual` compares the address for delegated signers, and the verifier address plus byte-content of the key data for external signers.
- `collectUniqueSigners` preserves the first occurrence of each duplicate, keyed by `getSignerKey`.

---

## Utilities

### SmartAccountUtils

Static helpers for WebAuthn signature processing, public-key extraction, and contract-address derivation. Operates on raw byte material independently of any platform WebAuthn API.

```dart
abstract class SmartAccountUtils {
  static Uint8List normalizeSignature(Uint8List derSignature);

  static Uint8List extractPublicKeyFromRegistration({
    Uint8List? publicKey,
    Uint8List? authenticatorData,
    Uint8List? attestationObject,
  });

  static Uint8List getContractSalt(Uint8List credentialId);

  static String deriveContractAddress({
    required Uint8List credentialId,
    required String deployerPublicKey,
    required String networkPassphrase,
  });
}
```

- `normalizeSignature`: Converts a DER-encoded secp256r1 signature into the 64-byte compact `r || s` form with `s` normalised to the lower half of the curve order (low-S). Throws `SmartAccountValidationException.invalidInput` on malformed DER.
- `extractPublicKeyFromRegistration`: Three-strategy public-key extraction: direct validation of `publicKey` if it is already a valid 65-byte uncompressed secp256r1 key; otherwise parse `authenticatorData` if available; otherwise scan `attestationObject` for the embedded public key.
- `getContractSalt`: Returns `SHA-256(credentialId)`, the salt used in contract-address derivation.
- `deriveContractAddress`: Computes the deterministic smart-account contract address from the credential ID, deployer public key, and network passphrase.

---

## Selected Signer

### OZSelectedSigner (sealed)

```dart
sealed class OZSelectedSigner {
  const OZSelectedSigner();
}
```

Selects a signer to participate in a multi-signature operation. There is no implicit connected passkey: to include it, supply an `OZSelectedSignerPasskey` entry referencing it.

### OZSelectedSignerPasskey

```dart
final class OZSelectedSignerPasskey extends OZSelectedSigner {
  const OZSelectedSignerPasskey({
    String? credentialId,
    Uint8List? credentialIdBytes,
    Uint8List? keyData,
    List<String>? transports,
  });

  final String? credentialId;
  final Uint8List? credentialIdBytes;
  final Uint8List? keyData;
  final List<String>? transports;
}
```

A WebAuthn passkey signer entry. Each instance triggers one OS WebAuthn authentication prompt.

- `credentialId`: Base64URL-encoded credential ID for display and lookup.
- `credentialIdBytes`: Raw credential ID bytes for the WebAuthn `allowCredentials` constraint. When `null`, the browser or OS may prompt for any credential.
- `keyData`: External-signer key data (uncompressed secp256r1 public key concatenated with the credential ID bytes, in that order). When supplied the SDK uses it directly without an on-chain lookup. `OZMultiSignerManager.submitWithMultipleSigners` requires this field to be non-null.
- `transports`: Optional WebAuthn transport hints (`internal`, `hybrid`, `usb`, `nfc`, `ble`). When `credentialIdBytes` is `null` the transports are dropped and the multi-signer pipeline leaves `allowCredentials` unset entirely.

### OZSelectedSignerWallet

```dart
final class OZSelectedSignerWallet extends OZSelectedSigner {
  const OZSelectedSignerWallet(String address);

  final String address;
}
```

A delegated wallet signer identified by its Stellar G-address. The address must have been registered as a `Delegated` signer on the smart-account contract, and the external wallet adapter must be able to sign for it.

### OZSelectedSignerEd25519

```dart
final class OZSelectedSignerEd25519 extends OZSelectedSigner {
  const OZSelectedSignerEd25519({
    required String verifierAddress,
    required Uint8List publicKey,
  });

  final String verifierAddress;
  final Uint8List publicKey;
}
```

An Ed25519 external signer identified by its verifier contract address and 32-byte public key. The `(verifierAddress, publicKey)` pair identifies the on-chain `External(verifierAddress, publicKey)` signer slot.

- `verifierAddress` — C-strkey of the Ed25519 verifier contract registered as part of the on-chain `External(verifierAddress, publicKey)` signer entry. The smart-account contract calls this verifier during `__check_auth` to validate the Ed25519 signature.
- `publicKey` — 32-byte Ed25519 public key identifying the signer slot on the smart account. Must match the public key registered in the on-chain signer entry.

`OZSelectedSignerEd25519` carries no signing material. It is a pure identifier; the signing capability must be registered on `kit.externalSigners` before the multi-signer pipeline executes — either by calling [`kit.externalSigners.addEd25519FromRawKey`](#added25519fromrawkey) at runtime, or by supplying `config.externalEd25519Adapter` at kit construction. The kit resolves the signing source automatically when `OZSelectedSignerEd25519` appears in `selectedSigners`.

Value equality compares both fields. `publicKey` equality is byte-by-byte.

Construct the kit and register the Ed25519 signing source exactly as shown in
[`addEd25519FromRawKey`](#added25519fromrawkey). With `kit` and
`ed25519PublicKey` in hand, route a multi-signer call:

```dart
// Example: transfer authorized by three different signer kinds in one call.
// `kit`, `ed25519VerifierAddress`, and `ed25519PublicKey` come from the
// addEd25519FromRawKey snippet above.
final result = await kit.multiSignerManager.multiSignerTransfer(
  tokenContract:
      'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  recipient:
      'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
  amount: '10',
  selectedSigners: <OZSelectedSigner>[
    OZSelectedSignerPasskey(credentialId: savedCredId, keyData: savedKeyData),
    OZSelectedSignerWallet('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ'),
    OZSelectedSignerEd25519(
      verifierAddress: ed25519VerifierAddress,
      publicKey: ed25519PublicKey,
    ),
  ],
);
```

See also: [`OZExternalSignerManager.addEd25519FromRawKey`](#added25519fromrawkey), [`OZExternalSignerManager.signEd25519AuthDigest`](#signed25519authdigest).

---

## Error Handling Example

Every smart-account failure is a `SmartAccountException` subclass (see [Errors](#errors)). Catch concrete subtypes for fine-grained recovery and fall back to the sealed base for everything else.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<void> sendOrRecover(OZSmartAccountKit kit) async {
  try {
    final result = await kit.transactionOperations.transfer(
      tokenContract: 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
      recipient: 'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
      amount: '10',
    );
    if (!result.success) {
      print('Transfer rejected: ${result.error}');
    }
  } on SmartAccountWalletNotConnected {
    print('Connect or create a wallet first.');
  } on WebAuthnCancelled {
    print('User cancelled the passkey prompt.');
  } on WebAuthnNotSupported {
    print('No WebAuthn provider configured for this platform.');
  } on SmartAccountInvalidAddress catch (e) {
    print('Bad address: ${e.message}');
  } on SmartAccountTransactionException catch (e) {
    print('Transaction failed (${e.code.code}): ${e.message}');
  } on SmartAccountException catch (e) {
    print('Smart-account error (${e.code.code}): ${e.message}');
  }
}
```
