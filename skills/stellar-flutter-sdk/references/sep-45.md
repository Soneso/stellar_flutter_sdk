# SEP-45: Web Authentication for Contract Accounts

**Purpose:** Authenticate Soroban smart contract accounts (C... addresses) with anchor services and receive a JWT token for subsequent SEP calls.
**Prerequisites:** Requires SEP-01 stellar.toml (provides `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`, `WEB_AUTH_CONTRACT_ID`, `SIGNING_KEY`)
**SEP-45 vs SEP-10:** SEP-45 is for contract accounts (C...). SEP-10 is for traditional accounts (G... and M...).

## Table of Contents

- [Quick Start](#quick-start)
- [Creating WebAuthForContracts](#creating-webauthforcontracts)
- [jwtToken() — the Complete Flow](#jwttoken--the-complete-flow)
- [Contracts Without Signature Requirements](#contracts-without-signature-requirements)
- [Client Domain Verification](#client-domain-verification)
- [Step-by-Step Authentication](#step-by-step-authentication)
- [Request Format](#request-format)
- [Response Objects](#response-objects)
- [Error Handling](#error-handling)
- [Testing with MockClient](#testing-with-mockclient)
- [Common Pitfalls](#common-pitfalls)
- [SEP-45 vs SEP-10 Comparison](#sep-45-vs-sep-10-comparison)

---

## Quick Start

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Your contract account (C... address) — must implement __check_auth
const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';

// Signer registered in your contract's __check_auth — must have private key
final signer = KeyPair.fromSecretSeed(contractSignerSeed);

// Load config from anchor's stellar.toml and authenticate in one call
final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);
final jwtToken = await webAuth.jwtToken(contractId, [signer]);

print('Authenticated! Token: ${jwtToken.substring(0, 50)}...');
```

---

## Creating WebAuthForContracts

### From domain (recommended)

`WebAuthForContracts.fromDomain()` is a static async factory. It fetches the anchor's
`stellar.toml`, reads `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`, `WEB_AUTH_CONTRACT_ID`, and
`SIGNING_KEY`, and returns a configured instance.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  final webAuth = await WebAuthForContracts.fromDomain(
    'anchor.example.com',
    Network.TESTNET,
  );
} on NoWebAuthForContractsEndpointFoundException catch (e) {
  print('No WEB_AUTH_FOR_CONTRACTS_ENDPOINT for ${e.domain}');
} on NoWebAuthContractIdFoundException catch (e) {
  print('No WEB_AUTH_CONTRACT_ID for ${e.domain}');
} catch (e) {
  print('Failed to load WebAuth config: $e');
}
```

Signature:
```
static Future<WebAuthForContracts> fromDomain(
  String domain,
  Network network, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
})
```

### Manual construction

Use when you have the values directly (e.g., cached or for tests).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = WebAuthForContracts(
  'https://auth.anchor.example.com/sep45',               // authEndpoint
  'CCALHRGH5RXIDJDRLPPG4ZX2S563TB2QKKJR4STWKVQCYB6JVPYQXHRG', // webAuthContractId (C...)
  'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',  // serverSigningKey (G...)
  'anchor.example.com',                                  // serverHomeDomain
  Network.TESTNET,                                       // network
);
```

Constructor signature:
```
WebAuthForContracts(
  String authEndpoint,       // WEB_AUTH_FOR_CONTRACTS_ENDPOINT — must be a valid URL
  String webAuthContractId,  // WEB_AUTH_CONTRACT_ID — must start with 'C'
  String serverSigningKey,   // SIGNING_KEY — must start with 'G'
  String serverHomeDomain,   // domain name — must not be empty
  Network network, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
  String? sorobanRpcUrl,     // defaults to soroban-testnet.stellar.org / soroban.stellar.org
})
```

The constructor throws `ArgumentError` if any parameter is invalid (wrong prefix, bad URL, empty domain).

```dart
// WRONG: webAuthContractId and serverSigningKey are swapped
WebAuthForContracts(endpoint, serverSigningKey, webAuthContractId, domain, Network.TESTNET);
// → ArgumentError: webAuthContractId must be a contract address starting with 'C'

// CORRECT: webAuthContractId (C...) before serverSigningKey (G...)
WebAuthForContracts(endpoint, webAuthContractId, serverSigningKey, domain, Network.TESTNET);
```

### Custom Soroban RPC URL

By default the SDK uses `https://soroban-testnet.stellar.org` (testnet) or
`https://soroban.stellar.org` (pubnet). Pass `sorobanRpcUrl` to override.

```dart
final webAuth = WebAuthForContracts(
  'https://auth.anchor.example.com/sep45',
  webAuthContractId,
  serverSigningKey,
  'anchor.example.com',
  Network.TESTNET,
  sorobanRpcUrl: 'https://my-rpc.example.com',
);
```

---

## jwtToken() — the Complete Flow

`jwtToken()` executes the entire SEP-45 flow in one call:

1. GET challenge from server (`authorization_entries` + optional `network_passphrase`)
2. Validate `network_passphrase` if present
3. Decode and validate all authorization entries (contract address, function name, args, server signature, nonce consistency)
4. Auto-fetch current ledger via Soroban RPC to set `signatureExpirationLedger` (if signers provided and no explicit expiration)
5. Sign the client authorization entry with the provided keypairs
6. POST signed entries to server and return the JWT token string

Method signature:
```
Future<String> jwtToken(
  String clientAccountId,                    // C... contract address to authenticate
  List<KeyPair> signers, {                   // keypairs with private keys; can be empty
  String? homeDomain,                        // defaults to serverHomeDomain from stellar.toml
  String? clientDomain,                      // wallet domain for client attribution
  KeyPair? clientDomainAccountKeyPair,       // wallet signing keypair (local signing)
  Future<SorobanAuthorizationEntry> Function(SorobanAuthorizationEntry)?
      clientDomainSigningCallback,           // callback for remote client domain signing
  int? signatureExpirationLedger,            // defaults to current ledger + 10
})
```

Returns the JWT token string. Throws on any failure — see [Error Handling](#error-handling).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';
final signer = KeyPair.fromSecretSeed(contractSignerSeed);

// Simple: auto-expiration, default home domain
final jwtToken = await webAuth.jwtToken(contractId, [signer]);

// With explicit home domain and custom expiration
final jwtToken = await webAuth.jwtToken(
  contractId,
  [signer],
  homeDomain: 'anchor.example.com',
  signatureExpirationLedger: 1500000,
);
```

**Signature expiration:** When signers are provided and `signatureExpirationLedger` is `null`, the SDK calls `SorobanServer.getLatestLedger()` and sets expiration to `sequence + 10` (~50–60 seconds). If the signers array is empty, this Soroban RPC call is skipped entirely.

---

## Contracts Without Signature Requirements

Some contracts implement `__check_auth` without requiring signature verification. Pass an empty list for signers:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

// Empty signers list — no signatures added, no Soroban RPC call made
final jwtToken = await webAuth.jwtToken(
  'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ',
  [],
);
```

This only works if the anchor also supports signature-less authentication.

---

## Client Domain Verification

Non-custodial wallets can prove their domain identity so the anchor can attribute requests to a specific wallet. The wallet's `stellar.toml` must publish a `SIGNING_KEY`.

### Local signing (wallet owns the key)

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';
final signer = KeyPair.fromSecretSeed(contractSignerSeed);
final clientDomainKeyPair = KeyPair.fromSecretSeed(walletSigningSecretSeed);

final jwtToken = await webAuth.jwtToken(
  contractId,
  [signer],
  homeDomain: 'anchor.example.com',
  clientDomain: 'wallet.example.com',
  clientDomainAccountKeyPair: clientDomainKeyPair,
);
```

### Remote signing via callback

When the client domain signing key is on a separate server, provide a callback. The callback receives a single `SorobanAuthorizationEntry` (the client domain entry) and must return it signed.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';
final signer = KeyPair.fromSecretSeed(contractSignerSeed);

// Callback receives ONE SorobanAuthorizationEntry and must return it signed
Future<SorobanAuthorizationEntry> signingCallback(SorobanAuthorizationEntry entry) async {
  final client = http.Client();
  try {
    final response = await client.post(
      Uri.parse('https://signing-server.wallet.example.com/sign-sep45'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $signingServerToken',
      },
      body: json.encode({
        'authorization_entry': entry.toBase64EncodedXdrString(),
        'network_passphrase': 'Test SDF Network ; September 2015',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Remote signing failed: ${response.body}');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return SorobanAuthorizationEntry.fromBase64EncodedXdr(
      data['authorization_entry'] as String,
    );
  } finally {
    client.close();
  }
}

// When using callback (no clientDomainAccountKeyPair), the SDK fetches the
// client domain's stellar.toml to get its SIGNING_KEY — one extra HTTP request
final jwtToken = await webAuth.jwtToken(
  contractId,
  [signer],
  clientDomain: 'wallet.example.com',
  clientDomainSigningCallback: signingCallback,
);
```

Callback signature: `Future<SorobanAuthorizationEntry> Function(SorobanAuthorizationEntry)`

```dart
// WRONG: SEP-10 delegate pattern — receives/returns base64 XDR string
Future<String> sep10Delegate(String transactionXdr) async { ... }

// CORRECT: SEP-45 callback — receives and returns SorobanAuthorizationEntry
Future<SorobanAuthorizationEntry> sep45Callback(SorobanAuthorizationEntry entry) async { ... }
```

When `clientDomain` is provided, you must supply either `clientDomainAccountKeyPair` or `clientDomainSigningCallback`. Providing neither throws `ArgumentError`.

```dart
// WRONG: clientDomain provided without either signing means — throws ArgumentError
await webAuth.jwtToken(contractId, [signer],
  clientDomain: 'wallet.example.com',
  // missing clientDomainAccountKeyPair and clientDomainSigningCallback
);

// CORRECT: provide one of the two signing options
await webAuth.jwtToken(contractId, [signer],
  clientDomain: 'wallet.example.com',
  clientDomainAccountKeyPair: walletKeyPair,   // option A: local keypair
  // or:
  // clientDomainSigningCallback: signingCallback,  // option B: remote callback
);
```

---

## Step-by-Step Authentication

For maximum control, call each step individually.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';
final signer = KeyPair.fromSecretSeed(contractSignerSeed);
const homeDomain = 'anchor.example.com';

final webAuth = await WebAuthForContracts.fromDomain(homeDomain, Network.TESTNET);

try {
  // Step 1: GET challenge from server
  final challengeResponse = await webAuth.getChallenge(contractId, homeDomain: homeDomain);

  // Step 2: Decode authorization entries from base64 XDR
  final authEntries = webAuth.decodeAuthorizationEntries(
    challengeResponse.authorizationEntries,
  );

  // Step 3: Validate challenge (security checks — always do before signing)
  webAuth.validateChallenge(authEntries, contractId, homeDomain: homeDomain);

  // Step 4: Get current ledger for signature expiration
  final sorobanServer = SorobanServer('https://soroban-testnet.stellar.org');
  final latestLedger = await sorobanServer.getLatestLedger();
  final expirationLedger = latestLedger.sequence! + 10;

  // Step 5: Sign client authorization entries
  final signedEntries = await webAuth.signAuthorizationEntries(
    authEntries,
    contractId,
    [signer],
    expirationLedger,
    null,   // clientDomainKeyPair
    null,   // clientDomainAccountId
    null,   // clientDomainSigningCallback
  );

  // Step 6: POST signed entries and get JWT
  final jwtToken = await webAuth.sendSignedChallenge(signedEntries);

  print('JWT Token: $jwtToken');
} catch (e) {
  print('Error: $e');
}
```

### Method signatures for low-level access

```
Future<ContractChallengeResponse> getChallenge(
  String clientAccountId, {
  String? homeDomain,    // defaults to serverHomeDomain
  String? clientDomain,
})

List<SorobanAuthorizationEntry> decodeAuthorizationEntries(String base64Xdr)

void validateChallenge(
  List<SorobanAuthorizationEntry> authEntries,
  String clientAccountId, {
  String? homeDomain,            // defaults to serverHomeDomain
  String? clientDomainAccountId,
})

Future<List<SorobanAuthorizationEntry>> signAuthorizationEntries(
  List<SorobanAuthorizationEntry> authEntries,
  String clientAccountId,
  List<KeyPair> signers,
  int? signatureExpirationLedger,
  KeyPair? clientDomainKeyPair,
  String? clientDomainAccountId,
  Future<SorobanAuthorizationEntry> Function(SorobanAuthorizationEntry)? clientDomainSigningCallback,
)

Future<String> sendSignedChallenge(List<SorobanAuthorizationEntry> signedEntries)
// returns JWT token string
```

---

## Request Format

By default the SDK submits signed challenges as `application/x-www-form-urlencoded`.
To switch to JSON, set the public field:

```dart
// Default: form-urlencoded (useFormUrlEncoded = true)
webAuth.useFormUrlEncoded = true;

// Switch to application/json
webAuth.useFormUrlEncoded = false;
```

---

## Response Objects

### ContractChallengeResponse

Returned by `getChallenge()`. Contains the authorization entries to decode, validate, and sign.

| Field | Type | Description |
|-------|------|-------------|
| `authorizationEntries` | `String` | Base64-encoded XDR array of `SorobanAuthorizationEntry` objects |
| `networkPassphrase` | `String?` | Optional — server's network passphrase for validation |

```dart
final challengeResponse = await webAuth.getChallenge(contractId);
final xdr = challengeResponse.authorizationEntries;
final passphrase = challengeResponse.networkPassphrase; // may be null
```

JSON mapping: `authorization_entries` → `authorizationEntries`, `network_passphrase` → `networkPassphrase`.

### SubmitContractChallengeResponse

Internal response from the token POST endpoint. `jwtToken()` extracts the token automatically; you only encounter this directly when using `sendSignedChallenge()`.

| Field | Type | Description |
|-------|------|-------------|
| `jwtToken` | `String?` | JWT token on success (JSON field: `token`) |
| `error` | `String?` | Error message on failure (JSON field: `error`) |

```dart
// WRONG: the JSON field is 'token', not 'jwt_token'
// CORRECT: SubmitContractChallengeResponse.jwtToken reads the 'token' JSON field
```

### JWT Claims

| Claim | Description |
|-------|-------------|
| `sub` | Authenticated contract account (C... address) |
| `iss` | Token issuer (authentication server URI) |
| `iat` | Issued-at timestamp (Unix epoch) |
| `exp` | Expiration timestamp (Unix epoch) |
| `client_domain` | Present when client domain verification was performed |

---

## Error Handling

All challenge validation exceptions extend `ContractChallengeValidationException implements Exception`.
Submit exceptions implement `Exception` directly. All exception classes are importable from
`package:stellar_flutter_sdk/stellar_flutter_sdk.dart`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);
const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';
final signer = KeyPair.fromSecretSeed(contractSignerSeed);

try {
  final jwtToken = await webAuth.jwtToken(contractId, [signer]);
  print('JWT: $jwtToken');

} on ArgumentError catch (e) {
  // Bad parameters: non-C... clientAccountId, clientDomain without signing means,
  // invalid constructor args (wrong prefixes, bad URL, empty domain)
  print('Invalid arguments: $e');

} on NoWebAuthForContractsEndpointFoundException catch (e) {
  // fromDomain(): stellar.toml is missing WEB_AUTH_FOR_CONTRACTS_ENDPOINT
  print('No WEB_AUTH_FOR_CONTRACTS_ENDPOINT for ${e.domain}');

} on NoWebAuthContractIdFoundException catch (e) {
  // fromDomain(): stellar.toml is missing WEB_AUTH_CONTRACT_ID
  print('No WEB_AUTH_CONTRACT_ID for ${e.domain}');

} on ContractChallengeRequestErrorResponse catch (e) {
  // GET challenge failed — bad account, rate limit, server error
  // e.statusCode: int?; e.message: String
  print('Challenge request failed (HTTP ${e.statusCode}): ${e.message}');

} on ContractChallengeValidationErrorSubInvocationsFound catch (e) {
  // SECURITY CRITICAL: challenge contains sub-invocations — do NOT sign
  print('SECURITY ALERT: sub-invocations in challenge from anchor');
  rethrow;

} on ContractChallengeValidationErrorInvalidContractAddress catch (e) {
  // Entry contract address ≠ WEB_AUTH_CONTRACT_ID — substitution attack
  print('Security error: contract address mismatch: $e');

} on ContractChallengeValidationErrorInvalidServerSignature catch (e) {
  // Server entry not signed by expected SIGNING_KEY — possible MITM
  print('Security error: invalid server signature: $e');

} on ContractChallengeValidationErrorInvalidFunctionName catch (e) {
  // Function name ≠ "web_auth_verify"
  print('Invalid challenge: wrong function name: $e');

} on ContractChallengeValidationErrorInvalidNetworkPassphrase catch (e) {
  // network_passphrase in response ≠ configured network — cross-network attack
  print('Network passphrase mismatch: $e');

} on ContractChallengeValidationErrorInvalidAccount catch (e) {
  // account arg in entries ≠ clientAccountId
  print('Invalid challenge: account mismatch: $e');

} on ContractChallengeValidationErrorInvalidHomeDomain catch (e) {
  // home_domain arg ≠ expected home domain
  print('Invalid challenge: home domain mismatch: $e');

} on ContractChallengeValidationErrorInvalidWebAuthDomain catch (e) {
  // web_auth_domain arg ≠ host of the auth endpoint URL
  print('Invalid challenge: web auth domain mismatch: $e');

} on ContractChallengeValidationErrorInvalidNonce catch (e) {
  // Nonce missing or inconsistent across entries — replay protection violated
  print('Invalid challenge: nonce inconsistency: $e');

} on ContractChallengeValidationErrorInvalidArgs catch (e) {
  // Args not in expected Map<Symbol, String> format, web_auth_domain_account
  // ≠ server SIGNING_KEY, or client_domain_account mismatch
  print('Invalid challenge: bad args: $e');

} on ContractChallengeValidationErrorMissingServerEntry catch (e) {
  // No authorization entry for the server account
  print('Invalid challenge: missing server entry: $e');

} on ContractChallengeValidationErrorMissingClientEntry catch (e) {
  // No authorization entry for the client contract or client domain account
  print('Invalid challenge: missing client entry: $e');

} on ContractChallengeValidationException catch (e) {
  // Catch-all for other validation failures (malformed XDR, empty entries, etc.)
  print('Challenge validation failed: $e');

} on SubmitContractChallengeErrorResponseException catch (e) {
  // Server rejected signed entries — signer not registered in __check_auth,
  // insufficient weight, invalid signature. HTTP 200 or 400 with 'error' field.
  // e.error: String
  print('Authentication rejected: ${e.error}');

} on SubmitContractChallengeTimeoutResponseException {
  // HTTP 504 Gateway Timeout — server overloaded during transaction simulation
  print('Server timeout — retry later');

} on SubmitContractChallengeUnknownResponseException catch (e) {
  // Unexpected HTTP status (not 200, 400, or 504)
  // e.code: int; e.body: String
  print('Unexpected response (HTTP ${e.code}): ${e.body}');
}
```

### Exception reference table

| Exception class | Trigger | Notes |
|-----------------|---------|-------|
| `ArgumentError` (Dart built-in) | Non-C... clientAccountId; clientDomain without signing means; bad constructor params | Fix calling code |
| `NoWebAuthForContractsEndpointFoundException` | `fromDomain()`: stellar.toml missing `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`; field `domain` | Check domain supports SEP-45 |
| `NoWebAuthContractIdFoundException` | `fromDomain()`: stellar.toml missing `WEB_AUTH_CONTRACT_ID`; field `domain` | Check domain supports SEP-45 |
| `MissingClientDomainForContractAuthException` | `clientDomainSigningCallback` provided without `clientDomain` | Add `clientDomain` parameter |
| `ContractChallengeRequestErrorResponse` | GET challenge failed; fields `message` + `statusCode` (int?) | Check account format |
| `ContractChallengeValidationErrorSubInvocationsFound` | Challenge has sub-invocations | **CRITICAL** — abort, do not sign |
| `ContractChallengeValidationErrorInvalidContractAddress` | Entry contract address ≠ `WEB_AUTH_CONTRACT_ID` | **CRITICAL** — substitution attack |
| `ContractChallengeValidationErrorInvalidServerSignature` | Server entry not signed by expected `SIGNING_KEY` | **CRITICAL** — possible MITM |
| `ContractChallengeValidationErrorInvalidFunctionName` | Function name ≠ `"web_auth_verify"` | **CRITICAL** — wrong function |
| `ContractChallengeValidationErrorInvalidNetworkPassphrase` | `network_passphrase` ≠ configured network | High — cross-network attack |
| `ContractChallengeValidationErrorInvalidAccount` | `account` arg ≠ client contract ID | High — account substitution |
| `ContractChallengeValidationErrorInvalidHomeDomain` | `home_domain` arg ≠ expected home domain | High — domain confusion |
| `ContractChallengeValidationErrorInvalidWebAuthDomain` | `web_auth_domain` arg ≠ auth endpoint host | High — server spoofing |
| `ContractChallengeValidationErrorInvalidNonce` | Nonce missing or inconsistent across entries | High — replay attack |
| `ContractChallengeValidationErrorInvalidArgs` | Args not in Map format, `web_auth_domain_account` ≠ server key, client domain mismatch | High |
| `ContractChallengeValidationErrorMissingServerEntry` | No entry whose credentials address = server signing key | High |
| `ContractChallengeValidationErrorMissingClientEntry` | No entry whose credentials address = client contract or client domain | High |
| `ContractChallengeValidationException` | Generic validation failure (malformed XDR, empty entries) | Unexpected server behavior |
| `SubmitContractChallengeErrorResponseException` | Server rejected signed entries; field `error` (String) | Check signer registration |
| `SubmitContractChallengeTimeoutResponseException` | HTTP 504 Gateway Timeout | Retry with backoff |
| `SubmitContractChallengeUnknownResponseException` | Unexpected HTTP status; fields `code` (int) + `body` (String) | Unexpected server behavior |

---

## Testing with MockClient

Use `MockClient` from the `http/testing.dart` package. Construct `WebAuthForContracts` manually and
pass the mock via the `httpClient` named parameter, then set `sorobanRpcUrl` to prevent real network
calls when auto-expiration is needed.

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Server configuration — must match WebAuthForContracts initialization
  const serverAccountId = 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP';
  const serverSecretSeed = 'SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W';
  final serverKeyPair = KeyPair.fromSecretSeed(serverSecretSeed);

  const webAuthContractId = 'CA7A3N2BB35XMTFPAYWVZEF4TEYXW7DAEWDXJNQGUPR5SWSM2UVZCJM2';
  const domain = 'example.stellar.org';
  const authServer = 'https://auth.example.stellar.org';
  const clientContractId = 'CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV';
  const successJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test';

  // Build args map for web_auth_verify
  XdrSCVal buildArgsMap({required String nonce}) {
    return XdrSCVal.forMap([
      XdrSCMapEntry(XdrSCVal.forSymbol('account'), XdrSCVal.forString(clientContractId)),
      XdrSCMapEntry(XdrSCVal.forSymbol('home_domain'), XdrSCVal.forString(domain)),
      XdrSCMapEntry(XdrSCVal.forSymbol('web_auth_domain'), XdrSCVal.forString('auth.example.stellar.org')),
      XdrSCMapEntry(XdrSCVal.forSymbol('web_auth_domain_account'), XdrSCVal.forString(serverAccountId)),
      XdrSCMapEntry(XdrSCVal.forSymbol('nonce'), XdrSCVal.forString(nonce)),
    ]);
  }

  // Build a single authorization entry
  SorobanAuthorizationEntry buildEntry({
    required String credentialsAddress,
    required BigInt nonce,
    required XdrSCVal argsMap,
  }) {
    final address = credentialsAddress.startsWith('C')
        ? Address.forContractId(credentialsAddress)
        : Address.forAccountId(credentialsAddress);

    final credentials = SorobanCredentials.forAddress(
      address,
      nonce,
      1000000, // expirationLedger
      XdrSCVal.forVec([]),
    );

    final contractAddress = Address.forContractId(webAuthContractId);
    final contractFn = XdrInvokeContractArgs(
      contractAddress.toXdr(),
      'web_auth_verify',
      [argsMap],
    );

    final function = SorobanAuthorizedFunction(contractFn: contractFn);
    final invocation = SorobanAuthorizedInvocation(function, subInvocations: []);
    return SorobanAuthorizationEntry(credentials, invocation);
  }

  // Encode authorization entries to base64 XDR (matches SDK wire format)
  String encodeEntries(List<SorobanAuthorizationEntry> entries) {
    final out = XdrDataOutputStream();
    out.writeInt(entries.length);
    for (final e in entries) {
      XdrSorobanAuthorizationEntry.encode(out, e.toXdr());
    }
    return base64Encode(out.bytes);
  }

  test('SEP-45 standard authentication', () async {
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final argsMap = buildArgsMap(nonce: nonce);

    final serverEntry = buildEntry(
      credentialsAddress: serverAccountId,
      nonce: BigInt.from(12345),
      argsMap: argsMap,
    );
    serverEntry.sign(serverKeyPair, Network.TESTNET); // server entry must be pre-signed

    final clientEntry = buildEntry(
      credentialsAddress: clientContractId,
      nonce: BigInt.from(12346),
      argsMap: argsMap,
    );

    final challengeXdr = encodeEntries([serverEntry, clientEntry]);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      // POST: return JWT token
      return http.Response(json.encode({'token': successJwt}), 200);
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    final clientSigner = KeyPair.random();
    final token = await webAuth.jwtToken(
      clientContractId,
      [clientSigner],
      homeDomain: domain,
    );

    expect(token, equals(successJwt));
  });
}
```

**Key details for building a valid mock challenge:**
- The server entry credentials address must match `serverSigningKey` (G... address)
- The client entry credentials address must match `clientAccountId` (C... address)
- The server entry must be signed with `serverKeyPair` and the correct `Network` before encoding
- `web_auth_domain` in the args map must match the **host** of the `authEndpoint` URL (e.g., `auth.example.stellar.org`, not the full URL; include port if non-standard)
- The `nonce` arg string must be identical across all entries
- No entry may contain sub-invocations
- The encoded challenge is an XDR array: `writeInt(count)` followed by each `XdrSorobanAuthorizationEntry`

**Mock response ordering for client domain callback:**

When using `clientDomainSigningCallback` (without `clientDomainAccountKeyPair`), the SDK fetches the client domain's stellar.toml after the challenge. Provide three responses in order:

```dart
var requestCount = 0;
final mockClient = MockClient((request) async {
  requestCount++;
  if (requestCount == 1 && request.method == 'GET') {
    // 1. Challenge response
    return http.Response(
      json.encode({'authorization_entries': challengeXdr}),
      200,
    );
  }
  if (requestCount == 2) {
    // 2. stellar.toml fetch for client domain signing key
    return http.Response('SIGNING_KEY = "$clientDomainAccount"', 200);
  }
  // 3. Token POST response
  return http.Response(json.encode({'token': successJwt}), 200);
});
```

---

## Common Pitfalls

**WRONG: passing a G... or M... address to jwtToken()**

```dart
// WRONG: jwtToken() requires a C... contract address — throws ArgumentError
await webAuth.jwtToken('GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP', [signer]);

// CORRECT: pass the C... contract address
await webAuth.jwtToken('CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ', [signer]);
```

**WRONG: signers must contain KeyPairs with private keys**

```dart
// WRONG: KeyPair.fromAccountId() has no private key and cannot sign
final publicOnly = KeyPair.fromAccountId(accountId);
await webAuth.jwtToken(contractId, [publicOnly]);
// → server rejects (SubmitContractChallengeErrorResponseException)

// CORRECT: KeyPair.fromSecretSeed() includes the private key
final signer = KeyPair.fromSecretSeed(secretSeed);
await webAuth.jwtToken(contractId, [signer]);
```

**WRONG: treating SubInvocationsFound as a recoverable error**

```dart
// WRONG: logging and continuing — could authorize unintended contract operations
} on ContractChallengeValidationErrorSubInvocationsFound catch (e) {
  print('Warning: $e'); // Do NOT retry or sign

// CORRECT: abort and alert
} on ContractChallengeValidationErrorSubInvocationsFound catch (e) {
  // This indicates a potentially malicious server — abort immediately
  rethrow;
```

**WRONG: network mismatch between WebAuthForContracts and the anchor**

```dart
// WRONG: pubnet WebAuthForContracts against a testnet anchor
final webAuth = WebAuthForContracts(endpoint, contractId, signingKey, domain, Network.PUBLIC);
// → ContractChallengeValidationErrorInvalidServerSignature or InvalidNetworkPassphrase

// CORRECT: match the network to the anchor's actual network
final webAuth = WebAuthForContracts(endpoint, contractId, signingKey, domain, Network.TESTNET);
```

**WRONG: wrong constructor parameter order**

```dart
// WRONG: confusing webAuthContractId (C...) and serverSigningKey (G...)
WebAuthForContracts(endpoint, serverSigningKey, webAuthContractId, domain, Network.TESTNET);
// → ArgumentError: webAuthContractId must be a contract address starting with 'C'

// CORRECT: webAuthContractId (C...) before serverSigningKey (G...)
WebAuthForContracts(endpoint, webAuthContractId, serverSigningKey, domain, Network.TESTNET);
```

**WRONG: using fromDomain() then assigning a mock httpClient**

`fromDomain()` uses its own `http.Client` for the stellar.toml fetch and creates the internal client. After `fromDomain()` returns, you can replace `webAuth.httpClient`, but the stellar.toml was already fetched with a real HTTP call. For testing, always construct `WebAuthForContracts` manually and pass the mock via the `httpClient` named parameter.

```dart
// WRONG: fromDomain() uses real network for stellar.toml — mock arrives too late
final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);
webAuth.httpClient = mockClient; // too late to mock the toml fetch

// CORRECT: construct manually for full mock control
final webAuth = WebAuthForContracts(
  authServer, webAuthContractId, serverAccountId, domain, Network.TESTNET,
  httpClient: mockClient,
);
```

**WRONG: ContractChallengeRequestErrorResponse fields**

```dart
// WRONG: no 'code' or 'body' fields on ContractChallengeRequestErrorResponse
print(e.code);    // does not exist
print(e.body);    // does not exist

// CORRECT: use 'message' and 'statusCode'
print(e.message);     // String error message
print(e.statusCode);  // int? HTTP status code
```

**WRONG: SubmitContractChallengeErrorResponseException field name**

```dart
// WRONG: no 'message' field
print(e.message);

// CORRECT: use 'error'
print(e.error); // String: server's error message
```

---

## SEP-45 vs SEP-10 Comparison

| Aspect | SEP-45 (`WebAuthForContracts`) | SEP-10 (`WebAuth`) |
|--------|-------------------------------|---------------------|
| Account type | Contract accounts (C...) | Traditional accounts (G... and M...) |
| stellar.toml endpoint key | `WEB_AUTH_FOR_CONTRACTS_ENDPOINT` | `WEB_AUTH_ENDPOINT` |
| Extra stellar.toml key | `WEB_AUTH_CONTRACT_ID` | — |
| Challenge format | Array of `SorobanAuthorizationEntry` (XDR) | Stellar transaction envelope (XDR) |
| Main class | `WebAuthForContracts` | `WebAuth` |
| Challenge response field | `authorization_entries` | `transaction` |
| Client domain callback arg | `SorobanAuthorizationEntry` (one entry) | `String` (base64 XDR transaction) |
| Client domain callback return | `SorobanAuthorizationEntry` | `String` (base64 XDR) |
| Memo support | No | Yes (G... accounts only) |
| Muxed account support | No | Yes (M... addresses) |
| Replay protection | Signature expiration ledger + nonce | Transaction time bounds |
| Auth verification | Contract `__check_auth` invoked by server | Server verifies Ed25519 signature |
| Empty signers allowed | Yes (contract may not need signatures) | No |
| Exception base class | `ContractChallengeValidationException implements Exception` | `ChallengeValidationError implements Exception` |
| `fromDomain()` exceptions | `NoWebAuthForContractsEndpointFoundException`, `NoWebAuthContractIdFoundException` | `NoWebAuthEndpointFoundException`, `NoWebAuthServerSigningKeyFoundException` |

---

## Related SEPs

- [sep-10.md](sep-10.md) — Web Authentication for traditional accounts (G... addresses)
- [sep-01.md](sep-01.md) — stellar.toml discovery (provides `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`, `WEB_AUTH_CONTRACT_ID`, `SIGNING_KEY`)

