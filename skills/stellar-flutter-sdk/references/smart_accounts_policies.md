# Context Rules, Policies, and Multi-Signer Operations

Signer management, context rules, policies, and multi-signer operations for an existing OpenZeppelin smart account — the dynamic authorization layer on top of the kit and transaction API in [smart_accounts.md](./smart_accounts.md). WebAuthn setup is covered in [smart_accounts_webauthn.md](./smart_accounts_webauthn.md).

Every public symbol referenced here is exported from `package:stellar_flutter_sdk/stellar_flutter_sdk.dart`.

```dart
import 'dart:convert';   // base64Url
import 'dart:math';      // Random.secure (recovery flow)
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

All operations are `async` and return a `Future`. The examples assume `final OZSmartAccountKit kit` is created and `kit.walletOperations.connectWallet(...)` has returned a connected session — see [smart_accounts.md](./smart_accounts.md#connecting-to-a-wallet). When connected, `kit.contractId` is the smart account's C-address and `kit.credentialId` is the active credential (Base64URL, unpadded).

## Table of Contents

- [Overview](#overview)
- [Signer Management](#signer-management)
- [Context Rules](#context-rules)
- [Policies](#policies)
- [Multi-Signer Operations](#multi-signer-operations)
- [Common Scenarios](#common-scenarios)
- [Events](#events)
- [Contract Error Codes](#contract-error-codes)

## Overview

On-chain authorization for an OZ smart account is arranged in three layers:

```
Smart Account (C-address)
  |
  +-- Context Rule #0 (Default, created at deploy)
  |     +-- Signers:  [Passkey (user's initial credential)]
  |     +-- Policies: []
  |
  +-- Context Rule #1 (CallContract("Cxxx...") e.g. a token)
  |     +-- Signers:  [Passkey A, Passkey B, Wallet G...]
  |     +-- Policies: [SpendingLimit("100 XLM / day")]
  |
  +-- Context Rule #2 (CallContract("Cyyy...") e.g. a DAO)
        +-- Signers:  [Wallet G..., Wallet G...]
        +-- Policies: [WeightedThreshold(weights, 80)]
```

When a transaction runs, the contract picks rules whose context type matches the invocation: specific-type rules (`CallContract`, `CreateContract`) are evaluated first, the `Default` rule is the fallback. A rule passes when its signers have signed and every one of its policies returns `true`.

**Single-passkey vs multi-signer.** Every state-changing method on the signer / context-rule / policy managers takes an optional `selectedSigners` list:

- `selectedSigners` empty (the default) -> single-passkey fast path: the connected passkey alone authorizes (one biometric prompt).
- `selectedSigners` non-empty -> routes through `OZMultiSignerManager.submitWithMultipleSigners`: every signer in the list signs. A one-entry list holding only the connected passkey still routes here and fails — see [Single-passkey collapse rule](#single-passkey-collapse-rule).

Kit sub-managers covered here (all accessed as properties, never called):

| Manager | Property | Purpose |
|---------|----------|---------|
| `OZSignerManager` | `kit.signerManager` | Add/remove signers on a context rule |
| `OZContextRuleManager` | `kit.contextRuleManager` | Add/remove/query/update context rules |
| `OZPolicyManager` | `kit.policyManager` | Install/remove policies on a context rule |
| `OZMultiSignerManager` | `kit.multiSignerManager` | Multi-party transfers and arbitrary contract calls |
| `OZExternalSignerManager` | `kit.externalSigners` | Custody of wallet (G-address) and Ed25519 signing keys |

Rule limits: `OZConstants.maxSigners` = 15 and `OZConstants.maxPolicies` = 5 are SDK constants. The rule-name limit of 20 UTF-8 bytes has no `OZConstants` entry — it is a contract limit enforced on-chain (rejected with error 3015 `NameTooLong`); the client only rejects an empty name.

Context-rule IDs and on-chain signer/policy IDs are plain Dart `int` (the contract's `u32`).

---

## Signer Management

`kit.signerManager` (type `OZSignerManager`) adds or removes signers on a specific context rule. Three signer kinds exist: WebAuthn passkeys, delegated Stellar accounts/contracts, and Ed25519 external signers.

### addNewPasskeySigner — register and add in one step

Runs a WebAuthn registration ceremony, persists the credential locally, emits a `CredentialCreated` event, then submits the on-chain `add_signer` call. Requires `webauthnProvider` in config (throws `WebAuthnNotSupported` otherwise).

```dart
Future<OZAddPasskeySignerResult> addNewPasskeySigner({
  required int contextRuleId,
  required String userName,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});

class OZAddPasskeySignerResult {
  final String credentialId;          // Base64URL, no padding
  final Uint8List publicKey;          // 65 bytes uncompressed secp256r1
  final OZTransactionResult transactionResult;
}
```

```dart
final result = await kit.signerManager.addNewPasskeySigner(
  contextRuleId: 0, // Default rule
  userName: 'Alice backup device',
);
print('Credential: ${result.credentialId}');
print('Submitted:  ${result.transactionResult.success}, hash=${result.transactionResult.hash}');
```

The user sees two prompts: one to register the new passkey, one for the currently-connected passkey to authorize the on-chain call.

### addPasskey — add a pre-registered passkey

Use when you already hold the public key and raw credential ID (e.g. imported from another device). Performs the on-chain `add_signer` call only; no local credential is stored.

> **Transport authenticity.** The `publicKey` and `credentialId` must arrive over a channel authenticated to the user. An attacker who controls the import channel (unsigned QR code, clipboard, unauthenticated WebSocket, URL query parameter) can substitute their own public key and become a signer on your smart account. Show the user a short hex fingerprint of the credential on both devices and require explicit confirmation. The SDK provides no canonical fingerprint helper — any stable hash-and-truncate both sides reproduce works (e.g. the first 16 bytes of `SHA-256(publicKey)`; do not use the raw `publicKey[0..15]` because byte 0 is always the constant `0x04` SEC-1 prefix).

```dart
Future<OZTransactionResult> addPasskey({
  required int contextRuleId,
  required Uint8List publicKey,    // 65 bytes, 0x04 prefix
  required Uint8List credentialId, // raw bytes, NOT Base64URL
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
// PRECONDITION: publicKey and credentialId were verified with the user on both devices.
final result = await kit.signerManager.addPasskey(
  contextRuleId: 0,
  publicKey: otherDevicePublicKey65,    // Uint8List, 65 bytes
  credentialId: otherDeviceCredentialId, // Uint8List, raw
);
if (!result.success) print('Failed: ${result.error}');
```

### addDelegated — add a Stellar account or contract signer

```dart
Future<OZTransactionResult> addDelegated({
  required int contextRuleId,
  required String address, // G-address (account) or C-address (contract)
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
// Add a Stellar account as a signer
await kit.signerManager.addDelegated(
  contextRuleId: 0,
  address: 'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
);
// Add another contract as a signer (custom account contract)
await kit.signerManager.addDelegated(
  contextRuleId: 0,
  address: 'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
);
```

The underlying `OZDelegatedSigner(address)` constructor throws `SmartAccountInvalidAddress` if `address` is neither a valid G-address nor a valid C-address.

### addEd25519 — add an Ed25519 external signer

Requires a deployed Ed25519 verifier contract. `publicKey` is the raw 32-byte Ed25519 key.

```dart
Future<OZTransactionResult> addEd25519({
  required int contextRuleId,
  required String verifierAddress, // C-address of the Ed25519 verifier
  required Uint8List publicKey,    // 32 bytes
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
await kit.signerManager.addEd25519(
  contextRuleId: 0,
  verifierAddress: 'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
  publicKey: backupEd25519PublicKey, // 32 bytes
);
```

### removeSigner — by on-chain ID

Signer IDs are assigned by the contract on insertion and are returned from `OZParsedContextRule.signerIds`, positionally aligned with `OZParsedContextRule.signers`.

```dart
Future<OZTransactionResult> removeSigner({
  required int contextRuleId,
  required int signerId,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
final rules = await kit.contextRuleManager.listContextRules();
final rule = rules.firstWhere((r) => r.id == 0);

// signers and signerIds are positionally aligned
final idx = rule.signers.indexWhere((s) =>
    s is OZDelegatedSigner &&
    s.address == 'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ');
if (idx >= 0) {
  await kit.signerManager.removeSigner(
    contextRuleId: 0,
    signerId: rule.signerIds[idx],
  );
}
```

### removeSignerBySigner — by signer value

Convenience overload that resolves the on-chain ID internally. Fetches the rule, finds the matching signer via `OZSmartAccountBuilders.signersEqual`, and delegates to the ID-based `removeSigner`.

```dart
Future<OZTransactionResult> removeSignerBySigner({
  required int contextRuleId,
  required OZSmartAccountSigner signer,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
await kit.signerManager.removeSignerBySigner(
  contextRuleId: 0,
  signer: OZDelegatedSigner('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ'),
);
```

Throws `SmartAccountInvalidInput` if the signer is not on the rule.

### Removing the last signer

The contract rejects removing the final signer when the rule has no policies — see error 3004 (`NoSignersAndPolicies`) in [Contract Error Codes](#contract-error-codes). Either add a replacement signer or a policy first, or remove the entire rule with `removeContextRule`.

### Signer type recap

`OZSmartAccountSigner` is a sealed class with two concrete variants:

```dart
// Delegated: a Stellar account (G) or contract (C) using native require_auth
final delegated = OZDelegatedSigner('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ');

// External: a verifier contract + key data, for WebAuthn (secp256r1) or Ed25519
final passkey = OZExternalSigner.webAuthn(
  verifierAddress: kit.config.webauthnVerifierAddress, // C-address
  publicKey: secp256r1PublicKey65,                     // 65 bytes, 0x04 prefix
  credentialId: webAuthnCredentialId,                  // raw bytes
);
final ed = OZExternalSigner.ed25519(
  verifierAddress: 'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
  publicKey: ed25519PublicKey32, // 32 bytes
);
```

`OZExternalSigner.webAuthn` packs `keyData = publicKey || credentialId`. `OZExternalSigner.ed25519` sets `keyData = publicKey` (exactly 32 bytes). This length difference is how parsed signers are discriminated (see [Inbound OZSelectedSigner mapping](#inbound-mapping-on-chain-signer-to-ozselectedsigner)).

### Deduplicating signers across rules

The same signer can be attached to several context rules. To render "all signers on this account" without repeats, dedup by `OZSmartAccountBuilders.getSignerKey(signer)` (a stable per-signer `String`) — never by object identity or `==`. A plain Dart map literal already preserves insertion order across rules; accumulate each rule the signer appears on.

```dart
final rules = await kit.contextRuleManager.listContextRules();
final bySigner = <String, ({OZSmartAccountSigner signer, List<int> ruleIds})>{};
for (final rule in rules) {
  for (final signer in rule.signers) {
    final key = OZSmartAccountBuilders.getSignerKey(signer); // stable String key
    final existing = bySigner[key];
    if (existing != null) {
      existing.ruleIds.add(rule.id);
    } else {
      bySigner[key] = (signer: signer, ruleIds: <int>[rule.id]);
    }
  }
}
// bySigner.values -> one entry per unique signer + the rule IDs it sits on.
```

`OZSmartAccountBuilders.collectUniqueSigners(List<OZSmartAccountSigner>)` is the ready-made shortcut when you only need the unique signers and not their rule memberships. Pairwise comparison is `OZSmartAccountBuilders.signersEqual(a, b)`.

---

## Context Rules

`kit.contextRuleManager` (type `OZContextRuleManager`) creates, lists, updates, and removes context rules.

### The Default rule

Every smart account is deployed with one rule at `id = 0`: context type `OZContextRuleTypeDefault`, name `"DefaultRule"`, signers `[initial passkey]`, policies `[]`. The Default rule is the fallback for any operation that does not match a more specific rule. Add signers/policies to it freely, but do not remove it unless you have added a rule of equivalent or greater coverage — otherwise the account becomes unusable.

### OZContextRuleType

A sealed hierarchy with three variants that determine which invocations a rule applies to:

```dart
sealed class OZContextRuleType { /* ... */ }

final class OZContextRuleTypeDefault extends OZContextRuleType {
  const OZContextRuleTypeDefault();
}
final class OZContextRuleTypeCallContract extends OZContextRuleType {
  const OZContextRuleTypeCallContract(this.contractAddress); // C-address String
  final String contractAddress;
}
final class OZContextRuleTypeCreateContract extends OZContextRuleType {
  OZContextRuleTypeCreateContract(Uint8List wasmHash); // copies; 32 bytes
  final Uint8List wasmHash;
}
```

On-chain encoding:

```
Default         ->  Vec([Symbol("Default")])
CallContract    ->  Vec([Symbol("CallContract"), Address(contractAddress)])
CreateContract  ->  Vec([Symbol("CreateContract"), Bytes(wasmHash)])
```

The `OZBuilders` static helpers wrap construction with validation:

```dart
final defaultCtx = OZBuilders.createDefaultContext();
final callCtx    = OZBuilders.createCallContractContext('CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY'); // validates C-address
final createCtx1 = OZBuilders.createCreateContractContextFromHex('abc123...'); // 64 hex chars, 0x prefix ok
final createCtx2 = OZBuilders.createCreateContractContextFromBytes(wasmHash32Bytes); // 32 bytes
```

### addContextRule

```dart
Future<OZTransactionResult> addContextRule({
  required OZContextRuleType contextType,
  required String name,                              // max 20 UTF-8 bytes
  int? validUntil,                                   // ledger sequence, null = no expiration
  required List<OZSmartAccountSigner> signers,
  Map<String, XdrSCVal> policies = const <String, XdrSCVal>{}, // C-address -> install params
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

Create a rule that applies to a specific token contract, signed by two delegated signers:

```dart
final signerA = OZDelegatedSigner('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ');
final signerB = OZDelegatedSigner('GC3C4MCEADMY26BVBPJIIUOKD5WZEZW5XI2LSU5F4QDZARBVAM4UTZEL');

final result = await kit.contextRuleManager.addContextRule(
  contextType: OZContextRuleTypeCallContract(
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  ),
  name: 'TokenTransfers', // <= 20 bytes
  signers: <OZSmartAccountSigner>[signerA, signerB],
);
if (result.success) print('Rule added, tx ${result.hash}');
```

To create a rule **with a policy already attached in one step**, populate the `policies` map — the value is the install-param `XdrSCVal` you build yourself (see [Policies](#policies) for the install-param shapes):

```dart
// SimpleThreshold install params = map{ Symbol("threshold"): U32 }
final thresholdParams = XdrSCVal.forMap(<XdrSCMapEntry>[
  XdrSCMapEntry(XdrSCVal.forSymbol('threshold'), XdrSCVal.forU32(2)),
]);

await kit.contextRuleManager.addContextRule(
  contextType: OZContextRuleTypeCallContract(
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  ),
  name: 'Guarded',
  signers: <OZSmartAccountSigner>[signerA, signerB],
  policies: <String, XdrSCVal>{
    'CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC': thresholdParams,
  },
);
```

```dart
// WRONG: signers empty AND policies empty -> SmartAccountInvalidInput (a rule needs >= 1 of each kind)
// CORRECT: supply at least one signer or one policy
```

The convenience methods on `kit.policyManager` (next section) cannot create a rule; they only install onto an existing one. To create a rule with a policy in a single transaction, use the `policies` map here.

### OZParsedContextRule

```dart
class OZParsedContextRule {
  final int id;
  final OZContextRuleType contextType;
  final String name;
  final List<OZSmartAccountSigner> signers; // aligned with signerIds
  final List<int> signerIds;
  final List<String> policies;              // C-addresses, aligned with policyIds
  final List<int> policyIds;
  final int? validUntil;
}
```

### Listing and reading rules

```dart
Future<List<OZParsedContextRule>> listContextRules({int? maxScanId});
Future<List<XdrSCVal>> getAllContextRules({int? maxScanId});
Future<XdrSCVal> getContextRule(int id);          // raw rule struct
Future<int> getContextRulesCount();
OZParsedContextRule parseContextRule(XdrSCVal scVal); // synchronous
```

```dart
final rules = await kit.contextRuleManager.listContextRules();
for (final rule in rules) {
  print('Rule #${rule.id}: ${rule.name} (${rule.contextType})');
  print('  signers: ${rule.signers.length}  policies: ${rule.policies.length}');
  if (rule.validUntil != null) print('  expires at ledger ${rule.validUntil}');
}
```

IDs are monotonically increasing and never reused, so removed rules leave gaps. `listContextRules` scans IDs `0` up to `maxScanId` (default `config.maxContextRuleScanId`, which is `50`) and skips gaps. Raise the cap if the account has accumulated more than 50 rules over its lifetime.

`getContextRule(id)` returns the **raw** rule `XdrSCVal` (the contract's `get_context_rule` struct). You need this raw form for the `set_threshold` fast-path below.

### updateName

```dart
Future<OZTransactionResult> updateName({
  required int id,
  required String name,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
await kit.contextRuleManager.updateName(id: 1, name: 'TokenTransfers');
```

Names do not affect matching or enforcement.

### updateValidUntil

Set or clear a rule's expiration ledger. Pass `null` to remove expiration.

```dart
Future<OZTransactionResult> updateValidUntil({
  required int id,
  int? validUntil,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
// Expire a rule roughly one week out. Read the current ledger via the kit's
// shared SorobanServer (kit.sorobanServer).
final latest = (await kit.sorobanServer.getLatestLedger()).sequence!;
final inAWeek = latest + 7 * Util.ledgersPerDay;
await kit.contextRuleManager.updateValidUntil(id: 1, validUntil: inAWeek);

// Remove expiration
await kit.contextRuleManager.updateValidUntil(id: 1, validUntil: null);
```

The contract skips a rule once its `validUntil` is past; evaluation falls back to matching non-expired rules (and Default). Expired rules remain on-chain until `removeContextRule`.

### removeContextRule

```dart
Future<OZTransactionResult> removeContextRule({
  required int id,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
await kit.contextRuleManager.removeContextRule(id: 3);
```

Do not remove rule `0` (Default) unless you have added equivalent coverage.

### A multi-field rule edit is NOT atomic

Adding a signer, installing a policy, and changing the expiry are each a separate on-chain submission; there is no batched rule-edit call. The non-obvious consequence an agent cannot infer from the signatures:

**Add-signer changes the rule's auth context — HALT and reload.** The contract re-evaluates the rule's signer set on each call, so a policy install or expiry update issued after an add-signer in the **same logical edit** is rejected by the new context. Ordering hint: apply policy/expiry changes first; then, if a signer was added and any policy/expiry work still remains, HALT — re-fetch the rule from chain and resubmit the leftover changes against the fresh state. The signers you read into local state before the add are now stale.

---

## Policies

`kit.policyManager` (type `OZPolicyManager`) installs and removes policies on a context rule. A policy is a separate, already-deployed Soroban contract. Policy contracts are shared network-wide (one deployment serves all smart accounts); you supply the C-address and per-account install parameters.

### Policy address discovery

You need a deployed policy contract C-address before installing it. Sources: published OpenZeppelin addresses for the network you target, or deploy your own policy contract and use its address. A testnet policy address fails on mainnet (and vice-versa) with contract-not-found during simulation. `policyAddress` must be a valid C-address; an invalid strkey throws `SmartAccountInvalidAddress` at input validation.

### Primary path — addPolicy with an install-param XdrSCVal

`addPolicy` is the generic entry point and the production idiom for every policy contract, including the three built-in ones. Build the install-param `XdrSCVal` **once** and feed the same value to both surfaces: `addContextRule(policies: {policyAddr: installParams})` to attach it when the rule is created, and `addPolicy(installParams: installParams)` to attach it to an existing rule later. The convenience methods below are a shortcut for an already-existing rule only — they cannot create a rule and they re-encode params the generic path lets you control directly.

```dart
Future<OZTransactionResult> addPolicy({
  required int contextRuleId,
  required String policyAddress,
  required XdrSCVal installParams, // SCVal map with policy-specific keys
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

The install-param map shapes. Map keys are `Symbol`s. The convenience methods emit each policy's install-param map in the contract's expected key order for you; for WeightedThreshold the nested `signer_weights` map is XDR-byte sorted by the SDK. When you hand-build the `XdrSCVal` yourself you are responsible for nested-map ordering.

```
SimpleThreshold    -> map{ Symbol("threshold"): U32 }
SpendingLimit      -> map{ Symbol("period_ledgers"): U32, Symbol("spending_limit"): I128 }
WeightedThreshold  -> map{ Symbol("signer_weights"): map{ <signerScVal>: U32, ... },
                           Symbol("threshold"): U32 }
```

The `OZPolicyInstallParams` sealed hierarchy (`OZSimpleThresholdPolicyParams`, `OZWeightedThresholdPolicyParams`, `OZSpendingLimitPolicyParams`) is public, but its `toScVal()` method is annotated `@internal`. Prefer the convenience methods, or build the `XdrSCVal` directly as shown — do not rely on `toScVal()` from application code.

Compact SimpleThreshold example via the generic path:

```dart
// SimpleThreshold install params: map{ Symbol("threshold"): U32 }
final installParams = XdrSCVal.forMap(<XdrSCMapEntry>[
  XdrSCMapEntry(XdrSCVal.forSymbol('threshold'), XdrSCVal.forU32(2)),
]);

await kit.policyManager.addPolicy(
  contextRuleId: 0,
  policyAddress: 'CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC',
  installParams: installParams,
);
```

Custom policy example. The keys (`allowed_contracts`, `max_per_tx`) and the address inside are illustrative of a hypothetical custom policy — only SimpleThreshold, WeightedThreshold, and SpendingLimit are built in, with the install-param shapes shown above.

```dart
final installParams = XdrSCVal.forMap(<XdrSCMapEntry>[
  XdrSCMapEntry(
    XdrSCVal.forSymbol('allowed_contracts'),
    XdrSCVal.forVec(<XdrSCVal>[
      XdrSCVal.forContractAddress('CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC'),
    ]),
  ),
  XdrSCMapEntry(XdrSCVal.forSymbol('max_per_tx'), XdrSCVal.forU32(10)),
]);
await kit.policyManager.addPolicy(
  contextRuleId: 0,
  policyAddress: 'CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC', // replace with your deployed custom-policy C-address
  installParams: installParams,
);
```

### Convenience shortcuts — for an already-existing rule only

These three methods encode the install params for you and call `addPolicy` internally. They install onto an **existing** context rule; they cannot create the rule. To create a rule and attach a policy in one transaction, use `addContextRule(policies: ...)` with a hand-built install-param `XdrSCVal`.

#### addSimpleThreshold — M-of-N

```dart
Future<OZTransactionResult> addSimpleThreshold({
  required int contextRuleId,
  required String policyAddress,
  required int threshold, // >= 1
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
// 2-of-3 on the Default rule
await kit.policyManager.addSimpleThreshold(
  contextRuleId: 0,
  policyAddress: 'CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC',
  threshold: 2,
);
```

threshold must satisfy `1 <= threshold <= rule.signers.length`; 0 is rejected client-side (`SmartAccountInvalidInput`); `> signers.length` yields contract error 3201 InvalidThreshold.

#### addWeightedThreshold — weighted voting

Each signer carries a weight; the sum of approving weights must reach `threshold`. Weight-map keys are `OZSmartAccountSigner` values that must match exactly what is stored on the rule.

```dart
Future<OZTransactionResult> addWeightedThreshold({
  required int contextRuleId,
  required String policyAddress,
  required Map<OZSmartAccountSigner, int> signerWeights,
  required int threshold,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
final admin = OZDelegatedSigner('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ');
final lead  = OZDelegatedSigner('GC3C4MCEADMY26BVBPJIIUOKD5WZEZW5XI2LSU5F4QDZARBVAM4UTZEL');
final dev   = OZDelegatedSigner('GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOKY3B2WSQHG4W37');

await kit.policyManager.addWeightedThreshold(
  contextRuleId: 1,
  policyAddress: 'CAF4OCRIB73T5777UWAQS7KGOG6WVIZ3EFXNNUYSPFSBKW2Q5XEIOSPW',
  signerWeights: <OZSmartAccountSigner, int>{admin: 50, lead: 30, dev: 20},
  threshold: 80, // admin+lead passes; lead+dev (50) does not
);
```

A weighted signer that is not also on the rule's signer list can never sign, so it can never contribute to the threshold — add it to the rule first.

#### addSpendingLimit — rolling rate limit

Caps the total amount transferred by the rule's context within a rolling window measured in ledgers. The policy intercepts a `transfer` invocation (argument 2 read as `i128`), so it applies to any SEP-41 token.

```dart
Future<OZTransactionResult> addSpendingLimit({
  required int contextRuleId,
  required String policyAddress,
  required String spendingLimit, // decimal XLM-style string, e.g. "1000" or "10.5"
  required int periodLedgers,    // window in ledgers (~5 s each)
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

Period constants from `Util`: `Util.ledgersPerHour` (720), `Util.ledgersPerDay` (17280). There is no week constant — compute `7 * Util.ledgersPerDay`.

```dart
// Limit the account to 1000 XLM per day when calling the native XLM SAC
const nativeSac = 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';

// 1. Create a CallContract rule scoping the policy to the native SAC.
await kit.contextRuleManager.addContextRule(
  contextType: OZContextRuleTypeCallContract(nativeSac),
  name: 'XlmDailyLimit',
  signers: <OZSmartAccountSigner>[OZDelegatedSigner('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ')],
);

// 2. Install the policy on that rule.
final rules = await kit.contextRuleManager.listContextRules();
final ruleId = rules.lastWhere((r) => r.contextType == OZContextRuleTypeCallContract(nativeSac)).id;
await kit.policyManager.addSpendingLimit(
  contextRuleId: ruleId,
  policyAddress: 'CBQE7L3UNP5IR4I7IBKLS7NV256WHR5TTH26HTMUIK7WXJC6J64RSE2L',
  spendingLimit: '1000', // decimal string; SDK converts to stroops internally
  periodLedgers: Util.ledgersPerDay,
);
```

```dart
// WRONG: installing SpendingLimit on a Default rule -> contract error 3227 OnlyCallContractAllowed
// CORRECT: install on a CallContract(target-token) rule
```

Internally, `addSpendingLimit` and the underlying `OZSpendingLimitPolicyParams` carry the limit as a `BigInt` (stroops). See [BigInt for i128 amounts](#bigint-for-i128) — never clamp these to a Dart `int`/JS `Number`.

### Editing an installed policy's params

There is **no in-place policy-update call**. To change a non-threshold policy's install params (e.g. a SpendingLimit's amount or period, a WeightedThreshold's weight map) you MUST `removePolicy` (or `removePolicyByAddress`) then `addPolicy` with the new install-param `XdrSCVal`. The lone exception is a threshold-only change on SimpleThreshold/WeightedThreshold, which uses the `set_threshold` fast-path below.

```dart
// Remove, then re-add with the new install params.
await kit.policyManager.removePolicyByAddress(contextRuleId: 1, policyAddress: policyC);
await kit.policyManager.addPolicy(
  contextRuleId: 1, policyAddress: policyC, installParams: newInstallParams,
);
```

### set_threshold fast-path — change a threshold without remove + re-add

A threshold-only change does NOT require removing and re-installing the policy. Both the SimpleThreshold and WeightedThreshold policy contracts export a `set_threshold(threshold, context_rule, smart_account)` function. Call it directly through the smart account.

Contract signature: `set_threshold(threshold: u32, context_rule: ContextRule, smart_account: Address)`. The `context_rule` argument is the **full rule struct**, not its id — so you must re-fetch the raw rule via `getContextRule(...)` immediately before the call and pass it as-is. Re-fetch right before to avoid acting on a stale rule (signer/policy edits change the struct).

```dart
final policyAddress = 'CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC';
const contextRuleId = 1;

// Re-fetch the raw rule struct immediately before the call (stale-rule caveat).
final rawRule = await kit.contextRuleManager.getContextRule(contextRuleId);

// Single-passkey fast path. set_threshold calls smart_account.require_auth(),
// so route it through the account's own execute(target, fn, args) entry point
// (executeAndSubmit) — the smart account is the invoker and authorizes the
// nested call. Do NOT use contractCall here: that invokes the policy contract
// directly and will not satisfy smart_account.require_auth().
final result = await kit.transactionOperations.executeAndSubmit(
  target: policyAddress,
  targetFn: 'set_threshold',
  targetArgs: <XdrSCVal>[
    XdrSCVal.forU32(3),                                                  // new threshold
    rawRule,                                                             // full ContextRule struct
    XdrSCVal.forAddress(Address.forContractId(kit.contractId!).toXdr()), // smart account
  ],
);
if (result.success) print('threshold updated: ${result.hash}');
```

Multi-signer variant — same args, routed through the multi-signer pipeline:

```dart
await kit.multiSignerManager.multiSignerExecuteAndSubmit(
  target: policyAddress,
  targetFn: 'set_threshold',
  targetArgs: <XdrSCVal>[
    XdrSCVal.forU32(3),
    rawRule,
    XdrSCVal.forAddress(Address.forContractId(kit.contractId!).toXdr()),
  ],
  selectedSigners: selectedSigners, // non-empty
);
```

### removePolicy — by ID

Policy IDs align positionally with `OZParsedContextRule.policies` via `OZParsedContextRule.policyIds`.

```dart
Future<OZTransactionResult> removePolicy({
  required int contextRuleId,
  required int policyId,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
final rule = (await kit.contextRuleManager.listContextRules()).firstWhere((r) => r.id == 0);
if (rule.policyIds.isNotEmpty) {
  await kit.policyManager.removePolicy(contextRuleId: 0, policyId: rule.policyIds.first);
}
```

### removePolicyByAddress — by address

Convenience overload that resolves the on-chain ID internally by matching the policy contract address.

```dart
Future<OZTransactionResult> removePolicyByAddress({
  required int contextRuleId,
  required String policyAddress,
  List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
  OZSubmissionMethod? forceMethod,
});
```

```dart
await kit.policyManager.removePolicyByAddress(
  contextRuleId: 0,
  policyAddress: 'CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC',
);
```

Throws `SmartAccountInvalidInput` if the policy is not on the rule.

---

## Multi-Signer Operations

`kit.multiSignerManager` (type `OZMultiSignerManager`) coordinates a transaction across more than one signer — multiple passkeys, one or more external wallets, Ed25519 keys, or a mix. Use it when a rule requires a threshold `> 1`, or to collect signatures from separate devices/users.

### Entry points

- **Any state-changing manager method with `selectedSigners` non-empty** — signer/policy/context-rule edits, threshold changes.
- **`multiSignerTransfer`** — SEP-41 `transfer` on a token contract.
- **`multiSignerContractCall`** — arbitrary contract call authorized under a `CallContract(target)` rule.
- **`multiSignerExecuteAndSubmit`** — arbitrary call routed through the smart account's own `execute(target, target_fn, target_args)` entry point; the target sees the smart account as the invoker.

### Single-passkey collapse rule

The routing condition is exactly `selectedSigners.isEmpty`. The connected passkey is never added implicitly, so a one-entry list holding only the connected passkey routes to multi-signer and fails.

```dart
// WRONG: connected passkey only, but passed in a one-entry list -> routes to
//        multi-signer, which requires keyData and fails for a bare passkey selector.
await kit.multiSignerManager.multiSignerTransfer(
  tokenContract: tokenC, recipient: r, amount: '1',
  selectedSigners: <OZSelectedSigner>[OZSelectedSignerPasskey()],
);
// CORRECT: for connected-passkey-only, use the single-signer transfer (no selectedSigners).
await kit.transactionOperations.transfer(tokenContract: tokenC, recipient: r, amount: '1');
```

When you genuinely need more than one signer, list every signer that will sign (including the connected passkey if it participates) and populate each selector fully.

### OZSelectedSigner

A sealed hierarchy with three variants:

```dart
sealed class OZSelectedSigner { const OZSelectedSigner(); }

final class OZSelectedSignerPasskey extends OZSelectedSigner {
  const OZSelectedSignerPasskey({
    this.credentialId,        // String? Base64URL, for tracking/lastUsed
    this.credentialIdBytes,   // Uint8List? raw -> WebAuthn allowCredentials hint
    this.keyData,             // Uint8List? 65-byte pubkey || credentialId
    this.transports,          // List<String>? e.g. ['internal', 'hybrid']
  });
  final String? credentialId;
  final Uint8List? credentialIdBytes;
  final Uint8List? keyData;
  final List<String>? transports;
}

final class OZSelectedSignerEd25519 extends OZSelectedSigner {
  const OZSelectedSignerEd25519({required this.verifierAddress, required this.publicKey});
  final String verifierAddress; // C-address of the Ed25519 verifier
  final Uint8List publicKey;    // 32-byte Ed25519 public key
}

final class OZSelectedSignerWallet extends OZSelectedSigner {
  const OZSelectedSignerWallet(this.address); // G-address of the delegated signer
  final String address;
}
```

Each `OZSelectedSignerPasskey` triggers one OS WebAuthn prompt. `OZSelectedSignerWallet` and `OZSelectedSignerEd25519` sign through `kit.externalSigners`.

#### keyData-null rule (passkey selectors)

In a multi-signer ceremony, every `OZSelectedSignerPasskey` MUST carry non-null `keyData`. Signer reconstruction is hoisted **outside** the per-entry loop; a `keyData: null` passkey selector throws `SmartAccountInvalidInput` ("keyData is required for passkey signers for rule resolution") before any prompt.

```dart
// WRONG: a passkey selector in a multi-signer list with keyData null
final p = OZSelectedSignerPasskey(credentialId: cred.credentialId); // keyData null -> throws

// CORRECT: supply keyData (and credentialIdBytes for allowCredentials routing)
final passkeySigner = OZSelectedSignerPasskey(
  credentialId: cred.credentialId,                  // Base64URL
  credentialIdBytes: base64Url.decode(base64Url.normalize(cred.credentialId)),
  keyData: onChainSigner.keyData,                   // pubkey || credId from the parsed rule
  transports: cred.transports,                      // null is fine
);
```

### Inbound mapping: on-chain signer to OZSelectedSigner

Build an `OZSelectedSigner` from a signer read off a parsed rule. Discriminate by `OZExternalSigner.keyData` length using the constants in `SmartAccountConstants`: `> secp256r1PublicKeySize` (65) is a WebAuthn passkey (65-byte pubkey followed by the credential id); `== ed25519PublicKeySize` (32) is an Ed25519 signer.

```dart
final rule = (await kit.contextRuleManager.listContextRules())
    .firstWhere((r) => r.id == contextRuleId);

final available = <OZSelectedSigner>[];
for (final signer in rule.signers) {
  if (signer is OZExternalSigner &&
      signer.keyData.length == SmartAccountConstants.ed25519PublicKeySize) {
    // Ed25519 external signer
    if (kit.externalSigners.canSignEd25519For(
          verifierAddress: signer.verifierAddress, publicKey: signer.keyData)) {
      available.add(OZSelectedSignerEd25519(
        verifierAddress: signer.verifierAddress,
        publicKey: signer.keyData,
      ));
    }
  } else if (signer is OZExternalSigner &&
      signer.keyData.length > SmartAccountConstants.secp256r1PublicKeySize) {
    // WebAuthn passkey: keyData = 65-byte pubkey || credentialId
    final credIdStr = OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer);
    if (credIdStr == null) continue;
    final credIdBytes = OZSmartAccountBuilders.getCredentialIdFromSigner(signer);
    final stored = await kit.credentialManager.getCredential(credIdStr);
    available.add(OZSelectedSignerPasskey(
      credentialId: credIdStr,
      credentialIdBytes: credIdBytes,        // raw credential id bytes
      keyData: signer.keyData,               // MUST be non-null (keyData-null rule)
      transports: stored?.transports,        // look up via the credential manager
    ));
  } else if (signer is OZDelegatedSigner) {
    if (await kit.externalSigners.canSignFor(signer.address)) {
      available.add(OZSelectedSignerWallet(signer.address));
    }
  }
}
```

`kit.externalSigners.canSignFor(String)` is `async` (returns `Future<bool>`); `canSignEd25519For({verifierAddress, publicKey})` is synchronous (returns `bool`).

### multiSignerTransfer

```dart
Future<OZTransactionResult> multiSignerTransfer({
  required String tokenContract,
  required String recipient,
  required String amount,                 // decimal string, NOT stroops
  required List<OZSelectedSigner> selectedSigners,
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
});
```

A 2-of-2 transfer with the connected passkey plus an external wallet:

```dart
final passkey = OZSelectedSignerPasskey(
  credentialId: kit.credentialId,
  credentialIdBytes: kit.credentialId == null
      ? null
      : base64Url.decode(base64Url.normalize(kit.credentialId!)),
  keyData: onChainPasskeySigner.keyData, // from the parsed rule
);
final wallet = OZSelectedSignerWallet('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ');

final result = await kit.multiSignerManager.multiSignerTransfer(
  tokenContract: 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  recipient: 'GC3C4MCEADMY26BVBPJIIUOKD5WZEZW5XI2LSU5F4QDZARBVAM4UTZEL',
  amount: '100',
  selectedSigners: <OZSelectedSigner>[passkey, wallet],
);
if (result.success) print('Multi-sig transfer ok: ${result.hash}');
```

### multiSignerContractCall

Direct call to an external contract, authorized under a `CallContract` rule on the target.

```dart
Future<OZTransactionResult> multiSignerContractCall({
  required String target,                 // C-address
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  required List<OZSelectedSigner> selectedSigners,
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
});
```

```dart
// passkey, wallet built as in the multiSignerTransfer example above.
// expiration_ledger is an ABSOLUTE ledger sequence: current + window.
final current = (await kit.sorobanServer.getLatestLedger()).sequence!;
final expirationLedger = current + Util.ledgersPerHour; // absolute future ledger
final args = <XdrSCVal>[
  XdrSCVal.forAddress(Address.forContractId(kit.contractId!).toXdr()),
  XdrSCVal.forAddress(Address.forContractId('CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC').toXdr()),
  Util.stroopsToI128ScVal(Util.toXdrInt64Amount('100')),
  XdrSCVal.forU32(expirationLedger),
];
await kit.multiSignerManager.multiSignerContractCall(
  target: 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  targetFn: 'approve',
  targetArgs: args,
  selectedSigners: <OZSelectedSigner>[passkey, wallet],
);
```

### multiSignerExecuteAndSubmit

Routes through the smart account's `execute(target, target_fn, target_args)` entry point; the target sees the smart account contract as the `require_auth` caller.

```dart
Future<OZTransactionResult> multiSignerExecuteAndSubmit({
  required String target,
  required String targetFn,
  List<XdrSCVal> targetArgs = const <XdrSCVal>[],
  required List<OZSelectedSigner> selectedSigners,
  OZSubmissionMethod? forceMethod,
  OZResolveContextRuleIds? resolveContextRuleIds,
});
```

```dart
// Governance vote authorized by two wallet signers
await kit.multiSignerManager.multiSignerExecuteAndSubmit(
  target: 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
  targetFn: 'vote',
  targetArgs: <XdrSCVal>[XdrSCVal.forU32(42), XdrSCVal.forBool(true)],
  selectedSigners: <OZSelectedSigner>[
    OZSelectedSignerWallet('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ'),
    OZSelectedSignerWallet('GC3C4MCEADMY26BVBPJIIUOKD5WZEZW5XI2LSU5F4QDZARBVAM4UTZEL'),
  ],
);
```

### OZResolveContextRuleIds (advanced)

```dart
typedef OZResolveContextRuleIds = Future<List<int>> Function(
  XdrSorobanAuthorizationEntry entry,
  int index,
);
```

The SDK auto-resolves which rule IDs each auth entry should invoke via a 3-tier match against `selectedSigners` (exact set, rule-subset with no policies, selected-subset). Supply this callback to force a choice or to disambiguate.

```dart
// Force all auth entries to use rule 2
Future<List<int>> forceRule2(XdrSorobanAuthorizationEntry e, int i) async => <int>[2];
await kit.multiSignerManager.multiSignerTransfer(
  tokenContract: tokenSac,
  recipient: recipient,
  amount: '10',
  selectedSigners: signers,
  resolveContextRuleIds: forceRule2,
);
```

When auto-resolution cannot find a unique rule it throws `SmartAccountInvalidInput` with one of: "No context rule matches ..." (add a matching or Default rule), "Selected signers match multiple context rules: ..." (use the callback), or "No context rule contains all selected signers." (the selection crosses rules).

### Custody requirements

An `OZSelectedSignerWallet` (G-address) resolves through `kit.externalSigners`. Register a signing source by either model:

- **In-memory custody (runtime):** `kit.externalSigners.addFromSecret('S...')` for a wallet keypair, or `kit.externalSigners.addEd25519FromRawKey(secretKeyBytes: seed32, verifierAddress: 'C...')` for an Ed25519 external signer. Both are memory-only and never persisted.
- **Adapter custody (kit construction):** supply `config.externalWallet` (an `OZExternalWalletAdapter`) and/or `config.externalEd25519Adapter` (an `OZExternalEd25519SignerAdapter`). The two paths resolve in opposite order: for the wallet adapter the in-memory keypair takes precedence and the adapter is the fallback; for the Ed25519 adapter the adapter is consulted first, then the in-memory key.

```dart
// In-memory wallet keypair
await kit.externalSigners.addFromSecret('SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZ6PRBVTL77SY');

// In-memory Ed25519 signer
kit.externalSigners.addEd25519FromRawKey(
  secretKeyBytes: ed25519Seed32, // raw 32-byte seed, NOT an S-strkey
  verifierAddress: 'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY',
);
```

### Signing order and prompts

Signatures are collected in the order `selectedSigners` is supplied. Each `OZSelectedSignerPasskey` triggers one WebAuthn prompt; the SDK passes its `credentialIdBytes` + `transports` as `allowCredentials` so the OS routes to the correct passkey. If a passkey prompt is cancelled, the call fails fast with `WebAuthnAuthenticationFailed` and remaining signers are not prompted.

### Add-before-remove (signer set safety)

When changing the signer set, add the new signer and confirm success before removing the old one. Never drop the rule below its minimum viable signer set in between — a policy-free rule reduced to zero signers fails with 3004 `NoSignersAndPolicies`, and a failure between two transactions can leave the account unusable. The [Common Scenarios](#common-scenarios) rotation flow shows the pattern.

---

## Common Scenarios

Each flow assumes `final OZSmartAccountKit kit` exists and `connectWallet(...)` succeeded with the stated preconditions.

### Passkey recovery via backup signer (lost device)

**Preconditions.** A backup `OZDelegatedSigner(G-address)` was added earlier to the Default rule, and the user still controls that Stellar account through an `OZExternalWalletAdapter` configured on `config.externalWallet`. The original passkey is gone. The smart account's contract ID is known (server-side record, indexer, or backup).

**Flow.** Register a fresh passkey, connect directly using the new credential + known contract ID, then add the new passkey on-chain authorized by the backup signer, and finally remove the old passkey.

```dart
final oldPasskeyCredentialIdBase64Url = /* fetched from your backup */ '';
final knownContractId = /* verified via two independent channels */ '';

// 1. Register a fresh passkey on the new device. 32 cryptographically random
//    bytes each for the challenge and the user id.
final rng = Random.secure();
Uint8List random32() =>
    Uint8List.fromList(List<int>.generate(32, (_) => rng.nextInt(256)));
final webauthn = kit.config.webauthnProvider!;
final reg = await webauthn.register(
  challenge: random32(),
  userId: random32(),
  userName: 'Recovery Device',
);
final newCredBytes = reg.credentialId;

// 2. Direct connect using the known (credentialId, contractId) pair. The new
//    passkey is not yet on-chain, which is fine: signing is routed to the backup.
//    connectWallet returns a tri-state (OZConnectWalletConnected |
//    OZConnectWalletAmbiguous when several contracts match the credential | null).
//    The supplied contractId makes the match unique, so the connected arm holds.
final connected = await kit.walletOperations.connectWallet(
  options: OZConnectWalletOptions(
    credentialId: base64Url.encode(newCredBytes),
    contractId: knownContractId,
  ),
);
if (connected is! OZConnectWalletConnected) {
  throw StateError('Unable to reconnect to $knownContractId');
}

// 3. The backup signer on the Default rule.
final backup = OZSelectedSignerWallet('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ');

// 4. Add the new passkey on-chain, authorized by the backup signer. The
//    non-empty selectedSigners list is load-bearing: an empty list would route
//    to the (nonexistent) new passkey and fail with 3016 UnauthorizedSigner.
final addResult = await kit.signerManager.addPasskey(
  contextRuleId: 0,
  publicKey: reg.publicKey,
  credentialId: newCredBytes,
  selectedSigners: <OZSelectedSigner>[backup],
);
if (!addResult.success) throw StateError('add_signer failed: ${addResult.error}');

// 5. Remove the old passkey, also authorized by the backup signer.
final rule = (await kit.contextRuleManager.listContextRules()).firstWhere((r) => r.id == 0);
final oldIdx = rule.signers.indexWhere((s) =>
    OZSmartAccountBuilders.getCredentialIdStringFromSigner(s) ==
    oldPasskeyCredentialIdBase64Url);
if (oldIdx >= 0) {
  await kit.signerManager.removeSigner(
    contextRuleId: 0,
    signerId: rule.signerIds[oldIdx],
    selectedSigners: <OZSelectedSigner>[backup],
  );
}
```

A raw-Ed25519 backup added via `addEd25519` uses the Ed25519 pipeline and is expressed as `OZSelectedSignerEd25519`, not `OZSelectedSignerWallet`; the verifier address and the in-memory/adapter Ed25519 key must be registered.

### Signer rotation (add new, then remove old)

**Preconditions.** Connected with the current passkey; the Default rule has one passkey signer and no policies.

**Flow.** Add the new passkey first (old passkey authorizes), reconnect with the new passkey, then remove the old one. Add first — never remove first.

```dart
// 1. Register the new passkey and add it on-chain; the old passkey authorizes
//    because selectedSigners is empty (single-passkey fast path).
final added = await kit.signerManager.addNewPasskeySigner(
  contextRuleId: 0,
  userName: 'New device',
);
if (!added.transactionResult.success) {
  throw StateError('add_signer failed: ${added.transactionResult.error}');
}
final newCredentialId = added.credentialId;

// 2. Remember the old credential ID BEFORE reconnecting.
final oldCredentialId = kit.credentialId!;

// 3. Reconnect using the new passkey (addNewPasskeySigner already persisted it).
//    connectWallet is tri-state; the connected arm is expected here, so assert it.
final reconn = await kit.walletOperations.connectWallet(
  options: OZConnectWalletOptions(credentialId: newCredentialId),
);
if (reconn is! OZConnectWalletConnected) {
  throw StateError('Failed to reconnect with new passkey');
}

// 4. Remove the old passkey; the new passkey authorizes (selectedSigners empty).
final rule = (await kit.contextRuleManager.listContextRules()).firstWhere((r) => r.id == 0);
final oldIdx = rule.signers.indexWhere((s) =>
    OZSmartAccountBuilders.getCredentialIdStringFromSigner(s) == oldCredentialId);
if (oldIdx < 0) throw StateError('Old passkey not found on Default rule');
await kit.signerManager.removeSigner(contextRuleId: 0, signerId: rule.signerIds[oldIdx]);
```

### Debugging failed `__check_auth` via contract error codes

**Preconditions.** A call such as `kit.transactionOperations.transfer(...)`, `kit.signerManager.removeSigner(...)`, or a policy install throws `SmartAccountTransactionSimulationFailed`. The contract rejected the auth check or a policy enforcement hook.

**Flow.** The simulation error message wraps the RPC simulation error, which contains the host error in the form `Error(Contract, #NNNN)`. Extract the numeric code with `RegExp(r'Error\s*\(\s*Contract\s*,\s*#(\d+)\s*\)')` (group 1 is the code) and map it to an action. There is no typed contract-error exception.

```dart
int? parseContractErrorCode(Object e) {
  final m = RegExp(r'Error\s*\(\s*Contract\s*,\s*#(\d+)\s*\)').firstMatch(e.toString());
  return m == null ? null : int.tryParse(m.group(1)!);
}

try {
  await kit.transactionOperations.transfer(
    tokenContract: 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
    recipient: 'GC3C4MCEADMY26BVBPJIIUOKD5WZEZW5XI2LSU5F4QDZARBVAM4UTZEL',
    amount: '10',
  );
} on SmartAccountTransactionSimulationFailed catch (e) {
  final code = parseContractErrorCode(e);
  final hint = switch (code) {
    3004 => 'NoSignersAndPolicies — rule would have 0 signers and 0 policies; add one first',
    3016 => 'UnauthorizedSigner — signer not on the resolved rule; adjust selectedSigners or pass resolveContextRuleIds',
    3221 => 'SpendingLimit exceeded for the current window; only reachable if a SpendingLimit policy is installed on the active rule — wait for reset or raise the limit',
    null => 'No contract code in message: $e',
    _ => 'Contract error $code — see Contract Error Codes below',
  };
  print('transfer rejected: $hint');
  if (code == OZContractErrorCodes.unauthorizedSigner) { // 3016
    // Recovery: re-resolve rule IDs or adjust the selected-signer set.
  }
}
```

`OZContractErrorCodes` constants (the codes the SDK interprets directly): `mathOverflow` 3012, `keyDataTooLarge` 3013, `contextRuleIdsLengthMismatch` 3014, `nameTooLong` 3015, `unauthorizedSigner` 3016. All other codes are on-chain-only — parse the message yourself.

---

## Events

Signer, policy, and context-rule changes do not emit dedicated kit events; they surface as a transaction-submitted kit event. The kit-level event catalogue and subscription mechanics are in [smart_accounts.md — Events](./smart_accounts.md#events). For on-chain contract-emitted events (`signer_added`, `policy_added`, `simple_threshold_changed`, etc.), query `SorobanServer(kit.config.rpcUrl).getEvents(...)` filtered by the smart account's contract ID — see [rpc.md](./rpc.md).

---

## Contract Error Codes

When the smart account contract rejects a call, the on-chain code is surfaced inside a `SmartAccountTransactionSimulationFailed` (simulation) or `SmartAccountTransactionSubmissionFailed` (submit/poll) message in the form `Error(Contract, #NNNN)` — extract it with the regex from the [Debugging](#debugging-failed-__check_auth-via-contract-error-codes) section above. The numeric value matches the contract's error enum.

### Smart account errors (3000 range)

| Code | Symbol | Meaning | Fix |
|------|--------|---------|-----|
| 3000 | ContextRuleNotFound | `contextRuleId` does not exist | Pass a valid ID from `listContextRules()`; IDs are never reused. |
| 3002 | UnvalidatedContext | No rule matches this operation's context type | Add a `CallContract` / `CreateContract` rule, or a `Default` rule. |
| 3003 | ExternalVerificationFailed | Verifier contract rejected the signature | Signature or key data is wrong, or the verifier was upgraded. |
| 3004 | NoSignersAndPolicies | Rule would have 0 signers and 0 policies | Supply at least one signer or one policy. |
| 3005 | PastValidUntil | `validUntil` is <= current ledger | Compute `validUntil` from a future ledger sequence: `(await kit.sorobanServer.getLatestLedger()).sequence` plus a window. |
| 3006 | SignerNotFound | `signerId` not present on the rule | Use `OZParsedContextRule.signerIds`. |
| 3007 | DuplicateSigner | Signer already on the rule | Each signer can appear at most once per rule. |
| 3008 | PolicyNotFound | `policyId` not present on the rule | Use `OZParsedContextRule.policyIds`. |
| 3009 | DuplicatePolicy | Policy contract already installed on the rule | Remove the existing installation first, or target a different rule. |
| 3010 | TooManySigners | > 15 signers on a rule | Limit to `OZConstants.maxSigners` = 15. |
| 3011 | TooManyPolicies | > 5 policies on a rule | Limit to `OZConstants.maxPolicies` = 5. |
| 3012 | MathOverflow | Internal ID counter hit `u32::MAX` | Extremely rare; create a new account. |
| 3013 | KeyDataTooLarge | External signer `keyData` exceeds the max size | secp256r1 pubkey (65) + credentialId must fit. |
| 3014 | ContextRuleIdsLengthMismatch | `context_rule_ids` length mismatch | Normally resolved by the auto-resolver; seeing it means a manual `resolveContextRuleIds` output was malformed. |
| 3015 | NameTooLong | Rule name > 20 UTF-8 bytes | Shorten the name. |
| 3016 | UnauthorizedSigner | A signer in the auth payload is not on the selected rule | Adjust `selectedSigners`, or pass `resolveContextRuleIds`. |

### SimpleThreshold policy errors (3200 range)

| Code | Symbol | Meaning |
|------|--------|---------|
| 3200 | SmartAccountNotInstalled | Policy was uninstalled or never installed on this smart account |
| 3201 | InvalidThreshold | `threshold == 0` or `threshold > signer_count` |
| 3202 | NotAllowed | Signer count below threshold at enforcement time |
| 3203 | AlreadyInstalled | Policy already installed on this rule (remove first) |

### WeightedThreshold policy errors (3210 range)

| Code | Symbol | Meaning |
|------|--------|---------|
| 3210 | SmartAccountNotInstalled | Policy was uninstalled or never installed |
| 3211 | InvalidThreshold | Threshold is 0 or > sum of weights |
| 3212 | MathOverflow | Weight sum would overflow `u32` |
| 3213 | NotAllowed | Sum of signing signers' weights below threshold |
| 3214 | AlreadyInstalled | Policy already installed on this rule |

### SpendingLimit policy errors (3220 range)

| Code | Symbol | Meaning |
|------|--------|---------|
| 3220 | SmartAccountNotInstalled | Policy was uninstalled or never installed |
| 3221 | SpendingLimitExceeded | Transfer would exceed the limit for the current window |
| 3222 | InvalidLimitOrPeriod | `spendingLimit <= 0` or `periodLedgers == 0` |
| 3223 | NotAllowed | Generic policy rejection at enforcement time |
| 3224 | HistoryCapacityExceeded | Transfer history exceeds the per-account/rule cap |
| 3225 | AlreadyInstalled | Policy already installed on this rule |
| 3226 | LessThanZero | `transfer` amount argument is negative |
| 3227 | OnlyCallContractAllowed | Policy installed on a `Default` or `CreateContract` rule; only `CallContract` rules are supported |

### Handling pattern

```dart
try {
  final res = await kit.policyManager.addSimpleThreshold(
    contextRuleId: 0,
    policyAddress: 'CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC',
    threshold: 2,
  );
  if (!res.success) print('submit failed: ${res.error}');
} on SmartAccountTransactionSimulationFailed catch (e) {
  print('simulation failed: $e'); // message carries the contract error code
} on SmartAccountInvalidInput catch (e) {
  print('client-side validation: ${e.message}');
} on SmartAccountWalletNotConnected {
  print('call connectWallet() first');
}
```

`SmartAccountTransactionSimulationFailed`, `SmartAccountTransactionSubmissionFailed`, `SmartAccountInvalidInput`, `SmartAccountInvalidAddress`, `SmartAccountInvalidAmount`, and `SmartAccountWalletNotConnected` are concrete exception subtypes (not factory methods). Catch the sealed bases `SmartAccountTransactionException` / `SmartAccountValidationException` / `SmartAccountWalletException` for broader handling.

### BigInt for i128

i128 amounts (transfer amounts, spending limits) and the stroops they convert to are `BigInt` end-to-end. `Util.toXdrInt64Amount(String)` returns a `BigInt`; `Util.stroopsToI128ScVal(BigInt)` consumes one; `OZSpendingLimitPolicyParams.spendingLimit` is a `BigInt`. On web, a stroops value above 2^53 exceeds JS `Number` range. Never lower a limit or clamp an amount to fit `Number` — keep `BigInt` throughout.

See also [smart_accounts.md — Error Handling](./smart_accounts.md#error-handling) for the full SDK exception hierarchy.
