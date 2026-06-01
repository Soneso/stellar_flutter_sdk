# Smart Account Kit

The Smart Account Kit provides passkey-authenticated smart accounts on
Stellar using OpenZeppelin's Soroban contracts. Users authenticate with
biometrics (Face ID, fingerprint, security keys) instead of managing
secret keys. The SDK handles wallet creation, contract deployment,
transaction signing, signer management, and policy enforcement across
Android, iOS, and Flutter web.

New to smart accounts? Start with the [onboarding guide](onboarding.md)
for background on how smart accounts, passkeys, and the on-chain
contracts work.

## Overview

A smart account is a Soroban contract that replaces traditional Stellar
key management with programmable authorization. Each smart account
supports:

- **Passkey authentication**: Users sign transactions with WebAuthn
  (secp256r1) instead of Ed25519 secret keys.
- **Multiple signers**: Combine passkeys, delegated Stellar accounts,
  and Ed25519 keys on a single account.
- **Context rules**: Define different authorization requirements for
  different operation types (default, calling a specific contract,
  creating a specific contract).
- **Policies**: Enforce authorization constraints such as spending
  limits and multi-signature thresholds, or attach custom policy
  contracts.
- **Fee sponsoring**: Submit transactions through an optional relayer so
  users never pay gas fees.
- **Session management**: Silent reconnection without re-authentication
  for 7 days (configurable).
- **Multi-signer transactions**: Coordinate signatures from passkey, delegated wallet, and Ed25519 external signers in a single transaction for context rules that require it.
- **Credential discovery**: Optional indexer lookup that maps a passkey
  credential to one or more deployed smart-account contracts.

The kit wraps the OpenZeppelin smart-account contracts deployed on
Soroban. The on-chain contract stores signers and policies; the SDK
handles WebAuthn ceremonies, transaction assembly, authorization-entry
signing, and submission.

## Architecture

The kit is split into two layers. The `core/` layer defines protocol-agnostic primitives that any Soroban `CustomAccountInterface` contract could use: signer types, signature wrappers, WebAuthn data structures, the `WebAuthnProvider` interface, error hierarchy, and the cryptographic helpers in `SmartAccountUtils`. The `oz/` layer contains code specific to the OpenZeppelin smart account contracts: the kit, all managers, the relayer and indexer HTTP clients, the OZ authorization payload codec, the WebAuthn signature XDR shape, policy install parameters, and the platform storage adapters.

```
+-----------------------------------------------------------------------+
|                         Your Application                              |
+-----------------------------------------------------------------------+
        |
        v
+-----------------------------------------------------------------------+
|                       OZSmartAccountKit                               |
|  Entry point. Created via OZSmartAccountKit.create(config: ...).      |
|  Provides sub-managers as lazy late-final properties:                 |
|                                                                       |
|  +-----------------------+  +----------------------------+            |
|  | walletOperations      |  | transactionOperations      |            |
|  | (OZWalletOperations)  |  | (OZTransactionOperations)  |            |
|  +-----------------------+  +----------------------------+            |
|  +-----------------------+  +----------------------------+            |
|  | signerManager         |  | contextRuleManager         |            |
|  | (OZSignerManager)     |  | (OZContextRuleManager)     |            |
|  +-----------------------+  +----------------------------+            |
|  +-----------------------+  +----------------------------+            |
|  | policyManager         |  | multiSignerManager         |            |
|  | (OZPolicyManager)     |  | (OZMultiSignerManager)     |            |
|  +-----------------------+  +----------------------------+            |
|  +-----------------------+  +----------------------------+            |
|  | credentialManager     |  | events                     |            |
|  | (OZCredentialManager) |  | (SmartAccountEventEmitter) |            |
|  +-----------------------+  +----------------------------+            |
+-----------------------------------------------------------------------+
        |                    |                       |
        v                    v                       v
+-------------------+  +-------------------+  +----------------------------------+
| WebAuthnProvider  |  | StorageAdapter    |  | OZExternalSignerManager          |
| (platform impl)   |  | (platform impl)   |  | (kit-constructed; config.        |
+-------------------+  +-------------------+  | externalWallet +                 |
        |                    |                 | externalEd25519Adapter injected) |
        v                    v                 +----------------------------------+
+----------------+   +-----------------------+
| Platform       |   | Credential & session  |
| biometric UI   |   | store (Keychain,      |
| (OS-level)     |   | EncryptedSharedPrefs, |
|                |   | IndexedDB, ...)       |
+----------------+   +-----------------------+

        OZSmartAccountKit also owns:

+----------------+   +------------------+   +---------------------+
| SorobanServer  |   | OZRelayerClient  |   | OZIndexerClient     |
| (Soroban RPC)  |   | (fee sponsoring) |   | (credential lookup) |
+----------------+   +------------------+   +---------------------+
```

`OZSmartAccountKit` is the single entry point. It holds configuration,
connection state (`isConnected`, `credentialId`, `contractId`), and
exposes all operations through sub-managers. Each sub-manager receives a
reference to the kit and reads its Soroban server, relayer, indexer, and
storage internally.

`WebAuthnProvider` is a platform-specific interface. The SDK ships
`PlatformWebAuthnProvider` (Android, iOS, via method channel) and
`BrowserWebAuthnProvider` (web, via `navigator.credentials`).

`StorageAdapter` persists credentials and sessions. The SDK ships
`InMemoryStorageAdapter` (default, non-persistent),
`PlatformStorageAdapter` (Android `EncryptedSharedPreferences`,
iOS Keychain), `IndexedDBStorageAdapter` (web), and
`LocalStorageAdapter` (web, smaller and unencrypted).

`ExternalWalletAdapter` and `OZExternalEd25519SignerAdapter` are optional adapters that delegate signing to external processes (for example WalletConnect or a hardware wallet). The kit constructs one `OZExternalSignerManager` at creation time and exposes it as `kit.externalSigners` — the unified front door for all external signers. Supply adapters via `config.externalWallet` and `config.externalEd25519Adapter`; register in-memory keypairs at runtime via `kit.externalSigners.addFromSecret(...)` and `kit.externalSigners.addEd25519FromRawKey(...)`.

## Quick Start

Add the SDK to your `pubspec.yaml`:

```yaml
dependencies:
  stellar_flutter_sdk: ^3.0.5
```

The smart-account kit is bundled in the SDK; no separate package is
required. Run `flutter pub get` and import the barrel:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

### Configure and create the kit

All public symbols below come from the SDK. The `accountWasmHash` and
`webauthnVerifierAddress` values shown are placeholders; see
[Testnet contract addresses](#testnet-contract-addresses).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webauthn = PlatformWebAuthnProvider(
  rpId: 'example.com',
  rpName: 'My Smart Wallet',
);

final storage = PlatformStorageAdapter();

final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: 'Test SDF Network ; September 2015',
  accountWasmHash: '<64-char hex SHA-256 of the smart-account WASM>',
  webauthnVerifierAddress: '<C-address of the deployed WebAuthn verifier>',
  rpId: 'example.com',
  rpName: 'My Smart Wallet',
  webauthnProvider: webauthn,
  storage: storage,
  relayerUrl: 'https://relayer.example.com', // optional: fee sponsoring
  indexerUrl: 'https://indexer.example.com', // optional: credential lookup
);

final kit = OZSmartAccountKit.create(config: config);
```

`OZSmartAccountKit.create` allocates `SorobanServer` eagerly. It also
allocates `OZRelayerClient` when `relayerUrl` is set, and
`OZIndexerClient` when `indexerUrl` is set or a network default applies.
There is no implicit `connect` step. Call `kit.close()` to release HTTP
clients and event listeners; `kit.close()` is idempotent and does not
touch storage or connection state.

### Create a wallet

`createWallet` triggers a WebAuthn registration ceremony (biometric
prompt), derives a deterministic contract address from the new passkey,
optionally deploys the contract, and optionally funds the smart account
via Friendbot on testnet.

```dart
final wallet = await kit.walletOperations.createWallet(
  userName: 'Alice',
  autoSubmit: true,
  autoFund: true,
  nativeTokenContract:
      'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
);

// wallet.credentialId         -- base64url-encoded credential ID
// wallet.contractId           -- Stellar C-address of the deployed contract
// wallet.signedTransactionXdr -- signed deploy envelope (always populated)
// wallet.transactionHash      -- deployment tx hash when autoSubmit is true
```

Note: `autoFund` calls Friendbot, which is testnet-only. On mainnet, fund the deployer keypair externally.

### Transfer XLM

`transfer` triggers a WebAuthn authentication ceremony to sign the
authorization entry. If a relayer is configured, the transaction is
fee-sponsored.

```dart
final result = await kit.transactionOperations.transfer(
  tokenContract:
      'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  recipient:
      'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
  amount: '10', // decimal; the SDK converts to stroops
);

if (result.success) {
  print('Transfer succeeded. Hash: ${result.hash}');
} else {
  print('Transfer failed: ${result.error}');
}
```

`transfer` returns a `TransactionResult`. To pass arbitrary contract
calls through the smart account, use
`kit.transactionOperations.contractCall(...)` or
`executeAndSubmit(...)`. For full control over the host function and
pre-built authorization entries, call the low-level
`submit({hostFunction, auth})`.

### Reconnect to an existing wallet

On app relaunch, use a two-step connect pattern. The first step
silently restores the session without prompting the user. If no session
exists, show a connect button and let the user trigger the second step.

```dart
final kit = OZSmartAccountKit.create(config: config);

// Step 1: silent restore at app launch (no biometric prompt).
final silent = await kit.walletOperations.connectWallet();
switch (silent) {
  case null:
    // No saved session: render a "Connect" button.
    break;
  case OZConnectWalletConnected(:final contractId):
    print('Reconnected to $contractId');
  case OZConnectWalletAmbiguous():
    // Unreachable on the silent restore path.
    break;
}

// Step 2: user taps "Connect" -- triggers WebAuthn if no session.
final result = await kit.walletOperations.connectWallet(
  options: const ConnectWalletOptions(prompt: true),
);
switch (result) {
  case null:
    // Unreachable when prompt is true.
    break;
  case OZConnectWalletConnected(:final contractId):
    print('Connected to $contractId');
  case OZConnectWalletAmbiguous(:final candidates, :final credentialId):
    // The indexer reported multiple contracts for this passkey.
    // Show a picker; reconnect with the chosen contract address.
    // Reusing credentialId avoids a second WebAuthn ceremony.
    final chosen = await showContractPicker(candidates);
    await kit.walletOperations.connectWallet(
      options: ConnectWalletOptions(
        credentialId: credentialId,
        contractId: chosen,
      ),
    );
}
```

Force fresh authentication when needed (for example before a sensitive
operation):

```dart
final fresh = await kit.walletOperations.connectWallet(
  options: const ConnectWalletOptions(fresh: true),
);
```

Connect directly with known credentials. This skips WebAuthn and the
session check; the cascade is bypassed so the result is always
`OZConnectWalletConnected` on success:

```dart
final direct = await kit.walletOperations.connectWallet(
  options: const ConnectWalletOptions(
    credentialId: '<credential id>',
    contractId: '<C-address>',
  ),
);
```

### Retry a failed deployment

When `createWallet(autoSubmit: false)` is used, or if a deployment fails
after the credential is created, use `deployPendingCredential` to submit
the deploy transaction later. The credential must exist in local
storage.

```dart
final result = await kit.walletOperations.deployPendingCredential(
  credentialId: pendingCredentialId,
  autoSubmit: true,
);
print('Deployed: ${result.contractId}, tx: ${result.transactionHash ?? "(deferred)"}');
```

### Add a signer

Add additional signers to a context rule so multiple parties can
authorize transactions.

```dart
// Add a delegated Stellar account on the default rule (id 0).
await kit.signerManager.addDelegated(
  contextRuleId: 0,
  address: 'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
);

// Add a new passkey signer end-to-end (WebAuthn registration,
// credential persistence, on-chain signer addition).
final passkeyResult = await kit.signerManager.addNewPasskeySigner(
  contextRuleId: 0,
  userName: 'Alice backup device',
);
// passkeyResult.credentialId       -- base64url credential id
// passkeyResult.publicKey          -- 65-byte uncompressed secp256r1 key
// passkeyResult.transactionResult  -- TransactionResult of the on-chain add

// Low-level: add a pre-registered passkey signer.
await kit.signerManager.addPasskey(
  contextRuleId: 0,
  publicKey: secp256r1PublicKey, // 65-byte uncompressed key
  credentialId: rawCredentialIdBytes,
);

// Remove by on-chain signer id.
await kit.signerManager.removeSigner(
  contextRuleId: 0,
  signerId: 1,
);
```

### Add a policy

Policies enforce constraints on context rules. Each context rule
supports up to 5 policies.

```dart
// Require 2-of-N signers to authorize.
await kit.policyManager.addSimpleThreshold(
  contextRuleId: 0,
  policyAddress: '<C-address of the simple-threshold policy contract>',
  threshold: 2,
);

// Limit spending to 1000 units per day. Ledger count comes from the
// SDK's Util.ledgersPerDay constant.
await kit.policyManager.addSpendingLimit(
  contextRuleId: 0,
  policyAddress: '<C-address of the spending-limit policy contract>',
  spendingLimit: '1000',
  periodLedgers: Util.ledgersPerDay,
);
```

For custom policy contracts beyond the built-in types, use `addPolicy`
with policy-specific install parameters:

```dart
await kit.policyManager.addPolicy(
  contextRuleId: 0,
  policyAddress: '<C-address of the custom policy contract>',
  installParams: XdrSCVal.forMap([
    XdrSCMapEntry(
      XdrSCVal.forSymbol('my_param'),
      XdrSCVal.forU32(42),
    ),
  ]),
);
```

### Multi-signer transfer

When a context rule requires multiple signatures, use
`kit.multiSignerManager` to coordinate. The caller passes a list of
`SelectedSigner` values and the manager drives one signing pass per
signer. Three signer types are supported: passkey, delegated wallet, and
Ed25519 external signer.

For passkey signers, every `SelectedSignerPasskey` in the list must carry
`keyData` populated before the call. For Ed25519 signers, a signing
source must be registered on `kit.externalSigners` for each
`SelectedSignerEd25519` entry — either an in-memory keypair or via
`config.externalEd25519Adapter`. For delegated wallet signers, supply
`config.externalWallet` at kit construction or register a keypair via
`kit.externalSigners.addFromSecret(secretKey)`.

```dart
// 1. Register an in-memory Ed25519 signing source at runtime.
const ed25519VerifierAddress =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

// 2. Construct the kit — the manager is created by the kit automatically.
final config = OZSmartAccountConfig(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: 'Test SDF Network ; September 2015',
  accountWasmHash: '<64-char hex WASM hash>',
  webauthnVerifierAddress: '<C-address of WebAuthn verifier>',
  // Optional: supply an out-of-process Ed25519 adapter at construction.
  // externalEd25519Adapter: myHardwareWalletAdapter,
  // Optional: supply an external wallet adapter for G-address signers.
  // externalWallet: myWalletConnectAdapter,
  // ...other fields...
);
final kit = OZSmartAccountKit.create(config: config);

// rawSeed is the 32-byte Ed25519 seed obtained from secure storage.
final ed25519PublicKey = kit.externalSigners.addEd25519FromRawKey(
  secretKeyBytes: rawSeed,
  verifierAddress: ed25519VerifierAddress,
);

// Optional: register an in-memory keypair for a G-address wallet signer.
// await kit.externalSigners.addFromSecret(secretKey);

// 3. Call the multi-signer method with all three signer kinds.
final result = await kit.multiSignerManager.multiSignerTransfer(
  tokenContract:
      'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  recipient:
      'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
  amount: '25',
  selectedSigners: <SelectedSigner>[
    SelectedSignerPasskey(credentialId: passkeyCredId, keyData: passkeyKeyData),
    SelectedSignerWallet('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ'),
    SelectedSignerEd25519(
      verifierAddress: ed25519VerifierAddress,
      publicKey: ed25519PublicKey,
    ),
  ],
);
```

`multiSignerContractCall` and `multiSignerExecuteAndSubmit` provide the
same multi-signer flow for arbitrary contract calls.

### Error handling

All operations throw subclasses of `SmartAccountException`, organised
under sealed bases for each error range. The `code` field is a
`SmartAccountErrorCode` enum value (numeric ranges by category).

```dart
try {
  final wallet = await kit.walletOperations.createWallet(
    userName: 'Alice',
    autoSubmit: true,
  );
} on WebAuthnCancelled {
  print('User cancelled the biometric prompt');
} on WebAuthnNotSupported catch (e) {
  print('WebAuthn not configured: ${e.message}');
} on TransactionSimulationFailed catch (e) {
  print('Contract simulation failed: ${e.message}');
} on TransactionSubmissionFailed catch (e) {
  print('Transaction submission failed: ${e.message}');
} on WalletNotFound catch (e) {
  print('Wallet not found on-chain: ${e.message}');
} on SmartAccountException catch (e) {
  print('Smart-account error [${e.code.code}]: ${e.message}');
}
```

### Event subscription

The kit's `events` property is a callback-based emitter
(`SmartAccountEventEmitter`). It is not a Dart `Stream`. Use
`on<E>(...)`, `once<E>(...)`, or the global `addListener(...)` and
remember to call the returned unsubscribe closure when the listener is
no longer needed.

```dart
final unsubscribe = kit.events.on<SmartAccountEventWalletConnected>((e) {
  print('Connected to ${e.contractId}');
});

// later
unsubscribe();
```

## Configuration Reference

`OZSmartAccountConfig` holds all parameters. Four fields are required;
all others have defaults. The constructor validates inputs and throws
`ConfigurationException` (one of `InvalidConfig` or `MissingConfig`) on
bad input.

### Required fields

| Field | Type | Description |
|---|---|---|
| `rpcUrl` | `String` | Soroban RPC endpoint URL (for example `https://soroban-testnet.stellar.org`). |
| `networkPassphrase` | `String` | Stellar network passphrase. Use `'Test SDF Network ; September 2015'` on testnet or `'Public Global Stellar Network ; September 2015'` on mainnet. |
| `accountWasmHash` | `String` | SHA-256 hash (64 hex characters) of the smart-account contract WASM binary. Obtained after uploading the contract to the network. |
| `webauthnVerifierAddress` | `String` | Contract address (`C...`, 56 characters) of the deployed WebAuthn signature verifier. |

### Optional fields

| Field | Type | Default | Description |
|---|---|---|---|
| `deployerKeypair` | `KeyPair?` | `null` (uses default) | Keypair used as the deployment source. If `null`, the kit derives the deterministic default from `SHA-256("openzeppelin-smart-account-kit")`. See [How wallet deployment works](#how-wallet-deployment-works). |
| `rpId` | `String?` | `null` | WebAuthn relying-party identifier. Documentation field on the config; the WebAuthn provider receives its own `rpId` at construction time. |
| `rpName` | `String` | `'Smart Account'` | Display name shown during WebAuthn ceremonies. Documentation field; the WebAuthn provider receives its own `rpName` at construction. |
| `sessionExpiryMs` | `int` | `604800000` (7 days) | Session duration in milliseconds. Sessions enable silent reconnection. |
| `signatureExpirationLedgers` | `int` | `Util.ledgersPerHour` (`720`, ~1 hour) | Authorization-entry expiration in ledgers (~5 s per ledger). Capped to `[1, 535_680]` (~31 days). |
| `timeoutInSeconds` | `int` | `30` | Reserved for future use. No pipeline code currently reads this value; polling and transaction-submission timeouts are determined by internal defaults. Capped to `[1, 600]`. |
| `relayerUrl` | `String?` | `null` | Relayer endpoint for fee-sponsored transactions. When set, the kit allocates `OZRelayerClient` with a 6-minute request timeout. |
| `indexerUrl` | `String?` | network default | Indexer endpoint for credential-to-contract lookup. When `null`, the kit uses `OZIndexerClient.getDefaultUrl(networkPassphrase)` if one exists. |
| `webauthnProvider` | `WebAuthnProvider?` | `null` | Platform-specific WebAuthn implementation. Required for `createWallet`, `connectWallet(prompt: true)`, `authenticatePasskey`, and any passkey-signing flow. |
| `storage` | `StorageAdapter?` | `InMemoryStorageAdapter()` | Credential and session persistence. Use a platform-specific adapter in production. |
| `externalWallet` | `ExternalWalletAdapter?` | `null` | Adapter for out-of-process wallet signing (for example WalletConnect). The kit injects this into `kit.externalSigners` at construction. In-memory G-address keypairs can be registered at runtime via `kit.externalSigners.addFromSecret(secretKey)` without an adapter. |
| `externalEd25519Adapter` | `OZExternalEd25519SignerAdapter?` | `null` | Adapter for out-of-process Ed25519 signing (for example hardware wallets). The kit injects this into `kit.externalSigners` at construction. In-memory Ed25519 keys can be registered at runtime via `kit.externalSigners.addEd25519FromRawKey(...)` without an adapter. |
| `maxContextRuleScanId` | `int` | `50` | Upper bound on the context-rule id scan when listing rules. Must be `>= 0`. |

### Builder pattern

```dart
final config = OZSmartAccountConfig.builder(
  rpcUrl: 'https://soroban-testnet.stellar.org',
  networkPassphrase: 'Test SDF Network ; September 2015',
  accountWasmHash: '<wasm hash hex>',
  webauthnVerifierAddress: '<verifier C-address>',
)
    .rpName('My Wallet App')
    .sessionExpiryMs(86400000) // 1 day
    .relayerUrl('https://relayer.example.com')
    .indexerUrl('https://indexer.example.com')
    .signatureExpirationLedgers(1440) // ~2 hours
    .storage(myStorageAdapter)
    .webauthnProvider(myWebAuthnProvider)
    .build();
```

### Platform wiring

Each platform pairs a `WebAuthnProvider` with a `StorageAdapter`. Use `PlatformWebAuthnProvider` + `PlatformStorageAdapter` on Android/iOS, and `BrowserWebAuthnProvider` + `IndexedDBStorageAdapter` on web. See [Sub-pages](#sub-pages) for per-platform entitlements and hosting.

### Storage adapter trade-offs

- **`InMemoryStorageAdapter`** -- process-memory only, not encrypted, not
  persisted. Suitable for unit tests and ephemeral dev sessions. All
  instances compare equal (so two configs with the default storage
  remain equal).
- **`PlatformStorageAdapter`** -- production choice on mobile.
  Android encrypts values with AES-256-GCM and wraps keys with
  AES-256-SIV via the Android Keystore. iOS uses the platform
  Keychain. Read-modify-write sequences are serialised on the native
  side.
- **`IndexedDBStorageAdapter`** -- recommended for production web. Larger
  quota than `localStorage`, indices on `contractId`, `createdAt`, and
  `isPrimary`, and an extra `Future<void> close()` and
  `deleteDatabase()` API beyond the abstract interface.
- **`LocalStorageAdapter`** -- web fallback. Around 5 MB per origin,
  unencrypted, simpler to reason about than IndexedDB. Use only when
  the dataset is small and the threat model accepts unencrypted local
  storage.

Per-platform setup steps for entitlements, Digital Asset Links, and
HTTPS hosting live in the dedicated WebAuthn pages: see
[Sub-pages](#sub-pages).

## Testnet contract addresses

Two values in `OZSmartAccountConfig` are tied to on-chain deployments
and change when the contracts are rebuilt or testnet is reset:

- `accountWasmHash` -- SHA-256 (hex) of the uploaded smart-account WASM.
- `webauthnVerifierAddress` -- `C...` address of the deployed WebAuthn
  signature verifier contract.

| Network passphrase | Default indexer URL |
|---|---|
| `Test SDF Network ; September 2015` | `https://smart-account-indexer.sdf-ecosystem.workers.dev` |
| `Public Global Stellar Network ; September 2015` | `https://smart-account-indexer-mainnet.sdf-ecosystem.workers.dev` |

Current testnet WASM hash and verifier contract address are published in
the OpenZeppelin
[stellar-contracts](https://github.com/OpenZeppelin/stellar-contracts)
repository. Look up the latest release for the multisig account example
and the WebAuthn verifier contract.

### Uploading your own WASM

If the published hash has expired (entries can be restored, but the hash
remains the same after restoration) or you need a custom build, clone
[stellar-contracts](https://github.com/OpenZeppelin/stellar-contracts)
and build/upload:

```bash
# Build the smart-account WASM
stellar contract build --package multisig-account-example

# Upload to testnet and capture the returned hash
stellar contract upload \
  --network testnet \
  --source <deployer-secret> \
  --wasm target/wasm32v1-none/release/multisig_account_example.wasm
```

The command prints a hex string. Use it as `accountWasmHash`.

## How wallet deployment works

`createWallet` deploys a Soroban smart-account contract. The deployment
involves two roles played by the deployer keypair:

1. **Address derivation.** The contract address is computed from
   `hash(deployer_public_key, salt, network_passphrase)` where `salt`
   is `SHA-256(credential_id)`. This is deterministic: given the same
   deployer keypair, credential ID, and network passphrase,
   `SmartAccountUtils.deriveContractAddress(...)` always returns the
   same contract address. It is a correctness property that follows
   directly from how Soroban computes contract addresses, not a special
   feature.
2. **Transaction signing.** The deployer signs the deployment
   transaction as its source account.

After deployment, the deployer has no privileges over the contract.
Only the configured signers (passkeys, delegated accounts, Ed25519
keys) can authorize operations on the smart account.

When a relayer is configured, the SDK still uses the deployer to derive
the contract address and build the deployment transaction, but submits
through the relayer which wraps it in a fee-bump transaction and pays
the fees. The deployer account must still exist on the network with the
minimum XLM reserve, but does not need to pay fees in this case.

On testnet, `autoFund: true` funds the smart-account contract via
Friendbot after deployment, retaining
`OZConstants.friendbotReserveXlm` (5 XLM) on the temporary funding
account as its minimum balance reserve.

### Default deployer

The SDK provides a default deployer derived from
`SHA-256("openzeppelin-smart-account-kit")` used as the Ed25519 seed:

```dart
final deployer = await OZSmartAccountConfig.createDefaultDeployer();
```

The default deployer's secret seed is publicly derivable. It is intended
to be used either with a relayer that sponsors transaction fees, or
funded externally before deployment. The seed string is fixed by the
contract spec, so the default deployer keypair is always the same and
wallets deployed through it share a single deterministic address space.

### Custom deployers

Production wallet applications typically use a custom deployer for
attribution and traceability. The deployer's public key is visible
on-chain, so a custom deployer gives the wallet provider an identity
that distinguishes deployments by different providers.

```dart
final config = OZSmartAccountConfig(
  // required fields ...
  deployerKeypair: myFundedKeypair,
);
```

Address derivation still applies: the same deployer plus credential ID
always produces the same contract address. With a custom deployer, an
indexer is recommended for wallet discovery, since clients that do not
know the deployer keypair cannot derive the address independently.

### Signer format compatibility

`OZDelegatedSigner` and `OZExternalSigner` encode to the standard SCVal
shape expected by the on-chain contract. The
`OZExternalSigner.webAuthn` factory packs the 65-byte SEC1 uncompressed
public key with the raw credential ID into the `keyData` field; the
`OZExternalSigner.ed25519` factory packs the 32-byte Ed25519 public key
alone. Signers added by any compatible smart-account SDK are recognised
on-chain.

WebAuthn-side helpers in `SmartAccountUtils` convert raw passkey output
into these formats:

- `extractPublicKeyFromRegistration({publicKey, authenticatorData,
  attestationObject})` runs a three-strategy cascade to produce the
  65-byte SEC1 uncompressed key from whatever the platform returned.
- `normalizeSignature(derBytes)` converts a DER-encoded ECDSA signature
  into the 64-byte compact `r || s` form with `s` in the low-S range,
  which is what the on-chain verifier expects.

## Contract limits

The OpenZeppelin smart-account contract enforces these limits per
context rule, also surfaced in `OZConstants`:

| Limit | Value | Source |
|---|---|---|
| Maximum signers per context rule | 15 | `OZConstants.maxSigners` |
| Maximum policies per context rule | 5 | `OZConstants.maxPolicies` |

The kit validates these limits client-side before submitting
transactions and reports violations as `ValidationException`. Contract-
level error codes returned by failed simulations are surfaced via
`ContractErrorCodes` (for example `keyDataTooLarge`, `nameTooLong`,
`unauthorizedSigner`).

## Sub-pages

| Guide | Description |
|---|---|
| [Onboarding Guide](onboarding.md) | Concepts behind smart accounts, passkeys, the on-chain contract, and the end-to-end lifecycle. |
| [API Reference](api-reference.md) | Full API reference for every public class and method in the smart-account namespace. |
| [WebAuthn Setup: iOS](webauthn-ios.md) | iOS AuthenticationServices integration and apple-app-site-association hosting. |
| [WebAuthn Setup: Android](webauthn-android.md) | Android Credential Manager integration and Digital Asset Links hosting. |
| [WebAuthn Setup: Web](webauthn-web.md) | Browser WebAuthn API, IndexedDB storage, and localhost development. |
