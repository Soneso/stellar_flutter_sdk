# SEP-02: Federation protocol

Federation allows users to send payments using human-readable addresses like `bob*example.com` instead of raw account IDs like `GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ`. It also enables organizations to map bank accounts or other external identifiers to Stellar accounts.

**When to use:** Building a wallet that supports sending payments to Stellar addresses, or implementing a service that resolves external identifiers (bank accounts, phone numbers) to Stellar accounts.

See the [SEP-02 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md) for protocol details.

## Address format

A Stellar address has two parts: `username*domain.com`
- **Username:** Any printable UTF-8 except `*` and `>` (emails and phone numbers are allowed)
- **Domain:** Any valid RFC 1035 domain name

Examples: `bob*example.com`, `alice@gmail.com*stellar.org`, `+14155550100*bank.com`

## How address resolution works

When you resolve a Stellar address like `bob*example.com`, this happens:

1. **Parse the address** - Split on `*` to get username (`bob`) and domain (`example.com`)
2. **Fetch stellar.toml** - Download `https://example.com/.well-known/stellar.toml`
3. **Find federation server** - Extract the `FEDERATION_SERVER` URL from the TOML
4. **Query federation server** - Make GET request: `FEDERATION_SERVER/federation?q=bob*example.com&type=name`
5. **Get account details** - Server returns account ID and optional memo

The SDK handles this entire flow automatically with `Federation.resolveStellarAddress()`.

**Note:** Federation servers may rate-limit requests. If you're making many lookups, consider caching responses appropriately (but remember that some services use ephemeral account IDs, so cache duration should be short).

## Quick example

Resolve a Stellar address to get the destination account ID for a payment. This single method call handles the entire federation lookup process, including fetching the stellar.toml and querying the federation server.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Resolve a Stellar address to an account ID
FederationResponse response =
    await Federation.resolveStellarAddress('bob*soneso.com');

print('Account: ${response.accountId}');
print('Memo: ${response.memo}');
```

## Resolving Stellar addresses

Convert a Stellar address to an account ID and optional memo. The memo is important because some services (like exchanges) use a single Stellar account for all users and require a memo to identify the recipient.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

FederationResponse response =
    await Federation.resolveStellarAddress('bob*soneso.com');

// The destination account for payments
String? accountId = response.accountId;
print('Account ID: $accountId');
// GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI

// Include memo if provided (required for some destinations)
String? memo = response.memo;
String? memoType = response.memoType;

if (memo != null) {
  print('Memo ($memoType): $memo');
}

// Original address for confirmation
String? address = response.stellarAddress;
print('Address: $address');
// bob*soneso.com
```

**Important:** Don't cache federation responses. Some services use random account IDs for privacy, which may change over time.

## Reverse lookup (account ID to address)

Find the Stellar address associated with an account ID. Unlike forward lookups, reverse lookups require you to know which federation server to query since the account ID doesn't contain domain information.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String accountId = 'GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI';
String federationServer = 'https://stellarid.io/federation/';

FederationResponse response =
    await Federation.resolveStellarAccountId(accountId, federationServer);

print('Address: ${response.stellarAddress}');
// bob*soneso.com
```

## Transaction lookup

Query a federation server to get information about who sent a transaction. This is useful for identifying the sender of an incoming payment when the federation server supports transaction lookups.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String txId = 'c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a';
String federationServer = 'https://stellarid.io/federation/';

// Returns federation record of the sender if known
FederationResponse response =
    await Federation.resolveStellarTransactionId(txId, federationServer);

if (response.stellarAddress != null) {
  print('Sender: ${response.stellarAddress}');
}
```

## Forward federation

Forward federation maps external identifiers (bank accounts, routing numbers, etc.) to Stellar accounts. Use this to pay someone who doesn't have a Stellar address but has another type of account that an anchor supports.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Pay to a bank account via an anchor
Map<String, String> params = {
  'forward_type': 'bank_account',
  'swift': 'BOPBPHMM',
  'acct': '2382376',
};

String federationServer = 'https://stellarid.io/federation/';
FederationResponse response =
    await Federation.resolveForward(params, federationServer);

print('Deposit to: ${response.accountId}');

// Use the memo to identify the recipient
if (response.memo != null) {
  print('Memo (${response.memoType}): ${response.memo}');
}
```

## Building a payment with federation

This complete example shows how to send a payment using a Stellar address. It resolves the recipient's address, builds a transaction with the appropriate memo, and submits it to the network.

```dart
import 'dart:convert';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Sender's keypair
KeyPair senderKeyPair =
    KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CPMLIHJPFV5RXN5M6CSS');
String senderAccountId = senderKeyPair.accountId;

// Resolve recipient's Stellar address
String recipient = 'alice*testanchor.stellar.org';
FederationResponse response =
    await Federation.resolveStellarAddress(recipient);

String destinationId = response.accountId!;

// Load sender account
AccountResponse senderAccount = await sdk.accounts.account(senderAccountId);

// Build payment operation
PaymentOperation paymentOp =
    PaymentOperationBuilder(destinationId, Asset.NATIVE, '10').build();

// Build transaction
TransactionBuilder txBuilder = TransactionBuilder(senderAccount);
txBuilder.addOperation(paymentOp);

// Include memo if federation response requires it
if (response.memo != null) {
  String? memoType = response.memoType;
  if (memoType == 'text') {
    txBuilder.addMemo(Memo.text(response.memo!));
  } else if (memoType == 'id') {
    txBuilder.addMemo(Memo.id(BigInt.parse(response.memo!)));
  } else if (memoType == 'hash') {
    // Hash memo values are base64-encoded in federation responses
    txBuilder.addMemo(MemoHash(base64Decode(response.memo!)));
  }
}

Transaction transaction = txBuilder.build();
transaction.sign(senderKeyPair, Network.TESTNET);

try {
  SubmitTransactionResponse result = await sdk.submitTransaction(transaction);
  print('Payment sent to $recipient');
} catch (e) {
  print('Payment failed: $e');
}
```

## Error handling

Federation lookups can fail for various reasons. This example demonstrates how to handle the most common error scenarios: invalid address format, missing federation server configuration, and unknown users.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Invalid address format (missing *)
// Throws Exception immediately without making network requests
try {
  await Federation.resolveStellarAddress('invalid-no-asterisk');
} catch (e) {
  print('Invalid format: $e');
  // Output: Invalid format: Exception: invalid federation address: invalid-no-asterisk
}

// Domain without federation server configured in stellar.toml
// Throws Exception when stellar.toml doesn't contain FEDERATION_SERVER
try {
  await Federation.resolveStellarAddress('user*domain-without-federation.com');
} catch (e) {
  print('No federation server: $e');
}

// User not found or federation server error
try {
  FederationResponse response =
      await Federation.resolveStellarAddress('nonexistent*soneso.com');
  print('Account: ${response.accountId}');
} catch (e) {
  print('Federation error: $e');
}
```

### Exception summary

| Error | When Thrown |
|-------|------------|
| `Exception` (invalid address) | Address doesn't contain `*` character |
| `Exception` (no federation server) | Domain's stellar.toml doesn't have `FEDERATION_SERVER` |
| `Exception` (HTTP error) | Federation server returns HTTP error (404, 500, etc.) |

## Custom HTTP client

All Federation methods accept optional `httpClient` and `httpRequestHeaders` named parameters. This is useful for configuring custom headers or mocking responses in tests.

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create a custom HTTP client
http.Client httpClient = http.Client();

// Pass the custom client to any Federation method
FederationResponse response = await Federation.resolveStellarAddress(
  'bob*soneso.com',
  httpClient: httpClient,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);

print('Account: ${response.accountId}');
```

## Finding the federation server

Each domain publishes its federation server URL in stellar.toml. The `resolveStellarAddress()` method does this lookup automatically, but you can also fetch it directly when needed for reverse lookups or manual queries.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Get federation server URL from stellar.toml
StellarToml stellarToml = await StellarToml.fromDomain('soneso.com');
String? federationServer = stellarToml.generalInformation.federationServer;

print('Federation Server: $federationServer');
// https://stellarid.io/federation/
```

**Note:** `Federation.resolveStellarAddress()` does this lookup automatically. You only need this for reverse lookups or when querying the federation server directly.

## FederationResponse properties

The `FederationResponse` object contains all the information returned by the federation server:

| Field | Type | Description |
|-------|------|-------------|
| `stellarAddress` | `String?` | Stellar address in `user*domain.com` format |
| `accountId` | `String?` | Stellar account ID (G-address) for payments |
| `memoType` | `String?` | Memo type: `text`, `id`, or `hash` |
| `memo` | `String?` | Memo value to include with payment |

**Note on hash memos:** When `memoType` is `hash`, the memo value is base64-encoded. Decode it before creating a `MemoHash`. This is necessary because `MemoHash` expects raw bytes (exactly 32 bytes), not a base64 string. The federation server encodes the binary hash as base64 for safe JSON transport.

## Testing with MockClient

Use `MockClient` from the `http` package to test federation lookups without real network calls. For `resolveStellarAddress`, the mock must handle two request paths: the stellar.toml fetch and the federation query.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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

FederationResponse response = await Federation.resolveStellarAddress(
  'alice*example.com',
  httpClient: mockClient,
);

print('Account: ${response.accountId}');
print('Memo: ${response.memo}');
```

## Related SEPs

- [SEP-01 stellar.toml](sep-01.md) - Where the `FEDERATION_SERVER` URL is published
- [SEP-10 Authentication](sep-10.md) - Some federation servers may require authentication

---

[Back to SEP Overview](README.md)
