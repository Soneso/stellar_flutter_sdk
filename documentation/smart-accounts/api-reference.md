# Smart Accounts API Reference

OpenZeppelin Smart Account support for the Stellar Flutter SDK. This reference documents every public class, function, constant, and event surface exposed by the smart-account namespace, covering wallet lifecycle, transaction signing, signer and policy management, WebAuthn ceremonies, storage, indexer / relayer integration, and the manual auth-entry helpers underneath.

All public symbols listed here are re-exported from the top-level package barrel `package:stellar_flutter_sdk/stellar_flutter_sdk.dart`. Imports throughout this document assume the consumer pulls everything from the barrel.

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
- [Indexer and Relayer Clients](#indexer-and-relayer-clients)
- [Auth Helpers](#auth-helpers)
- [Builder Helpers](#builder-helpers)
- [Selected Signer](#selected-signer)
  - [SelectedSignerPasskey](#selectedsignerpasskey)
  - [SelectedSignerWallet](#selectedsignerwallet)
  - [SelectedSignerEd25519](#selectedsignered25519)

---

## Quick Start

End-to-end example: instantiate the kit, create a wallet with a fresh passkey, fund it on testnet, and transfer a token.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<void> main() async {
  final webauthnProvider = PlatformWebAuthnProvider(
    rpId: 'example.com',
    rpName: 'My Smart Account',
  );

  final storage = PlatformStorageAdapter();

  // Real testnet values; replace for mainnet or your own deployment.
  final config = OZSmartAccountConfig(
    rpcUrl: 'https://soroban-testnet.stellar.org',
    networkPassphrase: 'Test SDF Network ; September 2015',
    accountWasmHash:
        '86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28',
    webauthnVerifierAddress:
        'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
    webauthnProvider: webauthnProvider,
    storage: storage,
  );

  final kit = OZSmartAccountKit.create(config: config);

  try {
    // Attempt to restore a saved session before prompting the user.
    final restored = await kit.walletOperations.connectWallet();
    if (restored is OZConnectWalletConnected) {
      print('Restored ${restored.contractId}');
    } else {
      // No session: create a fresh wallet, deploy it, and fund it via Friendbot.
      final created = await kit.walletOperations.createWallet(
        userName: 'Alice',
        autoSubmit: true,
        autoFund: true,
        nativeTokenContract:
            'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
      );
      print('Created ${created.contractId}');
    }

    final result = await kit.transactionOperations.transfer(
      tokenContract:
          'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
      recipient: 'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
      amount: '10',
    );
    if (result.success) {
      print('Transfer ${result.hash} confirmed at ledger ${result.ledger}');
    } else {
      print('Transfer failed: ${result.error}');
    }
  } finally {
    await kit.disconnect();
    await kit.close();
  }
}
```

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

- `config`: Configuration carrying the RPC endpoint, network passphrase, contract WASM hash, WebAuthn verifier contract address, optional relayer / indexer URLs, optional WebAuthn provider, optional storage adapter, optional external-wallet adapter, and optional external-signer manager for Ed25519 multi-signer flows.

**Returns:** A new, unconnected `OZSmartAccountKit`. Restore a previously-saved session via `kit.walletOperations.connectWallet()`.

### Properties

#### config

```dart
final OZSmartAccountConfig config
```

The configuration captured at construction time. Defines network endpoints, contract addresses, and operational parameters.

#### events

```dart
final SmartAccountEventEmitter events
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

#### externalWallet

```dart
ExternalWalletAdapter? get externalWallet
```

The optional external-wallet adapter captured from `config.externalWallet`. Stable for the lifetime of the kit; the multi-signer pipeline observes this reference.

### Manager Properties

The kit exposes seven managers as lazy, identity-preserving `late final` fields. Every property returns the same instance for the lifetime of the kit.

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

#### externalSignerManager

```dart
OZExternalSignerManager? get externalSignerManager
```

Resolves from `OZSmartAccountConfig.externalSignerManager`. Returns `null` when the consumer did not set it on the config. Multi-signer flows that include `SelectedSignerEd25519` instances require this to be non-null; flows with only passkey and wallet signers work with this null.

Construct the manager, register Ed25519 signing sources on it, then supply it to the kit via `OZSmartAccountConfig(externalSignerManager: manager)` before calling `OZSmartAccountKit.create(config: config)`. See [External Signer Management](#external-signer-management).

### Client Properties

#### indexerClient

```dart
final OZIndexerClient? indexerClient
```

The credential-to-contract indexer client. `null` when neither `config.indexerUrl` is set nor a network-default URL is registered for the configured passphrase. Use for direct credential or address lookups, contract-detail retrieval, and indexer statistics. See [Indexer and Relayer Clients](#indexer-and-relayer-clients).

#### relayerClient

```dart
final OZRelayerClient? relayerClient
```

The fee-sponsoring relayer client. `null` when `config.relayerUrl` is unset. The kit uses this internally to submit transactions when present; direct access is available for advanced submission flows. See [Indexer and Relayer Clients](#indexer-and-relayer-clients).

#### sorobanServer

```dart
final SorobanServer sorobanServer
```

The shared Soroban RPC server used by every manager for simulation, submission, and on-chain reads. Released by `close()`.

### Lifecycle Methods

#### disconnect

```dart
Future<void> disconnect() async
```

Disconnects the currently-connected wallet, clearing the in-memory connection state and removing the persisted session via `StorageAdapter.clearSession`. When a wallet was connected at the time of the call, emits a `SmartAccountEventWalletDisconnected` event. Stored credential entries remain in storage and can be reconnected later via `walletOperations.connectWallet`. Safe to call when no wallet is connected; the call is a no-op aside from the storage-clear request.

#### close

```dart
Future<void> close() async
```

Releases every held HTTP-client resource and removes every registered event listener. Closes the shared `sorobanServer` transport first, then the optional `indexerClient` and `relayerClient` HTTP clients, and finally tears down the kit's event subscriptions. Idempotent: a second invocation is a no-op. Storage and connection state are not touched; call `disconnect()` first to end an active session. The kit is not usable for new operations after `close()` returns.

#### getDeployer

```dart
Future<KeyPair> getDeployer() async
```

Returns the deployer keypair, resolving to the deterministic default when `config.deployerKeypair` is unset. The first call resolves the deployer via `OZSmartAccountConfig.effectiveDeployer` and caches the result; subsequent calls return the cached keypair.

#### getStorage

```dart
StorageAdapter getStorage()
```

Returns the storage adapter currently in use by the kit. Operations modules reach storage through this accessor so the kit remains the single owner of the adapter reference.

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
  String? rpId,
  String rpName = 'Smart Account',
  int sessionExpiryMs = OZConstants.defaultSessionExpiryMs,
  int signatureExpirationLedgers = Util.ledgersPerHour,
  int timeoutInSeconds = OZConstants.defaultTimeoutSeconds,
  String? relayerUrl,
  String? indexerUrl,
  WebAuthnProvider? webauthnProvider,
  StorageAdapter? storage,
  ExternalWalletAdapter? externalWallet,
  OZExternalSignerManager? externalSignerManager,
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
- `rpId`: WebAuthn relying-party ID (domain name). Forwarded to providers when constructed by consumer code; the kit itself does not read this field.
- `rpName`: Human-readable relying-party name shown during WebAuthn ceremonies. Default `'Smart Account'`.
- `sessionExpiryMs`: Session validity in milliseconds. Default `OZConstants.defaultSessionExpiryMs` (7 days).
- `signatureExpirationLedgers`: Auth-entry expiration in ledgers. Default `Util.ledgersPerHour` (720). Capped to `[1, 535680]`; the upper bound corresponds to approximately one month at five seconds per ledger.
- `timeoutInSeconds`: Stellar transaction-level timeout. Default `OZConstants.defaultTimeoutSeconds` (30). Capped to `[1, 600]`.
- `relayerUrl`: Optional relayer endpoint. When set, transactions can be fee-sponsored via the relayer pipeline.
- `indexerUrl`: Optional indexer endpoint. When unset, `effectiveIndexerUrl()` falls back to the well-known default URL for the configured network when available.
- `webauthnProvider`: Platform-specific WebAuthn provider. Required for any passkey-driven operation; an absent provider causes `createWallet`, `connectWallet(prompt: true)`, `authenticatePasskey`, and signer / transaction WebAuthn flows to throw `WebAuthnNotSupported`.
- `storage`: Storage adapter for credentials and sessions. Defaults to a fresh `InMemoryStorageAdapter()` when omitted. All `InMemoryStorageAdapter` instances compare equal, so two configs with the default storage are structurally equal.
- `externalWallet`: Optional external-wallet adapter used by the multi-signer pipeline for delegated G-address signers.
- `externalSignerManager`: Optional external-signer manager for Ed25519 multi-signer signing ceremonies. Construct `OZExternalSignerManager` separately, register signing keypairs via `OZExternalSignerManager.addEd25519FromRawKey(...)`, and supply the manager here so the kit can forward signing requests during multi-signer operations that include `SelectedSignerEd25519` entries. When `null`, any `SelectedSignerEd25519` in `selectedSigners` causes `OZMultiSignerManager` to throw `ValidationException.invalidInput`.
- `maxContextRuleScanId`: Upper bound on rule IDs to scan when iterating context rules. Default `50`. Increase if the account has had many add / remove cycles. Must be non-negative.

Throws `ConfigurationException.missingConfig` when a required parameter is blank, and `ConfigurationException.invalidConfig` when `accountWasmHash`, `webauthnVerifierAddress`, `signatureExpirationLedgers`, `timeoutInSeconds`, or `maxContextRuleScanId` fails validation.

Every constructor parameter is also exposed as a public `final` field with the same name and type.

### Platform-specific provider integration

See [WebAuthn Provider](#webauthn-provider), [Storage Adapter](#storage-adapter), and [ExternalWalletAdapter](#externalwalletadapter-abstract-class) for the platform-specific implementations and the abstract contracts.

### Factory and computed accessors

#### createDefaultDeployer

```dart
static Future<KeyPair> createDefaultDeployer() async
```

Derives the deterministic deployer keypair from `SHA-256("openzeppelin-smart-account-kit")`. The seed string is fixed across every implementation of the OpenZeppelin smart-account kit so the derived account ID is reproducible. The deployer only pays deployment fees; it does not control user wallets. Throws `ConfigurationException.invalidConfig` on derivation failure.

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

#### effectiveDeployer

```dart
Future<KeyPair> effectiveDeployer() async
```

Returns `deployerKeypair` when set; otherwise resolves to the deterministic default. Throws `ConfigurationException` if default derivation fails.

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
- `rpId(String? value)`
- `rpName(String value)`
- `sessionExpiryMs(int value)`
- `signatureExpirationLedgers(int value)`
- `timeoutInSeconds(int value)`
- `relayerUrl(String? value)`
- `indexerUrl(String? value)`
- `webauthnProvider(WebAuthnProvider? value)`
- `storage(StorageAdapter value)`
- `externalWallet(ExternalWalletAdapter? value)`
- `externalSignerManager(OZExternalSignerManager? value)`
- `maxContextRuleScanId(int value)`

#### build

```dart
OZSmartAccountConfig build()
```

Constructs the `OZSmartAccountConfig`, applying constructor validation. Throws `ConfigurationException` on failure.

---

## Wallet Operations

### OZWalletOperations

Manages the wallet lifecycle: passkey registration, contract derivation, deployment, session restoration, indexer-driven discovery, and standalone authentication. Accessed via `kit.walletOperations`.

```dart
final walletOps = kit.walletOperations;
```

#### createWallet

```dart
Future<CreateWalletResult> createWallet({
  String userName = 'Smart Account User',
  bool autoSubmit = false,
  bool autoFund = false,
  String? nativeTokenContract,
  SubmissionMethod? forceMethod,
  dio.CancelToken? cancelToken,
}) async
```

Creates a new smart-account wallet with a fresh WebAuthn passkey.

Flow:

1. Require a configured `WebAuthnProvider` and validate auto-fund preconditions.
2. Generate a 32-byte random challenge and a 32-byte random user ID; trigger the WebAuthn registration ceremony.
3. Extract the uncompressed secp256r1 public key from the registration result via `SmartAccountUtils.extractPublicKeyFromRegistration`.
4. Derive the deterministic smart-account contract address from the credential ID and the effective deployer.
5. Persist the credential as pending via the credential manager and emit a `SmartAccountEventCredentialCreated` event.
6. Set the kit's connected state and emit `SmartAccountEventWalletConnected`; save the session.
7. Build and sign the deploy transaction unconditionally so the caller can submit externally when `autoSubmit` is `false`.
8. When `autoSubmit` is `true`, submit the deploy transaction. When `autoFund` is also `true`, wait briefly for RPC visibility and then fund the wallet via Friendbot (testnet only). On success the pending credential is deleted.

**Parameters:**

- `userName`: Display name passed to WebAuthn and stored as the credential's nickname.
- `autoSubmit`: When `true`, submit the deploy transaction. When `false`, return the unsubmitted signed XDR in `signedTransactionXdr` so a consumer can submit it externally.
- `autoFund`: When `true`, fund the deployed wallet via Friendbot after a 5 s ledger-close delay. Requires `autoSubmit == true`, `nativeTokenContract != null`, and testnet.
- `nativeTokenContract`: Native-token Soroban contract address required when `autoFund` is `true`.
- `forceMethod`: Optional submission-method override. Defaults to auto-detection (relayer when configured, otherwise direct RPC).
- `cancelToken`: Optional Dio cancel token. Cancellation surfaces as `TransactionException.submissionFailed` with the underlying `DioException.cancel` preserved as the cause.

**Returns:** A `CreateWalletResult` carrying the credential ID, contract address, 65-byte public key, signed transaction XDR (always populated), optional transaction hash, and the nickname used for the credential.

**Throws:** `WebAuthnException.notSupported` when no provider is configured; `ValidationException.invalidInput` for missing auto-fund prerequisites; `WebAuthnException.registrationFailed` when the ceremony fails or is cancelled; `CredentialException.alreadyExists` when a duplicate credential ID is encountered; `StorageException.writeFailed` on persistence failures; `TransactionException` for build, sign, simulation, or submission failures.

#### connectWallet

```dart
Future<OZConnectWalletResult?> connectWallet({
  ConnectWalletOptions options = const ConnectWalletOptions(),
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
3. Indexer lookup: zero results throw `WalletException.notFound`; one result is verified and returned as `OZConnectWalletConnected`; multiple results are returned as `OZConnectWalletAmbiguous` without setting the connected state.

**Returns:** `null` when no session exists and `prompt` is `false`; otherwise an `OZConnectWalletConnected` (single-contract success, state set and session saved) or `OZConnectWalletAmbiguous` (caller must let the user pick a contract and reconnect with `credentialId` + the chosen `contractId`).

**Throws:** `ValidationException.invalidInput` when `contractId` is supplied without `credentialId`; `WebAuthnException` family on WebAuthn failures; `WalletException.notFound` when no on-chain contract is resolved; `TransactionException` on XDR or simulation failures during derivation / verification.

#### authenticatePasskey

```dart
Future<AuthenticatePasskeyResult> authenticatePasskey({
  Uint8List? challenge,
  List<String>? credentialIds,
  dio.CancelToken? cancelToken,
}) async
```

Triggers a WebAuthn authentication ceremony without modifying the kit's connection state. Useful for indexer-driven discovery, pre-authentication, or multi-signer flows that need a fresh signature before a wallet is selected.

**Parameters:**

- `challenge`: Optional challenge bytes. When omitted, a 32-byte secure random challenge is generated.
- `credentialIds`: Optional list of Base64URL-encoded credential IDs. When supplied, the authenticator is restricted to these credentials (the WebAuthn `allowCredentials` constraint). Padded and unpadded forms are accepted interchangeably; transport hints from local storage are forwarded into each `AllowCredential` entry.

**Returns:** An `AuthenticatePasskeyResult` carrying the credential ID, the normalised (64-byte compact, low-S) `OZWebAuthnSignature`, and the 65-byte public key when the credential is in local storage (empty otherwise).

**Throws:** `WebAuthnException.notSupported` when no provider is configured; `WebAuthnException.authenticationFailed` on ceremony failure; `CredentialException.invalid` when the provider returns a signature for a credential outside the requested allow-list; `ValidationException.invalidInput` when signature normalisation fails.

#### deployPendingCredential

```dart
Future<DeployPendingResult> deployPendingCredential({
  required String credentialId,
  bool autoSubmit = true,
  bool autoFund = false,
  String? nativeTokenContract,
  SubmissionMethod? forceMethod,
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

**Returns:** A `DeployPendingResult` carrying the contract address, the signed transaction XDR, and the optional transaction hash when submitted.

**Throws:** `ValidationException.invalidInput` when the auto-fund prerequisites are unmet; `CredentialException.notFound` when the credential is missing from storage; `CredentialException.invalid` when required fields are absent; `TransactionException` on build, sign, simulation, or submission failure.

### Result Types

#### CreateWalletResult

```dart
class CreateWalletResult {
  const CreateWalletResult({
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

  CreateWalletResult copyWith({...});
}
```

- `credentialId`: Base64URL-encoded WebAuthn credential ID (no padding).
- `contractId`: Smart account contract address (`C…`).
- `publicKey`: Uncompressed secp256r1 public key (65 bytes starting with `0x04`).
- `signedTransactionXdr`: Base64-encoded signed deploy-transaction envelope. Always populated.
- `transactionHash`: Transaction hash when auto-submitted, `null` otherwise.
- `nickname`: User-supplied display name stored with the credential.

Equality compares `publicKey` in constant time; `hashCode` is byte-content-derived.

#### DeployPendingResult

```dart
class DeployPendingResult {
  const DeployPendingResult({
    required String contractId,
    required String signedTransactionXdr,
    String? transactionHash,
  });

  final String contractId;
  final String signedTransactionXdr;
  final String? transactionHash;

  DeployPendingResult copyWith({...});
}
```

- `contractId`: Smart account contract address.
- `signedTransactionXdr`: Base64-encoded signed deploy-transaction envelope.
- `transactionHash`: Present when `autoSubmit` was `true`, `null` otherwise.

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
- `candidates`: Contract addresses returned by the indexer. Let the user pick one and call `connectWallet` again with `ConnectWalletOptions(credentialId: …, contractId: chosen)`.

#### AuthenticatePasskeyResult

```dart
class AuthenticatePasskeyResult {
  const AuthenticatePasskeyResult({
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

#### ConnectWalletOptions

```dart
class ConnectWalletOptions {
  const ConnectWalletOptions({
    String? credentialId,
    String? contractId,
    bool fresh = false,
    bool prompt = false,
  });

  final String? credentialId;
  final String? contractId;
  final bool fresh;
  final bool prompt;

  ConnectWalletOptions copyWith({
    String? credentialId,
    bool clearCredentialId = false,
    String? contractId,
    bool clearContractId = false,
    bool? fresh,
    bool? prompt,
  });
}
```

`copyWith` uses replace-or-clear semantics for the nullable string fields via the `clear…` flags.

---

## Transaction Operations

### OZTransactionOperations

High-level transaction building, signing, and submission for smart-account operations. Accessed via `kit.transactionOperations`.

#### transfer

```dart
Future<TransactionResult> transfer({
  required String tokenContract,
  required String recipient,
  required String amount,
  SubmissionMethod? forceMethod,
  dio.CancelToken? cancelToken,
}) async
```

SEP-41 token transfer from the connected smart account to `recipient`. The decimal `amount` is converted to stroops via `Util.toXdrInt64Amount` and the transaction is built as a direct `transfer(from, to, amount)` invocation on the token contract; authorisation runs against the matching `CallContract(tokenContract)` context rule.

**Parameters:**

- `tokenContract`: Token contract address (`C…`). Use the SAC address for XLM or the contract address for any SEP-41 custom token.
- `recipient`: Recipient address (`G…` or `C…`). Validated against Stellar address format.
- `amount`: Decimal amount, e.g. `"100"` or `"10.5"`. Converted to stroops internally.
- `forceMethod`: Optional `SubmissionMethod` override.

**Returns:** A `TransactionResult` carrying the submission outcome.

**Throws:** `WalletNotConnected`; `ValidationException.invalidAddress` for malformed recipients; `ValidationException.invalidInput` for self-transfer or invalid amount; downstream `TransactionException`, `WebAuthnException`, `CredentialException`.

#### contractCall

```dart
Future<TransactionResult> contractCall({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
  dio.CancelToken? cancelToken,
}) async
```

Invokes an arbitrary function on an external contract directly from the smart account. The host function calls `target.targetFn(targetArgs)` without going through the smart account's `execute()` entry point. The matching `CallContract(target)` context rule is used for authorisation.

**Parameters:**

- `target`: Target contract address (`C…`).
- `targetFn`: Function name to invoke on `target`.
- `targetArgs`: Pre-encoded XDR arguments. Construct via `XdrSCVal.forU32`, `XdrSCVal.forAddress`, `Util.stroopsToI128ScVal`, etc.
- `forceMethod`: Optional submission-method override.
- `resolveContextRuleIds`: Optional callback supplying per-entry context-rule IDs when auto-resolution is ambiguous.

#### executeAndSubmit

```dart
Future<TransactionResult> executeAndSubmit({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
  dio.CancelToken? cancelToken,
}) async
```

Executes a contract call through the smart account's `execute(target, target_fn, target_args)` entry point. The smart account becomes the direct invoker of the target contract, which is required by contracts that check their caller (for example policy contracts that verify the smart account is the caller).

The auth context is `CallContract(smartAccountAddress)`, so only `Default` rules, or rules targeting the smart account address explicitly, match. For external-contract calls with contract-specific rules use `contractCall` instead.

#### submit

```dart
Future<TransactionResult> submit({
  required XdrHostFunction hostFunction,
  required List<XdrSorobanAuthorizationEntry> auth,
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
  dio.CancelToken? cancelToken,
}) async
```

Low-level submission. Accepts a pre-built host function and handles the full authorisation lifecycle: simulation, auth-entry extraction, context-rule resolution, WebAuthn signing, re-simulation for accurate resource fees, source-account or deployer signing as required, relayer-or-RPC dispatch, and on-chain polling.

This is the primitive that `transfer`, `contractCall`, and `executeAndSubmit` build on. Use it directly when fine-grained control over host-function construction is required (multi-operation invocations, custom auth entries from external signers, and so on).

#### fundWallet

```dart
Future<String> fundWallet({
  required String nativeTokenContract,
  SubmissionMethod? forceMethod,
  dio.CancelToken? cancelToken,
}) async
```

Funds the connected smart-account wallet on testnet using Friendbot. Creates a temporary keypair, funds it via Friendbot, transfers all but `OZConstants.friendbotReserveXlm` to the smart account using the native-token contract, and returns the amount funded as a decimal XLM string.

**Throws:** `ValidationException.invalidAddress` for malformed `nativeTokenContract`; `TransactionException` on any step failure.

### Result Types

#### TransactionResult

```dart
class TransactionResult {
  const TransactionResult({
    required bool success,
    String? hash,
    int? ledger,
    String? error,
  });

  final bool success;
  final String? hash;
  final int? ledger;
  final String? error;

  TransactionResult copyWith({
    bool? success,
    String? hash,
    int? ledger,
    String? error,
  });
}
```

- `success`: Whether the transaction succeeded.
- `hash`: Transaction hash when submission succeeded.
- `ledger`: Ledger number where the transaction was confirmed.
- `error`: Error message when `success` is `false`.

#### ResolveContextRuleIds (typedef)

```dart
typedef ResolveContextRuleIds = Future<List<int>> Function(
  XdrSorobanAuthorizationEntry entry,
  int index,
);
```

Optional callback invoked during signing for each authorisation entry that matches the connected smart account. Receives the entry and its index in the auth-entries list and returns the context-rule IDs to use for the entry. When no callback is supplied the SDK auto-resolves the rule IDs from the connected signer and the active context rules.

#### SubmissionMethod

```dart
enum SubmissionMethod {
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
Future<StoredCredential> createPendingCredential({
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

Throws `ValidationException.invalidInput`, `CredentialException.alreadyExists`, `StorageException.writeFailed`.

#### saveCredential

```dart
Future<StoredCredential> saveCredential({
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

Checks whether the smart-account contract for this credential exists on-chain. When found, deletes the credential from storage and returns `true`. When not found or on transient RPC failure, returns `false`; swallowed exceptions are emitted as `SmartAccountEventCredentialSyncFailed` so consumers can observe them without losing the stable-return contract.

Throws `CredentialException.notFound` when the credential is absent from storage; `StorageException.readFailed` on storage failure.

#### syncAll

```dart
Future<SyncResult> syncAll() async
```

Runs `sync` against every stored credential and returns a `SyncResult` carrying the counts of credentials confirmed as deployed (and removed), credentials still pending, and credentials marked failed.

#### deleteCredential

```dart
Future<void> deleteCredential({required String credentialId}) async
```

Deletes the credential after verifying via `sync` that the corresponding contract is not on-chain. Refusing to delete a deployed credential prevents the user from removing a wallet that still exists on-chain. Emits `SmartAccountEventCredentialDeleted` on success.

Throws `CredentialException.notFound`, `CredentialException.invalid` (when the credential is on-chain), `StorageException`.

#### getCredential

```dart
Future<StoredCredential?> getCredential(String credentialId) async
```

Returns the stored credential or `null` when not present.

#### getCredentialsByContract

```dart
Future<List<StoredCredential>> getCredentialsByContract(String contractId) async
```

Returns all stored credentials whose `contractId` equals the supplied value.

#### getAllCredentials

```dart
Future<List<StoredCredential>> getAllCredentials() async
```

Returns every stored credential.

#### getForConnectedWallet

```dart
Future<List<StoredCredential>> getForConnectedWallet() async
```

Returns all credentials whose `contractId` matches `kit.contractId`. Returns an empty list when no wallet is connected.

#### getPendingCredentials

```dart
Future<List<StoredCredential>> getPendingCredentials() async
```

Returns every stored credential whose `deploymentStatus` is `pending` or `failed`. Useful for surfacing wallets that still need attention (retry, sync, or delete).

#### updateNickname

```dart
Future<void> updateNickname(String credentialId, String? nickname) async
```

Updates the credential's nickname. Throws `CredentialException.notFound` when the credential is absent.

#### clearAll

```dart
Future<void> clearAll() async
```

Removes every credential from storage. Irreversible; intended for account-deletion or reset flows.

### SyncResult

```dart
class SyncResult {
  const SyncResult({
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

## Signer Management

### OZSignerManager

Manages signers attached to context rules. Accessed via `kit.signerManager`.

Each context rule may carry up to `OZConstants.maxSigners` signers (15). The signer manager supports three signer kinds:

- WebAuthn passkeys (secp256r1 via the WebAuthn verifier contract).
- Delegated signers (Stellar accounts or contracts authorising via Soroban's native `require_auth`).
- Ed25519 signers (32-byte Ed25519 keys verified by a deployed Ed25519 verifier contract).

Every state-changing method accepts an optional `List<SelectedSigner>`; an empty list (the default) routes through the single-signer pipeline that authorises with the connected passkey, while a non-empty list routes through `OZMultiSignerManager.submitWithMultipleSigners`.

#### addNewPasskeySigner

```dart
Future<AddPasskeySignerResult> addNewPasskeySigner({
  required int contextRuleId,
  required String userName,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Registers a new WebAuthn passkey and adds it as a signer to `contextRuleId` in one flow. Triggers a WebAuthn registration ceremony, stores the credential locally as pending, emits `SmartAccountEventCredentialCreated`, then delegates to `addPasskey` for the on-chain signer addition.

Returns an `AddPasskeySignerResult` carrying the new credential ID, the 65-byte uncompressed public key, and the on-chain `TransactionResult`.

#### addPasskey

```dart
Future<TransactionResult> addPasskey({
  required int contextRuleId,
  required Uint8List publicKey,
  required Uint8List credentialId,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Adds a previously-registered WebAuthn passkey as a signer to `contextRuleId`. Validates that `publicKey` is exactly 65 bytes starting with `0x04` and that `credentialId` is non-empty, constructs an `OZExternalSigner.webAuthn` against `config.webauthnVerifierAddress`, and submits the signer-addition transaction.

#### addDelegated

```dart
Future<TransactionResult> addDelegated({
  required int contextRuleId,
  required String address,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Adds a delegated signer (Stellar G-address or C-address) to `contextRuleId`. Address validation runs in `OZDelegatedSigner`.

#### addEd25519

```dart
Future<TransactionResult> addEd25519({
  required int contextRuleId,
  required String verifierAddress,
  required Uint8List publicKey,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Adds an Ed25519 signer to `contextRuleId`. Validates that `verifierAddress` is a contract address and that `publicKey` is exactly 32 bytes.

#### removeSigner

```dart
Future<TransactionResult> removeSigner({
  required int contextRuleId,
  required int signerId,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Removes a signer from `contextRuleId` by its on-chain signer ID.

The contract rejects removing the last signer from a rule that has no policies. Callers must ensure either at least one signer remains or that policies provide an authorisation path.

#### removeSignerBySigner

```dart
Future<TransactionResult> removeSignerBySigner({
  required int contextRuleId,
  required OZSmartAccountSigner signer,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Removes a signer from `contextRuleId` by matching the signer value. Fetches the rule, parses it, finds the matching signer index via `OZSmartAccountBuilders.signersEqual`, and delegates to the ID-based `removeSigner`. Throws `ValidationException.invalidInput` when the signer is not on the rule.

### AddPasskeySignerResult

```dart
class AddPasskeySignerResult {
  const AddPasskeySignerResult({
    required String credentialId,
    required Uint8List publicKey,
    required TransactionResult transactionResult,
  });

  final String credentialId;
  final Uint8List publicKey;
  final TransactionResult transactionResult;
}
```

---

## Multi-Signer Operations

### OZMultiSignerManager

Manages multi-signature smart-account operations. Accessed via `kit.multiSignerManager`.

Signatures are collected sequentially in the order supplied via `selectedSigners`, enabling fail-fast behaviour on user cancellation. Each `SelectedSignerPasskey` triggers one WebAuthn authentication prompt; each `SelectedSignerWallet` signs via the configured `ExternalWalletAdapter`; each `SelectedSignerEd25519` calls `OZExternalSignerManager.signEd25519AuthDigest(...)` using the signing source registered for that `(verifierAddress, publicKey)` pair. The connected passkey is not added implicitly; include a `SelectedSignerPasskey` referencing it when it should sign.

`submitWithMultipleSigners` hoists external-signer reconstruction outside the per-entry loop, so every `SelectedSignerPasskey` in the list must carry a non-null `keyData` before the call; the hoist throws once at the top if any entry omits it.

#### multiSignerTransfer

```dart
Future<TransactionResult> multiSignerTransfer({
  required String tokenContract,
  required String recipient,
  required String amount,
  required List<SelectedSigner> selectedSigners,
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
}) async
```

SEP-41 transfer signed by the explicit list of signers in `selectedSigners`. Builds the `transfer(from, to, amount)` host function and routes through `submitWithMultipleSigners`.

#### multiSignerContractCall

```dart
Future<TransactionResult> multiSignerContractCall({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  required List<SelectedSigner> selectedSigners,
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
}) async
```

Calls an arbitrary function on an external contract directly, with multi-signer authorisation. The smart account's matching `CallContract(target)` context rule is used for authorisation.

#### multiSignerExecuteAndSubmit

```dart
Future<TransactionResult> multiSignerExecuteAndSubmit({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  required List<SelectedSigner> selectedSigners,
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
}) async
```

Executes a contract call through the smart account's `execute()` entry point with multi-signer authorisation.

#### submitWithMultipleSigners

```dart
Future<TransactionResult> submitWithMultipleSigners({
  required XdrHostFunction hostFunction,
  required List<SelectedSigner> selectedSigners,
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
}) async
```

Shared low-level multi-signer signing pipeline. Validates the complete signer set, simulates the host function to discover authorization entries, signs every matching entry with every supplied signer (passkey signatures via WebAuthn, wallet signatures via `ExternalWalletAdapter.signAuthEntry`, Ed25519 signatures via `OZExternalSignerManager.signEd25519AuthDigest`), re-simulates so the resource fees reflect the real signature payload size, and submits the final envelope via relayer or RPC. The three higher-level entry points (`multiSignerTransfer`, `multiSignerContractCall`, `multiSignerExecuteAndSubmit`) delegate here.

---

## External Signer Management

### OZExternalSignerManager

Manager for non-passkey signers used by multi-signer smart-account operations. Coordinates Stellar account signers that originate from Ed25519 secret keys (memory-only) or from external wallet connections through an `ExternalWalletAdapter`, and Ed25519 external signers identified by a `(verifierAddress, publicKey)` tuple.

Construct the manager separately, register signing sources on it, then supply it to the kit via `OZSmartAccountConfig(externalSignerManager: manager)` before calling `OZSmartAccountKit.create(config: config)`. Once wired through the config, `kit.externalSignerManager` returns the same instance. If you only need wallet signing and no Ed25519 signing, the manager is optional — passkey-only flows work without it.

```dart
OZExternalSignerManager({
  required String networkPassphrase,
  ExternalWalletAdapter? walletAdapter,
  WalletConnectionStorage? walletConnectionStorage,
})
```

**Fields:**

- `networkPassphrase`: Network passphrase used when delegating to `walletAdapter`.
- `walletAdapter`: Optional external-wallet adapter. When `null`, only keypair signers are supported.
- `walletConnectionStorage`: Optional persistence layer for wallet connections.

#### hasWalletAdapter

```dart
bool get hasWalletAdapter
```

`true` when an external-wallet adapter is configured.

#### addFromSecret

```dart
Future<String> addFromSecret(String secretKey) async
```

Adds an Ed25519 keypair signer derived from `secretKey`. The keypair is held in memory only and never persisted. Returns the derived G-address. When a signer with the same address already exists, the keypair entry takes precedence and the persisted wallet connection (if any) is removed.

Throws `SignerException.invalid` when the secret key is invalid.

#### addFromWallet

```dart
Future<ConnectedWallet?> addFromWallet() async
```

Connects an external wallet via `walletAdapter` and adds it as a signer. Returns `null` when the user cancels. When `walletConnectionStorage` is configured the connection is persisted for later restoration via `restoreConnections`.

Throws `ConfigurationException.missingConfig` when no wallet adapter is configured.

#### canSignFor

```dart
Future<bool> canSignFor(String address) async
```

`true` when any managed signer (keypair or wallet) can sign for `address`. Keypair signers are checked first.

#### get

```dart
Future<ExternalSignerInfo?> get(String address) async
```

Returns the signer info for `address`, preferring keypair entries over wallet entries.

#### getAll

```dart
Future<List<ExternalSignerInfo>> getAll() async
```

Lists every managed signer. Keypair signers come first; wallet signers whose addresses overlap with keypair signers are skipped.

#### hasSigners

```dart
Future<bool> hasSigners() async
```

`true` when at least one signer is registered.

#### signAuthEntry

```dart
Future<SignAuthEntryResult> signAuthEntry(
  String address,
  String authEntry,
) async
```

Signs an authorisation-entry preimage for `address`. For keypair signers the base64-encoded preimage is decoded, SHA-256-hashed, and signed with the in-memory Ed25519 keypair. For wallet signers the call is delegated to `ExternalWalletAdapter.signAuthEntry`. Keypair signers take precedence over wallet signers for the same address.

Throws `SignerException.notFound` when no signer is available for `address`; `TransactionException.signingFailed` on signing failure.

#### remove

```dart
Future<void> remove(String address) async
```

Removes the signer registered for `address`. Removes the keypair entry, asks the wallet adapter to release per-address state via `disconnectByAddress`, and removes the persisted wallet connection from storage.

#### removeAll

```dart
Future<void> removeAll() async
```

Removes every managed signer. Clears the keypair map, all Ed25519 keypair registrations, disconnects every external wallet connection via `ExternalWalletAdapter.disconnect`, and clears the persisted wallet connections from `walletConnectionStorage`. The `ed25519Adapter` is not affected; clear it separately if needed.

#### restoreConnections

```dart
Future<List<ConnectedWallet>> restoreConnections() async
```

Restores previously connected wallets from `walletConnectionStorage`. Reads the persisted list and calls `ExternalWalletAdapter.reconnect` for each entry; wallets whose reconnect returns `null` or throws are removed from storage. Idempotent: subsequent calls return the currently connected wallets without re-reading.

---

### Ed25519 Signing

The following methods and types support Ed25519 external signers identified by a `(verifierAddress, publicKey)` tuple. They complement the wallet-based signing methods above. See also [`SelectedSignerEd25519`](#selectedsignered25519) for how to reference these signers in multi-signer calls.

#### ed25519Adapter

```dart
OZExternalEd25519SignerAdapter? ed25519Adapter
```

Readable and writable public field. When set, the adapter is consulted before the in-memory keypair registry for every Ed25519 signing request (adapter-first precedence rule). Set to `null` to clear the adapter and force the in-memory keypair path. The field is also settable via `setEd25519Adapter(adapter)`.

#### setEd25519Adapter

```dart
void setEd25519Adapter(OZExternalEd25519SignerAdapter? adapter)
```

Assigns or clears the Ed25519 adapter. Equivalent to direct field assignment (`manager.ed25519Adapter = adapter`); provided as a method for call sites that prefer the explicit setter form.

**Parameters:**

- `adapter`: The new adapter, or `null` to clear.

#### addEd25519FromRawKey

```dart
Uint8List addEd25519FromRawKey({
  required Uint8List secretKeyBytes,
  required String verifierAddress,
})
```

Derives an Ed25519 keypair from raw 32-byte seed material and registers it in memory under the `(verifierAddress, publicKey)` tuple. The keypair is never persisted to storage; it is cleared when `removeEd25519(...)` is called or when `removeAll()` runs.

If a keypair is already registered for the same tuple, it is silently overwritten.

For hardware wallets, HSMs, or remote signing services, use `setEd25519Adapter(...)` instead — the raw secret never enters process memory.

**Parameters:**

- `secretKeyBytes`: Exactly 32 bytes of raw Ed25519 seed material. This is not a Stellar S-strkey; it is the raw seed.
- `verifierAddress`: C-strkey of the Ed25519 verifier contract under which this key is registered on-chain.

**Returns:** The derived 32-byte Ed25519 public key as a `Uint8List`. Pass this as the `publicKey` argument of `SelectedSignerEd25519(verifierAddress: ..., publicKey: ...)` to route multi-signer signing through this keypair.

**Throws:** `ValidationException.invalidInput` when `secretKeyBytes` is not exactly 32 bytes. `SignerException.invalid` when keypair construction fails.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// 1. Construct the manager and register the signing source.
const ed25519VerifierAddress =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

// Raw 32-byte seed obtained from secure storage or a key derivation function.
final rawSeed = Uint8List.fromList([
  0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
  0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
  0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
  0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
]);

final signerManager = OZExternalSignerManager(
  networkPassphrase: 'Test SDF Network ; September 2015',
);
final ed25519PublicKey = signerManager.addEd25519FromRawKey(
  secretKeyBytes: rawSeed,
  verifierAddress: ed25519VerifierAddress,
);

// 2. Supply the manager via config — construct the kit after the manager is ready.
final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: 'Test SDF Network ; September 2015',
  accountWasmHash:
      '86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28',
  webauthnVerifierAddress:
      'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
  externalSignerManager: signerManager,
);
final kit = OZSmartAccountKit.create(config: config);

// 3. Pass the identifier to the multi-signer call.
final signer = SelectedSignerEd25519(
  verifierAddress: ed25519VerifierAddress,
  publicKey: ed25519PublicKey,
);
```

See also: [`SelectedSignerEd25519`](#selectedsignered25519).

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

The multi-signer pipeline calls this method automatically for each `SelectedSignerEd25519` entry in `selectedSigners`. Direct calls are available for advanced integrations that need to produce signatures outside the pipeline.

After the signing source returns the 64-byte signature, the pipeline locally verifies it against `publicKey` via `KeyPair.fromPublicKey(publicKey).verify(authDigest, signature)` before incorporating it into the authorization payload. A wrong signature throws `TransactionException.signingFailed`.

**Parameters:**

- `verifierAddress`: C-strkey of the Ed25519 verifier contract.
- `publicKey`: 32-byte Ed25519 public key identifying the signer slot.
- `authDigest`: 32-byte auth digest to sign, computed as `SHA-256(signaturePayload || contextRuleIds.toXDR())`.

**Returns:** 64-byte raw Ed25519 signature over `authDigest`.

**Throws:** `ValidationException.invalidInput` (field `"selectedSigners"`) when no signing source is registered for the tuple; `TransactionException.signingFailed` when the adapter or in-memory keypair fails to produce a valid signature.

> **Quirk — adapter-first precedence**: when `ed25519Adapter` is set and its `canSignFor(verifierAddress, publicKey)` returns `true`, the adapter always signs, even if an in-memory keypair is also registered for the same tuple. To force use of the in-memory keypair, set `ed25519Adapter = null`.

> **Quirk — tuple-keyed storage**: the same 32-byte public key registered under two different verifier addresses is stored as two distinct entries. This matches the on-chain signer identity, where an `External(verifierAddress, publicKey)` entry is uniquely identified by both fields. Passing the wrong `verifierAddress` results in `ValidationException.invalidInput` even when the public key is correct.

See also: [`OZExternalEd25519SignerAdapter`](#ozexternaled25519signeradapter), [`SelectedSignerEd25519`](#selectedsignered25519).

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

Adapter for out-of-process Ed25519 signing sources such as hardware wallets and remote signing services. Assign a conforming instance to `OZExternalSignerManager.ed25519Adapter` (or call `setEd25519Adapter(adapter)`) to intercept signing requests before the in-memory keypair registry is consulted.

`canSignFor(verifierAddress, publicKey)`:

- Called synchronously by the pipeline before every Ed25519 sign request.
- `verifierAddress` — C-strkey of the Ed25519 verifier contract.
- `publicKey` — 32-byte Ed25519 public key identifying the signer slot.
- Return `true` if and only if a subsequent `signAuthDigest(authDigest, publicKey)` call for the same key will succeed without error. The pipeline trusts this return value.

`signAuthDigest(authDigest, publicKey)`:

- Called only when `canSignFor` returned `true` for the same `publicKey`.
- `authDigest` — 32-byte digest computed as `SHA-256(signaturePayload || contextRuleIds.toXDR())`.
- `publicKey` — the same 32-byte Ed25519 public key passed to `canSignFor`.
- Returns a 64-byte raw Ed25519 signature over `authDigest`. The pipeline locally verifies the returned signature before incorporating it; a wrong signature throws `TransactionException.signingFailed`.
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

// Construct the manager, attach the adapter, then wire via config.
final signerMgr = OZExternalSignerManager(
  networkPassphrase: 'Test SDF Network ; September 2015',
);
signerMgr.setEd25519Adapter(const MyHardwareWalletAdapter());

final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: 'Test SDF Network ; September 2015',
  accountWasmHash:
      '86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28',
  webauthnVerifierAddress:
      'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
  externalSignerManager: signerMgr,
);
final kit = OZSmartAccountKit.create(config: config);
```

> **Quirk — adapter-first precedence**: the adapter always signs when `canSignFor` returns `true`, even when an in-memory keypair is registered for the same `(verifierAddress, publicKey)` pair. Set `manager.ed25519Adapter = null` (or call `setEd25519Adapter(null)`) to clear the adapter and force the in-memory path.

See also: [`OZExternalSignerManager.signEd25519AuthDigest`](#signed25519authdigest).

### Supporting types

#### ExternalSignerInfo

```dart
class ExternalSignerInfo {
  const ExternalSignerInfo({
    required String address,
    required ExternalSignerType type,
    String? walletName,
    String? walletId,
  });
}
```

- `address`: Stellar G-address.
- `type`: `keypair` or `wallet`.
- `walletName`, `walletId`: Only meaningful when `type == wallet`.

#### ExternalSignerType

```dart
enum ExternalSignerType { keypair, wallet }
```

#### WalletConnectionStorage

```dart
abstract class WalletConnectionStorage {
  const WalletConnectionStorage();
  Future<String?> getItem(String key);
  Future<void> setItem(String key, String value);
  Future<void> removeItem(String key);
}
```

Simple key-value storage interface for persisting external wallet connections. Implementations must be safe for concurrent calls.

#### InMemoryWalletConnectionStorage

```dart
class InMemoryWalletConnectionStorage extends WalletConnectionStorage {
  InMemoryWalletConnectionStorage();
}
```

Default in-memory implementation. Not persistent.

#### createInMemoryWalletConnectionStorage

```dart
WalletConnectionStorage createInMemoryWalletConnectionStorage()
```

Top-level factory returning a fresh `InMemoryWalletConnectionStorage`.

---

## Context Rule Management

### OZContextRuleManager

Manages context rules on the connected smart account. Accessed via `kit.contextRuleManager`.

A context rule pairs a `ContextRuleType` match (default, call-contract, or create-contract) with a signer list and a policy list. When a transaction matches a rule, the smart account authorises it only if the rule's signer and policy requirements are met. Per-rule limits: at most `OZConstants.maxSigners` (15) signers, at most `OZConstants.maxPolicies` (5) policies.

Every state-changing method accepts an optional `List<SelectedSigner>` with the same semantics as on [OZSignerManager](#ozsignermanager): an empty list (the default) authorises with the connected passkey; a non-empty list routes through `OZMultiSignerManager.submitWithMultipleSigners`.

#### addContextRule

```dart
Future<TransactionResult> addContextRule({
  required ContextRuleType contextType,
  required String name,
  int? validUntil,
  required List<OZSmartAccountSigner> signers,
  Map<String, XdrSCVal> policies = const <String, XdrSCVal>{},
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Adds a new context rule.

**Parameters:**

- `contextType`: The `ContextRuleType` (default, call-contract, or create-contract).
- `name`: Human-readable rule name. Must be non-empty.
- `validUntil`: Optional expiration ledger. `null` means no expiration.
- `signers`: Signers attached to the rule. Must obey the per-rule maximum.
- `policies`: Map from policy contract address to its installation parameters (XDR-encoded `ScVal`). Validated and ordered deterministically before submission.

Throws `ValidationException.invalidInput` when the name is empty, when both `signers` and `policies` are empty, when the signer or policy limits are exceeded, or when any policy address is malformed.

#### getContextRule

```dart
Future<XdrSCVal> getContextRule(int id) async
```

Returns the raw `XdrSCVal` for the rule with the supplied on-chain `id`. Use `parseContextRule` to translate the response into a `ParsedContextRule`.

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
Future<List<ParsedContextRule>> listContextRules({int? maxScanId}) async
```

Returns every active context rule parsed into a `ParsedContextRule`.

#### parseContextRule

```dart
ParsedContextRule parseContextRule(XdrSCVal scVal)
```

Synchronously parses a single raw rule struct into a typed `ParsedContextRule`. Throws `ValidationException.invalidInput` when required fields are missing or malformed.

#### resolveContextRuleIdsForEntry

```dart
Future<List<int>> resolveContextRuleIdsForEntry(
  XdrSorobanAuthorizationEntry entry,
  List<OZSmartAccountSigner> signers,
  List<Object> contextRules,
) async
```

Resolves the context-rule IDs that apply to `entry` under the supplied `signers`. Fetches the active rule list when `contextRules` is empty before delegating to the pre-fetched-rules overload.

#### resolveContextRuleIdsForEntryWithRules

```dart
List<int> resolveContextRuleIdsForEntryWithRules(
  XdrSorobanAuthorizationEntry entry,
  List<OZSmartAccountSigner> selectedSigners,
  List<ParsedContextRule> rules,
)
```

Synchronous three-tier resolution against the pre-fetched `rules` list:

1. Tier 1: exact bidirectional signer-set match (same size, every selected signer in rule, every rule signer in selected).
2. Tier 2: rule signers form a subset of selected, and the rule carries no policies.
3. Tier 3: selected signers form a subset of rule (threshold scenarios where the user picks fewer signers than the rule).

Throws `ValidationException.invalidInput` when no rule matches the entry, or when multiple candidate rules still match every selected signer ambiguously.

#### updateName

```dart
Future<TransactionResult> updateName({
  required int id,
  required String name,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Updates the human-readable name of a context rule. Throws `ValidationException.invalidInput` for an empty name.

#### updateValidUntil

```dart
Future<TransactionResult> updateValidUntil({
  required int id,
  int? validUntil,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Updates the expiration ledger of a context rule. Pass `null` to remove the expiration (encoded on-chain as `Option::None`).

#### removeContextRule

```dart
Future<TransactionResult> removeContextRule({
  required int id,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Removes a context rule.

### Supporting types

See [Builder Helpers](#builder-helpers) for `ContextRuleType` (sealed: `ContextRuleTypeDefault`, `ContextRuleTypeCallContract`, `ContextRuleTypeCreateContract`), `ParsedContextRule`, and `OZBuilders`.

---

## Policy Management

### OZPolicyManager

Manages policies on context rules. Accessed via `kit.policyManager`.

A context rule may carry up to `OZConstants.maxPolicies` (5) policies. Every policy must be satisfied for the rule to authorise a transaction. Three convenience helpers are provided for the built-in policy types; custom policy contracts use `addPolicy` directly with an XDR-encoded install-params `ScVal`.

Every state-changing method accepts an optional `List<SelectedSigner>` with the same semantics as on [OZSignerManager](#ozsignermanager).

#### addSimpleThreshold

```dart
Future<TransactionResult> addSimpleThreshold({
  required int contextRuleId,
  required String policyAddress,
  required int threshold,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Installs a `SimpleThresholdParams` policy at `policyAddress` requiring at least `threshold` equal-weight signers from the rule's signer list.

#### addWeightedThreshold

```dart
Future<TransactionResult> addWeightedThreshold({
  required int contextRuleId,
  required String policyAddress,
  required Map<OZSmartAccountSigner, int> signerWeights,
  required int threshold,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Installs a `WeightedThresholdParams` policy where each signer carries a vote weight and the sum of approving-signer weights must reach `threshold`.

#### addSpendingLimit

```dart
Future<TransactionResult> addSpendingLimit({
  required int contextRuleId,
  required String policyAddress,
  required String spendingLimit,
  required int periodLedgers,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Installs a `SpendingLimitParams` policy capping the total amount spent within a rolling ledger window. The decimal `spendingLimit` string is converted to stroops via `Util.toXdrInt64Amount`.

#### addPolicy

```dart
Future<TransactionResult> addPolicy({
  required int contextRuleId,
  required String policyAddress,
  required XdrSCVal installParams,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Adds a policy with custom installation parameters. This is the generic entry point used by `addSimpleThreshold`, `addWeightedThreshold`, and `addSpendingLimit`. Call directly for custom policy contracts whose installation parameters are not covered by the convenience helpers.

#### removePolicy

```dart
Future<TransactionResult> removePolicy({
  required int contextRuleId,
  required int policyId,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
}) async
```

Removes a policy by its on-chain policy ID.

#### removePolicyByAddress

```dart
Future<TransactionResult> removePolicyByAddress({
  required int contextRuleId,
  required String policyAddress,
  List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
  SubmissionMethod? forceMethod,
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

The policy parameter classes are exposed as a sealed hierarchy under `PolicyInstallParams`. The `toScVal()` method on each is marked `@internal` because consumer flows normally use the convenience helpers on `OZPolicyManager`.

#### PolicyInstallParams (sealed)

```dart
sealed class PolicyInstallParams {
  const PolicyInstallParams();
  @internal XdrSCVal toScVal();
}
```

#### SimpleThresholdParams

```dart
final class SimpleThresholdParams extends PolicyInstallParams {
  const SimpleThresholdParams({required int threshold});
  final int threshold;
}
```

#### WeightedThresholdParams

```dart
final class WeightedThresholdParams extends PolicyInstallParams {
  WeightedThresholdParams({
    required Map<OZSmartAccountSigner, int> signerWeights,
    required int threshold,
  });
  final Map<OZSmartAccountSigner, int> signerWeights;
  final int threshold;
}
```

#### SpendingLimitParams

```dart
final class SpendingLimitParams extends PolicyInstallParams {
  const SpendingLimitParams({
    required BigInt spendingLimit,
    required int periodLedgers,
  });
  final BigInt spendingLimit;
  final int periodLedgers;
}
```

`spendingLimit` is expressed in stroops. To construct from a decimal XLM string, use the convenience helper `OZPolicyManager.addSpendingLimit` or the builder `OZSmartAccountBuilders.createSpendingLimitParams`.

---

## Events

> **Scope: SDK lifecycle events only.** `kit.events` emits **kit-level** events (wallet connected/disconnected, credential created/deleted, session expired, transaction signed/submitted). It does **not** emit on-chain smart-account contract events such as `SignerAdded`, `SignerRemoved`, `PolicyInstalled`, `PolicyRemoved`, `ContextRuleAdded`, or `ContextRuleRemoved`. Those are emitted by the OpenZeppelin smart-account contract and must be queried via `SorobanServer.getEvents(...)` with the account's contract ID as a filter.
>
> To fetch on-chain contract events (after the wallet is connected):
>
> ```dart
> final response = await kit.sorobanServer.getEvents(
>   GetEventsRequest(
>     startLedger: fromLedger,
>     filters: [
>       EventFilter(
>         type: 'contract',
>         contractIds: [contractId],
>       ),
>     ],
>   ),
> );
> for (final event in response.events ?? const <EventInfo>[]) {
>   // event.topic and event.value are base64-XDR-encoded SCVal entries
> }
> ```
>
> Each event's `topic` and `value` are base64-XDR-encoded `SCVal` entries that can be parsed with the SDK's XDR utilities.

The kit emits lifecycle events through `kit.events`, a `SmartAccountEventEmitter`. Event subscription is callback-based, not `Stream`-based. Consumers wanting `Stream` semantics can wrap `addListener` into a `StreamController`.

### SmartAccountEventEmitter

```dart
class SmartAccountEventEmitter {
  SmartAccountEventEmitter();

  void setErrorHandler(SmartAccountEventErrorHandler? handler);
  void Function() addListener(SmartAccountEventListener listener);
  void Function() on<E extends SmartAccountEvent>(void Function(E event) listener);
  void Function() once<E extends SmartAccountEvent>(void Function(E event) listener);
  void removeAllListeners([String? eventType]);
  int listenerCount(String eventType);
  void emit(SmartAccountEvent event);
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
typedef SmartAccountEventListener = void Function(SmartAccountEvent event);
typedef SmartAccountEventErrorHandler = void Function(
  SmartAccountEvent event,
  Object error,
  StackTrace stackTrace,
);
```

### Event hierarchy

```dart
sealed class SmartAccountEvent {
  const SmartAccountEvent();
  String get eventTypeName;
}
```

All concrete event arms are `final class` subclasses.

#### SmartAccountEventWalletConnected

```dart
final class SmartAccountEventWalletConnected extends SmartAccountEvent {
  const SmartAccountEventWalletConnected({
    required String contractId,
    required String credentialId,
  });
  final String contractId;
  final String credentialId;
  // eventTypeName: 'WalletConnected'
}
```

Emitted by wallet creation, connection, and deploy-pending paths after the kit's state is set.

#### SmartAccountEventWalletDisconnected

```dart
final class SmartAccountEventWalletDisconnected extends SmartAccountEvent {
  const SmartAccountEventWalletDisconnected({required String contractId});
  final String contractId;
  // eventTypeName: 'WalletDisconnected'
}
```

Emitted by `kit.disconnect()` when a wallet was connected at the time of the call.

#### SmartAccountEventCredentialCreated

```dart
final class SmartAccountEventCredentialCreated extends SmartAccountEvent {
  const SmartAccountEventCredentialCreated({required StoredCredential credential});
  final StoredCredential credential;
  // eventTypeName: 'CredentialCreated'
}
```

Emitted by `createWallet` and `addNewPasskeySigner` after the pending credential is persisted.

#### SmartAccountEventCredentialDeleted

```dart
final class SmartAccountEventCredentialDeleted extends SmartAccountEvent {
  const SmartAccountEventCredentialDeleted({required String credentialId});
  final String credentialId;
  // eventTypeName: 'CredentialDeleted'
}
```

Emitted by `credentialManager.deleteCredential` on successful removal.

#### SmartAccountEventSessionExpired

```dart
final class SmartAccountEventSessionExpired extends SmartAccountEvent {
  const SmartAccountEventSessionExpired({
    required String contractId,
    required String credentialId,
  });
  final String contractId;
  final String credentialId;
  // eventTypeName: 'SessionExpired'
}
```

Emitted by `connectWallet` when an expired session is found and auto-cleared.

#### SmartAccountEventCredentialSyncFailed

```dart
final class SmartAccountEventCredentialSyncFailed extends SmartAccountEvent {
  const SmartAccountEventCredentialSyncFailed({
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

#### SmartAccountEventTransactionSigned

```dart
final class SmartAccountEventTransactionSigned extends SmartAccountEvent {
  const SmartAccountEventTransactionSigned({
    required String contractId,
    required String? credentialId,
  });
  final String contractId;
  final String? credentialId;
  // eventTypeName: 'TransactionSigned'
}
```

Emitted by `transactionOperations.submit` after every required signature has been collected. `credentialId` is `null` when only external signers were involved.

#### SmartAccountEventTransactionSubmitted

```dart
final class SmartAccountEventTransactionSubmitted extends SmartAccountEvent {
  const SmartAccountEventTransactionSubmitted({
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
  if (event is SmartAccountEventWalletConnected) {
    print('Connected to ${event.contractId}');
  }
});

// Typed subscription: receive a single arm.
final unsubscribeTx = kit.events.on<SmartAccountEventTransactionSubmitted>(
  (event) => print('tx ${event.hash} submitted (success=${event.success})'),
);

// One-shot subscription.
kit.events.once<SmartAccountEventWalletDisconnected>(
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

> **Two independent namespaces share the 3xxx range.** `SmartAccountErrorCode` is the **SDK** error enum, surfaced via `SmartAccountException.code` when the kit raises a credential / wallet / WebAuthn / etc. error locally. A separate set of error codes, also in the 3xxx range, is defined by the **on-chain** OpenZeppelin smart-account contract and surfaced in transaction simulation / result XDR (typically wrapped in `TransactionSimulationFailed`). The two overlap but do not collide at runtime because they arrive through different channels:
>
> | Numeric code | SDK meaning (`SmartAccountErrorCode`) | On-chain meaning (OZ contract) |
> |---|---|---|
> | 3002 | `credentialAlreadyExists` | `UnvalidatedContext` |
> | 3003 | `credentialInvalid` | `ExternalVerificationFailed` |
>
> The table above shows only the two codes the SDK enum reuses; the on-chain enum spans `3000` and `3002`-`3016`. When inspecting an error code, first check the exception type to determine which namespace it belongs to. SDK-defined contract codes that the SDK interprets directly are declared in [`ContractErrorCodes`](#contract-error-codes); see the [OpenZeppelin contracts source](https://github.com/OpenZeppelin/stellar-contracts/blob/main/packages/accounts/src/smart_account/mod.rs) for the full on-chain `SmartAccountError` enum, along with the `WebAuthnError` and policy error enums.


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

### ConfigurationException

```dart
sealed class ConfigurationException extends SmartAccountException {
  static ConfigurationException invalidConfig(String details, {Object? cause});
  static ConfigurationException missingConfig(String param, {Object? cause});
}

final class InvalidConfig extends ConfigurationException { }
final class MissingConfig extends ConfigurationException { }
```

**Error Codes**: 1001 (invalidConfig), 1002 (missingConfig)

---

### WalletException

```dart
sealed class WalletException extends SmartAccountException {
  static WalletException notConnected({String? details, Object? cause});
  static WalletException alreadyExists(String identifier, {Object? cause});
  static WalletException notFound(String identifier, {Object? cause});
}

final class WalletNotConnected extends WalletException { }
final class WalletAlreadyExists extends WalletException { }
final class WalletNotFound extends WalletException { }
```

**Error Codes**: 2001 (walletNotConnected), 2002 (walletAlreadyExists), 2003 (walletNotFound)

---

### CredentialException

```dart
sealed class CredentialException extends SmartAccountException {
  static CredentialException notFound(String credentialId, {Object? cause});
  static CredentialException alreadyExists(String credentialId, {Object? cause});
  static CredentialException invalid(String details, {Object? cause});
  static CredentialException deploymentFailed(String details, {Object? cause});
}

final class CredentialNotFound extends CredentialException { }
final class CredentialAlreadyExists extends CredentialException { }
final class CredentialInvalid extends CredentialException { }
final class CredentialDeploymentFailed extends CredentialException { }
```

**Error Codes**: 3001-3004

---

### WebAuthnException

```dart
sealed class WebAuthnException extends SmartAccountException {
  static WebAuthnException registrationFailed(String details, {Object? cause});
  static WebAuthnException authenticationFailed(String details, {Object? cause});
  static WebAuthnException notSupported({String? details, Object? cause});
  static WebAuthnException cancelled({String? details, Object? cause});
}

final class WebAuthnRegistrationFailed extends WebAuthnException { }
final class WebAuthnAuthenticationFailed extends WebAuthnException { }
final class WebAuthnNotSupported extends WebAuthnException { }
final class WebAuthnCancelled extends WebAuthnException { }
```

**Error Codes**: 4001-4004

---

### TransactionException

```dart
sealed class TransactionException extends SmartAccountException {
  static TransactionException simulationFailed(String details, {Object? cause});
  static TransactionException signingFailed(String details, {Object? cause});
  static TransactionException submissionFailed(String details, {Object? cause});
  static TransactionException timeout({String? details, Object? cause});
}

final class TransactionSimulationFailed extends TransactionException { }
final class TransactionSigningFailed extends TransactionException { }
final class TransactionSubmissionFailed extends TransactionException { }
final class TransactionTimeout extends TransactionException { }
```

**Error Codes**: 5001-5004

---

### SignerException

```dart
sealed class SignerException extends SmartAccountException {
  static SignerException notFound(String identifier, {Object? cause});
  static SignerException invalid(String details, {Object? cause});
}

final class SignerNotFound extends SignerException { }
final class SignerInvalid extends SignerException { }
```

**Error Codes**: 6001 (signerNotFound), 6002 (signerInvalid)

---

### ValidationException

```dart
sealed class ValidationException extends SmartAccountException {
  static ValidationException invalidAddress(String address, {Object? cause});
  static ValidationException invalidAmount(String value, {String? reason, Object? cause});
  static ValidationException invalidInput(String field, String reason, {Object? cause});
}

final class InvalidAddress extends ValidationException { }
final class InvalidAmount extends ValidationException { }
final class InvalidInput extends ValidationException { }
```

**Error Codes**: 7001 (invalidAddress), 7002 (invalidAmount), 7003 (invalidInput)

---

### StorageException

```dart
sealed class StorageException extends SmartAccountException {
  static StorageException readFailed(String key, {Object? cause});
  static StorageException writeFailed(String key, {Object? cause});
}

final class StorageReadFailed extends StorageException { }
final class StorageWriteFailed extends StorageException { }
```

**Error Codes**: 8001-8002

---

### SessionException

```dart
sealed class SessionException extends SmartAccountException { }

final class SessionExpired extends SessionException { }
final class SessionInvalid extends SessionException { }
```

**Error Codes**: 9001 (sessionExpired), 9002 (sessionInvalid)

---

### IndexerException

```dart
sealed class IndexerException extends SmartAccountException { }

final class IndexerRequestFailed extends IndexerException { }
final class IndexerTimeout extends IndexerException { }
```

**Error Codes**: 10001-10002

### Contract error codes

```dart
class ContractErrorCodes {
  static const int mathOverflow = 3012;
  static const int keyDataTooLarge = 3013;
  static const int contextRuleIdsLengthMismatch = 3014;
  static const int nameTooLong = 3015;
  static const int unauthorizedSigner = 3016;
}
```

Numeric error codes returned by the OpenZeppelin smart-account contract for failed on-chain calls. Surfaced as the `error` field on `TransactionResult` (alongside the SDK's error wrapping).

### Cancellation semantics

Every cancellable async method accepts an optional `dio.CancelToken`. Cancellation surfaces as:

- `TransactionException.submissionFailed('Operation cancelled', cause: <DioException of type cancel>)` for kit-level transaction operations.
- `OZRelayerResponse(success: false, error: 'Request cancelled')` for the relayer client; the relayer never throws after construction.
- `IndexerException.requestFailed('Request cancelled')` for the indexer client.

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
  static const int webauthnTimeoutMs = 60000;                   // 60 s
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

### LocalStorageAdapter and IndexedDBStorageAdapter defaults

The web storage facades expose the following static defaults:

- `LocalStorageAdapter.defaultKeyPrefix`: `'stellar_sa_'`
- `IndexedDBStorageAdapter.defaultDbName`: `'stellar_smart_account'`

---

## WebAuthn Provider

### WebAuthnProvider abstract class

```dart
abstract class WebAuthnProvider {
  const WebAuthnProvider();

  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  });

  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<AllowCredential>? allowCredentials,
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

### AllowCredential

```dart
class AllowCredential {
  const AllowCredential({required Uint8List id, List<String>? transports});

  final Uint8List id;
  final List<String>? transports;

  static AllowCredential fromId(Uint8List id);
  static List<AllowCredential> fromIds(List<Uint8List> ids);
}
```

Credential descriptor pairing a raw credential ID with optional transport hints, used to constrain which passkeys the authenticator offers during `authenticate`. When `transports` is `null` the authenticator picks the transport.

### PlatformWebAuthnProvider (mobile / desktop)

```dart
class PlatformWebAuthnProvider implements WebAuthnProvider {
  PlatformWebAuthnProvider({
    required String rpId,
    required String rpName,
    int timeout = OZConstants.webauthnTimeoutMs,
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
- `timeout`: WebAuthn ceremony timeout in milliseconds. Defaults to `OZConstants.webauthnTimeoutMs` (60 s).
- `authenticatorAttachment`: Optional `"platform"` or `"cross-platform"` hint. `null` (the default) allows both. Currently ignored by the Apple-side implementation.
- `methodChannel`: Test-only override of the method channel.

**Platform requirements:**

- On Android targets, consumers must host a Digital Asset Links file at `https://<rpId>/.well-known/assetlinks.json` linking the relying-party domain to the consumer app's signing certificate.
- On Apple targets, consumers must declare the relying-party domain in their app's `.entitlements` under `com.apple.developer.associated-domains` with a `webcredentials:<rpId>` entry, and serve the matching Apple App Site Association file at `https://<rpId>/.well-known/apple-app-site-association`.

**Isolate affinity:** must be invoked from the root isolate. Background isolates do not have a foreground activity or window and any call from such an isolate fails with `WebAuthnRegistrationFailed` or `WebAuthnAuthenticationFailed`.

### BrowserWebAuthnProvider (web)

```dart
class BrowserWebAuthnProvider implements WebAuthnProvider {
  BrowserWebAuthnProvider({
    required String rpId,
    required String rpName,
    int timeoutMs = OZConstants.webauthnTimeoutMs,
  });
}
```

Bridges through `navigator.credentials.create()` / `.get()` to the browser's WebAuthn API. Requests COSE algorithm `-7` (ES256, secp256r1) during registration and applies a three-strategy public-key extraction.

The class facade is selected by conditional export: on web the real implementation is used; on non-web targets a stub is selected so cross-target code that holds a typed handle compiles. Every method on the stub throws `UnsupportedError` with guidance to use `PlatformWebAuthnProvider` on mobile / desktop.

---

## Storage Adapter

### StorageAdapter abstract class

```dart
abstract class StorageAdapter {
  Future<void> save(StoredCredential credential);
  Future<StoredCredential?> get(String credentialId);
  Future<List<StoredCredential>> getByContract(String contractId);
  Future<List<StoredCredential>> getAll();
  Future<void> delete(String credentialId);
  Future<void> update(String credentialId, StoredCredentialUpdate updates);
  Future<void> clear();
  Future<void> saveSession(StoredSession session);
  Future<StoredSession?> getSession();
  Future<void> clearSession();
}
```

Pluggable persistence layer for smart-account credentials and sessions. Implementations must be safe for concurrent calls from a single Dart isolate; cross-isolate or cross-process implementations are responsible for any additional synchronisation.

`save` has upsert semantics. `delete` is silently a no-op when no credential matches. `update` throws `CredentialException.notFound` when the target credential does not exist. `getSession` auto-clears expired sessions and returns `null`, so callers always observe "valid session or none".

### Supporting types

#### StoredCredential

```dart
class StoredCredential {
  StoredCredential({
    required String credentialId,
    required Uint8List publicKey,
    String? contractId,
    CredentialDeploymentStatus deploymentStatus = CredentialDeploymentStatus.pending,
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
  final CredentialDeploymentStatus deploymentStatus;
  final String? deploymentError;
  final int createdAt;
  final int? lastUsedAt;
  final String? nickname;
  final bool isPrimary;
  final List<String>? transports;
  final String? deviceType;
  final bool? backedUp;

  StoredCredential copyWith({...});
  StoredCredential applyUpdate(StoredCredentialUpdate updates);
}
```

Equality compares `publicKey` in constant time so credential lookups cannot leak partial-key match information through timing differences.

#### StoredCredentialUpdate

```dart
class StoredCredentialUpdate {
  const StoredCredentialUpdate({
    CredentialDeploymentStatus? deploymentStatus,
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

Partial update spec. Only non-null fields are applied; a `null` value means "no change" and does not clear the field. To clear a field, save a full replacement `StoredCredential` via `StorageAdapter.save`.

#### StoredSession

```dart
class StoredSession {
  const StoredSession({
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

#### CredentialDeploymentStatus

```dart
enum CredentialDeploymentStatus {
  pending,
  failed,
}
```

On successful deployment the credential is removed from storage rather than transitioned to a terminal "deployed" state, so the only persisted statuses are `pending` and `failed`.

### InMemoryStorageAdapter

```dart
class InMemoryStorageAdapter implements StorageAdapter {
  InMemoryStorageAdapter();
}
```

Default fallback when `config.storage` is omitted. Stores all data in a Dart-isolate-local map and does not persist across application restarts. Concurrent calls are serialised through an internal Future-based lock so interleaved reads and writes never observe a partially-applied update.

**Security:** this adapter stores credential public-key bytes and session metadata in plain process memory. Suitable only for testing and development. Production apps must supply a platform-backed secure storage adapter.

All `InMemoryStorageAdapter` instances compare equal because two freshly-created instances are functionally identical (both empty); this makes the adapter usable as the default value of an enclosing data class without breaking that data class's structural equality.

### PlatformStorageAdapter (mobile / desktop)

```dart
class PlatformStorageAdapter implements StorageAdapter {
  PlatformStorageAdapter({MethodChannel? methodChannel});
}
```

Dispatches to the native platform's secure-storage plugin via the `com.soneso.stellar_flutter_sdk/smartaccount/storage` method channel.

- The Android side is backed by `EncryptedSharedPreferences` over the Android Keystore (AES-256-GCM for values, AES-256-SIV for keys).
- The Apple side is backed by the platform Keychain via the Security framework's `SecItem*` primitives.

Method-channel calls are dispatched in arrival order. The native handlers serialise concurrent operations using a platform-specific mutex on each side. Callers do not need to wrap calls in a Dart-side lock.

**Asymmetric corruption handling:**

- `get` returns `null` if the stored payload is corrupt or unreadable; the corruption is logged on the native side but not surfaced to Dart.
- `getAll` skips corrupted entries (logged) and returns the valid subset.
- `update` throws `StorageReadFailed` when the entry is corrupt, because the read-modify-write sequence cannot proceed safely without a known prior state. Callers wanting lossy semantics should `delete` the corrupt entry and `save` a replacement.

The optional `methodChannel` parameter exists for testing only; production code must omit it so the shared channel name is used.

### IndexedDBStorageAdapter (web)

```dart
class IndexedDBStorageAdapter implements StorageAdapter {
  IndexedDBStorageAdapter({String dbName = defaultDbName});

  static const String defaultDbName = 'stellar_smart_account';

  Future<void> close();
  Future<void> deleteDatabase({String? name});
}
```

Browser IndexedDB-backed storage adapter; the recommended option for production web. The database name defaults to `stellar_smart_account` and can be overridden for test isolation. Stores credentials in a `credentials` object store with indices on `contractId`, `createdAt`, and `isPrimary`; sessions live in a `sessions` store keyed by `'current'`.

In addition to the `StorageAdapter` interface, exposes `close()` to release the database connection and `deleteDatabase({String? name})` to remove the database (useful in tests and account-deletion flows).

The class is a conditional-export facade: on web the real `IDBDatabase`-backed implementation is used; on non-web targets a stub is selected so cross-target code compiles. Construction succeeds and `close()` is a no-op on non-web; every other operation throws `UnsupportedError`.

### LocalStorageAdapter (web)

```dart
class LocalStorageAdapter implements StorageAdapter {
  LocalStorageAdapter({String keyPrefix = defaultKeyPrefix});

  static const String defaultKeyPrefix = 'stellar_sa_';
}
```

Browser `localStorage`-backed storage adapter. Approximately 5 MB capacity per origin, unencrypted. Inferior to `IndexedDBStorageAdapter` for production: prefer `IndexedDBStorageAdapter` unless you have a specific reason to use `localStorage` (for example synchronous compatibility with another stack).

The class is a conditional-export facade: on web the real `Storage`-backed implementation is used; on non-web targets a stub is selected. Construction succeeds on non-web; every storage operation throws `UnsupportedError`.

### ExternalWalletAdapter abstract class

```dart
abstract class ExternalWalletAdapter {
  const ExternalWalletAdapter();

  Future<ConnectedWallet?> connect();
  Future<void> disconnect();
  Future<void> disconnectByAddress(String address) async {}

  Future<SignAuthEntryResult> signAuthEntry(
    String preimageXdr, {
    SignAuthEntryOptions? options,
  });

  List<ConnectedWallet> getConnectedWallets();
  bool canSignFor(String address);
  ConnectedWallet? getWalletForAddress(String address) => null;
  Future<ConnectedWallet?> reconnect(String walletId) async => null;
}
```

Protocol for integrating external wallets (Freighter, LOBSTR, and so on) into the multi-signer pipeline. Concrete adapters extend this class so they inherit the no-op defaults for `disconnectByAddress`, `getWalletForAddress`, and `reconnect`.

**signAuthEntry contract:** the SDK supplies a base64-encoded `HashIDPreimage` XDR. The wallet must base64-decode the preimage bytes, SHA-256 hash them, Ed25519-sign the 32-byte hash, and return the 64-byte raw signature base64-encoded. The SDK handles auth-entry construction and signature framing. Adapters that omit the SHA-256 step, sign a different payload, or return a non-canonical encoding produce a signature that the Soroban host rejects at submission time, surfacing as `TransactionException.simulationFailed` during the post-sign re-simulation.

### Supporting types

#### ConnectedWallet

```dart
class ConnectedWallet {
  const ConnectedWallet({
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
- `walletId`: Unique wallet identifier (for example `freighter`, `lobstr`). Used for reconnection via `reconnect`.
- `walletName`: Human-readable display name.

#### SignAuthEntryOptions

```dart
class SignAuthEntryOptions {
  const SignAuthEntryOptions({String? networkPassphrase, String? address});

  final String? networkPassphrase;
  final String? address;
}
```

#### SignAuthEntryResult

```dart
class SignAuthEntryResult {
  const SignAuthEntryResult({
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

## Indexer and Relayer Clients

### OZIndexerClient

```dart
class OZIndexerClient {
  OZIndexerClient(String indexerUrl, {Duration? timeout});

  static Map<String, String> get defaultIndexerUrls;
  static String? getDefaultUrl(String networkPassphrase);
  static OZIndexerClient? forNetwork(String networkPassphrase, {Duration? timeout});

  Future<OZCredentialLookupResponse> lookupByCredentialId(
    String credentialId, {
    dio.CancelToken? cancelToken,
  });

  Future<OZAddressLookupResponse> lookupByAddress(
    String address, {
    dio.CancelToken? cancelToken,
  });

  Future<OZContractDetailsResponse> getContract(
    String contractId, {
    dio.CancelToken? cancelToken,
  });

  Future<OZIndexerStatsResponse> getStats({dio.CancelToken? cancelToken});

  Future<bool> isHealthy({dio.CancelToken? cancelToken});

  Future<void> close();
}
```

Client for the OpenZeppelin smart-account indexer service. The indexer maps WebAuthn credential IDs and signer addresses to deployed smart-account contract addresses, and exposes contract-detail and aggregate statistics endpoints.

**Constructor parameters:**

- `indexerUrl`: Indexer endpoint URL. Must be HTTPS, or `http://localhost…` for local development. Constructor throws `ConfigurationException.invalidConfig` for blank, non-HTTPS, or userinfo-bearing URLs.
- `timeout`: Per-request timeout. Defaults to `OZConstants.defaultIndexerTimeoutMs` (10 s). The connect timeout is capped at `OZConstants.maxIndexerConnectTimeoutMs` independently of the overall timeout.

**Static helpers:**

- `defaultIndexerUrls`: Unmodifiable map from network passphrase to the well-known default indexer URL.
- `getDefaultUrl(networkPassphrase)`: Returns the default URL for the supplied passphrase or `null`.
- `forNetwork(networkPassphrase, {timeout})`: Convenience factory returning a client bound to the default URL for the network, or `null` when no default exists.

**Method behaviour:** every call throws `IndexerException.requestFailed` for network or non-2xx errors, `IndexerException.timeout` when the request exceeds the configured timeout, and `ValidationException` for malformed inputs. `isHealthy` never throws and returns `false` for any failure mode.

`close` releases the underlying HTTP client and is idempotent. The injected-Dio test-only constructor `OZIndexerClient.withDio` is `@visibleForTesting`; the injected client is not closed by `close`.

### Indexer response types

The indexer client returns a family of public DTOs:

- `OZCredentialLookupResponse`: `credentialId`, `contracts: List<OZIndexedContractSummary>`, `count`.
- `OZAddressLookupResponse`: `signerAddress`, `contracts: List<OZIndexedContractSummary>`, `count`.
- `OZContractDetailsResponse`: `contractId`, `summary: OZIndexedContractSummary`, `contextRules: List<OZIndexedContextRule>`.
- `OZIndexedContractSummary`: `contractId`, `contextRuleCount`, `externalSignerCount`, `delegatedSignerCount`, `nativeSignerCount`, `firstSeenLedger`, `lastSeenLedger`, `contextRuleIds`.
- `OZIndexedContextRule`: parsed indexer-side rule representation including signers and policies.
- `OZIndexedSigner`, `OZIndexedPolicy`: entries inside an indexed context rule.
- `OZIndexerStatsResponse` and `OZIndexerStats`: aggregate counts and metadata.
- `OZEventTypeCount`: counts per event type, embedded in stats responses.
- `OZIndexerHealthCheckResponse`: health-check payload (`status`, version metadata).

All response types carry `fromJson` / `toJson` for cross-process serialisation.

### OZRelayerClient

```dart
class OZRelayerClient {
  OZRelayerClient(String relayerUrl, {Duration? timeout});

  Future<OZRelayerResponse> send(
    XdrHostFunction hostFunction,
    List<XdrSorobanAuthorizationEntry> authEntries, {
    int? perRequestTimeoutMs,
    dio.CancelToken? cancelToken,
  });

  Future<OZRelayerResponse> sendXdr(
    XdrTransactionEnvelope transactionEnvelope, {
    int? perRequestTimeoutMs,
    dio.CancelToken? cancelToken,
  });

  Future<void> close();
}
```

Client for submitting transactions to an OpenZeppelin smart-account relayer.

**Constructor parameters:**

- `relayerUrl`: Relayer endpoint URL. Must be HTTPS, or `http://localhost…` for local development.
- `timeout`: Default per-request timeout. Defaults to `OZConstants.defaultRelayerTimeoutMs` (6 min). The connect timeout is capped at `OZConstants.maxRelayerConnectTimeoutMs` independently of the overall timeout.

**Submission modes:**

- `send(hostFunction, authEntries)`: Mode 1. The relayer assembles, fee-bumps, and submits the transaction from its components. Used when no source-account auth entry exists.
- `sendXdr(transactionEnvelope)`: Mode 2. Submits a fully-signed envelope; the relayer fee-bumps it preserving the inner signature. Used when at least one source-account auth entry is present (for example wallet deployment).

Both methods return an `OZRelayerResponse` and **never throw** on network failure, timeout, cancellation, or relayer-reported errors. The `success` flag, `error`, and `errorCode` fields on the response carry the outcome.

`close` releases the underlying HTTP client and is idempotent. The injected-Dio test-only constructor `OZRelayerClient.withDio` is `@visibleForTesting`.

### Relayer types

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

`error` is truncated to at most 200 characters (with an ellipsis suffix) when the relayer returns an oversized message; the cap prevents a hostile relayer from forcing arbitrarily large strings into response instances.

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

- `signature` must be in compact 64-byte format (`r || s`) with a normalised low-S value to prevent malleability. Constructor throws `ValidationException.invalidInput` otherwise.
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

Ed25519 signature with a 32-byte public key and a 64-byte signature. Constructor throws `ValidationException.invalidInput` when either length is wrong.

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

Static helpers for `ContextRuleType` and parsed-rule utilities.

```dart
class OZBuilders {
  static ContextRuleType createDefaultContext();
  static ContextRuleType createCallContractContext(String contractAddress);
  static ContextRuleType createCreateContractContextFromHex(String wasmHashHex);
  static ContextRuleType createCreateContractContextFromBytes(Uint8List wasmHash);

  static List<OZSmartAccountSigner> collectUniqueSignersFromRules(
    List<ParsedContextRule> rules,
  );
}
```

- `createDefaultContext`: Returns `ContextRuleTypeDefault`. Matches any operation that does not match a more specific rule.
- `createCallContractContext`: Returns `ContextRuleTypeCallContract` for the supplied contract address. Validates the address.
- `createCreateContractContextFromHex`: Returns `ContextRuleTypeCreateContract` from a hex-encoded WASM hash (optionally `0x`-prefixed); must decode to 32 bytes.
- `createCreateContractContextFromBytes`: Returns `ContextRuleTypeCreateContract` from raw WASM-hash bytes; must be exactly 32 bytes.
- `collectUniqueSignersFromRules`: Returns the unique signers from `rules`, removing duplicates across rules. First occurrence wins.

### ContextRuleType (sealed)

```dart
sealed class ContextRuleType {
  const ContextRuleType();
  XdrSCVal toScVal();
}

final class ContextRuleTypeDefault extends ContextRuleType {
  const ContextRuleTypeDefault();
}

final class ContextRuleTypeCallContract extends ContextRuleType {
  const ContextRuleTypeCallContract(String contractAddress);
  final String contractAddress;
}

final class ContextRuleTypeCreateContract extends ContextRuleType {
  ContextRuleTypeCreateContract(Uint8List wasmHash);
  final Uint8List wasmHash;
}
```

`toScVal` produces:

- `ContextRuleTypeDefault` → `Vec([Symbol("Default")])`
- `ContextRuleTypeCallContract` → `Vec([Symbol("CallContract"), Address(contractAddress)])`
- `ContextRuleTypeCreateContract` → `Vec([Symbol("CreateContract"), Bytes(wasmHash)])`

`ContextRuleTypeCreateContract` defensively copies the supplied `wasmHash` and uses constant-time byte equality.

### ParsedContextRule

```dart
class ParsedContextRule {
  const ParsedContextRule({
    required int id,
    required ContextRuleType contextType,
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
  static String? getCredentialIdStringFromSigner(OZSmartAccountSigner signer);
  static bool isDelegatedSigner(OZSmartAccountSigner signer);
  static bool isExternalSigner(OZSmartAccountSigner signer);
  static String describeSignerType(OZSmartAccountSigner signer);

  // Signer matching
  static bool signerMatchesCredential(OZSmartAccountSigner signer, Uint8List credentialId);
  static bool signerMatchesCredentialId(OZSmartAccountSigner signer, String credentialId);
  static bool signerMatchesAddress(OZSmartAccountSigner signer, String address);

  // Signer comparison and deduplication
  static bool signersEqual(OZSmartAccountSigner a, OZSmartAccountSigner b);
  static String getSignerKey(OZSmartAccountSigner signer);
  static List<OZSmartAccountSigner> collectUniqueSigners(List<OZSmartAccountSigner> signers);

  // Policy parameter builders
  static OZSimpleThresholdParams createThresholdParams(int threshold);
  static OZWeightedThresholdParams createWeightedThresholdParams({
    required int threshold,
    required Map<OZSmartAccountSigner, int> signerWeights,
  });
  static OZSpendingLimitParams createSpendingLimitParams({
    required String spendingLimit,
    required int periodLedgers,
  });
}
```

**Notes on individual helpers:**

- `getCredentialIdStringFromSigner` returns the Base64URL-encoded credential ID without trailing `=` padding, matching the canonical form produced by the connect path.
- `describeSignerType` returns one of `"Stellar Account"`, `"Passkey (WebAuthn)"`, `"Ed25519"`, or `"External Verifier"`.
- `signerMatchesCredentialId` ignores trailing `=` padding on either side so padded and unpadded forms compare interchangeably.
- `signersEqual` compares the address for delegated signers, and the verifier address plus byte-content of the key data for external signers.
- `collectUniqueSigners` preserves the first occurrence of each duplicate, keyed by `getSignerKey`.
- The policy-parameter builders validate `threshold > 0`, non-empty weights, and so on; they return `OZSimpleThresholdParams`, `OZWeightedThresholdParams`, and `OZSpendingLimitParams` value types. `OZSpendingLimitParams` is constructed via a private constructor accessible only through `createSpendingLimitParams`.

### Policy parameter value types

```dart
class OZSimpleThresholdParams {
  const OZSimpleThresholdParams({required int threshold});
  final int threshold;
}

class OZWeightedThresholdParams {
  const OZWeightedThresholdParams({
    required int threshold,
    required Map<OZSmartAccountSigner, int> signerWeights,
  });
  final int threshold;
  final Map<OZSmartAccountSigner, int> signerWeights;
}

class OZSpendingLimitParams {
  // Constructed via OZSmartAccountBuilders.createSpendingLimitParams.
  final BigInt spendingLimit; // stroops
  final int periodLedgers;
}
```

These public value types are distinct from the sealed `PolicyInstallParams` hierarchy on `OZPolicyManager`; they exist so consumer code can pass typed policy descriptions through its own layers before reaching the manager-level convenience helpers.

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

  static Uint8List? extractPublicKeyFromAuthenticatorData(Uint8List authenticatorData);
  static Uint8List extractPublicKeyFromAttestationObject(Uint8List attestationObject);

  static Uint8List getContractSalt(Uint8List credentialId);

  static String deriveContractAddress({
    required Uint8List credentialId,
    required String deployerPublicKey,
    required String networkPassphrase,
  });
}
```

- `normalizeSignature`: Converts a DER-encoded secp256r1 signature into the 64-byte compact `r || s` form with `s` normalised to the lower half of the curve order (low-S). Throws `ValidationException.invalidInput` on malformed DER.
- `extractPublicKeyFromRegistration`: Three-strategy public-key extraction: direct validation of `publicKey` if it is already a valid 65-byte uncompressed secp256r1 key; otherwise parse `authenticatorData` if available; otherwise scan `attestationObject` for the embedded public key.
- `extractPublicKeyFromAuthenticatorData`: Parses WebAuthn authenticator data and returns the 65-byte uncompressed public key, or `null` when no attested credential data is present.
- `extractPublicKeyFromAttestationObject`: Scans the attestation object for the embedded uncompressed public key.
- `getContractSalt`: Returns `SHA-256(credentialId)`, the salt used in contract-address derivation.
- `deriveContractAddress`: Computes the deterministic smart-account contract address from the credential ID, deployer public key, and network passphrase.

---

## Selected Signer

### SelectedSigner (sealed)

```dart
sealed class SelectedSigner {
  const SelectedSigner();
}
```

Selects a signer to participate in a multi-signature operation. There is no implicit connected passkey: to include it, supply a `SelectedSignerPasskey` entry referencing it.

### SelectedSignerPasskey

```dart
final class SelectedSignerPasskey extends SelectedSigner {
  const SelectedSignerPasskey({
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

### SelectedSignerWallet

```dart
final class SelectedSignerWallet extends SelectedSigner {
  const SelectedSignerWallet(String address);

  final String address;
}
```

A delegated wallet signer identified by its Stellar G-address. The address must have been registered as a `Delegated` signer on the smart-account contract, and the external wallet adapter must be able to sign for it.

### SelectedSignerEd25519

```dart
final class SelectedSignerEd25519 extends SelectedSigner {
  const SelectedSignerEd25519({
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

`SelectedSignerEd25519` carries no signing material. It is a pure identifier; the signing capability must be registered separately via [`OZExternalSignerManager.addEd25519FromRawKey`](#added25519fromrawkey) or by setting [`ed25519Adapter`](#ed25519adapter) on the manager before the multi-signer pipeline executes. The kit resolves the signing source automatically when `SelectedSignerEd25519` appears in `selectedSigners`, provided `OZSmartAccountConfig.externalSignerManager` is non-null.

Value equality compares both fields. `publicKey` equality is byte-by-byte.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Example: transfer authorized by three different signer kinds in one call.
const ed25519VerifierAddress =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

// 1. Construct the external-signer manager and register the Ed25519 key.
final signerManager = OZExternalSignerManager(
  networkPassphrase: 'Test SDF Network ; September 2015',
);
// rawSeed is the 32-byte Ed25519 seed obtained from secure storage.
final ed25519PublicKey = signerManager.addEd25519FromRawKey(
  secretKeyBytes: rawSeed,
  verifierAddress: ed25519VerifierAddress,
);

// 2. Supply the manager via config when constructing the kit.
final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: 'Test SDF Network ; September 2015',
  accountWasmHash:
      '86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28',
  webauthnVerifierAddress:
      'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
  externalSignerManager: signerManager,
);
final kit = OZSmartAccountKit.create(config: config);

// 3. Call the multi-signer method; the kit resolves signing automatically.
final result = await kit.multiSignerManager.multiSignerTransfer(
  tokenContract:
      'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  recipient:
      'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
  amount: '10',
  selectedSigners: <SelectedSigner>[
    SelectedSignerPasskey(credentialId: savedCredId, keyData: savedKeyData),
    SelectedSignerWallet('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ'),
    SelectedSignerEd25519(
      verifierAddress: ed25519VerifierAddress,
      publicKey: ed25519PublicKey,
    ),
  ],
);
```

See also: [`OZExternalSignerManager.addEd25519FromRawKey`](#added25519fromrawkey), [`OZExternalSignerManager.signEd25519AuthDigest`](#signed25519authdigest).
