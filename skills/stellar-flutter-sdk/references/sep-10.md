# SEP-10: Web Authentication

**Purpose:** Prove ownership of a Stellar account to an anchor or service and receive a JWT token for authenticated API calls.
**Prerequisites:** Requires SEP-01 stellar.toml (provides `WEB_AUTH_ENDPOINT` and `SIGNING_KEY`)

## Table of Contents

- [Quick Start](#quick-start)
- [Creating WebAuth](#creating-webauth)
- [jwtToken() — the Complete Flow](#jwttoken--the-complete-flow)
- [Standard Authentication](#standard-authentication)
- [Multi-Signature Authentication](#multi-signature-authentication)
- [Memo-Based Authentication](#memo-based-authentication)
- [Muxed Account Authentication](#muxed-account-authentication)
- [Client Domain Verification](#client-domain-verification)
- [Multiple Home Domains](#multiple-home-domains)
- [Response Objects](#response-objects)
- [Error Handling](#error-handling)
- [Testing with MockClient](#testing-with-mockclient)
- [Common Pitfalls](#common-pitfalls)

---

## Quick Start

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Load config from anchor's stellar.toml and run the full SEP-10 flow in one call
final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);

final userKeyPair = KeyPair.fromSecretSeed(userSecretSeed);
final jwtToken = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);

// Use jwtToken as Bearer token for SEP-12, SEP-24, SEP-31, etc.
print('Authenticated! Token: $jwtToken');
```

---

## Creating WebAuth

### From domain (recommended)

`WebAuth.fromDomain()` is a static async factory. It fetches the anchor's
`stellar.toml`, reads `WEB_AUTH_ENDPOINT` and `SIGNING_KEY`, and returns a
configured `WebAuth` instance.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
} on NoWebAuthEndpointFoundException catch (e) {
  print('No WEB_AUTH_ENDPOINT found for ${e.domain}');
} on NoWebAuthServerSigningKeyFoundException catch (e) {
  print('No SIGNING_KEY found for ${e.domain}');
} catch (e) {
  print('Failed to load WebAuth config: $e');
}
```

Signature:
```
static Future<WebAuth> fromDomain(
  String domain,
  Network network, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
})
```

### Manual construction

Use when you already have the endpoint and signing key (e.g., loaded stellar.toml
separately, or for tests with known values).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = WebAuth(
  'https://testanchor.stellar.org/auth', // authEndpoint (WEB_AUTH_ENDPOINT)
  Network.TESTNET,                        // network
  'GCUZ6YLL5RQBTYLTTQLPCM73C5XAIUGK2TIMWQH7HPSGWVS2KJ2F3CHS', // serverSigningKey (SIGNING_KEY)
  'testanchor.stellar.org',               // serverHomeDomain
);
```

Constructor signature:
```
WebAuth(
  String authEndpoint,
  Network network,
  String serverSigningKey,
  String serverHomeDomain, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
})
```

Note: parameter order is `authEndpoint, network, serverSigningKey, serverHomeDomain`.

```dart
// WRONG: wrong parameter order — signingKey before network
WebAuth('https://example.com/auth', serverSigningKey, Network.TESTNET, 'example.com');

// CORRECT: authEndpoint, network, serverSigningKey, serverHomeDomain
WebAuth('https://example.com/auth', Network.TESTNET, serverSigningKey, 'example.com');
```

---

## jwtToken() — the Complete Flow

`jwtToken()` performs all SEP-10 steps internally:

1. Requests a challenge transaction from the auth endpoint (GET)
2. Validates the challenge (sequence number = 0, server signature, time bounds, operation types, source accounts, home domain, web\_auth\_domain)
3. Signs the transaction with the provided signers
4. Submits the signed transaction to the auth endpoint (POST)
5. Returns the JWT token string

Method signature:
```
Future<String> jwtToken(
  String clientAccountId,                                   // G... or M... account address
  List<KeyPair> signers,                                    // must include private keys
  {
    int? memo,                                              // ID memo for shared accounts (G... only)
    String? homeDomain,                                     // override home domain when server serves multiple
    String? clientDomain,                                   // wallet domain for client attribution
    KeyPair? clientDomainAccountKeyPair,                    // wallet signing keypair (if local)
    Future<String> Function(String transactionXdr)?         // callback for remote signing
        clientDomainSigningDelegate,
  }
)
```

Returns the JWT token string. Throws exceptions on any failure — see [Error Handling](#error-handling).

---

## Standard Authentication

For a single-signature account that owns its own keys. The account does not need to
exist on-chain — SEP-10 only proves key ownership.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);

  final userKeyPair = KeyPair.fromSecretSeed(userSecretSeed);

  final jwtToken = await webAuth.jwtToken(
    userKeyPair.accountId,
    [userKeyPair],
  );

  print('JWT: $jwtToken');
}
```

---

## Multi-Signature Authentication

For accounts that require multiple signers to meet the server's threshold. Provide all
required keypairs — their combined weight must satisfy the server's requirements.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);

  final signer1 = KeyPair.fromSecretSeed(secretSeed1);
  final signer2 = KeyPair.fromSecretSeed(secretSeed2);

  // Both signers sign the challenge. Combined weight must meet threshold.
  final jwtToken = await webAuth.jwtToken(
    signer1.accountId, // the account being authenticated
    [signer1, signer2],
  );

  print('JWT: $jwtToken');
}
```

---

## Memo-Based Authentication

For services that distinguish users sharing a single Stellar account via an integer memo.
The `memo` parameter must be a positive integer (`int`, not `BigInt`).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);

  final sharedAccountKeyPair = KeyPair.fromSecretSeed(sharedSecretSeed);
  const int userId = 1234567890; // integer user ID

  final jwtToken = await webAuth.jwtToken(
    sharedAccountKeyPair.accountId, // G... address
    [sharedAccountKeyPair],
    memo: userId,
  );

  print('JWT for user $userId: $jwtToken');
}
```

**Important:** `memo` only works with G... (non-muxed) account IDs. Providing a memo
together with an M... address throws `NoMemoForMuxedAccountsException`.

---

## Muxed Account Authentication

Muxed accounts (M... addresses) embed a user ID into the account address as an
alternative to memos. Pass the M... address as `clientAccountId` and the underlying
G... keypair in `signers`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);

  // Muxed account address (M...) — encodes both the G... account and a memo ID
  const muxedAccountId = 'MB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375UAAAAAAACMICQP7P4';

  // Signing keypair is the underlying G... account's keypair
  final baseKeyPair = KeyPair.fromSecretSeed(baseSecretSeed);

  final jwtToken = await webAuth.jwtToken(
    muxedAccountId, // M... address
    [baseKeyPair],  // sign with the underlying G... keypair
  );

  print('JWT: $jwtToken');
}
```

```dart
// WRONG: memo with M... address — throws NoMemoForMuxedAccountsException
await webAuth.jwtToken('MAAAA...', [keyPair], memo: 12345);

// CORRECT: use one method of user identification, never both
await webAuth.jwtToken('MAAAA...', [keyPair]);          // muxed account only
await webAuth.jwtToken('GAAA...', [keyPair], memo: 12345); // G... + memo only
```

---

## Client Domain Verification

Non-custodial wallets can prove their identity to anchors by providing a client domain
signature. The anchor can then tailor the experience for users of known, trusted wallets.

### Local signing (wallet has the key)

Provide `clientDomain` and `clientDomainAccountKeyPair`. The wallet's `stellar.toml`
must publish a `SIGNING_KEY` that matches the keypair.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);

  final userKeyPair = KeyPair.fromSecretSeed(userSecretSeed);
  final clientDomainKeyPair = KeyPair.fromSecretSeed(walletSigningSecretSeed);

  final jwtToken = await webAuth.jwtToken(
    userKeyPair.accountId,
    [userKeyPair],
    clientDomain: 'mywallet.com',
    clientDomainAccountKeyPair: clientDomainKeyPair,
  );

  print('JWT: $jwtToken');
}
```

### Remote signing delegate (key on a separate server)

When the wallet's signing key is stored on a dedicated signing server, provide a
delegate instead. The SDK fetches the wallet's `stellar.toml` to get its `SIGNING_KEY`
for validation, then calls the delegate with the base64-encoded transaction XDR.
The delegate must return the signed transaction as base64-encoded XDR.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
  final userKeyPair = KeyPair.fromSecretSeed(userSecretSeed);

  // Delegate: receives base64 XDR, must return signed base64 XDR
  Future<String> signingDelegate(String transactionXdr) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('https://signing-server.mywallet.com/sign-sep-10'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $signingServerToken',
        },
        body: json.encode({
          'transaction': transactionXdr,
          'network_passphrase': 'Test SDF Network ; September 2015',
        }),
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (!data.containsKey('transaction')) {
        throw Exception('Invalid signing server response: ${response.body}');
      }
      return data['transaction'] as String;
    } finally {
      client.close();
    }
  }

  final jwtToken = await webAuth.jwtToken(
    userKeyPair.accountId,
    [userKeyPair],
    clientDomain: 'mywallet.com',       // required with delegate
    clientDomainSigningDelegate: signingDelegate,
  );

  print('JWT: $jwtToken');
}
```

Delegate signature: `Future<String> Function(String transactionXdr)`

```dart
// WRONG: delegate provided without clientDomain — throws MissingClientDomainException
await webAuth.jwtToken(accountId, [keyPair],
  clientDomainSigningDelegate: (xdr) async => await sign(xdr),
  // missing clientDomain!
);

// CORRECT: always provide clientDomain alongside the delegate
await webAuth.jwtToken(accountId, [keyPair],
  clientDomain: 'mywallet.com',
  clientDomainSigningDelegate: (xdr) async => await sign(xdr),
);
```

---

## Multiple Home Domains

When an anchor's auth server handles multiple home domains, use `homeDomain` to specify
which domain the challenge should be issued for.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
  final userKeyPair = KeyPair.fromSecretSeed(userSecretSeed);

  final jwtToken = await webAuth.jwtToken(
    userKeyPair.accountId,
    [userKeyPair],
    homeDomain: 'other-domain.com',
  );

  print('JWT: $jwtToken');
}
```

---

## Response Objects

### ChallengeResponse

Returned from `getChallengeResponse()`. You only encounter this directly for
lower-level access — `jwtToken()` handles the full flow automatically.

| Field | Type | Description |
|-------|------|-------------|
| `transaction` | `String?` | Base64-encoded XDR transaction envelope to sign |
| `networkPassphrase` | `String?` | Optional: server's network passphrase for verification |

```dart
// Low-level access
final challengeResponse = await webAuth.getChallengeResponse(accountId);
final xdr = challengeResponse.transaction!;
final networkPassphrase = challengeResponse.networkPassphrase; // may be null
```

JSON mapping: `transaction` → `transaction` field, `networkPassphrase` → `network_passphrase` field.

### SubmitCompletedChallengeResponse

Returned internally by `sendSignedChallengeTransaction()`. You rarely need to use
this directly.

| Field | Type | Description |
|-------|------|-------------|
| `jwtToken` | `String?` | JWT token string on success |
| `error` | `String?` | Server error message on failure |

JSON mapping: `jwtToken` → `token` field (not `jwt_token`), `error` → `error` field.

```dart
// WRONG: json['jwt_token'] — the server field is 'token', mapped to jwtToken property
// CORRECT: the SubmitCompletedChallengeResponse.jwtToken property accesses json['token']
```

---

## Error Handling

All exceptions are importable from `package:stellar_flutter_sdk/stellar_flutter_sdk.dart`.
Challenge validation exceptions extend `ChallengeValidationError implements Exception`.
The three submit exceptions implement `Exception` directly.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  try {
    final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
    final userKeyPair = KeyPair.fromSecretSeed(userSecretSeed);

    final jwtToken = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);
    print('JWT: $jwtToken');

  } on NoWebAuthEndpointFoundException catch (e) {
    // stellar.toml exists but is missing WEB_AUTH_ENDPOINT
    print('No WEB_AUTH_ENDPOINT in stellar.toml for ${e.domain}');

  } on NoWebAuthServerSigningKeyFoundException catch (e) {
    // stellar.toml exists but is missing SIGNING_KEY
    print('No SIGNING_KEY in stellar.toml for ${e.domain}');

  } on NoMemoForMuxedAccountsException {
    // memo provided with an M... account address
    print('Cannot use memo with a muxed (M...) account');

  } on MissingClientDomainSigningKeyException {
    // clientDomain provided without signing key or delegate
    print('Provide clientDomainAccountKeyPair or clientDomainSigningDelegate with clientDomain');

  } on MissingClientDomainException {
    // clientDomainSigningDelegate provided without clientDomain
    print('clientDomain required when using clientDomainSigningDelegate');

  } on NoClientDomainSigningKeyFoundException catch (e) {
    // clientDomainSigningDelegate used but client domain stellar.toml lacks SIGNING_KEY
    print('No SIGNING_KEY in stellar.toml for client domain ${e.domain}');

  } on ChallengeRequestErrorResponse catch (e) {
    // Server rejected the challenge GET request (bad account, server error, etc.)
    // e.code: HTTP status code; e.body: response body (via ErrorResponse)
    print('Challenge request failed HTTP ${e.code}: ${e.body}');

  } on ChallengeValidationErrorInvalidSeqNr catch (e) {
    // SECURITY: challenge has a non-zero sequence number — could be an executable transaction
    print('SECURITY: invalid sequence number — do not sign: $e');

  } on ChallengeValidationErrorInvalidSignature catch (e) {
    // Challenge not signed by the expected server key, or has wrong number of signatures
    print('Invalid server signature — check stellar.toml SIGNING_KEY: $e');

  } on ChallengeValidationErrorInvalidTimeBounds catch (e) {
    // Challenge expired or not yet valid — request a fresh challenge
    print('Challenge expired — retry to get a fresh one: $e');

  } on ChallengeValidationErrorInvalidHomeDomain catch (e) {
    // First operation's data name does not match '<serverHomeDomain> auth'
    print('Home domain mismatch in challenge: $e');

  } on ChallengeValidationErrorInvalidWebAuthDomain catch (e) {
    // web_auth_domain op value does not match the auth endpoint host
    print('web_auth_domain mismatch: $e');

  } on ChallengeValidationErrorInvalidSourceAccount catch (e) {
    // Wrong source account on an operation
    print('Invalid source account in challenge operation: $e');

  } on ChallengeValidationErrorInvalidOperationType catch (e) {
    // SECURITY: challenge contains a non-ManageData operation
    print('SECURITY: non-ManageData op in challenge — server may be malicious: $e');

  } on ChallengeValidationErrorInvalidMemoType catch (e) {
    // Memo in challenge is not MEMO_ID (e.g., server sent MEMO_TEXT)
    print('Invalid memo type in challenge: $e');

  } on ChallengeValidationErrorInvalidMemoValue catch (e) {
    // Memo value missing or doesn't match the requested memo
    print('Memo value mismatch in challenge: $e');

  } on ChallengeValidationErrorMemoAndMuxedAccount catch (e) {
    // Challenge has both a memo and an M... source account — mutually exclusive
    print('Challenge has both memo and muxed account: $e');

  } on ChallengeValidationError catch (e) {
    // Catch-all for other challenge validation issues (malformed XDR, zero operations, etc.)
    print('Challenge validation failed: $e');

  } on SubmitCompletedChallengeErrorResponseException catch (e) {
    // Server rejected signed challenge (HTTP 400) — insufficient signers, bad signature, etc.
    // e.error: server's error message string
    print('Authentication rejected: ${e.error}');

  } on SubmitCompletedChallengeTimeoutResponseException {
    // Server returned HTTP 504 Gateway Timeout
    print('Server timeout — retry later');

  } on SubmitCompletedChallengeUnknownResponseException catch (e) {
    // Server returned an unexpected HTTP status code
    // e.code: int HTTP status; e.body: String response body
    print('Unexpected HTTP ${e.code}: ${e.body}');
  }
}
```

### Exception reference table

| Exception class | When thrown | Action |
|-----------------|-------------|--------|
| `NoWebAuthEndpointFoundException` | `fromDomain()`: stellar.toml missing WEB\_AUTH\_ENDPOINT | Check domain supports SEP-10 |
| `NoWebAuthServerSigningKeyFoundException` | `fromDomain()`: stellar.toml missing SIGNING\_KEY | Check domain supports SEP-10 |
| `NoMemoForMuxedAccountsException` | memo provided with M... account | Use memo OR muxed, not both |
| `MissingClientDomainSigningKeyException` | `clientDomain` set without signing key or delegate | Provide `clientDomainAccountKeyPair` or delegate |
| `MissingClientDomainException` | delegate provided without `clientDomain` | Add `clientDomain` parameter |
| `NoClientDomainSigningKeyFoundException` | delegate used, client domain SIGNING\_KEY absent | Configure stellar.toml |
| `ChallengeRequestErrorResponse` | Server rejected GET (bad account, rate limit, etc.) | Check account format |
| `ChallengeValidationErrorInvalidSeqNr` | Sequence number != 0 | **Security risk** — abort |
| `ChallengeValidationErrorInvalidSignature` | Wrong server signature or wrong sig count | Verify stellar.toml SIGNING\_KEY |
| `ChallengeValidationErrorInvalidTimeBounds` | Challenge expired or future-dated | Retry — get fresh challenge |
| `ChallengeValidationErrorInvalidHomeDomain` | First op key != `'<serverHomeDomain> auth'` | Check serverHomeDomain config |
| `ChallengeValidationErrorInvalidWebAuthDomain` | web\_auth\_domain op value != auth endpoint host | Server config mismatch |
| `ChallengeValidationErrorInvalidSourceAccount` | Wrong source on any operation | Server config issue |
| `ChallengeValidationErrorInvalidOperationType` | Non-ManageData op in challenge | **Security risk** — server may be malicious |
| `ChallengeValidationErrorInvalidMemoType` | Memo is not MEMO\_ID | Server config issue |
| `ChallengeValidationErrorInvalidMemoValue` | Memo missing or value mismatch | Server config issue |
| `ChallengeValidationErrorMemoAndMuxedAccount` | Challenge has both memo and M... address | Server config issue |
| `ChallengeValidationError` | Generic validation failure (malformed XDR, zero operations) | Unexpected server behavior |
| `SubmitCompletedChallengeErrorResponseException` | Server rejected signed challenge (HTTP 400) | Provide all required signers |
| `SubmitCompletedChallengeTimeoutResponseException` | HTTP 504 Gateway Timeout | Retry with exponential backoff |
| `SubmitCompletedChallengeUnknownResponseException` | Unexpected HTTP status code | Check server logs |

### Exception properties

```dart
// ChallengeRequestErrorResponse (extends ErrorResponse)
// — inherits: e.code (int HTTP status), e.body (String response body)

// ChallengeValidationError and all subclasses
// — toString() returns the error message string

// SubmitCompletedChallengeErrorResponseException
// e.error — String: server's error message

// SubmitCompletedChallengeUnknownResponseException
// e.code — int: HTTP status code
// e.body — String: response body

// NoWebAuthEndpointFoundException
// e.domain — String: the domain where endpoint was not found

// NoWebAuthServerSigningKeyFoundException
// e.domain — String: the domain where signing key was not found

// NoClientDomainSigningKeyFoundException
// e.domain — String: the client domain where signing key was not found
```

---

## Testing with MockClient

Replace the HTTP client on a manually-constructed `WebAuth` instance with a
`MockClient` from the `http/testing.dart` package. No network calls are made.

```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Server configuration — must match what WebAuth is initialized with
  const serverAccountId = 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP';
  const serverSecretSeed = 'SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W';
  final serverKeyPair = KeyPair.fromSecretSeed(serverSecretSeed);

  const domain = 'place.domain.com';
  const authServer = 'http://api.stellar.org/auth';

  // Client keypair
  const clientSecretSeed = 'SBAYNYLQFXVLVAHW4BXDQYNJLMDQMZ5NQDDOHVJD3PTBAUIJRNRK5LGX';
  final clientKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
  final clientAccountId = clientKeyPair.accountId;

  const successJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  Uint8List generateNonce([int length = 64]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return Uint8List.fromList(base64Url.encode(values).codeUnits);
  }

  // Build a valid challenge transaction (mimics what the server would produce)
  String buildChallenge(String accountId, [int? memo]) {
    // Account with sequence -1: after build() the sequence becomes 0
    final transactionAccount = Account(serverAccountId, BigInt.from(-1));

    // First op: '<domain> auth', source = client account (as MuxedAccount)
    final muxedAccount = MuxedAccount.fromAccountId(accountId)!;
    final firstOp = ManageDataOperationBuilder(domain + ' auth', generateNonce())
        .setMuxedSourceAccount(muxedAccount)
        .build();

    // Second op: 'web_auth_domain', value = host of authServer, source = server
    final secondOp = ManageDataOperationBuilder(
      'web_auth_domain',
      Uint8List.fromList('api.stellar.org'.codeUnits),
    ).setSourceAccount(serverAccountId).build();

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final preconditions = TransactionPreconditions();
    preconditions.timeBounds = TimeBounds(now - 1, now + 300);

    final transaction = TransactionBuilder(transactionAccount)
        .addOperation(firstOp)
        .addOperation(secondOp)
        .addMemo(memo != null ? MemoId(BigInt.from(memo)) : Memo.none())
        .addPreconditions(preconditions)
        .build();

    transaction.sign(serverKeyPair, Network.TESTNET);
    return json.encode({'transaction': transaction.toEnvelopeXdrBase64()});
  }

  test('SEP-10 standard authentication', () async {
    final webAuth = WebAuth(authServer, Network.TESTNET, serverAccountId, domain);

    webAuth.httpClient = MockClient((request) async {
      // Challenge GET
      if (request.method == 'GET' &&
          request.url.queryParameters['account'] == clientAccountId) {
        return http.Response(buildChallenge(clientAccountId), 200);
      }
      // Token POST — verify signature and return JWT
      if (request.method == 'POST') {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final envelopeXdr = XdrTransactionEnvelope.fromEnvelopeXdrString(
          body['transaction'] as String,
        );
        // Server signature [0] + client signature [1]
        if (envelopeXdr.v1!.signatures.length == 2) {
          return http.Response(json.encode({'token': successJwt}), 200);
        }
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final jwt = await webAuth.jwtToken(clientAccountId, [clientKeyPair]);
    expect(jwt, equals(successJwt));
  });
}
```

**Key details for building a valid mock challenge:**
- The `Account` sequence starts at `BigInt.from(-1)` — `build()` increments it to 0 (required by SEP-10)
- First ManageData op key must be `'<serverHomeDomain> auth'`, source must be the client account (use `setMuxedSourceAccount`)
- The `web_auth_domain` op source must be the server signing key account ID; its value must be the **host** of the auth URL (e.g., `'api.stellar.org'`, not the full URL)
- The transaction must be signed by the server's keypair with the correct `Network`
- Time bounds must include the current time

---

## Common Pitfalls

**Wrong: `memo` with M... muxed account**

```dart
// WRONG: throws NoMemoForMuxedAccountsException
await webAuth.jwtToken('MAAAA...', [keyPair], memo: 12345);

// CORRECT: choose one method of user identification
await webAuth.jwtToken('MAAAA...', [keyPair]);              // muxed account encodes the memo
await webAuth.jwtToken('GAAA...', [keyPair], memo: 12345);  // G... account + separate memo
```

**Wrong: network passphrase mismatch**

The `Network` passed to `WebAuth` must match the network the server signed the challenge
with. If they differ, `ChallengeValidationErrorInvalidSignature` is thrown even though
the challenge was technically valid on its own network.

```dart
// WRONG: WebAuth on public network but anchor signed for testnet
// → ChallengeValidationErrorInvalidSignature (signatures won't verify)
final webAuth = WebAuth(endpoint, Network.PUBLIC, signingKey, domain);

// CORRECT: match the network to the anchor's actual network
final webAuth = WebAuth(endpoint, Network.TESTNET, signingKey, domain);
```

**Wrong: `signers` list must contain KeyPairs with secret keys**

```dart
// WRONG: KeyPair.fromAccountId() has no private key and cannot sign
final publicOnly = KeyPair.fromAccountId(accountId);
await webAuth.jwtToken(accountId, [publicOnly]);
// → server rejects signed challenge (SubmitCompletedChallengeErrorResponseException)

// CORRECT: KeyPair.fromSecretSeed() includes the private key
final fullKeyPair = KeyPair.fromSecretSeed(secretSeed);
await webAuth.jwtToken(accountId, [fullKeyPair]);
```

**Wrong: `clientDomain` without any signing method**

```dart
// WRONG: clientDomain without signing key or delegate — throws MissingClientDomainSigningKeyException
await webAuth.jwtToken(accountId, [keyPair],
  clientDomain: 'mywallet.com',
  // missing: clientDomainAccountKeyPair or clientDomainSigningDelegate
);

// CORRECT: always provide a signing method with clientDomain
await webAuth.jwtToken(accountId, [keyPair],
  clientDomain: 'mywallet.com',
  clientDomainAccountKeyPair: clientDomainKeyPair,
);
```

**Wrong: `clientDomainSigningDelegate` without `clientDomain`**

```dart
// WRONG: throws MissingClientDomainException
await webAuth.jwtToken(accountId, [keyPair],
  clientDomainSigningDelegate: (xdr) async => await sign(xdr),
);

// CORRECT: clientDomain is required alongside the delegate
await webAuth.jwtToken(accountId, [keyPair],
  clientDomain: 'mywallet.com',
  clientDomainSigningDelegate: (xdr) async => await sign(xdr),
);
```

**Wrong: `memo` parameter type is `int`, not `BigInt`**

```dart
// WRONG: memo expects int?, not BigInt
await webAuth.jwtToken(accountId, [keyPair], memo: BigInt.from(12345));

// CORRECT: pass a plain Dart int
await webAuth.jwtToken(accountId, [keyPair], memo: 12345);
```

**Wrong: treating security exceptions as recoverable**

`ChallengeValidationErrorInvalidSeqNr` and `ChallengeValidationErrorInvalidOperationType`
indicate potential malicious server behavior. Never retry or ignore them.

```dart
try {
  final jwt = await webAuth.jwtToken(accountId, [keyPair]);
} on ChallengeValidationErrorInvalidSeqNr catch (e) {
  // Non-zero sequence number: signing could execute a real transaction
  // CORRECT: treat as fatal, do not retry
  throw Exception('SECURITY: auth server returned challenge with non-zero seq nr');
} on ChallengeValidationErrorInvalidOperationType catch (e) {
  // Non-ManageData op: could be a payment or account modification
  // CORRECT: treat as fatal, do not retry
  throw Exception('SECURITY: auth server returned challenge with non-ManageData op');
}
```

**Wrong: assigning httpClient after construction with fromDomain**

`WebAuth.fromDomain()` creates its own internal `http.Client`. To use a custom
`MockClient` for testing, construct `WebAuth` manually, then assign `httpClient`:

```dart
// CORRECT pattern for testing
final webAuth = WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
webAuth.httpClient = MockClient((request) async { ... });
```

---

## JWT Token Structure

The JWT returned by `jwtToken()` is a standard JSON Web Token. The SDK returns the raw
string and does not decode it. Use any JWT library or [jwt.io](https://jwt.io) to inspect.

Standard claims in the token:

| Claim | Description |
|-------|-------------|
| `sub` | Authenticated account — G... address, M... address, or `G...:memo` for memo auth |
| `iss` | Token issuer (the authentication server URL) |
| `iat` | Issued-at timestamp (Unix epoch) |
| `exp` | Expiration timestamp (Unix epoch) |
| `client_domain` | Present when client domain verification was performed |

Use the token as a `Bearer` header for SEP-12 (KYC), SEP-24 (interactive deposit/
withdrawal), SEP-31 (cross-border payments), and any other authenticated anchor API.

```dart
// Using JWT with http for a SEP-24 endpoint
final response = await http.get(
  Uri.parse('https://anchor.example.com/sep24/info'),
  headers: {'Authorization': 'Bearer $jwtToken'},
);
```

---

## Related SEPs

- [sep-01.md](sep-01.md) — stellar.toml discovery (provides `WEB_AUTH_ENDPOINT` and `SIGNING_KEY`)
- SEP-06 — Deposit/Withdrawal API (requires SEP-10 JWT)
- SEP-12 — KYC API (requires SEP-10 JWT)
- SEP-24 — Interactive Deposit/Withdrawal (requires SEP-10 JWT)
- SEP-31 — Cross-Border Payments (requires SEP-10 JWT)

