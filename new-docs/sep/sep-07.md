# SEP-07: URI Scheme for Delegated Signing

SEP-07 defines a URI scheme (`web+stellar:`) that enables applications to request transaction signing from external wallets. Instead of handling private keys directly, your application generates a URI that a wallet can open, sign, and submit.

**When to use:** Building web applications that need users to sign transactions, creating payment request links, QR codes for payments, or integrating with hardware wallets or other signing services.

See the [SEP-07 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md) for complete protocol details.

## Quick example

The simplest way to create a payment request URI is with `generatePayOperationURI()`. This creates a `web+stellar:pay?` URI that any SEP-07 compliant wallet can process.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// Generate a payment request URI for 100 USDC
String uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  amount: '100',
  assetCode: 'USDC',
  assetIssuer: 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
);

print(uri);
// Output: web+stellar:pay?destination=GDGUF4SC...&amount=100&asset_code=USDC&asset_issuer=GA5ZSEJY...
```

## Generating URIs

### Transaction signing (tx operation)

The `tx` operation requests a wallet to sign a specific XDR-encoded transaction. Use this when you have full control over the transaction structure and need an exact transaction to be signed.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Source account keypair (the account that will sign)
KeyPair sourceKeyPair = KeyPair.fromSecretSeed('SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF');
String accountId = sourceKeyPair.accountId;
AccountResponse sourceAccount = await sdk.accounts.account(accountId);

// Build a transaction that sets the home domain
SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
setOp.setSourceAccount(accountId);
setOp.setHomeDomain('www.example.com');

Transaction transaction = TransactionBuilder(sourceAccount)
    .addOperation(setOp.build())
    .build();

// Generate a SEP-07 URI from the unsigned transaction
final uriScheme = URIScheme();
String uri = uriScheme.generateSignTransactionURI(
  transaction.toEnvelopeXdrBase64(),
);

print(uri);
// Output: web+stellar:tx?xdr=AAAAAgAAAAD...
```

### Transaction URI with all options

The `generateSignTransactionURI()` method accepts optional parameters for callbacks, messages, signature verification, and more.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
String xdrBase64 = 'AAAAAgAAAAD...'; // Your transaction XDR

String uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  replace: null,  // Field replacement spec (see "Field replacement with Txrep" section)
  callback: 'url:https://example.com/callback',  // Where to POST signed tx
  publicKey: 'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV', // Which account should sign
  chain: null,  // Nested SEP-07 URI that triggered this one
  message: 'Please sign to update your account settings',  // User-facing message (max 300 chars)
  networkPassphrase: Network.TESTNET.networkPassphrase,  // Omit for public network
  originDomain: 'example.com',  // Your domain (requires signing the URI)
);

print(uri);
```

### Field replacement with Txrep (replace parameter)

The `replace` parameter lets you specify fields in the transaction that should be filled in by the wallet user. This uses the [SEP-11 Txrep](sep-11.md) format to identify fields. Useful when you want the user to provide certain values like source account or destination.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
String xdrBase64 = 'AAAAAgAAAAD...'; // Transaction XDR with placeholder accounts

// Build a replace string using UriSchemeReplacement
final replacements = [
  UriSchemeReplacement('X', 'sourceAccount', 'Account to pay fees from'),
  UriSchemeReplacement('Y', 'operations[0].destination', 'Account to receive tokens'),
];

String replaceString = uriScheme.uriSchemeReplacementsToString(replacements);

String uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  replace: replaceString,
);

print(uri);
```

### Transaction chaining (chain parameter)

The `chain` parameter embeds a previous SEP-07 URI that triggered the creation of this one. This is informational and enables verification of the full request chain. Chains can nest up to 7 levels deep.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
String xdrBase64 = 'AAAAAgAAAAD...';

// The original URI that triggered this request
String originalUri = 'web+stellar:tx?xdr=AAAA...&origin_domain=original.com&signature=...';

String uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  chain: originalUri,  // Embed the original request for audit purposes
  callback: 'url:https://multisig-coordinator.com/collect',
  originDomain: 'multisig-coordinator.com',
);

print(uri);
```

### Multisig coordination

The `callback` parameter is particularly useful for multisig coordination services. Instead of submitting directly to the network, the signed transaction is POSTed to a coordination service that collects signatures from multiple parties.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
String xdrBase64 = 'AAAAAgAAAAD...'; // Transaction requiring multiple signatures

// Generate URI that sends signed tx to a multisig coordinator
String uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  callback: 'url:https://multisig-service.example.com/collect',
  message: 'Sign to approve the 2-of-3 multisig transaction',
  originDomain: 'multisig-service.example.com',
);

// Each signer receives this URI and signs independently
// The coordinator collects signatures and submits when threshold is met
print(uri);
```

### Payment request (pay operation)

The `pay` operation requests a payment to a destination without pre-building a transaction. The wallet can choose the payment method (direct or path payment) and source asset.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// Simple XLM payment (no asset_code means native XLM)
String uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  amount: '50.5',
);
print(uri);
// Output: web+stellar:pay?destination=GDGUF4SC...&amount=50.5
```

### Payment with asset and memo

When accepting payments for specific assets or with order tracking via memos, specify the full payment details.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// Payment with specific asset and text memo
String uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  amount: '100',
  assetCode: 'USDC',
  assetIssuer: 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  memo: 'order-12345',
  memoType: 'MEMO_TEXT',
);
print(uri);
```

### Payment with hash or return memo

For `MEMO_HASH` and `MEMO_RETURN` memo types, the memo value must be base64-encoded before being passed to the method.

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// MEMO_HASH requires base64 encoding of the 32-byte hash
final hashBytes = sha256.convert(utf8.encode('my-unique-identifier')).bytes;
String memoValue = base64Encode(hashBytes);

String uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  amount: '100',
  memo: memoValue,
  memoType: 'MEMO_HASH',
);
print(uri);
```

### Donation request (no amount)

Omit the amount to let the user decide how much to send. Useful for donations or tips.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// Omitting amount allows user to specify any amount
String uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  message: 'Support our open source project!',
);

print(uri);
// Output: web+stellar:pay?destination=GDGUF4SC...&msg=Support%20our%20open%20source%20project%21
```

## Signing URIs for origin verification

If your application issues SEP-07 URIs and wants to prove authenticity, sign them with a keypair whose public key is published as `URI_REQUEST_SIGNING_KEY` in your [stellar.toml](sep-01.md) file.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// Your signing keypair - the public key must match URI_REQUEST_SIGNING_KEY in your stellar.toml
KeyPair signerKeyPair = KeyPair.fromSecretSeed('SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF');

// First generate the URI with origin_domain (signature will be added by addSignature)
String uri = uriScheme.generateSignTransactionURI(
  'AAAAAgAAAAD...',
  originDomain: 'example.com',
);

// Sign the URI - this appends the signature parameter
String signedUri = uriScheme.addSignature(uri, signerKeyPair);

print(signedUri);
// Output: web+stellar:tx?xdr=...&origin_domain=example.com&signature=bIZ53bPK...
```

## Validating URIs

Before processing a URI from an untrusted source, validate it. SEP-07 provides two levels of validation.

### Structure validation (no network request)

`isValidSep7Url()` validates URI structure, parameter formats, and values without fetching stellar.toml.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
String uri = 'web+stellar:pay?destination=GDGUF4SC...&amount=100';

IsValidSep7UrlResult result = uriScheme.isValidSep7Url(uri);
if (result.result) {
  print('URI is structurally valid');
} else {
  print('Invalid: ${result.reason}');
}
```

### Full validation including signature (network request)

`isValidSep7SignedUrl()` validates structure, then fetches `stellar.toml` from `origin_domain`, extracts `URI_REQUEST_SIGNING_KEY`, and verifies the Ed25519 signature.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
String uri = 'web+stellar:tx?xdr=...&origin_domain=example.com&signature=...';

IsValidSep7UrlResult result = await uriScheme.isValidSep7SignedUrl(uri);
if (result.result) {
  // URI is valid and signature verified - safe to display origin_domain to user
  final parsed = uriScheme.tryParseSep7Url(uri);
  print('Verified request from: ${parsed?.queryParameters[URIScheme.originDomainParameterName]}');
} else {
  // Possible failure reasons:
  // - "Missing parameter 'origin_domain'"
  // - "Missing parameter 'signature'"
  // - "The 'origin_domain' parameter is not a fully qualified domain name"
  // - "Toml not found or invalid for 'domain'"
  // - "No signing key found in toml from 'domain'"
  // - "Signature is not from the signing key '...' found in the toml data of 'domain'"
  print('Validation failed: ${result.reason}');
}
```

### Signature verification with known public key

`verifySignature()` checks the signature without fetching stellar.toml. Returns `bool`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
String uri = 'web+stellar:tx?xdr=...&signature=...';
String signingKey = 'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV';

if (uriScheme.verifySignature(uri, signingKey)) {
  print('Signature is valid');
} else {
  print('Invalid or malformed');
}
```

## Signing and submitting transactions

Use `signAndSubmitTransaction()` to sign a transaction from a URI and submit it. The method handles submission to either a callback URL or directly to the Stellar network.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// The URI containing the transaction to sign
String uri = 'web+stellar:tx?xdr=AAAAAgAAAAD...';

// User's signing keypair
KeyPair signerKeyPair = KeyPair.fromSecretSeed('SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF');

// Sign and submit the transaction
SubmitUriSchemeTransactionResponse response = await uriScheme.signAndSubmitTransaction(
  uri,
  signerKeyPair,
  network: Network.TESTNET,
);

// Check the result - only one response type will be set
if (response.submitTransactionResponse != null) {
  // Transaction was submitted directly to the Stellar network
  SubmitTransactionResponse txResponse = response.submitTransactionResponse!;
  if (txResponse.success) {
    print('Transaction successful! Hash: ${txResponse.hash}');
  } else {
    print('Transaction failed');
    print(txResponse.extras?.resultCodes?.transactionResultCode);
  }
} else if (response.response != null) {
  // Transaction was sent to the callback URL specified in the URI
  final httpResponse = response.response!;
  print('Callback response status: ${httpResponse.statusCode}');
  print('Callback response body: ${httpResponse.body}');
}
```

## Parsing URI parameters

Use `tryParseSep7Url()` to parse a SEP-07 URI and extract its parameters.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();
String uri = 'web+stellar:pay?destination=GDGUF4SC...&amount=100&memo=order-123&msg=Payment%20for%20order';

ParsedSep7UrlResult? parsed = uriScheme.tryParseSep7Url(uri);
if (parsed != null) {
  print('Operation: ${parsed.operationType}'); // "pay"

  // Access parameters - values are already URL-decoded
  String? destination = parsed.queryParameters[URIScheme.destinationParameterName];
  String? amount = parsed.queryParameters[URIScheme.amountParameterName];
  String? memo = parsed.queryParameters[URIScheme.memoParameterName];
  String? message = parsed.queryParameters[URIScheme.messageParameterName];
  String? callback = parsed.queryParameters[URIScheme.callbackParameterName];

  print('Destination: $destination');
  print('Amount: $amount');

  if (memo != null) {
    print('Memo: $memo');
  }

  if (message != null) {
    print('Message: $message');
  }

  if (callback != null) {
    print('Callback: $callback');
  } else {
    print('Submit directly to network');
  }
}
```

### Parsing replace parameters

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// After parsing a URI with a replace parameter
ParsedSep7UrlResult? parsed = uriScheme.tryParseSep7Url(uri);
if (parsed != null) {
  String? replaceParam = parsed.queryParameters[URIScheme.replaceParameterName];
  if (replaceParam != null) {
    List<UriSchemeReplacement> replacements =
        uriScheme.uriSchemeReplacementsFromString(replaceParam);
    for (final r in replacements) {
      print('Field: ${r.path}');   // e.g. "sourceAccount"
      print('ID: ${r.id}');        // e.g. "X"
      print('Hint: ${r.hint}');    // e.g. "Account to pay fees from"
    }
  }
}
```

### Available parameter constants

The `URIScheme` class provides constants for all standard parameter names:

| Constant | Value | Description |
|----------|-------|-------------|
| `URIScheme.xdrParameterName` | `xdr` | Transaction envelope XDR |
| `URIScheme.replaceParameterName` | `replace` | Txrep field replacement spec |
| `URIScheme.callbackParameterName` | `callback` | Callback URL for submission |
| `URIScheme.publicKeyParameterName` | `pubkey` | Required signing public key |
| `URIScheme.chainParameterName` | `chain` | Nested SEP-07 URI |
| `URIScheme.messageParameterName` | `msg` | User-facing message |
| `URIScheme.networkPassphraseParameterName` | `network_passphrase` | Network identifier |
| `URIScheme.originDomainParameterName` | `origin_domain` | Request originator domain |
| `URIScheme.signatureParameterName` | `signature` | URI signature |
| `URIScheme.destinationParameterName` | `destination` | Payment recipient |
| `URIScheme.amountParameterName` | `amount` | Payment amount |
| `URIScheme.assetCodeParameterName` | `asset_code` | Asset code |
| `URIScheme.assetIssuerParameterName` | `asset_issuer` | Asset issuer account |
| `URIScheme.memoParameterName` | `memo` | Transaction memo value |
| `URIScheme.memoTypeParameterName` | `memo_type` | Memo type |

## Error handling

Error handling for URI validation and transaction submission.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

// 1. Validate URI structure before processing
String uri = 'web+stellar:tx?xdr=invalid-data';
IsValidSep7UrlResult validation = uriScheme.isValidSep7Url(uri);
if (!validation.result) {
  print('Invalid URI: ${validation.reason}');
}

// 2. Validate signed URI (async - fetches stellar.toml)
String signedUri = 'web+stellar:tx?xdr=...&origin_domain=example.com&signature=...';
IsValidSep7UrlResult signedValidation = await uriScheme.isValidSep7SignedUrl(signedUri);
if (!signedValidation.result) {
  print('Validation failed: ${signedValidation.reason}');
}

// 3. Handle transaction submission errors
try {
  String txUri = 'web+stellar:tx?xdr=AAAAAgAAAAD...';
  KeyPair keyPair = KeyPair.fromSecretSeed('SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF');
  SubmitUriSchemeTransactionResponse response =
      await uriScheme.signAndSubmitTransaction(txUri, keyPair, network: Network.TESTNET);

  if (response.submitTransactionResponse != null) {
    SubmitTransactionResponse txResponse = response.submitTransactionResponse!;
    if (!txResponse.success) {
      // Transaction was submitted but failed
      print('Transaction failed: ${txResponse.extras?.resultCodes?.transactionResultCode}');
      List<String>? opCodes = txResponse.extras?.resultCodes?.operationsResultCodes;
      if (opCodes != null) {
        for (int i = 0; i < opCodes.length; i++) {
          print('  Operation $i: ${opCodes[i]}');
        }
      }
    }
  }
} on ArgumentError catch (e) {
  // URI is invalid, missing xdr, XDR cannot be parsed
  print('Bad URI: $e');
} catch (e) {
  // HTTP error (callback) or Horizon error (network submission)
  print('Submission error: $e');
}
```

## Testing with mock HTTP

Inject a `MockClient` to test stellar.toml fetching and callback submissions without making actual network requests. Assign directly to `uriScheme.httpClient`.

```dart
import 'dart:convert';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final signerKeyPair = KeyPair.random();
final signerAccountId = signerKeyPair.accountId;

final uriScheme = URIScheme();

// Build and sign a URI
String uri = uriScheme.generateSignTransactionURI(
  xdrBase64,
  originDomain: 'place.domain.com',
);
String signedUri = uriScheme.addSignature(uri, signerKeyPair);

// Mock stellar.toml returning our signing key
String tomlContent = 'URI_REQUEST_SIGNING_KEY="$signerAccountId"';

uriScheme.httpClient = MockClient((request) async {
  if (request.url.toString().startsWith(
          'https://place.domain.com/.well-known/stellar.toml') &&
      request.method == 'GET') {
    return http.Response(tomlContent, 200);
  }
  return http.Response(json.encode({'error': 'Bad request'}), 400);
});

IsValidSep7UrlResult result = await uriScheme.isValidSep7SignedUrl(signedUri);
assert(result.result); // true

// Reset to real client when done
uriScheme.httpClient = http.Client();
```

## QR codes

SEP-07 URIs can be encoded into QR codes for mobile scanning. Encode the complete URI into the QR code data.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final uriScheme = URIScheme();

String uri = uriScheme.generatePayOperationURI(
  'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
  amount: '25',
  memo: 'coffee',
  memoType: 'MEMO_TEXT',
);

// Use any QR code library to encode the URI
// Example with qr_flutter:
// QrImageView(data: uri, version: QrVersions.auto, size: 200.0)

print('Encode this URI in a QR code: $uri');
```

## Security considerations

When implementing SEP-07 support, follow these security practices from the specification:

### For applications generating URIs

- **Always sign your URIs** with an `origin_domain` and `signature` when possible. Unsigned URIs should be treated as untrusted.
- **Publish your `URI_REQUEST_SIGNING_KEY`** in your stellar.toml file.
- **Include meaningful messages** in the `msg` parameter to help users understand what they're signing.
- **Use unique memos** to track individual payment requests.

### For wallets processing URIs

- **Always validate signed URIs** before displaying `origin_domain` to users.
- **Never auto-sign transactions** - always get explicit user consent.
- **Display transaction details clearly** so users understand what they're signing.
- **Warn users about unsigned URIs** - they are equivalent to HTTP vs HTTPS.
- **Track known destination addresses** and warn about new recipients.
- **Use fonts that distinguish similar characters** to prevent homograph attacks (e.g., distinguishing `l` from `I`, or Latin from Cyrillic characters).
- **Cache `URI_REQUEST_SIGNING_KEY`** per domain and alert users if it changes.

### Callback security

- **Callbacks receive signed transactions** - be careful what endpoints you trust.
- **Validate callback URLs** before sending signed transactions to them.
- **The `msg` field can be spoofed** - only trust message content after successful signature validation.

## Further reading

- [SEP-07 test cases](https://github.com/niclas9/stellar_flutter_sdk/blob/master/test/integration/sep0007_test.dart) - SDK test cases demonstrating URI generation, signing, and validation

## Related SEPs

- [SEP-01 stellar.toml](sep-01.md) - Where `URI_REQUEST_SIGNING_KEY` is published for signature verification
- [SEP-11 Txrep](sep-11.md) - Human-readable transaction format used in the `replace` parameter

---

[Back to SEP Overview](README.md)
