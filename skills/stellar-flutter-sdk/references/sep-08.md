# SEP-08: Regulated Assets

**Purpose:** Handle assets that require issuer approval for every transaction before submission to the Stellar network.
**Prerequisites:** None (but the asset issuer must have `AUTH_REQUIRED` and `AUTH_REVOCABLE` flags set)

SEP-08 defines a protocol for regulated assets — assets where an issuer-run approval server must evaluate and co-sign every transaction. This enables compliance with securities regulations, KYC/AML requirements, velocity limits, and jurisdiction-based restrictions.

**Spec:** [SEP-0008](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md)

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [How Regulated Assets Work](#2-how-regulated-assets-work)
3. [Creating the Service](#3-creating-the-service)
4. [RegulatedAsset](#4-regulatedasset)
5. [Checking Authorization Flags](#5-checking-authorization-flags)
6. [postTransaction — Submitting for Approval](#6-posttransaction--submitting-for-approval)
7. [Handling All Response Types](#7-handling-all-response-types)
8. [postAction — Handling Action Required](#8-postaction--handling-action-required)
9. [Complete Workflow Example](#9-complete-workflow-example)
10. [Response Classes Reference](#10-response-classes-reference)
11. [Error Handling](#11-error-handling)
12. [Common Pitfalls](#12-common-pitfalls)

---

## 1. Quick Start

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From your app: destinationId (String), senderSeed (String)
// Load stellar.toml from issuer domain — extracts regulated asset definitions
final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');

// Access discovered regulated assets
final asset = service.regulatedAssets.first;
print('${asset.code} issued by ${asset.issuerId}');
print('Approval server: ${asset.approvalServer}');

// Build and sign a transaction
final senderKeyPair = KeyPair.fromSecretSeed(senderSeed);
final senderAccount = await service.sdk.accounts.account(senderKeyPair.accountId);

final tx = TransactionBuilder(senderAccount)
    .addOperation(
      PaymentOperationBuilder(destinationId, asset, '100').build()
    )
    .build();
tx.sign(senderKeyPair, service.network);

// Submit to approval server (NOT directly to Stellar network)
final response = await service.postTransaction(
  tx.toEnvelopeXdrBase64(),
  asset.approvalServer,
);

if (response is PostTransactionSuccess) {
  // Approved — submit the returned signed tx to Stellar network
  // Use submitTransactionEnvelopeXdrBase64 to submit the XDR string directly
  await service.sdk.submitTransactionEnvelopeXdrBase64(response.tx);
} else if (response is PostTransactionRejected) {
  print('Rejected: ${response.error}');
}
```

---

## 2. How Regulated Assets Work

Per SEP-08:

1. **Issuer flags**: The asset issuer account must have both `AUTH_REQUIRED` and `AUTH_REVOCABLE` flags set. This allows the issuer to grant and revoke authorization atomically.
2. **stellar.toml discovery**: The issuer's `stellar.toml` (SEP-01) lists assets with `regulated=true` and an `approval_server` URL. The toml **must** include `NETWORK_PASSPHRASE` for the service to initialize.
3. **Transaction composition**: Build and sign the transaction normally using the regulated asset. Do not add authorization operations yourself — the approval server handles that.
4. **Approval**: POST the signed transaction XDR envelope to the approval server (not to Stellar). The server evaluates compliance rules and returns one of five statuses.
5. **Network submission**: Submit a `success` transaction as returned. Show a `revised` transaction to the user and submit it only after the user approves and signs it (`signRevision` in section 9).

---

## 3. Creating the Service

### From domain (recommended)

Fetches `stellar.toml` from the domain's `/.well-known/stellar.toml`, parses it, and extracts all regulated asset definitions. Pass the bare domain — no protocol prefix.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
  print('Network: ${service.network.networkPassphrase}');
  print('Assets: ${service.regulatedAssets.length}');
} catch (e) {
  print('Failed to initialize: $e');
}
```

`fromDomain()` signature:
```dart
import 'package:http/http.dart' as http;

static Future<RegulatedAssetsService> fromDomain(
  String domain, {
  http.Client? httpClient,           // custom HTTP client (timeouts, proxies)
  Map<String, String>? httpRequestHeaders,  // custom request headers
  String? horizonUrl,                // override Horizon URL (default: toml HORIZON_URL)
  Network? network,                  // override network (default: toml NETWORK_PASSPHRASE)
})
```

### From StellarToml data

If you have already loaded a `StellarToml` instance, pass it directly to the constructor:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml toml = await StellarToml.fromDomain('regulated-asset-issuer.com');
final service = RegulatedAssetsService(toml);
```

Constructor signature:
```dart
import 'package:http/http.dart' as http;

RegulatedAssetsService(
  StellarToml tomlData, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
  String? horizonUrl,
  Network? network,
})
```

**Requirements for initialization:** The `stellar.toml` data must contain `NETWORK_PASSPHRASE` (or you must pass `network`). Without a resolvable network, the constructor throws `IncompleteInitData`. The Horizon URL is resolved from (in priority order): the `horizonUrl` parameter, the toml `HORIZON_URL` field, or SDK defaults for public/testnet/futurenet networks.

### With custom HTTP client

Inject a custom `http.Client` for timeouts, proxies, or SSL configuration. The same client handles both the stellar.toml fetch and all subsequent approval server requests:

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final client = http.Client();

final service = await RegulatedAssetsService.fromDomain(
  'regulated-asset-issuer.com',
  httpClient: client,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

---

## 4. RegulatedAsset

`RegulatedAsset` extends `AssetTypeCreditAlphaNum`, making it usable wherever a standard Stellar asset is expected (payments, offers, trustlines). It adds approval server information specific to SEP-08.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');

for (RegulatedAsset asset in service.regulatedAssets) {
  // Inherited from AssetTypeCreditAlphaNum
  asset.code;        // String  e.g. "GOAT"
  asset.issuerId;    // String  G... issuer account ID
  asset.type;        // String  "credit_alphanum4" or "credit_alphanum12"
  asset.toXdr();     // XdrAsset

  // SEP-08 specific fields (direct property access)
  asset.approvalServer;    // String   full URL of approval server endpoint
  asset.approvalCriteria;  // String?  human-readable compliance description (may be null)
}
```

Assets are extracted from `stellar.toml` currencies where `regulated == true`, `code != null`, `issuer != null`, and `approvalServer != null`. Entries missing any of these are silently skipped and will not appear in `service.regulatedAssets`.

---

## 5. Checking Authorization Flags

Before transacting, verify the issuer account has the required flags. Per SEP-08, regulated asset issuers must have both `AUTH_REQUIRED` and `AUTH_REVOCABLE` set:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
final asset = service.regulatedAssets.first;

try {
  final required = await service.authorizationRequired(asset);
  if (!required) {
    print('Warning: issuer not properly configured for regulated assets');
  }
} on IssuerAccountNotFound catch (e) {
  print('Issuer account not found: $e');
}
```

`authorizationRequired()` loads the issuer account from Horizon and checks both `authRequired` and `authRevocable` flags. Returns `true` only when both are set. Throws `IssuerAccountNotFound` if the issuer account does not exist on the network.

---

## 6. postTransaction — Submitting for Approval

Build and sign a transaction normally, then submit the base64-encoded XDR envelope to the approval server. Do not submit directly to Stellar — the approval server must co-sign first.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From your app: destinationId (String), senderSeed (String)
final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
final regulatedAsset = service.regulatedAssets.first;

final senderKeyPair = KeyPair.fromSecretSeed(senderSeed);
final senderAccount = await service.sdk.accounts.account(senderKeyPair.accountId);

final tx = TransactionBuilder(senderAccount)
    .addOperation(
      PaymentOperationBuilder(destinationId, regulatedAsset, '100').build()
    )
    .build();
tx.sign(senderKeyPair, service.network);

// Submit to approval server
final response = await service.postTransaction(
  tx.toEnvelopeXdrBase64(),
  regulatedAsset.approvalServer,
);
```

`postTransaction()` signature:
```dart
Future<PostTransactionResponse> postTransaction(
  String tx,              // base64-encoded XDR transaction envelope
  String approvalServer,  // full URL from asset.approvalServer
)
```

Sends a POST with `Content-Type: application/json` and body `{"tx": "<base64>"}`. Returns a `PostTransactionResponse` subclass. Throws `UnknownPostTransactionResponse` for HTTP codes other than 200 or 400 with an `error` field.

---

## 7. Handling All Response Types

The approval server returns one of five response types. Use `is` checks to branch:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From your app: approvalServer (String), userApproves (function, shows the revision with the server's message and returns the user's decision)
// From the section Complete Workflow Example: senderKeyPair (KeyPair), service (RegulatedAssetsService), signRevision (function), txXdr (String)
final response = await service.postTransaction(txXdr, approvalServer);

if (response is PostTransactionSuccess) {
  // Approved without modification — submit returned tx to Stellar network
  if (response.message != null) {
    print('Approval message: ${response.message}');  // String?
  }
  // Use submitTransactionEnvelopeXdrBase64 to submit the XDR string directly
  await service.sdk.submitTransactionEnvelopeXdrBase64(response.tx);

} else if (response is PostTransactionRevised) {
  // Transaction was modified for compliance: the user reviews and signs the revision
  // message is REQUIRED (String, never null) for revised
  print('Revised: ${response.message}');
  // signRevision checks the revision and signs it only on the user's approval (Complete Workflow Example)
  String? signedRevision = await signRevision(txXdr, response.tx, response.message,
      senderKeyPair, service.network, userApproves);
  if (signedRevision != null) {
    await service.sdk.submitTransactionEnvelopeXdrBase64(signedRevision);
  }

} else if (response is PostTransactionPending) {
  // Approval delayed — retry after timeout milliseconds
  // timeout is int, defaults to 0 if the server did not provide a value
  final timeoutMs = response.timeout;  // int — milliseconds (0 means unknown)
  if (timeoutMs > 0) {
    print('Retry in ${timeoutMs / 1000} seconds');
    await Future.delayed(Duration(milliseconds: timeoutMs));
  }
  if (response.message != null) {
    print('Message: ${response.message}');  // String?
  }
  // Resubmit the SAME txXdr unchanged after waiting

} else if (response is PostTransactionActionRequired) {
  // User must complete an action before approval — see postAction section
  print('Action required: ${response.message}');         // String (required)
  print('Action URL: ${response.actionUrl}');            // String (required)
  print('Method: ${response.actionMethod}');             // String — "GET" or "POST", defaults to "GET"
  if (response.actionFields != null) {
    // List<String> of SEP-9 field names the server is requesting
    print('Fields: ${response.actionFields!.join(", ")}');
  }

} else if (response is PostTransactionRejected) {
  // Cannot be made compliant — do not retry without addressing the issue
  print('Rejected: ${response.error}');  // String (required)
}
```

### Response summary table

| Class | HTTP | Status value | Key fields |
|---|---|---|---|
| `PostTransactionSuccess` | 200 | `"success"` | `String tx`, `String? message` |
| `PostTransactionRevised` | 200 | `"revised"` | `String tx`, `String message` |
| `PostTransactionPending` | 200 | `"pending"` | `int timeout` (ms, default 0), `String? message` |
| `PostTransactionActionRequired` | 200 | `"action_required"` | `String message`, `String actionUrl`, `String actionMethod` (default `"GET"`), `List<String>? actionFields` |
| `PostTransactionRejected` | 400 | `"rejected"` | `String error` |

---

## 8. postAction — Handling Action Required

When the server returns `action_required` with `actionMethod == "POST"`, you can programmatically submit the requested SEP-9 fields:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From your app: approvalServer (String)
// From the section Complete Workflow Example: service (RegulatedAssetsService), txXdr (String)
final response = await service.postTransaction(txXdr, approvalServer);

if (response is PostTransactionActionRequired) {
  print('Action required: ${response.message}');

  if (response.actionMethod == 'POST') {
    // Wallet has the required fields — submit them programmatically
    final actionResponse = await service.postAction(
      response.actionUrl,
      {
        'email_address': 'user@example.com',
        'mobile_number': '+1234567890',
      },
    );

    if (actionResponse is PostActionDone) {
      // Action complete — resubmit the ORIGINAL transaction unchanged
      final retryResponse = await service.postTransaction(txXdr, approvalServer);
      // Handle retryResponse (likely success or revised now)

    } else if (actionResponse is PostActionNextUrl) {
      // More steps needed — user must complete action in browser
      print('Open in browser: ${actionResponse.nextUrl}');  // String
      if (actionResponse.message != null) {
        print('Message: ${actionResponse.message}');  // String?
      }
      // After user completes, resubmit original txXdr
    }

  } else {
    // actionMethod is "GET" (or server did not specify — defaults to "GET")
    // Direct user to open the URL in a browser
    print('Open URL in browser: ${response.actionUrl}');
    // After user completes the action, resubmit txXdr unchanged
  }
}
```

`postAction()` signature:
```dart
Future<PostActionResponse> postAction(
  String url,                          // action_url from PostTransactionActionRequired
  Map<String, dynamic> actionFields,   // SEP-9 field names and values
)
```

Sends a POST with `Content-Type: application/json` and body containing the action fields as JSON. Returns either `PostActionDone` or `PostActionNextUrl`. Throws `UnknownPostActionResponse` for non-200 HTTP responses.

### postAction response types

| Class | Result value | Key fields |
|---|---|---|
| `PostActionDone` | `"no_further_action_required"` | (none — empty class; resubmit original tx) |
| `PostActionNextUrl` | `"follow_next_url"` | `String nextUrl`, `String? message` |

---

## 9. Complete Workflow Example

Full flow including all response types, error handling, and network submission:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<void> sendRegulatedAssetPayment({
  required String domain,
  required String senderSeed,
  required String destinationId,
  required String amount,
  // Shows the revised transaction and the server's message; returns the user's decision
  required Future<bool> Function(Transaction revised, String message) userApproves,
}) async {
  // Step 1: Initialize service from issuer's stellar.toml
  RegulatedAssetsService service;
  try {
    service = await RegulatedAssetsService.fromDomain(domain);
  } catch (e) {
    throw Exception('Failed to load stellar.toml from $domain: $e');
  }

  if (service.regulatedAssets.isEmpty) {
    throw Exception('No regulated assets found in stellar.toml');
  }

  final regulatedAsset = service.regulatedAssets.first;
  print('Using asset: ${regulatedAsset.code} / ${regulatedAsset.issuerId}');
  if (regulatedAsset.approvalCriteria != null) {
    print('Criteria: ${regulatedAsset.approvalCriteria}');
  }

  // Step 2: Verify issuer is properly configured
  try {
    final authRequired = await service.authorizationRequired(regulatedAsset);
    if (!authRequired) {
      print('Warning: issuer account does not have AUTH_REQUIRED + AUTH_REVOCABLE set');
    }
  } on IssuerAccountNotFound catch (e) {
    print('Warning: could not verify issuer flags: $e');
  }

  // Step 3: Build and sign the transaction
  final senderKeyPair = KeyPair.fromSecretSeed(senderSeed);
  final senderAccount = await service.sdk.accounts.account(senderKeyPair.accountId);

  final tx = TransactionBuilder(senderAccount)
      .addOperation(
        PaymentOperationBuilder(destinationId, regulatedAsset, amount).build()
      )
      .build();
  tx.sign(senderKeyPair, service.network);
  final txXdr = tx.toEnvelopeXdrBase64();

  // Step 4: Submit for approval and handle all response types
  String? approvedTxXdr;

  try {
    final response = await service.postTransaction(txXdr, regulatedAsset.approvalServer);

    if (response is PostTransactionSuccess) {
      print('Approved');
      if (response.message != null) print('Message: ${response.message}');
      approvedTxXdr = response.tx;

    } else if (response is PostTransactionRevised) {
      // Transaction was modified: the user reviews and signs the revision
      print('Revised: ${response.message}');
      approvedTxXdr = await signRevision(txXdr, response.tx, response.message,
          senderKeyPair, service.network, userApproves);

    } else if (response is PostTransactionPending) {
      final waitMs = response.timeout;  // int, 0 = unknown
      print('Pending. ${waitMs > 0 ? "Retry in ${waitMs}ms" : "Retry after a moment"}');
      if (response.message != null) print('Message: ${response.message}');
      // Resubmit txXdr unchanged after waiting
      return;

    } else if (response is PostTransactionActionRequired) {
      print('Action required: ${response.message}');

      if (response.actionMethod == 'POST') {
        final actionResponse = await service.postAction(
          response.actionUrl,
          {'email_address': 'user@example.com'},
        );

        if (actionResponse is PostActionDone) {
          // Resubmit original transaction — not the action response
          final retry = await service.postTransaction(txXdr, regulatedAsset.approvalServer);
          if (retry is PostTransactionSuccess) {
            approvedTxXdr = retry.tx;
          } else if (retry is PostTransactionRevised) {
            approvedTxXdr = await signRevision(txXdr, retry.tx, retry.message,
                senderKeyPair, service.network, userApproves);
          } else {
            print('Unexpected response after action: $retry');
            return;
          }
        } else if (actionResponse is PostActionNextUrl) {
          print('Complete action in browser: ${actionResponse.nextUrl}');
          if (actionResponse.message != null) print(actionResponse.message);
          return;
        }

      } else {
        // GET — direct user to the browser
        print('Open in browser: ${response.actionUrl}');
        return;
      }

    } else if (response is PostTransactionRejected) {
      throw Exception('Transaction rejected: ${response.error}');
    }

  } on UnknownPostTransactionResponse catch (e) {
    throw Exception('Approval server error (HTTP ${e.code}): ${e.body}');
  } on UnknownPostActionResponse catch (e) {
    throw Exception('Action endpoint error (HTTP ${e.code}): ${e.body}');
  }

  // Step 5: Submit the approved transaction; a revision the user rejected stays null
  if (approvedTxXdr != null) {
    // submitTransactionEnvelopeXdrBase64 accepts the base64 XDR string directly
    final result = await service.sdk.submitTransactionEnvelopeXdrBase64(approvedTxXdr);
    if (result.success) {
      print('Submitted: ${result.hash}');
    } else {
      print('Submission failed: ${result.extras?.resultCodes}');
    }
  }
}

// SEP-8: the wallet checks a revised transaction, shows it to the user, and
// signs it only when the user approves. A rejection signs nothing and returns null.
Future<String?> signRevision(String originalXdr, String revisedXdr, String message,
    KeyPair userKeyPair, Network network,
    Future<bool> Function(Transaction revised, String message) userApproves) async {
  Transaction original = AbstractTransaction.fromEnvelopeXdrString(originalXdr) as Transaction;
  Transaction revised = AbstractTransaction.fromEnvelopeXdrString(revisedXdr) as Transaction;
  // An operation without its own source uses the transaction source
  MuxedAccount sourceOf(Operation op, Transaction tx) => op.sourceAccount ?? tx.sourceAccount;
  // The original operations stay unchanged, with the same source (mux ID included),
  // and in their order; operations the server adds must not use the user account
  List<Operation> originalOps = original.operations;
  int kept = 0;
  for (Operation op in revised.operations) {
    if (kept < originalOps.length &&
        op.toXdrBase64() == originalOps[kept].toXdrBase64() &&
        sourceOf(op, revised).accountId == sourceOf(originalOps[kept], original).accountId) {
      kept++;
      continue;
    }
    String source = sourceOf(op, revised).ed25519AccountId;
    if (source == userKeyPair.accountId) {
      throw Exception('The revision adds or changes an operation on the user account');
    }
  }
  if (kept < originalOps.length) {
    throw Exception('The revision removes or changes an original operation');
  }
  if (!await userApproves(revised, message)) return null;
  revised.sign(userKeyPair, network);
  return revised.toEnvelopeXdrBase64();
}
```

---

## 10. Response Classes Reference

### PostTransactionSuccess

```dart
class PostTransactionSuccess extends PostTransactionResponse {
  String  tx;       // Base64 XDR envelope — contains original + issuer signatures
  String? message;  // Optional human-readable info for the user
}
```

### PostTransactionRevised

```dart
class PostTransactionRevised extends PostTransactionResponse {
  String tx;       // Base64 XDR of revised, issuer-signed transaction
  String message;  // Required explanation of what was changed (never null)
}
```

### PostTransactionPending

```dart
class PostTransactionPending extends PostTransactionResponse {
  int     timeout = 0;  // Milliseconds to wait before retrying; 0 = unknown
  String? message;      // Optional human-readable info
}
```

### PostTransactionActionRequired

```dart
class PostTransactionActionRequired extends PostTransactionResponse {
  String        message;                 // Required description of the action needed
  String        actionUrl;              // URL for completing the action
  String        actionMethod = 'GET';   // "GET" or "POST" — defaults to "GET"
  List<String>? actionFields;           // SEP-9 field names the server requests, or null
}
```

### PostTransactionRejected

```dart
class PostTransactionRejected extends PostTransactionResponse {
  String error;  // Human-readable rejection reason (never null)
}
```

### PostActionDone

```dart
class PostActionDone extends PostActionResponse {
  // No properties — empty class signals "no further action required"
  // After receiving this, resubmit the original transaction via postTransaction()
}
```

### PostActionNextUrl

```dart
class PostActionNextUrl extends PostActionResponse {
  String  nextUrl;  // URL where user completes remaining steps in browser
  String? message;  // Optional human-readable info
}
```

---

## 11. Error Handling

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From your app: approvalServer (String)
// From the section Complete Workflow Example: txXdr (String)
try {
  final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
  final response = await service.postTransaction(txXdr, approvalServer);
  // handle response types...

} on IncompleteInitData catch (e) {
  // stellar.toml missing NETWORK_PASSPHRASE (or custom network with no HORIZON_URL)
  print('stellar.toml incomplete: $e');

} on IssuerAccountNotFound catch (e) {
  // authorizationRequired() could not load issuer account from Horizon
  print('Issuer account not found: $e');

} on UnknownPostTransactionResponse catch (e) {
  // Approval server returned HTTP code other than 200, or 400 without error field
  print('Approval server error (HTTP ${e.code}): ${e.body}');

} on UnknownPostTransactionResponseStatus catch (e) {
  // Server returned a status value not in: success, revised, pending, action_required, rejected
  print('Unknown approval server status: $e');

} on UnknownPostActionResponse catch (e) {
  // Action endpoint returned non-200 HTTP response
  print('Action endpoint error (HTTP ${e.code}): ${e.body}');

} on UnknownPostActionResponseResult catch (e) {
  // Action endpoint returned unknown result (not "no_further_action_required" or "follow_next_url")
  print('Unknown action result: $e');

} catch (e) {
  // stellar.toml fetch failed, network error, or other unexpected error
  print('Error: $e');
}
```

### Exception reference

| Exception | Thrown by | Trigger |
|---|---|---|
| `IncompleteInitData` | Constructor, `fromDomain()` | `stellar.toml` missing `NETWORK_PASSPHRASE`, or custom network with no resolvable Horizon URL |
| `IssuerAccountNotFound` | `authorizationRequired()` | Issuer account does not exist on the network |
| `UnknownPostTransactionResponse` | `postTransaction()` | HTTP code other than 200, or 400 without an `error` JSON field |
| `UnknownPostTransactionResponseStatus` | `postTransaction()` | Server returned an unknown `status` value |
| `UnknownPostActionResponse` | `postAction()` | Action endpoint returned non-200 HTTP response |
| `UnknownPostActionResponseResult` | `postAction()` | Action endpoint returned unknown `result` value |

---

## 12. Common Pitfalls

**Wrong: calling `toXdrBase64()` instead of `toEnvelopeXdrBase64()`**

```dart
// From the section Complete Workflow Example: tx (Transaction)
// WRONG: toXdrBase64() serializes the transaction body without the envelope wrapper
// The approval server will not be able to parse or sign it
String txXdr = tx.toXdrBase64();  // incorrect

// CORRECT: use toEnvelopeXdrBase64() to include the full signed envelope
String txXdr = tx.toEnvelopeXdrBase64();
```

**Wrong: submitting to Stellar network before getting approval**

```dart
// From the section Quick Start: asset (RegulatedAsset), service (RegulatedAssetsService), tx (Transaction)
// WRONG: submitting directly bypasses the approval server entirely
await service.sdk.submitTransaction(tx);

// CORRECT: submit to approval server first, then submit the RETURNED transaction
final response = await service.postTransaction(tx.toEnvelopeXdrBase64(), asset.approvalServer);
if (response is PostTransactionSuccess) {
  // WRONG: service.sdk.submitTransaction(response.tx) -- submitTransaction() takes Transaction, not String
  // CORRECT: use submitTransactionEnvelopeXdrBase64() which takes the base64 XDR string
  await service.sdk.submitTransactionEnvelopeXdrBase64(response.tx);
}
```

**Wrong: `PostTransactionPending.timeout` is milliseconds, not seconds**

```dart
// From your app: response (PostTransactionResponse)
final pending = response as PostTransactionPending;

// WRONG: treating timeout as seconds
await Future.delayed(Duration(seconds: pending.timeout)); // waits 5000 seconds if timeout=5000!

// CORRECT: timeout is milliseconds
await Future.delayed(Duration(milliseconds: pending.timeout));
```

**Wrong: `PostTransactionPending.timeout` is `int`, not `int?`**

```dart
// From your app: response (PostTransactionPending)
// WRONG: null-checking timeout — it always defaults to 0 (int), never null
if (response.timeout == null) { /* ... */ }  // never true

// CORRECT: check for 0 to detect "unknown" wait time
if (response.timeout == 0) {
  // Server did not specify — use your own retry strategy
} else {
  await Future.delayed(Duration(milliseconds: response.timeout));
}
```

**Wrong: `PostTransactionRevised.message` is a required `String`, not `String?`**

```dart
// From your app: response (PostTransactionResponse)
// WRONG: null-checking message on revised (it is always set)
if (response is PostTransactionRevised) {
  if (response.message != null) { /* ... */ }  // redundant: always non-null
}

// NOTE: For success, message IS nullable (String?)
// For revised, message is always a String
if (response is PostTransactionSuccess) {
  if (response.message != null) { /* ... */ }  // correct: nullable here
}
```

**Wrong: `PostTransactionActionRequired.actionMethod` defaults to `"GET"`, not `null`**

```dart
// From your app: fields (Map<String,dynamic>), response (PostTransactionActionRequired)
// From the section Quick Start: service (RegulatedAssetsService)
// WRONG: checking for null — actionMethod always has a value
if (response.actionMethod == null) { /* ... */ }  // never executes

// CORRECT: check for "POST" to use programmatic posting; otherwise use browser ("GET")
if (response.actionMethod == 'POST') {
  final actionResponse = await service.postAction(response.actionUrl, fields);
} else {
  // actionMethod is "GET" (or server omitted it, which also defaults to "GET")
  print('Open in browser: ${response.actionUrl}');
}
```

**Wrong: forgetting to resubmit the ORIGINAL transaction after `PostActionDone`**

```dart
// From your app: actionResponse (PostActionResponse), approvalServer (String)
// From the setup above: service (RegulatedAssetsService), txXdr (String)
// WRONG: PostActionDone has no tx property — there is nothing to submit from it
if (actionResponse is PostActionDone) {
  await service.sdk.submitTransaction(actionResponse.something); // no such field!
}

// CORRECT: resubmit the ORIGINAL txXdr via postTransaction() again
if (actionResponse is PostActionDone) {
  final retryResponse = await service.postTransaction(txXdr, approvalServer);
  // handle retryResponse as usual
}
```

**Wrong: using `nextUrl` property as `next_url` (snake_case)**

```dart
// From your app: actionResponse (PostActionNextUrl)
// WRONG: snake_case — that is the JSON key name, not the Dart property
print(actionResponse.next_url);  // compile error

// CORRECT: camelCase Dart property
print(actionResponse.nextUrl);
```

**Wrong: accessing `regulatedAssets` before checking it is non-empty**

```dart
// From the section Quick Start: service (RegulatedAssetsService)
// WRONG: will throw RangeError if stellar.toml has no qualifying regulated assets
final asset = service.regulatedAssets.first;

// A currency entry is skipped if any of these are missing: code, issuer, regulated=true, approval_server
// CORRECT: always check length first
if (service.regulatedAssets.isEmpty) {
  throw Exception('No regulated assets found in stellar.toml');
}
final asset = service.regulatedAssets.first;
```

**Wrong: `RegulatedAsset.issuerId` vs nonexistent `getIssuer()`**

```dart
// From the setup above: asset (RegulatedAsset)
// WRONG: there are no getter methods — access fields directly
final issuer = asset.getIssuer();   // compile error
final code   = asset.getCode();     // compile error

// CORRECT: direct property access
final issuer = asset.issuerId;  // String
final code   = asset.code;      // String
```

**Network resolution: explicit parameter vs stellar.toml**

```dart
// From the section From StellarToml data: toml (StellarToml)
// Pass network explicitly
final service = RegulatedAssetsService(toml, network: Network.TESTNET);

// fromDomain() forwards horizonUrl and network to the constructor
final serviceFromDomain = await RegulatedAssetsService.fromDomain(
  'example.com',
  horizonUrl: 'https://custom-horizon.example.com',
  network: Network.TESTNET,  // forwarded to constructor
);

// Or let the service read NETWORK_PASSPHRASE from stellar.toml
final serviceTomlNetwork = await RegulatedAssetsService.fromDomain('example.com');

// Note: if network is not passed and stellar.toml lacks NETWORK_PASSPHRASE,
// throws IncompleteInitData — ensure at least one source of network is present
```
