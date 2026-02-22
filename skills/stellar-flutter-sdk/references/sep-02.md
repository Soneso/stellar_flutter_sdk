# SEP-02: Federation Protocol

**Purpose:** Resolve human-readable Stellar addresses (`name*domain.com`) to account IDs and memo instructions; perform reverse lookups and forward routing.
**Prerequisites:** None (auto-discovers federation server via SEP-01 for address lookups)

## Table of Contents

1. [Resolve Stellar Address (name lookup)](#1-resolve-stellar-address-name-lookup)
2. [Resolve Account ID (reverse lookup)](#2-resolve-account-id-reverse-lookup)
3. [Resolve Transaction ID (txid lookup)](#3-resolve-transaction-id-txid-lookup)
4. [Resolve Forward](#4-resolve-forward)
5. [FederationResponse Fields](#5-federationresponse-fields)
6. [Using the Memo in a Payment](#6-using-the-memo-in-a-payment)
7. [Custom HTTP Client](#7-custom-http-client)
8. [Testing with MockClient](#8-testing-with-mockclient)
9. [Common Pitfalls](#9-common-pitfalls)

---

## 1. Resolve Stellar Address (name lookup)

`Federation.resolveStellarAddress()` is a static async method. It accepts a
federation address in the format `name*domain.com`, automatically fetches the
domain's `stellar.toml` to discover the federation server, then performs a
`type=name` query.

The username portion can be a simple name, an email address
(`maria@gmail.com*domain.com`), or an E.164 phone number
(`+14155550100*domain.com`).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Resolve bob*soneso.com to a Stellar account ID
FederationResponse response =
    await Federation.resolveStellarAddress('bob*soneso.com');

print(response.stellarAddress); // bob*soneso.com
print(response.accountId);      // GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI
print(response.memoType);       // text  (null if no memo required)
print(response.memo);           // hello memo text  (null if no memo required)
```

Throws `Exception` if:
- The address does not contain `*` (invalid format)
- The domain's `stellar.toml` has no `FEDERATION_SERVER` entry
- The HTTP request fails or the server returns a non-200 status

```dart
// Error handling
try {
  FederationResponse response =
      await Federation.resolveStellarAddress('bob*example.com');
  // Use response fields
} catch (e) {
  print('Federation lookup failed: $e');
}
```

---

## 2. Resolve Account ID (reverse lookup)

`Federation.resolveStellarAccountId()` performs a `type=id` query. You must
supply the federation server URL directly — the SDK does not auto-discover it
from the account's domain.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

FederationResponse response = await Federation.resolveStellarAccountId(
  'GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI',
  'https://stellarid.io/federation/',
);

print(response.stellarAddress); // bob*soneso.com
print(response.accountId);      // GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI
print(response.memoType);       // text
print(response.memo);           // hello memo text
```

**Note:** Reverse lookups are ambiguous when an anchor sends transactions on
behalf of users — the account ID will be the anchor's, not the individual
user's. In that case use `resolveStellarTransactionId` instead.

---

## 3. Resolve Transaction ID (txid lookup)

`Federation.resolveStellarTransactionId()` performs a `type=txid` query.
Returns the federation record of the sender of the transaction, if known by
the server.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

FederationResponse response = await Federation.resolveStellarTransactionId(
  'ae05181b239bd4a64ba2fb8086901479a0bde86f8e912150e74241fe4f5f0948',
  'https://api.example.com/federation',
);

print(response.stellarAddress); // sender*example.com
print(response.accountId);      // G...
```

---

## 4. Resolve Forward

`Federation.resolveForward()` performs a `type=forward` query for routing
payments to external networks or financial institutions. All institution-specific
parameters are passed as a `Map<String, String>`.

The resulting URL includes `type=forward` plus all entries from your map:
`?type=forward&forward_type=bank_account&swift=BOPBPHMM&acct=2382376`

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

FederationResponse response = await Federation.resolveForward(
  {
    'forward_type': 'bank_account',
    'swift': 'BOPBPHMM',
    'acct': '2382376',
  },
  'https://api.example.com/federation',
);

print(response.accountId); // G... (account to send payment to)
print(response.memoType);  // id
print(response.memo);      // 54321
```

The response provides the `accountId` and optional memo that must be attached
to the Stellar payment to correctly route the forwarded funds.

---

## 5. FederationResponse Fields

All four methods return a `FederationResponse`. All fields are nullable — which
fields are populated depends on the lookup type and what the server provides.

```dart
class FederationResponse {
  String? stellarAddress; // "name*domain.com" — set for name/id/txid lookups
  String? accountId;      // "G..." — set for all successful lookups
  String? memoType;       // "text" | "id" | "hash" — null if no memo required
  String? memo;           // memo value as String — null if no memo required
}
```

**JSON field mapping** (from the federation server response):

| JSON key          | Dart field        |
|-------------------|-------------------|
| `stellar_address` | `stellarAddress`  |
| `account_id`      | `accountId`       |
| `memo_type`       | `memoType`        |
| `memo`            | `memo`            |

**memo field:** Always a `String` regardless of memo type. For `id` memo, the
server returns an integer as a string (e.g., `"12345"`). Parse with
`BigInt.parse(fed.memo!)` when building the transaction memo (`Memo.id` takes `BigInt`).

---

## 6. Using the Memo in a Payment

After resolving a federation address, always check for memo instructions and
attach them to your payment transaction:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<void> payFederationAddress(
    String federationAddress, String amountXlm, KeyPair senderKeyPair) async {
  // 1. Resolve the federation address
  FederationResponse fed =
      await Federation.resolveStellarAddress(federationAddress);

  if (fed.accountId == null) {
    throw Exception('Federation server returned no account ID');
  }

  // 2. Build the memo — required if memoType is set
  Memo memo = Memo.none();
  if (fed.memoType != null && fed.memo != null) {
    switch (fed.memoType) {
      case 'text':
        memo = Memo.text(fed.memo!);
        break;
      case 'id':
        // WRONG: Memo.id(int.parse(fed.memo!)) — Memo.id takes BigInt, not int
        memo = Memo.id(BigInt.parse(fed.memo!));
        break;
      case 'hash':
        // Base64-encoded 32-byte hash
        memo = MemoHash(base64Decode(fed.memo!));
        break;
    }
  }

  // 3. Build and submit the payment
  StellarSDK sdk = StellarSDK.TESTNET;
  AccountResponse sender = await sdk.accounts.account(senderKeyPair.accountId);

  Transaction tx = TransactionBuilder(sender)
      .addOperation(
        PaymentOperationBuilder(fed.accountId!, Asset.NATIVE, amountXlm)
            .build(),
      )
      .addMemo(memo)
      .build();

  tx.sign(senderKeyPair, Network.TESTNET);
  SubmitTransactionResponse result = await sdk.submitTransaction(tx);
  print('Success: ${result.success}');
}
```

**Important:** If the federation response includes `memoType` and `memo`, you
MUST attach that memo to the payment or it may be unroutable at the destination.

---

## 7. Custom HTTP Client

All four static methods accept optional `httpClient` and `httpRequestHeaders`
named parameters. Use these for custom timeouts, proxies, or additional headers.

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final client = http.Client();

FederationResponse response = await Federation.resolveStellarAddress(
  'bob*example.com',
  httpClient: client,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

For `resolveStellarAccountId`, `resolveStellarTransactionId`, and
`resolveForward`, the same named parameters apply:

```dart
FederationResponse response = await Federation.resolveStellarAccountId(
  'G...',
  'https://api.example.com/federation',
  httpClient: client,
  httpRequestHeaders: {'Authorization': 'Bearer token'},
);
```

---

## 8. Testing with MockClient

Use `MockClient` from the `http` package to test federation lookups without
real network calls. For `resolveStellarAddress`, the mock must handle two
request paths: the `stellar.toml` fetch and the federation query.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

void main() {
  test('resolve address with memo — mock', () async {
    final mockClient = MockClient((request) async {
      final url = request.url.toString();

      // First request: stellar.toml discovery
      if (url.contains('.well-known/stellar.toml')) {
        return http.Response(
          'FEDERATION_SERVER="https://api.example.com/federation"',
          200,
        );
      }

      // Second request: federation lookup
      if (url.contains('/federation')) {
        expect(request.url.queryParameters['q'], 'alice*example.com');
        expect(request.url.queryParameters['type'], 'name');

        return http.Response(
          json.encode({
            'stellar_address': 'alice*example.com',
            'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
            'memo_type': 'id',
            'memo': '12345',
          }),
          200,
        );
      }

      return http.Response('Not found', 404);
    });

    final response = await Federation.resolveStellarAddress(
      'alice*example.com',
      httpClient: mockClient,
    );

    expect(response.stellarAddress, 'alice*example.com');
    expect(response.accountId, 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP');
    expect(response.memoType, 'id');
    expect(response.memo, '12345');
  });

  test('resolveForward — mock', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.queryParameters['type'], 'forward');
      expect(request.url.queryParameters['forward_type'], 'bank_account');
      expect(request.url.queryParameters['swift'], 'BOPBPHMM');
      expect(request.url.queryParameters['acct'], '2382376');

      return http.Response(
        json.encode({
          'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
          'memo_type': 'id',
          'memo': '54321',
        }),
        200,
      );
    });

    final response = await Federation.resolveForward(
      {
        'forward_type': 'bank_account',
        'swift': 'BOPBPHMM',
        'acct': '2382376',
      },
      'https://api.example.com/federation',
      httpClient: mockClient,
    );

    expect(response.accountId, isNotNull);
    expect(response.memoType, 'id');
    expect(response.memo, '54321');
  });
}
```

---

## 9. Common Pitfalls

**Missing `*` in the address:**

```dart
// WRONG: throws Exception("invalid federation address: bob.example.com")
await Federation.resolveStellarAddress('bob.example.com');

// CORRECT: must use * as separator between username and domain
await Federation.resolveStellarAddress('bob*example.com');
```

**Passing a domain name instead of a full URL to resolveStellarAccountId:**

```dart
// WRONG: resolveStellarAccountId does NOT auto-discover the federation server
// A bare domain will be parsed as a relative URI; the HTTP request will fail
await Federation.resolveStellarAccountId('G...', 'example.com');

// CORRECT: pass the full federation server URL (https://...)
await Federation.resolveStellarAccountId('G...', 'https://api.example.com/federation');
```

**Not attaching the memo when one is required:**

```dart
// WRONG: omitting the memo causes unroutable payments at many exchanges
FederationResponse fed = await Federation.resolveStellarAddress('alice*exchange.com');
TransactionBuilder(account)
    .addOperation(PaymentOperationBuilder(fed.accountId!, Asset.NATIVE, '10').build())
    // forgot .addMemo(...)
    .build();

// CORRECT: always check and attach memo
Memo memo = Memo.none();
if (fed.memoType != null && fed.memo != null) {
  if (fed.memoType == 'text') memo = Memo.text(fed.memo!);
  if (fed.memoType == 'id')   memo = Memo.id(BigInt.parse(fed.memo!));
}
TransactionBuilder(account)
    .addOperation(PaymentOperationBuilder(fed.accountId!, Asset.NATIVE, '10').build())
    .addMemo(memo)
    .build();
```

**Treating memo as an int — it is always String:**

```dart
// WRONG: response.memo is String? — there is no int field
int memoId = fed.memo; // compile error

// CORRECT: parse the string to BigInt when building a MemoId (Memo.id takes BigInt)
if (fed.memoType == 'id') {
  Memo memo = Memo.id(BigInt.parse(fed.memo!));
}
```

**Assuming all FederationResponse fields are non-null:**

```dart
// WRONG: forward lookups do not return stellarAddress; it will be null
print(fed.stellarAddress!.length); // throws if null

// CORRECT: all FederationResponse fields are String? — null-check before use
if (fed.stellarAddress != null) {
  print(fed.stellarAddress!);
}
print(fed.accountId ?? 'no account id returned');
```

**resolveStellarAddress makes two HTTP requests — mock both:**

`resolveStellarAddress` first fetches `https://DOMAIN/.well-known/stellar.toml`
to discover `FEDERATION_SERVER`, then queries the federation endpoint. When
mocking, your `MockClient` must handle both URLs or the lookup will fail.