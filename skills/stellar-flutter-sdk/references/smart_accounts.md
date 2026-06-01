# Smart Accounts Reference

Passkey-authenticated smart accounts on Stellar using OpenZeppelin Soroban contracts. Core production API: kit setup, wallet creation, connection, transactions, credentials, external signers, events, and the indexer.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Configuration](#configuration)
- [Kit Lifecycle](#kit-lifecycle)
- [Creating a Wallet](#creating-a-wallet)
- [Connecting to a Wallet](#connecting-to-a-wallet)
- [Standalone Passkey Authentication](#standalone-passkey-authentication)
- [Signer Types](#signer-types)
- [Transactions](#transactions)
- [Credential Management](#credential-management)
- [External Signer Manager](#external-signer-manager)
- [Events](#events)
- [Indexer](#indexer)
- [Deterministic Address Derivation](#deterministic-address-derivation)
- [Deployer Details](#deployer-details)
- [Error Handling](#error-handling)
- [Constants](#constants)

All public smart-account symbols ship in the single SDK barrel; no separate package or import is required.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

Related references:

- [Soroban Contracts](./soroban_contracts.md) — Soroban RPC, host functions, contract invocation primitives.
- [XDR](./xdr.md) — building `XdrSCVal`, `XdrHostFunction`, auth-entry values.

---

## Overview

A smart account is a Soroban contract whose authorization logic lives on-chain. Instead of a classical Stellar account secured by an Ed25519 secret key, the smart account verifies signatures against configured signers and applies context rules and policies.

Supported signer types:

- WebAuthn passkey (secp256r1) via an on-chain verifier contract.
- Delegated Stellar account (G-address) or contract (C-address) using native `require_auth`.
- Ed25519 external signer via a verifier contract.

`OZSmartAccountKit.create(config: config)` is the single entry point. The kit exposes managers as properties: `walletOperations`, `transactionOperations`, `signerManager`, `contextRuleManager`, `policyManager`, `credentialManager`, `multiSignerManager`, plus `externalSigners` and `events`. Internally the kit owns a `SorobanServer` (RPC), an optional `OZRelayerClient` (fee-bump), and an optional `OZIndexerClient` (credential lookup).

```dart
// WRONG: kit.walletOperations() — it is a property, not a method
// CORRECT: kit.walletOperations — property access (no parentheses)
```

`externalSigners` is a non-null `OZExternalSignerManager` constructed by the kit from config. It is the single front door for all external (non-passkey) signers.

```dart
// WRONG: kit.externalSignerManager — no such getter
// WRONG: kit.externalWallet — no such getter
// CORRECT: kit.externalSigners — non-null, kit-owned
```

---

## Installation

Smart accounts are part of the main SDK package. Add the dependency and import the barrel:

```yaml
# pubspec.yaml
dependencies:
  stellar_flutter_sdk: ^2.x.x   # check pub.dev for the current version
```

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

Every public smart-account type (`OZSmartAccountKit`, `OZSmartAccountConfig`, signer types, result types, the external-signer manager, the indexer client, events, errors) is exported from this one barrel. There is no `smartaccount`-specific import.

---

## Configuration

`OZSmartAccountConfig` is a plain class with four required fields and several optional ones. The constructor validates inputs and throws `ConfigurationException` on invalid values. Use the direct constructor as the primary path.

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `rpcUrl` | `String` | Soroban RPC endpoint URL |
| `networkPassphrase` | `String` | Stellar network passphrase (testnet or mainnet) |
| `accountWasmHash` | `String` | SHA-256 hash (hex, 64 chars) of the smart account WASM |
| `webauthnVerifierAddress` | `String` | C-address of the deployed WebAuthn verifier contract |

```dart
// WRONG: accountWasmHash = 'YWJjMTIzZGVm...' — base64 is NOT accepted
// CORRECT: a 64-character hex string. Regex is [0-9a-fA-F]{64}; the constructor
//          throws ConfigurationException otherwise.
// WRONG: webauthnVerifierAddress = 'GA7Q...' — must be a C-address, not a G-address
// CORRECT: webauthnVerifierAddress = 'CBCD...' — validated via StrKey.isValidContractId
```

### Optional fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `deployerKeypair` | `KeyPair?` | `null` | Null means use the deterministic default deployer |
| `rpId` | `String?` | `null` | WebAuthn Relying Party ID (domain); browser uses origin when null |
| `rpName` | `String` | `'Smart Account'` | Display name shown during WebAuthn prompts |
| `sessionExpiryMs` | `int` | `604800000` (7 days) | Session duration for silent reconnect (milliseconds) |
| `signatureExpirationLedgers` | `int` | `720` (`Util.ledgersPerHour`, ~1 h) | Auth-entry expiration in ledgers (not seconds); replay window. Must be in `[1, 535680]` |
| `timeoutInSeconds` | `int` | `30` | Reserved; no pipeline code currently reads it. Must be in `[1, 600]` |
| `relayerUrl` | `String?` | `null` | Enables fee-bump relayer |
| `indexerUrl` | `String?` | `null` | Enables credential-to-contract discovery |
| `webauthnProvider` | `WebAuthnProvider?` | `null` | Platform passkey implementation |
| `storage` | `StorageAdapter` | `InMemoryStorageAdapter()` | Credential/session persistence |
| `externalWallet` | `ExternalWalletAdapter?` | `null` | Wallet adapter (Freighter/LOBSTR-style) injected into `kit.externalSigners` |
| `externalEd25519Adapter` | `OZExternalEd25519SignerAdapter?` | `null` | Ed25519 adapter (hardware wallet, HSM, remote signer) injected into `kit.externalSigners` |
| `maxContextRuleScanId` | `int` | `50` | Highest context-rule ID to scan when listing |

```dart
// WRONG: sessionExpiryMs = 7 — interpreted as 7 milliseconds, expires immediately
// CORRECT: sessionExpiryMs = 7 * 24 * 60 * 60 * 1000 — milliseconds
// WRONG: signatureExpirationLedgers = 3600 — 3600 ledgers is ~5 hours, not 1 hour
// CORRECT: signatureExpirationLedgers = Util.ledgersPerHour — 720 ledgers ~1 hour
```

> DANGER: the default `InMemoryStorageAdapter` is non-persistent and tests-only. Omit `storage` in production and credentials are lost when the process exits — the on-chain smart account becomes unreachable. Always pass a platform-backed adapter. See [WebAuthn Setup](./smart_accounts_webauthn.md).

### Direct construction (primary path)

```dart
final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: Network.TESTNET.networkPassphrase,
  accountWasmHash:
      'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
  webauthnVerifierAddress:
      'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
  relayerUrl: 'https://relayer.example.com',   // optional
  indexerUrl: 'https://indexer.example.com',   // optional
  webauthnProvider: myWebAuthnProvider,        // required for createWallet / signing
  storage: myKeychainStorageAdapter,           // use platform storage in production
);
```

### copyWith and builder (alternatives)

A `copyWith(...)` method returns a modified copy (pass `setRelayerUrl: true` with `relayerUrl: null` to clear an optional field). A fluent `OZSmartAccountConfig.builder(...)...build()` is also available. Prefer the direct constructor; reach for these only when a derived or fluent shape helps.

### Default deployer

When `deployerKeypair` is null the deterministic default is used. Obtain it directly:

```dart
// Async — derives an Ed25519 keypair from SHA-256('openzeppelin-smart-account-kit').
final KeyPair defaultDeployer =
    await OZSmartAccountConfig.createDefaultDeployer();
print(defaultDeployer.accountId); // always the same G-address
```

See [Deployer Details](#deployer-details).

---

## Kit Lifecycle

Create the kit once and keep it alive for the app session. `create` is synchronous; it makes no network calls and loads no sessions.

```dart
final OZSmartAccountKit kit = OZSmartAccountKit.create(config: config);
```

```dart
// WRONG: OZSmartAccountKit.create(config) — config is a named parameter
// CORRECT: OZSmartAccountKit.create(config: config)
```

### Connection state

Read-only properties reflecting in-memory state only:

```dart
final bool connected     = kit.isConnected;
final String? credId     = kit.credentialId; // Base64URL, no padding
final String? contractId = kit.contractId;   // C-address
```

```dart
// WRONG: kit.credentialId returns hex — it does NOT; it is Base64URL without padding
// CORRECT: credentialId is Base64URL-encoded (WebAuthn specification)
```

After an app restart `isConnected` is always `false`. Call `kit.walletOperations.connectWallet()` to restore the session from storage.

### disconnect — per-session teardown

Clears in-memory connection state and the stored session. Stored credentials remain so the user can reconnect later. The kit, its events, and `externalSigners` stay usable.

```dart
await kit.disconnect();
// Emits SmartAccountEventWalletDisconnected with the previously-connected contractId.
```

### close — final shutdown

Releases the kit's HTTP resources (Soroban RPC transport, indexer, relayer) and removes every event listener. Idempotent. Does NOT touch the stored session — call `disconnect()` first if you want both. After `close()` the kit is no longer usable for new operations; manager calls that need RPC fail because the transport is closed.

```dart
try {
  // use kit ...
} finally {
  await kit.close(); // call close() last
}
```

```dart
// WRONG: await kit.close(); await kit.transactionOperations.transfer(...) — RPC is closed
// CORRECT: perform all operations first; close() is the final call
```

---

## Creating a Wallet

`walletOperations.createWallet(...)` runs a WebAuthn registration ceremony, derives a deterministic contract address, and optionally deploys (and funds on testnet) the smart account contract.

> Account-loss risk — add a backup signer before funding. A freshly-created wallet has exactly one signer: the passkey on the device that ran `createWallet`. If that device is lost and passkey sync is unavailable, the account and its funds become permanently inaccessible. Add a backup signer (second-device passkey, a recovery G-address, or an Ed25519 key) before funding a production wallet. See [Context Rules, Policies, and Multi-Signer](./smart_accounts_policies.md).

### Signature

```dart
Future<CreateWalletResult> createWallet({
  String userName = 'Smart Account User',
  bool autoSubmit = false,
  bool autoFund = false,
  String? nativeTokenContract,
  SubmissionMethod? forceMethod,
  CancelToken? cancelToken,   // dio.CancelToken
});
```

### CreateWalletResult

```dart
class CreateWalletResult {
  final String credentialId;          // Base64URL, no padding
  final String contractId;            // deterministic C-address
  final Uint8List publicKey;          // 65 bytes uncompressed secp256r1
  final String signedTransactionXdr;  // always populated, even when autoSubmit = false
  final String? transactionHash;      // null unless autoSubmit succeeded
  final String? nickname;
}
```

```dart
// WRONG: result.transactionHash is always set — it is null when autoSubmit = false
// CORRECT: signedTransactionXdr is always set; transactionHash only after autoSubmit
// WRONG: result.publicKey.length == 32 — secp256r1, not Ed25519
// CORRECT: result.publicKey.length == 65 (0x04 prefix + 32-byte X + 32-byte Y)
```

### autoSubmit vs autoFund

| Flag | Meaning |
|------|---------|
| `autoSubmit` | Submit the deploy transaction immediately. When `false`, the result carries `signedTransactionXdr` only — submit later with `deployPendingCredential(...)` or your own code. |
| `autoFund` | After deploy, fund the new smart account via Friendbot. Requires `autoSubmit = true` and a `nativeTokenContract` C-address. Testnet-only. |

Idiom: drive `autoFund` from `autoSubmit` (funding only makes sense when the deploy runs) and pass `nativeTokenContract` only when funding (`nativeTokenContract: autoFund ? nativeSac : null`).

```dart
// WRONG: createWallet(autoFund: true) without nativeTokenContract — throws ValidationException
// CORRECT: createWallet(autoSubmit: true, autoFund: true, nativeTokenContract: nativeSac)
// WRONG: autoFund: true on mainnet — Friendbot is testnet-only; funding silently no-ops
// CORRECT: on mainnet leave autoFund: false and fund the wallet out-of-band
```

When `autoFund = true`: a temporary keypair is funded via Friendbot, the SDK waits ~5 s for propagation, then transfers the temp balance minus `OZConstants.friendbotReserveXlm` (5 XLM) to the smart account via the native SAC contract.

### Create and deploy in one call

```dart
final wallet = await kit.walletOperations.createWallet(
  userName: 'Alice',
  autoSubmit: true,
);
print('Contract:    ${wallet.contractId}');
print('Credential:  ${wallet.credentialId}');
print('Deploy hash: ${wallet.transactionHash}');
```

### Create now, deploy later

```dart
// Step 1: create credential and build a signed deploy tx without submitting.
final wallet = await kit.walletOperations.createWallet(
  userName: 'Alice',
  autoSubmit: false,
);
// wallet.signedTransactionXdr is populated; wallet.transactionHash is null.
// The credential is stored with deploymentStatus = CredentialDeploymentStatus.pending.

// Step 2: submit later via deployPendingCredential (uses the stored credential).
final DeployPendingResult deploy =
    await kit.walletOperations.deployPendingCredential(
  credentialId: wallet.credentialId,
  autoSubmit: true,
);
print('Deployed: ${deploy.contractId}, tx: ${deploy.transactionHash}');
```

### Create, deploy, and fund on testnet

On a fresh testnet the default deployer G-account does not exist on-chain and the deploy will fail. Fund it via Friendbot first (skip if a relayer pays deploy fees or you supplied a funded `deployerKeypair`).

```dart
// Ensure the default deployer exists on testnet — required when no relayer is
// configured. The default deployer is deterministic, so this preflight is
// idempotent across processes.
final deployer = await OZSmartAccountConfig.createDefaultDeployer();
final server = SorobanServer(config.rpcUrl);
final existing = await server.getAccount(deployer.accountId);
if (existing == null) {
  await FriendBot.fundTestAccount(deployer.accountId);
  await Future<void>.delayed(const Duration(seconds: 5)); // allow propagation
}

final wallet = await kit.walletOperations.createWallet(
  userName: 'Alice',
  autoSubmit: true,
  autoFund: true,
  nativeTokenContract:
      'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
);
```

### DeployPendingResult and deployPendingCredential

```dart
class DeployPendingResult {
  final String contractId;
  final String signedTransactionXdr;
  final String? transactionHash; // null when autoSubmit was false
}

Future<DeployPendingResult> deployPendingCredential({
  required String credentialId,
  bool autoSubmit = true,
  bool autoFund = false,
  String? nativeTokenContract,
  SubmissionMethod? forceMethod,
  CancelToken? cancelToken,
});
```

The credential must already exist in storage with a valid `publicKey` and `contractId` from a prior `createWallet(autoSubmit: false)`. On successful deployment the credential is deleted from storage.

### Failures

Throws `WebAuthnException`, `ValidationException`, `TransactionException`, `CredentialException`, or `StorageException` subtypes. See [Error Handling](#error-handling).

```dart
// WRONG: calling createWallet() with config.webauthnProvider == null
// Result: throws WebAuthnException (notSupported)
// CORRECT: set config.webauthnProvider to a platform implementation first
```

See [WebAuthn Setup](./smart_accounts_webauthn.md) for platform providers.

---

## Connecting to a Wallet

`walletOperations.connectWallet(...)` restores a session, prompts WebAuthn, or connects directly with known credentials. It suits the two-phase app-launch pattern.

### Signature

```dart
Future<OZConnectWalletResult?> connectWallet({
  ConnectWalletOptions options = const ConnectWalletOptions(),
  CancelToken? cancelToken,
});
```

### ConnectWalletOptions

```dart
class ConnectWalletOptions {
  const ConnectWalletOptions({
    this.credentialId,   // String?
    this.contractId,     // String? — must be paired with credentialId
    this.fresh = false,  // skip session, always WebAuthn
    this.prompt = false, // restore session, else WebAuthn
  });
}
```

### Decision matrix

| Options | Behavior | Returns |
|---------|----------|---------|
| (default) | Silent session restore | `OZConnectWalletConnected` or `null` |
| `prompt: true` | Restore session, else WebAuthn | Non-null on success |
| `fresh: true` | Skip session, always WebAuthn | Non-null on success |
| `credentialId` [+ `contractId`] | Direct connect, skip session and WebAuthn | `OZConnectWalletConnected` on success; throws `WalletNotFound` if the contract does not exist on-chain |

When `credentialId` (or `contractId`) is supplied the method takes the direct path; when neither is set and `fresh` is false it attempts silent restore, returning `null` when no valid session exists and `prompt` is false.

### Tri-state result

`OZConnectWalletResult` is a sealed type with two arms. `OZConnectWalletConnected` means a single contract resolved (kit state set, session saved). `OZConnectWalletAmbiguous` means the indexer reported multiple contracts where the passkey is a signer; kit state is NOT set — let the user pick a contract and reconnect with the chosen `contractId`.

```dart
sealed class OZConnectWalletResult {
  String get credentialId;
}

final class OZConnectWalletConnected extends OZConnectWalletResult {
  final String credentialId;        // Base64URL, no padding
  final String contractId;          // C-address
  final bool restoredFromSession;
}

final class OZConnectWalletAmbiguous extends OZConnectWalletResult {
  final String credentialId;
  final List<String> candidates;    // contract addresses
}
```

`OZConnectWalletAmbiguous` is unreachable when an explicit `contractId` is supplied; that path always yields `OZConnectWalletConnected` or throws.

### Phase 1: silent restore at app launch

```dart
final kit = OZSmartAccountKit.create(config: config);

final restored = await kit.walletOperations.connectWallet();
switch (restored) {
  case null:
    // No saved session — show a Connect button.
    break;
  case OZConnectWalletConnected(:final contractId):
    print('Reconnected to $contractId');
  case OZConnectWalletAmbiguous():
    // Unreachable for silent restore: the saved session supplies an explicit
    // contractId, which bypasses the cascade.
    break;
}
```

### Phase 2: user taps Connect

```dart
final result = await kit.walletOperations.connectWallet(
  options: const ConnectWalletOptions(prompt: true),
);
switch (result) {
  case null:
    break; // unreachable when prompt: true
  case OZConnectWalletConnected(:final contractId):
    print('Connected: $contractId');
  case OZConnectWalletAmbiguous(:final credentialId, :final candidates):
    // Show a picker, then reconnect with credentialId + the chosen contractId.
    final chosen = await showPicker(candidates);
    await kit.walletOperations.connectWallet(
      options: ConnectWalletOptions(
        credentialId: credentialId,
        contractId: chosen,
      ),
    );
}
```

### Force fresh authentication

Required for sensitive operations (for example changing signers):

```dart
final fresh = await kit.walletOperations.connectWallet(
  options: const ConnectWalletOptions(fresh: true),
);
```

### Direct connect with known credentials

No WebAuthn ceremony, no session check. Useful after the user picks a wallet from an indexer list:

```dart
final direct = await kit.walletOperations.connectWallet(
  options: const ConnectWalletOptions(
    credentialId: 'abc123_...',  // Base64URL, from indexer
    contractId: 'CABC...',
  ),
);
// OZConnectWalletConnected on success; throws WalletNotFound if the contract
// does not exist on-chain.
```

```dart
// WRONG: ConnectWalletOptions(contractId: 'CABC...') — contractId alone is rejected
// CORRECT: pair contractId with credentialId
```

### Contract lookup cascade order

When resolving via `credentialId` (or after WebAuthn) without an explicit `contractId`, the SDK resolves in this order:

1. Local storage. A hit means deployment is pending or failed (successful deploy deletes the credential). Failed entries throw `WalletNotFound`; pending entries use the stored `contractId`.
2. Deterministic address derivation from the configured deployer, verified on-chain. If no contract exists at the derived address, the cascade falls through.
3. Indexer fallback (if configured): contracts where the passkey is a registered signer.
   - 0 contracts: throws `WalletNotFound`.
   - 1 contract: verify on-chain and return `OZConnectWalletConnected`.
   - N > 1: return `OZConnectWalletAmbiguous`; kit state is NOT set.

When an explicit `contractId` is supplied the cascade is bypassed and only on-chain verification runs.

---

## Standalone Passkey Authentication

`authenticatePasskey(...)` runs a WebAuthn ceremony without connecting the kit. Use it when you need a signature first and want to discover contracts later, or for multi-signer authorization.

```dart
Future<AuthenticatePasskeyResult> authenticatePasskey({
  Uint8List? challenge,
  List<String>? credentialIds,
  CancelToken? cancelToken,
});

class AuthenticatePasskeyResult {
  final String credentialId;           // Base64URL, no padding
  final OZWebAuthnSignature signature; // normalized compact (low-S) signature
  final Uint8List publicKey;           // 65 bytes if in local storage; empty otherwise
}
```

Typical flow:

```dart
// 1. Authenticate.
final auth = await kit.walletOperations.authenticatePasskey();

// 2. Look up contracts via the indexer.
final response =
    await kit.indexerClient?.lookupByCredentialId(auth.credentialId);
final first = response?.contracts.isNotEmpty == true
    ? response!.contracts.first
    : null;

// 3. Connect to the chosen contract.
if (first != null) {
  await kit.walletOperations.connectWallet(
    options: ConnectWalletOptions(
      credentialId: auth.credentialId,
      contractId: first.contractId,
    ),
  );
}
```

---

## Signer Types

Smart-account signers are a sealed hierarchy:

```dart
sealed class OZSmartAccountSigner {
  XdrSCVal toScVal();
  String get uniqueKey;
}
```

### OZDelegatedSigner

A Stellar address (G or C) that authorizes via native `require_auth`. No verifier contract.

```dart
final accountSigner =
    OZDelegatedSigner('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ');
final contractSigner =
    OZDelegatedSigner('CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY');
```

On-chain SCVal: `Vec([Symbol('Delegated'), Address(address)])`. The constructor throws `ValidationException` (invalid address) when `address` is neither a valid Ed25519 account ID nor a valid contract address.

### OZExternalSigner

A verifier contract plus key-data bytes. Use the factories for passkeys and Ed25519 keys rather than the raw constructor.

```dart
// WebAuthn signer — keyData = publicKey || credentialId.
final OZExternalSigner passkey = OZExternalSigner.webAuthn(
  verifierAddress: 'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
  publicKey: secp256r1PublicKey, // 65 bytes, 0x04 prefix
  credentialId: credentialIdBytes, // raw bytes (NOT Base64URL-encoded here)
);

// Ed25519 signer.
final OZExternalSigner ed = OZExternalSigner.ed25519(
  verifierAddress: 'CDEF...',
  publicKey: ed25519PublicKey, // 32 bytes
);
```

```dart
// WRONG: OZExternalSigner.WebAuthn(...) — no such PascalCase factory
// CORRECT: OZExternalSigner.webAuthn(...)
// WRONG: publicKey.length == 33 — compressed form is not accepted
// CORRECT: publicKey.length == 65 and publicKey[0] == 0x04
// WRONG: credentialId: someBase64UrlString — must be raw bytes
// CORRECT: credentialId is the raw Uint8List from the WebAuthn ceremony
```

The `webAuthn` factory validates `SmartAccountConstants.secp256r1PublicKeySize` (65) and the `0x04` prefix; `ed25519` validates `SmartAccountConstants.ed25519PublicKeySize` (32). On-chain SCVal: `Vec([Symbol('External'), Address(verifier), Bytes(keyData)])`.

### OZSmartAccountBuilders

The same factories with descriptive names plus inspection and matching helpers. All entry points are pure static functions; use these so widget/UI code need not import signer types directly.

```dart
final delegated =
    OZSmartAccountBuilders.createDelegatedSigner('GA7Q...');
final passkey = OZSmartAccountBuilders.createWebAuthnSigner(
  webauthnVerifierAddress: 'CB26...',
  publicKey: publicKey65,
  credentialId: credentialIdBytes,
);
final edSigner = OZSmartAccountBuilders.createEd25519Signer(
  ed25519VerifierAddress: 'CDEF...',
  publicKey: publicKey32,
);

// Inspection
final bool isPasskey = OZSmartAccountBuilders.isExternalSigner(passkey);
final Uint8List? credId =
    OZSmartAccountBuilders.getCredentialIdFromSigner(passkey);
final String? credIdStr =
    OZSmartAccountBuilders.getCredentialIdStringFromSigner(passkey); // Base64URL
final String typeLabel =
    OZSmartAccountBuilders.describeSignerType(passkey); // 'Passkey (WebAuthn)'

// Matching and dedup
final bool matches =
    OZSmartAccountBuilders.signerMatchesCredentialId(passkey, 'base64url-id');
final bool same = OZSmartAccountBuilders.signersEqual(passkey, other);
final List<OZSmartAccountSigner> unique =
    OZSmartAccountBuilders.collectUniqueSigners(signers);
```

### Signer constants

```dart
SmartAccountConstants.ed25519PublicKeySize;     // 32
SmartAccountConstants.ed25519SecretSeedSize;    // 32
SmartAccountConstants.ed25519SignatureSize;     // 64
SmartAccountConstants.secp256r1PublicKeySize;   // 65
SmartAccountConstants.uncompressedPubkeyPrefix; // 0x04
```

---

## Transactions

`kit.transactionOperations` handles token transfers and arbitrary contract calls for the connected smart account. Each state-changing operation runs a WebAuthn ceremony to sign authorization entries.

### TransactionResult

```dart
class TransactionResult {
  final bool success;
  final String? hash;
  final int? ledger;
  final String? error;
}
```

### transfer

SEP-41 compatible token transfer (XLM via SAC, or any Soroban token).

```dart
Future<TransactionResult> transfer({
  required String tokenContract, // C-address of the token contract
  required String recipient,     // G-address or C-address
  required String amount,        // decimal string — converted to stroops internally
  SubmissionMethod? forceMethod,
  CancelToken? cancelToken,
});
```

```dart
final result = await kit.transactionOperations.transfer(
  tokenContract: 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  recipient: 'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
  amount: '10.5',
);
if (result.success) {
  print('Hash: ${result.hash}, ledger: ${result.ledger}');
} else {
  print('Failed: ${result.error}');
}
```

```dart
// WRONG: amount: 10 — must be a String
// CORRECT: amount: '10' — decimal string with up to 7 places
// WRONG: amount: '10500000' — that is 10.5 million XLM, not 10.5
// CORRECT: amount: '10.5' — the SDK converts to stroops automatically
// WRONG: recipient == kit.contractId — transfer-to-self throws ValidationException
// CORRECT: recipient must differ from the smart account's contractId
```

`transfer` throws `WalletNotConnected` when no wallet is connected, `ValidationException` for a bad recipient or amount, `TransactionException` for simulation/submission failures, and `WebAuthnException` for biometric cancellation.

### contractCall

Calls an arbitrary function on an external contract, authorized by the smart account (context-rule type `CallContract(target)`).

```dart
Future<TransactionResult> contractCall({
  required String target,                       // C-address of target contract
  required String targetFn,                     // function name
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
  CancelToken? cancelToken,
});
```

Example — approve a token spender:

```dart
final connected = kit.contractId!;
final args = <XdrSCVal>[
  XdrSCVal.forAddressStrKey(connected),         // from
  XdrSCVal.forAddressStrKey(spenderContract),   // spender
  Util.stroopsToI128ScVal(Util.toXdrInt64Amount('100')), // amount as i128
  XdrSCVal.forU32(720),                         // expiration ledger
];

final result = await kit.transactionOperations.contractCall(
  target: tokenContract,
  targetFn: 'approve',
  targetArgs: args,
);
```

`ResolveContextRuleIds` is `Future<List<int>> Function(XdrSorobanAuthorizationEntry entry, int index)`. Supply it to disambiguate which context rule authorizes an entry when multiple match — see [Context Rules, Policies, and Multi-Signer](./smart_accounts_policies.md).

### executeAndSubmit

Like `contractCall`, but routes through the smart account contract's `execute(target, target_fn, target_args)` entry point. Use it when the target contract should see the smart account as invoker via `execute` rather than via `require_auth`.

```dart
Future<TransactionResult> executeAndSubmit({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
  CancelToken? cancelToken,
});
```

### submit (low-level escape hatch)

Submits an arbitrary host function. `transfer`, `contractCall`, and `executeAndSubmit` all funnel into this after building an `InvokeContract` host function. Use it directly when the host function is not `InvokeContract` (for example `CreateContract`, `UploadContractWasm`) or to hand-craft auth entries.

```dart
Future<TransactionResult> submit({
  required XdrHostFunction hostFunction,
  required List<XdrSorobanAuthorizationEntry> auth,
  SubmissionMethod? forceMethod,
  ResolveContextRuleIds? resolveContextRuleIds,
  CancelToken? cancelToken,
});
```

```dart
// WRONG: submit(hostFunction: hf) — auth is required (pass an empty list)
// CORRECT:
final result = await kit.transactionOperations.submit(
  hostFunction: myHostFunction, // build via XdrHostFunction / InvokeHostFunction helpers — see xdr.md
  auth: const <XdrSorobanAuthorizationEntry>[], // simulation produces the entries
);
```

The SDK simulates the host function, signs auth entries whose address matches the connected smart account, re-simulates, and submits. Pass an empty `auth` list in most cases; pre-supplied entries are forwarded unchanged. See [XDR](./xdr.md) for constructing `XdrHostFunction` values.

### fundWallet

Post-deploy testnet top-up. Generates a throw-away keypair, funds it via Friendbot, and transfers the balance (minus `OZConstants.friendbotReserveXlm`, 5 XLM) to the connected smart account via the native SAC contract. Testnet-only.

```dart
Future<String> fundWallet({
  required String nativeTokenContract, // XLM SAC C-address
  SubmissionMethod? forceMethod,
  CancelToken? cancelToken,
}); // returns the funded amount as a decimal XLM string
```

```dart
// WRONG: fundWallet() — nativeTokenContract is required
// CORRECT:
final amount = await kit.transactionOperations.fundWallet(
  nativeTokenContract: 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
);
print('Funded $amount XLM');
```

Use it after `createWallet(autoSubmit: true, autoFund: false)` to defer funding, or to top up during development. Throws `WalletNotConnected`, `ValidationException` (invalid SAC address), or `TransactionException` (Friendbot/submission failures).

### Submission modes

```dart
enum SubmissionMethod { relayer, rpc }
```

The kit auto-selects: relayer when `relayerUrl` is configured, otherwise direct RPC. Override per call with `forceMethod`:

```dart
final result = await kit.transactionOperations.transfer(
  tokenContract: tokenId,
  recipient: to,
  amount: '10',
  forceMethod: SubmissionMethod.rpc, // force direct RPC even if a relayer is set
);
// Forcing SubmissionMethod.relayer with no relayer configured throws TransactionException.
```

When a relayer is configured the SDK picks automatically between two modes: address-credential auth entries are fee-bumped by the relayer (Mode 1); source-account (Void) auth entries are signed with the deployer keypair, then the relayer fee-bumps (Mode 2). No caller intervention is needed. A relayer can see and censor transactions but cannot steal funds, since signatures are bound to the auth payload — use a relayer you operate or contractually trust on mainnet.

### Lifecycle

Each `transfer` / `contractCall` / `executeAndSubmit` call simulates, prompts WebAuthn once per matching auth entry (usually one per transaction), re-simulates with real signatures, submits, then polls for confirmation. Amounts above 2^53 must use `BigInt` end-to-end (see [BigInt for large amounts](#bigint-for-large-amounts)).

---

## Credential Management

`kit.credentialManager` manages local credential storage. Credentials are WebAuthn passkeys with deployment-state and usage metadata.

### StoredCredential

```dart
class StoredCredential {
  final String credentialId;                  // Base64URL, no padding
  final Uint8List publicKey;                  // 65 bytes uncompressed secp256r1
  final String? contractId;
  final CredentialDeploymentStatus deploymentStatus; // default: pending
  final String? deploymentError;
  final int createdAt;                        // ms since epoch
  final int? lastUsedAt;
  final String? nickname;
  final bool isPrimary;
  final List<String>? transports;             // 'usb' | 'nfc' | 'ble' | 'internal' | 'hybrid'
  final String? deviceType;                   // 'singleDevice' | 'multiDevice'
  final bool? backedUp;
}

enum CredentialDeploymentStatus { pending, failed }
// No 'deployed' status — credentials are deleted from storage after a successful deploy.
```

### Lifecycle

```text
pending --[deploy success]--> deleted from storage
pending --[deploy failure]--> failed (deploymentError set)
pending --[sync discovers contract on-chain]--> deleted from storage
failed  --[deleteCredential]--> deleted from storage
```

After deployment the credential is removed from storage. Reconnection is via sessions (short-term) or the indexer (long-term); the public key stays on-chain as part of the context-rule signers.

### Operations

```dart
// Save or upsert (overwrites existing by ID).
final StoredCredential cred = await kit.credentialManager.saveCredential(
  credentialId: 'abc123_...',
  publicKey: publicKey65,
  nickname: 'MacBook Touch ID',
  contractId: 'CABC...',
);

// Lookup
final StoredCredential? found =
    await kit.credentialManager.getCredential('abc123_...');
final List<StoredCredential> all =
    await kit.credentialManager.getAllCredentials();
final List<StoredCredential> byContract =
    await kit.credentialManager.getCredentialsByContract('CABC...');
final List<StoredCredential> forCurrent =
    await kit.credentialManager.getForConnectedWallet();
final List<StoredCredential> pending =
    await kit.credentialManager.getPendingCredentials();

// Update
await kit.credentialManager.updateNickname('abc123_...', 'MacBook Pro Touch ID');

// Delete (refuses if the contract is already deployed on-chain).
await kit.credentialManager.deleteCredential(credentialId: 'abc123_...');

// Bulk clear (irreversible).
await kit.credentialManager.clearAll();
```

```dart
// WRONG: kit.credentialManager.deleteCredential('abc123_...') — credentialId is named
// CORRECT: kit.credentialManager.deleteCredential(credentialId: 'abc123_...')
```

### Syncing with on-chain state

`sync` and `syncAll` reconcile local storage against the chain — essential when the app may be killed mid-deployment.

```dart
final bool deployed = await kit.credentialManager.sync('abc123_...');
// true  -> contract exists on-chain; credential deleted from storage
// false -> contract not yet on-chain; credential remains

final SyncResult summary = await kit.credentialManager.syncAll();
print('Deployed: ${summary.deployed}, pending: ${summary.pending}, '
    'failed: ${summary.failed}');

class SyncResult {
  final int deployed;
  final int pending;
  final int failed;
}
```

### Storage adapter

`config.storage` defaults to `InMemoryStorageAdapter` (non-persistent). Implement `StorageAdapter` for production using platform storage:

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

See [WebAuthn Setup](./smart_accounts_webauthn.md) for Keychain, EncryptedSharedPreferences, and IndexedDB-backed implementations.

---

## External Signer Manager

`kit.externalSigners` (non-null `OZExternalSignerManager`) is the kit-owned front door for all external (non-passkey) signers. The multi-signer pipeline routes every G-address wallet and Ed25519 signing through it. It handles two signer kinds, each with two custody models.

| Signer kind | In-memory custody (SDK holds the key) | Adapter custody (SDK never sees the key) |
|---|---|---|
| Wallet / G-address | `kit.externalSigners.addFromSecret('S...')` at runtime | `config.externalWallet` (`ExternalWalletAdapter`) at kit construction |
| Ed25519 external | `kit.externalSigners.addEd25519FromRawKey(...)` at runtime | `config.externalEd25519Adapter` (`OZExternalEd25519SignerAdapter`) at kit construction |

```dart
// WRONG: config.externalSignerManager — no such field
// WRONG: config.setEd25519Adapter(...) / kit.ed25519Adapter = ... — no such setters
// CORRECT: pass config.externalWallet / config.externalEd25519Adapter at construction,
//          or register in-memory keys at runtime on kit.externalSigners
final mgr = kit.externalSigners;
```

### Sync vs async

Verify the method shape before calling — several methods are synchronous:

| Method | Shape |
|--------|-------|
| `addFromSecret(secretKey)` | `Future<String>` — await |
| `addFromWallet()` | `Future<ConnectedWallet?>` — await |
| `canSignFor(address)` | `Future<bool>` — await |
| `get(address)` | `Future<ExternalSignerInfo?>` — await |
| `getAll()` | `Future<List<ExternalSignerInfo>>` — await |
| `hasSigners()` | `Future<bool>` — await |
| `signAuthEntry(address, authEntry)` | `Future<SignAuthEntryResult>` — await |
| `remove(address)` | `Future<void>` — await |
| `removeAll()` | `Future<void>` — await |
| `restoreConnections()` | `Future<List<ConnectedWallet>>` — await |
| `addEd25519FromRawKey({...})` | `Uint8List` — synchronous, no await |
| `canSignEd25519For({...})` | `bool` — synchronous, no await |
| `signEd25519AuthDigest({...})` | `Future<Uint8List>` — await |
| `removeEd25519({...})` | `void` — synchronous, no await |

```dart
// WRONG: if (kit.externalSigners.canSignFor(addr)) { ... } — canSignFor is async
// CORRECT: if (await kit.externalSigners.canSignFor(addr)) { ... }
// WRONG: final pk = await kit.externalSigners.addEd25519FromRawKey(...) — it is synchronous
// CORRECT: final pk = kit.externalSigners.addEd25519FromRawKey(...)
```

### Wallet (G-address) signers

```dart
// In-memory custody: register a secret seed at runtime. Returns the derived G-address.
final String gAddress = await kit.externalSigners.addFromSecret(
  'SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34REYB6WBMG7CKKFJHYAEGQ',
);

// Adapter custody: connect a wallet (Freighter/LOBSTR-style) via the configured adapter.
final ConnectedWallet? wallet = await kit.externalSigners.addFromWallet();
// null when the user cancels; throws ConfigurationException when no walletAdapter is set.

// Query
final bool can = await kit.externalSigners.canSignFor(gAddress);
final List<ExternalSignerInfo> all = await kit.externalSigners.getAll();
```

```dart
// WRONG: addFromSecret('GA7Q...') — secret seeds are S-addresses
// CORRECT: addFromSecret('S...') — Stellar secret seed
```

`canSignFor` checks in-memory keypair signers first, then the wallet adapter. `getAll` returns keypair signers first, then wallet signers, deduplicated by address (keypair wins).

```dart
class ExternalSignerInfo {
  final String address;            // G-address
  final ExternalSignerType type;   // keypair | wallet
  final String? walletName;        // only for wallet
  final String? walletId;          // only for wallet
}

enum ExternalSignerType { keypair, wallet }
```

### restoreConnections — call at app launch

For adapter-custody wallets, reconnect persisted connections before any multi-signer action, or the adapter's `canSignFor` returns false for wallets connected in a previous session:

```dart
await kit.externalSigners.restoreConnections();
```

The kit-owned manager uses an in-memory wallet-connection store, so adapter-custody wallet connections do not persist across app launches unless the adapter itself restores them.

### Two Ed25519 custody paths

Ed25519 external signers are keyed by the `(verifierAddress, publicKey)` tuple, matching the on-chain `External(verifier, keyData)` signer slot. Resolution is adapter-first: `config.externalEd25519Adapter` is consulted before the in-memory registry.

```dart
// In-memory custody: register a raw 32-byte seed. Returns the derived 32-byte public key.
final Uint8List publicKey = kit.externalSigners.addEd25519FromRawKey(
  secretKeyBytes: rawSeedBytes,        // exactly 32 bytes — NOT an S-strkey
  verifierAddress: 'CDEF...',          // Ed25519 verifier contract
);

// Pure getter: true when the adapter OR the in-memory registry can sign for the slot.
final bool can = kit.externalSigners.canSignEd25519For(
  verifierAddress: 'CDEF...',
  publicKey: publicKey,
);
```

```dart
// WRONG: addEd25519FromRawKey(secretKeyBytes: utf8.encode('S...'), ...) — must be the raw 32-byte seed
// CORRECT: pass the raw 32-byte Ed25519 seed bytes directly
```

Adapter custody (hardware wallet, HSM, remote signer) keeps the raw seed out of process memory:

```dart
abstract class OZExternalEd25519SignerAdapter {
  bool canSignFor(String verifierAddress, Uint8List publicKey);
  Future<Uint8List> signAuthDigest(Uint8List authDigest, Uint8List publicKey);
}
```

`addEd25519FromRawKey` throws `ValidationException` (invalid input) when `secretKeyBytes` is not exactly 32 bytes.

### Multi-signer cleanup lifecycle (runtime footgun)

When you register in-memory signing material for a multi-signer submit (`addFromSecret` for a delegated/wallet G-address, `addEd25519FromRawKey` for an Ed25519 slot), you MUST clear it on BOTH success and failure so raw key material never persists across operations. Use `try/finally`.

The straightforward cleanup is `removeAll()` — `Future<void>`, await. It clears the in-memory delegated and Ed25519 keypair registries AND calls `walletAdapter?.disconnect()` (disconnecting connected wallets and clearing their persisted connections), covering everything you registered in one call.

```dart
// Register, submit, then clear on BOTH paths.
await kit.externalSigners.addFromSecret(delegatedSecret);
kit.externalSigners.addEd25519FromRawKey(   // synchronous; returns the 32-byte public key
  secretKeyBytes: rawEd25519Seed,
  verifierAddress: ed25519Verifier,
);
try {
  final result = await kit.transactionOperations.transfer(
    tokenContract: tokenId,
    recipient: to,
    amount: '10',
  );
  // ... handle result ...
} finally {
  await kit.externalSigners.removeAll(); // await — async
}
```

> `removeAll()` does NOT clear an Ed25519 adapter supplied via `config.externalEd25519Adapter` — adapter custody is set at construction. If you used adapter custody, clear the adapter's own key state separately via its clear method.

When to prefer TARGETED removal instead — only when you must keep a live wallet-connector session connected across operations (since `removeAll()` disconnects every wallet). Track exactly what you registered and drop only those:

- `remove(address)` — `Future<void>`, await. Drops one G-address's in-memory keypair AND calls `walletAdapter?.disconnectByAddress(address)` for that address only.
- `removeEd25519(verifierAddress: ..., publicKey: ...)` — `void`, synchronous. Drops one in-memory Ed25519 slot.

```dart
// Targeted alternative — preserve a wallet connection you did not register here.
final g = await kit.externalSigners.addFromSecret(delegatedSecret);
final pub = kit.externalSigners.addEd25519FromRawKey(
  secretKeyBytes: rawEd25519Seed, verifierAddress: ed25519Verifier);
try {
  // ... submit ...
} finally {
  await kit.externalSigners.remove(g);                        // await — async
  kit.externalSigners.removeEd25519(                          // synchronous — no await
    verifierAddress: ed25519Verifier, publicKey: pub);
}
```

> `removeAll()` is also the teardown counterpart to `restoreConnections()` for a full logout / reset. It is distinct from `kit.disconnect()`, which only clears the connection session and does NOT touch `externalSigners`.

Adapter-custody Ed25519 keys (`config.externalEd25519Adapter`) live on the adapter, not the manager. Clear them on the adapter instance directly, separately from the manager cleanup above.

### signAuthEntry

For lower-level multi-signer flows, sign an auth-entry preimage with the registered signer for an address. Keypair signers sign locally; wallet signers delegate to the adapter.

```dart
final SignAuthEntryResult signed = await kit.externalSigners.signAuthEntry(
  gAddress,
  base64AuthEntry, // Base64 HashIDPreimage::SorobanAuthorization XDR
);

class SignAuthEntryResult {
  final String signedAuthEntry; // Base64 raw 64-byte Ed25519 signature
  final String? signerAddress;
}
```

```dart
// WRONG: authEntry as hex — must be Base64
// WRONG: treating signedAuthEntry as DER — it is a raw 64-byte Ed25519 signature, Base64-encoded
// CORRECT: base64-decode signedAuthEntry to recover the 64-byte r||s signature
```

Throws `SignerNotFound` when no signer matches the address, `TransactionSigningFailed` on a signing error.

### Standalone construction (advanced)

The multi-signer pipeline always uses `kit.externalSigners`. Construct a manager directly only for advanced use outside a kit — for example to supply a custom `WalletConnectionStorage` for cross-launch wallet-connection persistence.

```dart
OZExternalSignerManager({
  required String networkPassphrase,
  ExternalWalletAdapter? walletAdapter,
  WalletConnectionStorage? walletConnectionStorage,
  OZExternalEd25519SignerAdapter? ed25519Adapter,
});

abstract class WalletConnectionStorage {
  Future<String?> getItem(String key);
  Future<void> setItem(String key, String value);
  Future<void> removeItem(String key);
}
```

`InMemoryWalletConnectionStorage` is the default fallback (loses data on process exit). Implement `WalletConnectionStorage` over `shared_preferences` or secure storage for persistence.

---

## Events

`kit.events` is a `SmartAccountEventEmitter`. Subscribe before the first kit operation so no early lifecycle event is missed. `emit` dispatches synchronously on the calling isolate (no microtask hop), so a listener runs before the awaiting caller resumes; keep listener bodies fast and non-blocking.

### Event types

```dart
sealed class SmartAccountEvent {
  String get eventTypeName;
}

final class SmartAccountEventWalletConnected      // contractId, credentialId
final class SmartAccountEventWalletDisconnected   // contractId
final class SmartAccountEventCredentialCreated    // credential (StoredCredential)
final class SmartAccountEventCredentialDeleted    // credentialId
final class SmartAccountEventSessionExpired       // contractId, credentialId
final class SmartAccountEventCredentialSyncFailed // credentialId, error, stackTrace?
final class SmartAccountEventTransactionSigned     // contractId, credentialId?
final class SmartAccountEventTransactionSubmitted  // hash, success
```

### Subscriptions

```dart
// Typed — returns an unsubscribe function.
final void Function() unsub =
    kit.events.on<SmartAccountEventWalletConnected>((event) {
  print('Connected to ${event.contractId}');
});
unsub();

// One-shot — auto-unsubscribes after the first matching event.
kit.events.once<SmartAccountEventTransactionSubmitted>((event) {
  print('First tx: ${event.hash}, ok=${event.success}');
});

// Global — receives every event.
final unsubAll = kit.events.addListener((event) {
  if (event is SmartAccountEventWalletDisconnected) {
    print('Disconnected: ${event.contractId}');
  }
});
```

### Error handler and other API

Listener exceptions are swallowed by default to protect other listeners. Install a handler for debugging:

```dart
kit.events.setErrorHandler((event, error, stackTrace) {
  print('Listener failed on ${event.eventTypeName}: $error');
});

kit.events.removeAllListeners('WalletConnected'); // by event type name (typed only)
kit.events.removeAllListeners();                  // typed + global
final int n = kit.events.listenerCount('WalletConnected');
```

`SmartAccountEventTransactionSubmitted.success = true` means the network accepted the transaction for inclusion, NOT that it confirmed in a ledger. Use `TransactionResult.success` for confirmed state.

---

## Indexer

`OZIndexerClient` queries an off-chain index of smart-account contracts keyed by credential ID and signer address. Use it for "Connect Wallet" discovery and for fetching on-chain state without iterating context rules by hand.

`kit.indexerClient` is populated when `config.indexerUrl` is set, or when a network default exists for `config.networkPassphrase` (testnet and mainnet have defaults). It is `null` only for custom networks with no explicit `indexerUrl`.

```dart
// WRONG: kit.indexerClient!.lookupByCredentialId(id) — null-unsafe; guard instead
// CORRECT: kit.indexerClient?.lookupByCredentialId(id) — null when no indexer is configured
```

### Methods

```dart
Future<OZCredentialLookupResponse> lookupByCredentialId(String credentialId,
    {CancelToken? cancelToken});
Future<OZAddressLookupResponse> lookupByAddress(String address,
    {CancelToken? cancelToken});
Future<OZContractDetailsResponse> getContract(String contractId,
    {CancelToken? cancelToken});
Future<OZIndexerStatsResponse> getStats({CancelToken? cancelToken});
Future<bool> isHealthy({CancelToken? cancelToken}); // never throws; false on any error
```

```dart
final response = await kit.indexerClient?.lookupByCredentialId(auth.credentialId);
for (final c in response?.contracts ?? const []) {
  print('${c.contractId} (${c.contextRuleCount} rules)');
}

final contracts =
    (await kit.indexerClient?.lookupByAddress('GA7Q...'))?.contracts ??
        const <OZIndexedContractSummary>[];

final details = await kit.indexerClient?.getContract('CABC...');
for (final rule in details?.contextRules ?? const []) {
  print('Rule ${rule.contextRuleId}: ${rule.signers.length} signers, '
      '${rule.policies.length} policies');
}
```

`lookupByCredentialId` accepts the Base64URL credential ID (the SDK converts it to hex for the HTTP call). It throws `ValidationException`, `IndexerRequestFailed`, or `IndexerTimeout`; address/contract lookups validate the address shape and throw `ValidationException` on bad input.

### Direct construction (standalone use)

```dart
final indexer = OZIndexerClient.forNetwork(Network.TESTNET.networkPassphrase)
    ?? (throw StateError('No default indexer URL for this network'));
// or OZIndexerClient(indexerUrl, timeout: Duration(...))
// Close it yourself when used standalone; the kit closes kit.indexerClient automatically.
await indexer.close();
```

Static helpers: `OZIndexerClient.defaultIndexerUrls` (map), `OZIndexerClient.getDefaultUrl(passphrase)`, `OZIndexerClient.forNetwork(passphrase, {timeout})`.

### Response types

```dart
class OZCredentialLookupResponse {
  final String credentialId;                       // Base64URL
  final List<OZIndexedContractSummary> contracts;
  final int count;
}

class OZAddressLookupResponse {
  final String signerAddress;
  final List<OZIndexedContractSummary> contracts;
  final int count;
}

class OZContractDetailsResponse {
  final String contractId;
  final OZIndexedContractSummary summary;
  final List<OZIndexedContextRule> contextRules;
}

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

class OZIndexedContextRule {
  final int contextRuleId;
  final List<OZIndexedSigner> signers;
  final List<OZIndexedPolicy> policies;
}

class OZIndexedSigner {
  final String signerType;     // 'External' | 'Delegated' | 'Native'
  final String? signerAddress; // populated for Delegated
  final String? credentialId;  // HEX, populated for External
}

class OZIndexedPolicy {
  final String policyAddress;
  final Object? installParams; // untyped JSON
}

class OZIndexerStatsResponse { final OZIndexerStats stats; }

class OZIndexerStats {
  final int totalEvents;
  final int uniqueContracts;
  final int uniqueCredentials;
  final int firstLedger;
  final int lastLedger;
  final List<OZEventTypeCount> eventTypes;
}

class OZEventTypeCount { final String eventType; final int count; }
```

```dart
// WRONG: treating OZIndexedSigner.credentialId as Base64URL — the indexer returns HEX here
// CORRECT: it is lowercase hex (no 0x prefix). Convert before matching the SDK's
//          internal Base64URL credential IDs:
//   final bytes = Util.hexToBytes(indexed.credentialId!);
//   final base64url = base64Url.encode(bytes).replaceAll('=', '');
```

---

## Deterministic Address Derivation

The contract address for a smart account is deterministic given the same credential ID, deployer, and network passphrase. `SmartAccountUtils.deriveContractAddress` is synchronous.

```dart
final String derived = SmartAccountUtils.deriveContractAddress(
  credentialId: base64Url.decode(walletResult.credentialId), // raw bytes (NOT Base64URL string)
  deployerPublicKey: deployer.accountId,                     // G-address of deployer
  networkPassphrase: Network.TESTNET.networkPassphrase,
); // returns a C-address
```

Algorithm:

```text
salt          = SHA-256(credentialId)
deployerAddr  = SCAddress::Account(deployerPublicKey)
networkId     = SHA-256(networkPassphrase as UTF-8)
preimage      = HashIDPreimage::ContractID { networkId, FromAddress { deployerAddr, Uint256(salt) } }
contractBytes = SHA-256(XDR_encode(preimage))
contractId    = StrKey.encodeContractId(contractBytes)
```

Use this for wallet discovery without an indexer: derive the address, then verify it exists via `SorobanServer.getContractData`.

### Also exposed

```dart
static Uint8List SmartAccountUtils.getContractSalt(Uint8List credentialId);
static Uint8List SmartAccountUtils.normalizeSignature(Uint8List derSignature);
static Uint8List SmartAccountUtils.extractPublicKeyFromRegistration({
  Uint8List? publicKey,
  Uint8List? authenticatorData,
  Uint8List? attestationObject,
});
```

`normalizeSignature` converts a DER-encoded secp256r1 signature to 64-byte compact `r || s` with low-S normalization, required for Soroban signature verification.

---

## Deployer Details

The deployer is the Stellar keypair whose G-address signs the deploy transaction. Its public key participates in address derivation, so the contract address is deterministic per deployer + credential.

### Default deployer

```dart
// Internally: KeyPair derived from SHA-256('openzeppelin-smart-account-kit').
final KeyPair defaultDeployer =
    await OZSmartAccountConfig.createDefaultDeployer();
```

The default deployer's secret is publicly derivable — anyone who knows the SDK can reconstruct it. This is safe by design: the deployer has no post-deploy authority. After deployment, only the configured signers (passkeys, delegated, Ed25519) can authorize operations; the deployer is not a signer or admin and cannot move funds or change policies.

Implications: every app using the default deployer shows the same deployer G-address on-chain (no attribution); if that shared G-address is funded on mainnet, anyone who knows the derivation can spend its XLM on deploys. Treat the default deployer as a testnet convenience or pair it with a relayer (so it never holds funds).

Set `deployerKeypair` to a keypair you control for mainnet attribution and to avoid the shared-address concerns. Clients that do not know the deployer keypair cannot derive addresses locally — run an indexer for discovery in that case.

### Fee payment summary

| Setup | Who pays the deploy fee |
|-------|-------------------------|
| Relayer configured | Relayer (via fee-bump) |
| No relayer, default deployer | Default deployer G-address (must be funded) |
| No relayer, custom deployer | Your custom deployer G-address (must be funded) |

### Going to mainnet

- Set `networkPassphrase` to the mainnet passphrase and point `rpcUrl` at a mainnet Soroban RPC.
- Stop using Friendbot. `FriendBot.fundTestAccount` targets testnet only — fund mainnet accounts with real XLM out-of-band.
- Set `autoFund: false` on `createWallet`; fund wallets out-of-band unless mainnet funding is plumbed through.
- Replace the default deployer with a custom `deployerKeypair`, or fund the default G-address / configure a relayer.
- Audit `storage` — `InMemoryStorageAdapter` silently loses credentials on process exit, locking users out of mainnet funds.
- Replace any testnet-only contract addresses (WASM hash, WebAuthn verifier, policy contracts) with mainnet values; cross-check against the network passphrase.
- Consider shortening `signatureExpirationLedgers` from the default 720 for high-value flows.

---

## Error Handling

All SDK errors are subtypes of the sealed `SmartAccountException`, which carries a `code` (`SmartAccountErrorCode`) and a `message`. Each category is a sealed subclass with concrete leaf types.

```dart
sealed class SmartAccountException implements Exception {
  final SmartAccountErrorCode code;
  final String message;
  final Object? cause;
}
```

### Hierarchy

| Category (sealed) | Concrete leaf types |
|-------------------|---------------------|
| `ConfigurationException` | `InvalidConfig`, `MissingConfig` |
| `WalletException` | `WalletNotConnected`, `WalletAlreadyExists`, `WalletNotFound` |
| `CredentialException` | `CredentialNotFound`, `CredentialAlreadyExists`, `CredentialInvalid`, `CredentialDeploymentFailed` |
| `WebAuthnException` | `WebAuthnRegistrationFailed`, `WebAuthnAuthenticationFailed`, `WebAuthnNotSupported`, `WebAuthnCancelled` |
| `TransactionException` | `TransactionSimulationFailed`, `TransactionSigningFailed`, `TransactionSubmissionFailed`, `TransactionTimeout` |
| `SignerException` | `SignerNotFound`, `SignerInvalid` |
| `ValidationException` | `InvalidAddress`, `InvalidAmount`, `InvalidInput` |
| `StorageException` | `StorageReadFailed`, `StorageWriteFailed` |
| `SessionException` | `SessionExpired`, `SessionInvalid` |
| `IndexerException` | `IndexerRequestFailed`, `IndexerTimeout` |

### Handling pattern

```dart
try {
  final wallet = await kit.walletOperations.createWallet(
    userName: 'Alice',
    autoSubmit: true,
  );
  print('Created: ${wallet.contractId}');
} on WebAuthnCancelled {
  print('User cancelled the biometric prompt'); // neutral dismissal state
} on WebAuthnException catch (e) {
  print('WebAuthn failed: ${e.message}'); // no credential, rpId mismatch, etc.
} on TransactionException catch (e) {
  print('Transaction failed: ${e.message}');
} on WalletNotFound {
  print('Wallet not found on-chain');
} on SmartAccountException catch (e) {
  print('Error [${e.code.code}]: ${e.message}');
}
```

Catch the category base (`WebAuthnException`, `TransactionException`, ...) for coarse handling; catch a leaf type (`WebAuthnCancelled`, `WalletNotFound`, ...) for fine-grained recovery. Order leaf `on` clauses before their category base.

---

## Constants

```dart
OZConstants.maxSigners;             // 15 (per context rule)
OZConstants.maxPolicies;            // 5  (per context rule)
OZConstants.defaultSessionExpiryMs; // 604800000 (7 days)
OZConstants.defaultTimeoutSeconds;  // 30
OZConstants.defaultRelayerTimeoutMs;// 360000 (6 min)
OZConstants.defaultIndexerTimeoutMs;// 10000
OZConstants.webauthnTimeoutMs;      // 60000
OZConstants.friendbotReserveXlm;    // 5
```

`OZConstants` does NOT bundle a testnet WASM hash or contract addresses — supply those via `OZSmartAccountConfig`.

---

## Pitfall recap

- BigInt for large amounts: `transfer`/`fundWallet` take decimal `String` amounts; `contractCall` i128 args are `BigInt` end-to-end via `Util.stroopsToI128ScVal(Util.toXdrInt64Amount(...))`. For values above 2^53 keep `BigInt` throughout — never lower a sentinel or clamp to fit a JS `Number` (web compatibility). <a id="bigint-for-large-amounts"></a>
- C-address alphabet is base32 `A-Z` + `2-7` (RFC 4648) — never use digits `0`, `1`, `8`, `9`. Invalid C-addresses are rejected silently by `StrKey.isValidContractId` and surface as `ConfigurationException` / `ValidationException`.
- `await` is required for async external-signer methods, especially `canSignFor` and `removeAll`. `addEd25519FromRawKey`, `canSignEd25519For`, and `removeEd25519` are synchronous — do not `await` them.
- `autoFund` is testnet/Friendbot-only and requires `autoSubmit: true` plus a `nativeTokenContract`.
- Call `close()` last; RPC-backed manager calls fail after `close()`.
- Clear in-memory external signing material on both success and failure (`try/finally`). `removeAll()` is the straightforward cleanup (clears all in-memory signers and disconnects wallets); use targeted `remove(address)` + `removeEd25519(...)` only when you must keep a live wallet connection across operations. Neither clears adapter custody (`config.externalEd25519Adapter`) — clear that on the adapter.
