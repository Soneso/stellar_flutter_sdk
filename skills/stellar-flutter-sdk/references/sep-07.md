# SEP-07: URI Scheme for Delegated Signing

**Purpose:** Generate `web+stellar:` URIs that request transaction signing from external wallets without exposing private keys.
**Prerequisites:** None
**Spec:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Generate Pay URI](#2-generate-pay-uri)
3. [Generate Transaction URI](#3-generate-transaction-uri)
4. [Sign a URI](#4-sign-a-uri)
5. [Validate a URI](#5-validate-a-uri)
6. [Sign and Submit a Transaction](#6-sign-and-submit-a-transaction)
7. [Parse URI Parameters](#7-parse-uri-parameters)
8. [Replace Parameters (SEP-11 Txrep)](#8-replace-parameters-sep-11-txrep)
9. [SubmitUriSchemeTransactionResponse](#9-submiturisschemetransactionresponse)
10. [Testing with Mock HTTP](#10-testing-with-mock-http)
11. [Parameter Constants](#11-parameter-constants)
12. [Common Pitfalls](#12-common-pitfalls)

---

## 1. Quick Start

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// Payment request URI (web+stellar:pay?)
final payUri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  amount: '100',
  assetCode: 'USDC',
  assetIssuer: 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  memo: 'order-12345',
  memoType: 'MEMO_TEXT',
);
print(payUri);
// web+stellar:pay?destination=GDGUF4SC...&amount=100&asset_code=USDC&...

// Transaction URI (web+stellar:tx?)
final sdk = StellarSDK.TESTNET;
final accountId = 'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV';
final sourceAccount = await sdk.accounts.account(accountId);

final setOp = SetOptionsOperationBuilder()
    ..setSourceAccount(accountId)
    ..setHomeDomain('www.example.com');
final transaction = TransactionBuilder(sourceAccount)
    .addOperation(setOp.build())
    .build();

final txUri = uriScheme.generateSignTransactionURI(
  transaction.toEnvelopeXdrBase64(),
  originDomain: 'example.com',
);
final signerKeyPair = KeyPair.fromSecretSeed('S...');
final signedTxUri = uriScheme.addSignature(txUri, signerKeyPair);
```

---

## 2. Generate Pay URI

`generatePayOperationURI()` creates a `web+stellar:pay?` URI. The wallet can choose the payment path (direct payment or path payment) and source asset.

### Minimum (destination only — donation/open amount)

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

final uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
);
// web+stellar:pay?destination=GDGUF4SC...
```

### With all pay parameters

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

final uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  amount: '100',                              // decimal string; omit to let user choose
  assetCode: 'USDC',                          // omit for native XLM
  assetIssuer: 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  memo: 'order-12345',                        // text value; see note below for hash memos
  memoType: 'MEMO_TEXT',                      // MEMO_TEXT | MEMO_ID | MEMO_HASH | MEMO_RETURN
  callback: 'url:https://example.com/pay',    // must be prefixed with "url:"
  message: 'Payment for order 12345',         // max 300 chars, shown to wallet user
  networkPassphrase: Network.TESTNET.networkPassphrase, // omit for public network
  originDomain: 'example.com',                // requires addSignature() call after generation
  signature: null,                            // leave null; addSignature() appends this
);
print(uri);
```

**MEMO_HASH / MEMO_RETURN:** The memo value must be base64-encoded before passing it. The SDK validates this with a regex check.

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

// Create a 32-byte hash for MEMO_HASH
final hashBytes = sha256.convert(utf8.encode('my-identifier')).bytes;
final memoValue = base64Encode(hashBytes);

final uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  memo: memoValue,
  memoType: 'MEMO_HASH',
);
```

---

## 3. Generate Transaction URI

`generateSignTransactionURI()` creates a `web+stellar:tx?` URI that asks a wallet to sign a specific pre-built transaction.

### Minimum (XDR only)

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
// xdrBase64 is the output of transaction.toEnvelopeXdrBase64()
final uri = uriScheme.generateSignTransactionURI(xdrBase64);
print(uri);
// web+stellar:tx?xdr=AAAAAgAAAAD...
```

### Build transaction then generate URI

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final sdk = StellarSDK.TESTNET;
final keyPair = KeyPair.fromSecretSeed('S...');
final sourceAccount = await sdk.accounts.account(keyPair.accountId);

final setOp = SetOptionsOperationBuilder()
    ..setHomeDomain('www.example.com');
final transaction = TransactionBuilder(sourceAccount)
    .addOperation(setOp.build())
    .build();

final uriScheme = URIScheme();
final uri = uriScheme.generateSignTransactionURI(
  transaction.toEnvelopeXdrBase64(),
);
print(uri);
```

### With all tx parameters

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

final uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  replace: 'sourceAccount:X,operations[0].destination:Y;X:Account paying fees,Y:Recipient',
  callback: 'url:https://multisig.example.com/collect',  // must be prefixed with "url:"
  publicKey: 'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV', // which account should sign
  chain: 'web+stellar:tx?xdr=AAAA...&origin_domain=originator.com&signature=...', // max 7 levels deep
  message: 'Please sign to update your home domain',  // max 300 chars
  networkPassphrase: Network.TESTNET.networkPassphrase, // omit for public network
  originDomain: 'example.com',                          // requires addSignature() call after generation
  signature: null,                                      // leave null; addSignature() appends this
);
print(uri);
```

---

## 4. Sign a URI

`addSignature()` appends a cryptographic `signature` parameter to the URI. The signature proves the URI originated from the domain in `origin_domain`. The corresponding public key must be published as `URI_REQUEST_SIGNING_KEY` in the domain's `stellar.toml`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// Generate URI with origin_domain FIRST (addSignature requires it to be present for
// meaningful signature verification, though it does not enforce the field itself)
final uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  originDomain: 'example.com',
);

// Sign with the keypair whose public key is in stellar.toml as URI_REQUEST_SIGNING_KEY
final signerKeyPair = KeyPair.fromSecretSeed('S...');
final signedUri = uriScheme.addSignature(uri, signerKeyPair);

print(signedUri);
// web+stellar:tx?xdr=...&origin_domain=example.com&signature=bIZ53bPK...
```

`addSignature()` returns the full signed URI string. It throws `ArgumentError` if the URI is invalid or already contains a `signature` parameter.

**Pay URI signing works identically:**

```dart
final uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  amount: '50',
  originDomain: 'example.com',
);
final signedUri = uriScheme.addSignature(uri, signerKeyPair);
```

**Your domain's `stellar.toml` must contain:**

```toml
URI_REQUEST_SIGNING_KEY = "GBCD..."  # public key of signerKeyPair
```

---

## 5. Validate a URI

### Structure validation (no network request)

`isValidSep7Url()` validates URI structure, parameter formats, and values without fetching stellar.toml. Returns `IsValidSep7UrlResult` with `result` (bool) and `reason` (String? — only set when `result` is `false`).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
final uri = 'web+stellar:pay?destination=GDGUF...&amount=100';

final result = uriScheme.isValidSep7Url(uri);
if (result.result) {
  print('URI is structurally valid');
} else {
  print('Invalid: ${result.reason}');
}
```

Validation checks performed:
- URI starts with `web+stellar:`
- Operation type is `tx` or `pay`
- `tx` requires `xdr` (valid transaction envelope)
- `pay` requires `destination` (valid Stellar address)
- `asset_code` max 12 chars; `asset_issuer` must be valid G... address
- `pubkey` must be valid G... address (tx only)
- `msg` max 300 chars
- `origin_domain` must be a fully qualified domain name
- `chain` only on tx; max 7 nesting levels
- `memo_type` must be MEMO_TEXT, MEMO_ID, MEMO_HASH, or MEMO_RETURN
- MEMO_HASH / MEMO_RETURN memo values must be base64-encoded and 32 bytes
- pay-only params (`destination`, `amount`, `asset_code`, `asset_issuer`, `memo`, `memo_type`) rejected on tx URIs
- tx-only params (`xdr`, `replace`, `pubkey`, `chain`) rejected on pay URIs

### Full validation including signature (network request)

`isValidSep7SignedUrl()` is `async`. It calls `isValidSep7Url()` first, then fetches `stellar.toml` from `origin_domain`, extracts `URI_REQUEST_SIGNING_KEY`, and verifies the Ed25519 signature.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
final uri = 'web+stellar:tx?xdr=...&origin_domain=example.com&signature=...';

final result = await uriScheme.isValidSep7SignedUrl(uri);
if (result.result) {
  // URI is valid and signature verified — safe to display origin_domain to user
  final parsed = uriScheme.tryParseSep7Url(uri);
  print('Verified request from: ${parsed?.queryParameters[URIScheme.originDomainParameterName]}');
} else {
  print('Validation failed: ${result.reason}');
  // DO NOT display origin_domain; DO NOT allow signing
}
```

`isValidSep7SignedUrl()` failure reasons:
- `"Missing parameter 'origin_domain'"` — origin_domain absent
- `"Missing parameter 'signature'"` — signature absent
- `"The 'origin_domain' parameter is not a fully qualified domain name"` — bad domain
- `"Toml not found or invalid for 'domain'"` — HTTP error fetching stellar.toml
- `"No signing key found in toml from 'domain'"` — stellar.toml has no URI_REQUEST_SIGNING_KEY
- `"Signing key found in toml from 'domain' is not valid"` — URI_REQUEST_SIGNING_KEY is not a valid G... address
- `"Signature is not from the signing key '...' found in the toml data of 'domain'"` — signature verification failed

### Signature verification with known public key

`verifySignature()` checks the signature without fetching stellar.toml. Returns `bool` (never throws).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
final uri = 'web+stellar:tx?xdr=...&signature=...';
final signingKey = 'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV';

if (uriScheme.verifySignature(uri, signingKey)) {
  print('Signature is valid');
} else {
  print('Invalid or malformed');
}
```

Returns `false` if: `signerPublicKey` is invalid, URI is invalid, URI has no `signature` parameter, or signature mismatch.

---

## 6. Sign and Submit a Transaction

`signAndSubmitTransaction()` extracts the transaction from a `web+stellar:tx?` URI, signs it, and submits it either to a callback URL or directly to the Stellar network.

- If `callback` parameter starts with `url:` — POSTs signed XDR to that URL with `Content-Type: application/x-www-form-urlencoded`, body `xdr=<url-encoded-xdr>`.
- Otherwise — submits directly to the Stellar network (PUBLIC or TESTNET based on `network` param).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
final uri = 'web+stellar:tx?xdr=AAAAAgAAAAD...';
final signerKeyPair = KeyPair.fromSecretSeed('S...');

// Validate the URI before signing (wallets should always do this)
final validationResult = await uriScheme.isValidSep7SignedUrl(uri);
if (!validationResult.result) {
  print('Invalid URI: ${validationResult.reason}');
  return;
}

// Display transaction details to user and get approval...

try {
  final response = await uriScheme.signAndSubmitTransaction(
    uri,
    signerKeyPair,
    network: Network.TESTNET,  // defaults to Network.PUBLIC when omitted
  );

  if (response.submitTransactionResponse != null) {
    // Submitted directly to Stellar network
    final txResponse = response.submitTransactionResponse!;
    if (txResponse.success) {
      print('Transaction successful! Hash: ${txResponse.hash}');
    } else {
      print('Transaction failed');
    }
  } else if (response.response != null) {
    // Submitted to callback URL
    final httpResponse = response.response!;
    print('Callback status: ${httpResponse.statusCode}');
    print('Callback body: ${httpResponse.body}');
  }
} on ArgumentError catch (e) {
  // URI is invalid, missing xdr param, XDR cannot be parsed, or unsupported tx type
  print('Bad URI: $e');
} catch (e) {
  // HTTP error (callback) or Horizon error (network submission)
  print('Submission error: $e');
}
```

`signAndSubmitTransaction()` throws `ArgumentError` if:
- URI is not a valid SEP-07 URI
- Operation type is not `tx`
- `xdr` parameter is absent
- XDR cannot be parsed as a valid transaction

It also supports `FeeBumpTransaction` in addition to regular `Transaction`.

---

## 7. Parse URI Parameters

`tryParseSep7Url()` returns `ParsedSep7UrlResult?` — `null` if the URI is invalid. The result contains `operationType` (String — `"tx"` or `"pay"`) and `queryParameters` (Map<String, String> — URL-decoded values).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
final uri = 'web+stellar:pay?destination=GABC...&amount=100&asset_code=USD&msg=Invoice';

final parsed = uriScheme.tryParseSep7Url(uri);
if (parsed != null) {
  print('Operation: ${parsed.operationType}');  // "pay"

  // Access parameters using string keys
  final destination = parsed.queryParameters['destination'];
  final amount = parsed.queryParameters['amount'];
  final assetCode = parsed.queryParameters['asset_code'];
  final message = parsed.queryParameters['msg'];

  // Or using constants to avoid typos
  final msg = parsed.queryParameters[URIScheme.messageParameterName];
  final originDomain = parsed.queryParameters[URIScheme.originDomainParameterName];
  final signature = parsed.queryParameters[URIScheme.signatureParameterName];
}

// For tx URIs
final txUri = 'web+stellar:tx?xdr=AAAA...&callback=url:https://example.com&pubkey=GABC...';
final txParsed = uriScheme.tryParseSep7Url(txUri);
if (txParsed != null) {
  print(txParsed.operationType);                             // "tx"
  final xdr = txParsed.queryParameters[URIScheme.xdrParameterName];
  final callback = txParsed.queryParameters[URIScheme.callbackParameterName];
  final pubkey = txParsed.queryParameters[URIScheme.publicKeyParameterName];
}
```

Check `operationType` before accessing operation-specific keys:

```dart
if (parsed.operationType == URIScheme.operationTypeTx) {
  // has xdr, optionally: replace, callback, pubkey, chain
} else if (parsed.operationType == URIScheme.operationTypePay) {
  // has destination, optionally: amount, asset_code, asset_issuer, memo, memo_type, callback
}
```

---

## 8. Replace Parameters (SEP-11 Txrep)

The `replace` parameter lets the URI request the wallet fill in specific fields in the transaction XDR, using Txrep (SEP-11) path notation.

### Compose a replace string

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

final replacements = [
  UriSchemeReplacement('X', 'sourceAccount', 'account from where you pay fees'),
  UriSchemeReplacement('Y', 'operations[0].destination', 'account receiving tokens'),
  UriSchemeReplacement('Y', 'operations[1].destination', 'account receiving tokens'),
];

final replaceString = uriScheme.uriSchemeReplacementsToString(replacements);
// "sourceAccount:X,operations[0].destination:Y,operations[1].destination:Y;X:account from where you pay fees,Y:account receiving tokens"
// Note: duplicate hints are deduplicated automatically

// Use in a URI (generateSignTransactionURI URL-encodes it automatically)
final uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  replace: replaceString,
);
```

### Parse a replace string

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// After parsing a URI:
final parsed = uriScheme.tryParseSep7Url(uri);
if (parsed != null) {
  final replaceParam = parsed.queryParameters[URIScheme.replaceParameterName];
  if (replaceParam != null) {
    final replacements = uriScheme.uriSchemeReplacementsFromString(replaceParam);
    for (final r in replacements) {
      print('Field: ${r.path}');   // e.g. "sourceAccount"
      print('ID: ${r.id}');        // e.g. "X"
      print('Hint: ${r.hint}');    // e.g. "account from where you pay fees"
      // Prompt user to provide value for this field
    }
  }
}
```

`UriSchemeReplacement` constructor: `UriSchemeReplacement(String id, String path, String hint)`.

Field path format (Txrep SEP-11 notation):
- `sourceAccount` — top-level field
- `operations[0].destination` — indexed operation field
- No `tx.` prefix; no metadata fields (`_present`, `len`)

---

## 9. SubmitUriSchemeTransactionResponse

Returned by `signAndSubmitTransaction()`. Exactly one of the two fields is non-null, depending on whether a callback URL was present in the URI.

```dart
// Direct network submission (no callback in URI):
final txResponse = response.submitTransactionResponse; // SubmitTransactionResponse?
if (txResponse != null) {
  txResponse.success;           // bool
  txResponse.hash;              // String? — transaction hash
  txResponse.ledger;            // int?
  txResponse.envelopeXdr;       // String? — signed envelope XDR
  txResponse.resultXdr;         // String? — result XDR
  txResponse.extras?.resultCodes?.transactionResultCode; // String? e.g. "tx_failed"
  txResponse.extras?.resultCodes?.operationsResultCodes; // List<String>?
}

// Callback URL submission:
final httpResponse = response.response; // http.Response?
if (httpResponse != null) {
  httpResponse.statusCode;   // int — HTTP status code
  httpResponse.body;         // String — response body (use body, not getBody())
  httpResponse.headers;      // Map<String, String>
}
```

---

## 10. Testing with Mock HTTP

Inject a mock `http.Client` to test stellar.toml fetching and callback submissions without real network requests. Assign directly to `uriScheme.httpClient`.

### Mock successful signature validation

```dart
import 'dart:convert';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final signerKeyPair = KeyPair.random();
final signerAccountId = signerKeyPair.accountId;

final uriScheme = URIScheme();

// Build and sign a URI
final uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  originDomain: 'place.domain.com',
);
final signedUri = uriScheme.addSignature(uri, signerKeyPair);

// Mock stellar.toml returning our signing key
final tomlContent =
    'URI_REQUEST_SIGNING_KEY="$signerAccountId"';

uriScheme.httpClient = MockClient((request) async {
  if (request.url.toString().startsWith(
          'https://place.domain.com/.well-known/stellar.toml') &&
      request.method == 'GET') {
    return http.Response(tomlContent, 200);
  }
  return http.Response(json.encode({'error': 'Bad request'}), 400);
});

final result = await uriScheme.isValidSep7SignedUrl(signedUri);
assert(result.result); // true
```

### Mock callback submission

```dart
import 'dart:convert';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

uriScheme.httpClient = MockClient((request) async {
  if (request.url.toString().startsWith('https://examplepost.com') &&
      request.method == 'POST' &&
      request.body.startsWith(URIScheme.xdrParameterName)) {
    return http.Response('', 200);
  }
  return http.Response(json.encode({'error': 'Bad request'}), 400);
});

final signerKeyPair = KeyPair.fromSecretSeed('S...');
final uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  callback: 'url:https://examplepost.com',
);

final response = await uriScheme.signAndSubmitTransaction(
  uri, signerKeyPair, network: Network.TESTNET,
);
assert(response.submitTransactionResponse == null);
assert(response.response != null);
assert(response.response!.statusCode == 200);

// Reset to real client when done
uriScheme.httpClient = http.Client();
```

### Mock toml failure scenarios

```dart
// TOML not found (404) — isValidSep7SignedUrl returns result=false,
// reason="Toml not found or invalid for 'domain'"
uriScheme.httpClient = MockClient((_) async => http.Response('Not Found', 404));

// TOML has no URI_REQUEST_SIGNING_KEY — reason="No signing key found in toml from 'domain'"
final tomlWithoutKey = '[DOCUMENTATION]\nORG_NAME="Example"\n';
uriScheme.httpClient = MockClient((_) async => http.Response(tomlWithoutKey, 200));

// TOML with wrong key — reason="Signature is not from the signing key..."
final wrongKey = 'URI_REQUEST_SIGNING_KEY="GCCHBLJOZUFBVAUZP55N7ZU6ZB5VGEDHSXT23QC6UIVDQNGI6QDQTOOR"';
uriScheme.httpClient = MockClient((_) async => http.Response(wrongKey, 200));
```

---

## 11. Parameter Constants

All constants are static on `URIScheme`:

| Constant | String value | Used in |
|----------|-------------|---------|
| `URIScheme.uriSchemeName` | `web+stellar:` | URI prefix |
| `URIScheme.operationTypeTx` | `tx` | tx URI operation string |
| `URIScheme.operationTypePay` | `pay` | pay URI operation string |
| `URIScheme.xdrParameterName` | `xdr` | tx URI — transaction XDR |
| `URIScheme.replaceParameterName` | `replace` | tx URI — Txrep field spec |
| `URIScheme.callbackParameterName` | `callback` | both — callback URL |
| `URIScheme.publicKeyParameterName` | `pubkey` | tx URI — required signer |
| `URIScheme.chainParameterName` | `chain` | tx URI — nested URI |
| `URIScheme.messageParameterName` | `msg` | both — user-facing message |
| `URIScheme.networkPassphraseParameterName` | `network_passphrase` | both |
| `URIScheme.originDomainParameterName` | `origin_domain` | both — for signing |
| `URIScheme.signatureParameterName` | `signature` | both — URI signature |
| `URIScheme.destinationParameterName` | `destination` | pay URI |
| `URIScheme.amountParameterName` | `amount` | pay URI |
| `URIScheme.assetCodeParameterName` | `asset_code` | pay URI |
| `URIScheme.assetIssuerParameterName` | `asset_issuer` | pay URI |
| `URIScheme.memoParameterName` | `memo` | pay URI |
| `URIScheme.memoTypeParameterName` | `memo_type` | pay URI |
| `URIScheme.uriSchemePrefix` | `stellar.sep.7 - URI Scheme` | signing payload prefix |
| `URIScheme.memoTextType` | `MEMO_TEXT` | memo type values |
| `URIScheme.memoIdType` | `MEMO_ID` | memo type values |
| `URIScheme.memoHashType` | `MEMO_HASH` | memo type values |
| `URIScheme.memoReturnType` | `MEMO_RETURN` | memo type values |

---

## 12. Common Pitfalls

**Use `addSignature()`, not the deprecated `signURI()`:**

```dart
// WRONG: signURI() is @Deprecated — use addSignature() instead
final signedUri = uriScheme.signURI(uri, signerKeyPair); // deprecated

// CORRECT: addSignature() is the current API
final signedUri = uriScheme.addSignature(uri, signerKeyPair);
```

**Use `isValidSep7SignedUrl()`, not the deprecated `checkUIRSchemeIsValid()`:**

```dart
// WRONG: checkUIRSchemeIsValid() is @Deprecated and throws URISchemeError (also deprecated)
try {
  await uriScheme.checkUIRSchemeIsValid(uri); // deprecated
} on URISchemeError catch (e) { ... }

// CORRECT: isValidSep7SignedUrl() returns IsValidSep7UrlResult with result and reason
final result = await uriScheme.isValidSep7SignedUrl(uri);
if (!result.result) {
  print(result.reason);
}
```

**Callback value must be prefixed with `url:`:**

```dart
// WRONG: raw URL — signAndSubmitTransaction() will NOT route to callback
final uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  callback: 'https://example.com/submit',  // missing "url:" prefix
);
// callback is ignored; falls through to direct network submission

// CORRECT: prefix with "url:"
final uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  callback: 'url:https://example.com/submit',
);
```

**Signing requires `origin_domain` to already be in the URI:**

```dart
// WRONG: generate without origin_domain, then sign
final uri = uriScheme.generateSignTransactionURI(xdrBase64);
final signed = uriScheme.addSignature(uri, keyPair);
// signed URI has no origin_domain — isValidSep7SignedUrl() returns false:
// "Missing parameter 'origin_domain'"

// CORRECT: include origin_domain at generation time
final uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  originDomain: 'example.com',
);
final signed = uriScheme.addSignature(uri, keyPair);
```

**`addSignature()` throws if signature already present:**

```dart
// WRONG: signing a URI that already has a signature parameter
final doubleSignedUri = uriScheme.addSignature(signedUri, keyPair);
// throws ArgumentError: "sep7 url already contains a 'signature' parameter"

// CORRECT: only call addSignature() on unsigned URIs
final uri = uriScheme.generateSignTransactionURI(xdrBase64, originDomain: 'example.com');
final signed = uriScheme.addSignature(uri, keyPair); // uri has no signature yet
```

**`signAndSubmitTransaction()` defaults to public network when network is null:**

```dart
// WRONG: omitting network for testnet transactions
final response = await uriScheme.signAndSubmitTransaction(uri, keyPair);
// submits to PUBLIC network — testnet transactions fail with tx_bad_seq or are lost

// CORRECT: always pass the network explicitly
final response = await uriScheme.signAndSubmitTransaction(
  uri, keyPair, network: Network.TESTNET,
);
```

**Callback HTTP response field is `body`, not `getBody()`:**

```dart
// WRONG: http.Response does not have getBody()
final body = response.response!.getBody(); // no such method

// CORRECT: http.Response.body is a String field (direct property access)
final body = response.response!.body;
final status = response.response!.statusCode;
```

**`tryParseSep7Url()` returns decoded parameter values; no need to URL-decode manually:**

```dart
// WRONG: parsing query params manually
final encodedCallback = uri.split('callback=')[1].split('&')[0]; // fragile
final callback = Uri.decodeComponent(encodedCallback);

// CORRECT: tryParseSep7Url() returns URL-decoded values in queryParameters
final parsed = uriScheme.tryParseSep7Url(uri);
final callback = parsed?.queryParameters['callback'];
// already decoded — e.g. "url:https://example.com/submit"
```

**Deprecated `getParameterValue()` — use `tryParseSep7Url()` instead:**

```dart
// WRONG: getParameterValue() is @Deprecated
final xdr = uriScheme.getParameterValue(URIScheme.xdrParameterName, uri);

// CORRECT: parse first, then access queryParameters map
final parsed = uriScheme.tryParseSep7Url(uri);
final xdr = parsed?.queryParameters[URIScheme.xdrParameterName];
```
