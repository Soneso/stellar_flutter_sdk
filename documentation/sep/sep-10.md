# SEP-10: Stellar Web Authentication

SEP-10 defines how wallets prove account ownership to anchors and other services. When a service needs to verify you control a Stellar account, SEP-10 handles the challenge-response flow and returns a JWT token you can use for authenticated requests.

**Use SEP-10 when:**
- Authenticating with anchors before deposits/withdrawals (SEP-6, SEP-24)
- Submitting KYC information (SEP-12)
- Accessing any service that requires proof of account ownership

**Spec:** [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)

## Quick Example

This example demonstrates the simplest SEP-10 authentication flow: creating a WebAuth instance from the anchor's domain and obtaining a JWT token in a single call.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create WebAuth from the anchor's domain - this automatically loads
// the stellar.toml and extracts the WEB_AUTH_ENDPOINT and SIGNING_KEY
final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);

// Get JWT token - handles challenge request, signing, and submission
final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');
final jwtToken = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);

// Use the token for authenticated requests to SEP-6, SEP-12, SEP-24, etc.
print('Authenticated! Token: ${jwtToken.substring(0, 50)}...');
```

## Detailed Usage

### Creating WebAuth

#### From domain (recommended)

This method loads configuration automatically from the anchor's stellar.toml file, so you always have the correct endpoint and signing key.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Loads stellar.toml and extracts WEB_AUTH_ENDPOINT and SIGNING_KEY
final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
```

#### Manual construction

Use this when you already have the endpoint and signing key, or when testing with custom configurations.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = WebAuth(
  'https://testanchor.stellar.org/auth',     // authEndpoint
  Network.TESTNET,                            // network
  'GCUZ6YLL5RQBTYLTTQLPCM73C5XAIUGK2TIMWQH7HPSGWVS2KJ2F3CHS', // serverSigningKey
  'testanchor.stellar.org',                   // serverHomeDomain
);
```

### Standard authentication

For most use cases, `jwtToken()` handles the entire SEP-10 flow: requesting a challenge, validating it, signing with your keypair(s), and getting the JWT token.

> **Note:** Accounts don't need to exist on the Stellar network to authenticate. SEP-10 only proves you control the signing key for an account address. The server handles non-existent accounts by assuming default signature requirements.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');

final jwtToken = await webAuth.jwtToken(
  userKeyPair.accountId,
  [userKeyPair],
);
```

The method performs these steps internally:
1. Requests a challenge transaction from the server
2. Validates the challenge (sequence number = 0, valid signatures, time bounds, operations)
3. Signs with your keypair(s)
4. Submits the signed transaction to the server
5. Returns the JWT token

### Multi-signature accounts

For accounts requiring multiple signatures to meet the authentication threshold, provide all required signers. The combined signature weight must meet the server's requirements.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);

// Provide all signers needed to meet the account's threshold
final signer1 = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');
final signer2 = KeyPair.fromSecretSeed('SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2HIF74DBGCZ6V5CSBRROPGKVZ');

final jwtToken = await webAuth.jwtToken(
  signer1.accountId,
  [signer1, signer2],
);
```

### Muxed accounts

Muxed accounts (M... addresses) bundle a user ID with a G... account. This lets services distinguish between multiple users sharing the same Stellar account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');

// Create muxed account with user ID embedded in the address
final muxedAccount = MuxedAccount(userKeyPair.accountId, 1234567890);

final jwtToken = await webAuth.jwtToken(
  muxedAccount.accountId, // Returns M... address
  [userKeyPair],
);
```

#### Memo-based user separation

For services that use memos instead of muxed accounts to identify users sharing a single Stellar account, pass the memo as a separate parameter.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');

final jwtToken = await webAuth.jwtToken(
  userKeyPair.accountId,
  [userKeyPair],
  memo: 1234567890, // User ID memo (must be integer)
);
```

> **Note:** You cannot use both a muxed account (M...) and a memo simultaneously. The SDK will throw a `NoMemoForMuxedAccountsException` if you attempt this.

### Client attribution (non-custodial wallets)

Client domain verification lets wallets prove their identity to anchors. Anchors can then provide different experiences for users coming from known, trusted wallets.

#### Local signing

When the wallet has direct access to its signing key, provide the keypair directly. The wallet's stellar.toml must include a `SIGNING_KEY` that matches the provided keypair.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);

final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');
final clientDomainKeyPair = KeyPair.fromSecretSeed('SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2HIF74DBGCZ6V5CSBRROPGKVZ');

final jwtToken = await webAuth.jwtToken(
  userKeyPair.accountId,
  [userKeyPair],
  clientDomain: 'mywallet.com',
  clientDomainAccountKeyPair: clientDomainKeyPair,
);
```

#### Remote signing callback

When the client domain signing key is stored on a separate server (recommended for security), use a callback to delegate signing. This is the recommended approach for production.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');

// Callback receives base64-encoded transaction XDR and must return signed XDR
Future<String> signingDelegate(String transactionXdr) async {
  final client = http.Client();
  try {
    final response = await client.post(
      Uri.parse('https://signing-server.mywallet.com/sign'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_API_TOKEN',
      },
      body: json.encode({
        'transaction': transactionXdr,
        'network_passphrase': 'Test SDF Network ; September 2015',
      }),
    );

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (!data.containsKey('transaction')) {
      throw Exception('Invalid signing server response');
    }
    return data['transaction'] as String;
  } finally {
    client.close();
  }
}

final jwtToken = await webAuth.jwtToken(
  userKeyPair.accountId,
  [userKeyPair],
  clientDomain: 'mywallet.com',
  clientDomainSigningDelegate: signingDelegate,
);
```

### Multiple home domains

When an anchor serves multiple domains from the same authentication server, specify which domain the challenge should be issued for.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');

final jwtToken = await webAuth.jwtToken(
  userKeyPair.accountId,
  [userKeyPair],
  homeDomain: 'other-domain.com', // Request challenge for specific domain
);
```

## Error handling

The SDK provides specific exception types for different failure scenarios. This lets you handle errors precisely and give users appropriate feedback.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
  final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');

  final jwtToken = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);

} on NoWebAuthEndpointFoundException catch (e) {
  // stellar.toml missing WEB_AUTH_ENDPOINT
  print('No WEB_AUTH_ENDPOINT found for ${e.domain}');

} on NoWebAuthServerSigningKeyFoundException catch (e) {
  // stellar.toml missing SIGNING_KEY
  print('No SIGNING_KEY found for ${e.domain}');

} on ChallengeRequestErrorResponse catch (e) {
  // Server rejected the challenge request (HTTP error from auth endpoint)
  print('Challenge request failed HTTP ${e.code}: ${e.body}');

} on ChallengeValidationErrorInvalidSeqNr {
  // CRITICAL SECURITY: Challenge has non-zero sequence number
  // This could indicate a malicious server trying to get you to sign a real transaction
  print('Security error: Invalid sequence number - DO NOT PROCEED');

} on ChallengeValidationErrorInvalidSignature {
  // Challenge wasn't properly signed by the server's signing key
  print('Invalid server signature - check stellar.toml SIGNING_KEY');

} on ChallengeValidationErrorInvalidTimeBounds {
  // Challenge expired or time bounds invalid - request a new one
  print('Challenge expired or invalid time bounds');

} on ChallengeValidationErrorInvalidHomeDomain {
  // First operation's data key doesn't match expected "domain auth" format
  print('Invalid home domain in challenge');

} on ChallengeValidationErrorInvalidWebAuthDomain {
  // web_auth_domain operation value doesn't match the auth endpoint host
  print('Invalid web auth domain');

} on ChallengeValidationErrorInvalidSourceAccount {
  // Operation source account is incorrect (first op must be client, others must be server)
  print('Invalid source account in challenge operation');

} on ChallengeValidationErrorInvalidOperationType {
  // Challenge contains non-ManageData operations (security risk)
  print('Invalid operation type - all operations must be ManageData');

} on ChallengeValidationErrorInvalidMemoType {
  // Memo must be MEMO_NONE or MEMO_ID
  print('Invalid memo type');

} on ChallengeValidationErrorInvalidMemoValue {
  // Memo value doesn't match the requested memo
  print('Memo value mismatch');

} on ChallengeValidationErrorMemoAndMuxedAccount {
  // Challenge has both memo and muxed account (invalid per SEP-10)
  print('Cannot have both memo and muxed account');

} on ChallengeValidationError catch (e) {
  // Generic validation errors (specific errors have their own exception types above)
  print('Challenge validation failed: $e');

} on SubmitCompletedChallengeErrorResponseException catch (e) {
  // Server rejected the signed challenge (e.g., insufficient signers, invalid signatures)
  print('Authentication failed: ${e.error}');

} on SubmitCompletedChallengeTimeoutResponseException {
  // Server returned 504 Gateway Timeout - retry with backoff
  print('Server timeout - please retry');

} on SubmitCompletedChallengeUnknownResponseException catch (e) {
  // Unexpected HTTP response from server
  print('Unexpected server response HTTP ${e.code}: ${e.body}');
}
```

### Exception reference

| Exception | Cause | Solution |
|-----------|-------|----------|
| `NoWebAuthEndpointFoundException` | stellar.toml missing WEB_AUTH_ENDPOINT | Check domain supports SEP-10 |
| `NoWebAuthServerSigningKeyFoundException` | stellar.toml missing SIGNING_KEY | Check domain supports SEP-10 |
| `NoMemoForMuxedAccountsException` | Memo provided with M... account | Use memo OR muxed, not both |
| `ChallengeRequestErrorResponse` | Server rejected challenge request | Check account ID format, server status |
| `ChallengeValidationErrorInvalidSeqNr` | Sequence number != 0 | **Security risk** - do not proceed |
| `ChallengeValidationErrorInvalidSignature` | Bad server signature | Verify stellar.toml SIGNING_KEY |
| `ChallengeValidationErrorInvalidTimeBounds` | Challenge expired | Request a new challenge |
| `ChallengeValidationErrorInvalidHomeDomain` | Wrong home domain | Check domain configuration |
| `ChallengeValidationErrorInvalidWebAuthDomain` | Wrong web auth domain | Verify auth endpoint URL |
| `ChallengeValidationErrorInvalidSourceAccount` | Wrong operation source | Server configuration issue |
| `ChallengeValidationErrorInvalidOperationType` | Non-ManageData operation | **Security risk** - server may be malicious |
| `ChallengeValidationErrorInvalidMemoType` | Memo not NONE or ID | Server configuration issue |
| `ChallengeValidationErrorInvalidMemoValue` | Memo mismatch | Check memo parameter matches server |
| `ChallengeValidationErrorMemoAndMuxedAccount` | Both memo and M... address | Use one or the other, not both |
| `SubmitCompletedChallengeErrorResponseException` | Signed challenge rejected | Provide sufficient signers |
| `SubmitCompletedChallengeTimeoutResponseException` | Server timeout (504) | Retry with exponential backoff |
| `SubmitCompletedChallengeUnknownResponseException` | Unexpected HTTP response | Check server logs, contact support |

### Retry logic example

For production applications, implement retry logic with exponential backoff for transient failures.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Authenticates with automatic retry for transient failures.
Future<String> authenticateWithRetry(
  WebAuth webAuth,
  String accountId,
  List<KeyPair> signers, {
  int maxRetries = 3,
}) async {
  int attempt = 0;
  Object? lastException;

  while (attempt < maxRetries) {
    try {
      return await webAuth.jwtToken(accountId, signers);
    } on ChallengeValidationErrorInvalidTimeBounds catch (e) {
      // Challenge expired - retry immediately with fresh challenge
      attempt++;
      lastException = e;
    } on SubmitCompletedChallengeTimeoutResponseException catch (e) {
      // Server timeout - retry with exponential backoff
      attempt++;
      lastException = e;
      await Future.delayed(Duration(seconds: 1 << attempt)); // 2, 4, 8 seconds
    }
  }

  throw lastException ?? Exception('Authentication failed after $maxRetries attempts');
}

// Usage
final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A');

final jwtToken = await authenticateWithRetry(webAuth, userKeyPair.accountId, [userKeyPair]);
```

## Security notes

- **Store tokens securely.** JWT tokens grant access to protected services. Don't log them or expose them in URLs.
- **Use the correct network.** Ensure you pass `Network.TESTNET` or `Network.PUBLIC` matching the server's network.

The SDK automatically validates challenges (sequence number, signatures, time bounds, operations) and throws specific exceptions if anything looks wrong.

> **Note:** The SDK does not currently support Authorization headers when requesting challenges (SEP-10 v3.4.0 feature). Most servers don't require this, as it's an optional feature that servers may implement to restrict or rate-limit challenge generation.

## Testing

Replace the HTTP client on a manually-constructed `WebAuth` instance with a `MockClient` from `package:http/testing.dart`. No network calls are made.

```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Server configuration - must match what WebAuth is initialized with
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
  String buildChallenge(String accountId) {
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
        .addMemo(Memo.none())
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
      // Token POST - verify signature and return JWT
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
- The `Account` sequence starts at `BigInt.from(-1)` -- `build()` increments it to 0 (required by SEP-10)
- First ManageData op key must be `'<serverHomeDomain> auth'`, source must be the client account (use `setMuxedSourceAccount`)
- The `web_auth_domain` op source must be the server signing key account ID; its value must be the **host** of the auth URL (e.g., `'api.stellar.org'`, not the full URL)
- The transaction must be signed by the server's keypair with the correct `Network`
- Time bounds must include the current time

## JWT token structure

The JWT token returned by SEP-10 authentication contains standard claims. The SDK doesn't include a JWT decoder, but understanding the token structure helps with debugging and validation.

**Standard JWT claims:**
- `sub` - The authenticated account (G... or M... address, or G...:memo format for memo-based auth)
- `iss` - The token issuer (authentication server URL)
- `iat` - Token issued at timestamp (Unix epoch)
- `exp` - Token expiration timestamp (Unix epoch)
- `client_domain` - (optional) Present when client domain verification was performed

To decode and inspect a JWT token, you can use any JWT library or the [jwt.io](https://jwt.io) debugger.

## Related SEPs

- [SEP-01](sep-01.md) - stellar.toml discovery (provides auth endpoint)
- [SEP-06](sep-06.md) - Deposit/withdrawal (uses SEP-10 auth)
- [SEP-12](sep-12.md) - KYC API (uses SEP-10 auth)
- [SEP-24](sep-24.md) - Interactive deposit/withdrawal (uses SEP-10 auth)
- [SEP-45](sep-45.md) - Web Authentication for Contract Accounts (Soroban alternative)

---

[Back to SEP Overview](README.md)
