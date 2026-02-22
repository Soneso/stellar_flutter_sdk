# SEP-30: Account Recovery

**Purpose:** Recover access to Stellar accounts when the owner loses their private key. Recovery servers act as cosigners: register your account with one or more servers, then call on them to sign a key-rotation transaction if you ever lose your private key.
**Prerequisites:** Requires JWT from SEP-10 (see `sep-10.md`) for registration and updates. Recovery (signing) uses a JWT from the server's alternate auth flow (email/phone/stellar_address).

## Table of Contents

1. [How Recovery Works](#1-how-recovery-works)
2. [Creating the Service](#2-creating-the-service)
3. [Registering an Account](#3-registering-an-account)
4. [Adding the Recovery Signer to Your Stellar Account](#4-adding-the-recovery-signer-to-your-stellar-account)
5. [Signing a Recovery Transaction](#5-signing-a-recovery-transaction)
6. [Updating Identity Information](#6-updating-identity-information)
7. [Getting Account Details](#7-getting-account-details)
8. [Listing Accounts](#8-listing-accounts)
9. [Deleting a Registration](#9-deleting-a-registration)
10. [Error Handling](#10-error-handling)
11. [Request and Response Objects](#11-request-and-response-objects)
12. [Common Pitfalls](#12-common-pitfalls)

---

## 1. How Recovery Works

1. **Register**: Call `registerAccount()` with your account address, one or more identities (role + auth methods), and your SEP-10 JWT. The server returns a signer public key.
2. **Add Signer**: Add the server's signer key to your Stellar account via `SetOptionsOperationBuilder` with weight=1. Set account thresholds so the server alone cannot control the account.
3. **Recovery**: If you lose your key, authenticate to the recovery server via alternate means (email, phone, etc.). The server issues a JWT proving that identity.
4. **Sign Transaction**: Build a transaction that adds your new key. Call `signTransaction()` with the recovery JWT and the signing address from the registered account. The server returns a base64 signature.
5. **Attach Signature**: Decode the base64 signature and attach it to the transaction envelope as an `XdrDecoratedSignature`.
6. **Submit**: Submit the signed transaction to Horizon to regain control.

---

## 2. Creating the Service

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Basic: service URL only
final service = SEP30RecoveryService("https://recovery.example.com");

// With custom HTTP client (timeouts, proxies, etc.)
import 'package:http/http.dart' as http;

final service = SEP30RecoveryService(
  "https://recovery.example.com",
  httpClient: http.Client(),
  httpRequestHeaders: {'X-Custom-Header': 'value'},
);
```

Constructor signature:
```
SEP30RecoveryService(String serviceAddress, {http.Client? httpClient, Map<String, String>? httpRequestHeaders})
```

The `httpClient` can also be set directly after construction (used in the integration tests):

```dart
final service = SEP30RecoveryService(recoveryServerUrl);
service.httpClient = myCustomClient;
```

---

## 3. Registering an Account

Call `registerAccount()` with:
- `address` — the Stellar account address (G... format)
- `request` — a `SEP30Request` containing one or more `SEP30RequestIdentity` objects
- `jwt` — a SEP-10 JWT proving you control the account

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

// Build authentication methods — multiple methods provide fallback options
final emailAuth = SEP30AuthMethod("email", "person@example.com");
final phoneAuth = SEP30AuthMethod("phone_number", "+10000000001"); // E.164 format
final stellarAuth = SEP30AuthMethod(
  "stellar_address",
  "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H",
);

// Single identity with role "owner"
final ownerIdentity = SEP30RequestIdentity("owner", [emailAuth, phoneAuth, stellarAuth]);
final request = SEP30Request([ownerIdentity]);

try {
  SEP30AccountResponse response =
      await service.registerAccount(accountId, request, jwtToken);

  print("Account: ${response.address}");
  for (final signer in response.signers) {
    print("Add signer to account: ${signer.key}");
  }
  for (final identity in response.identities) {
    print("Identity role: ${identity.role ?? 'unspecified'}");
  }
} on SEP30ConflictResponseException catch (e) {
  // Account already registered — use updateIdentitiesForAccount() instead
  print("Already registered: ${e.error}");
}
```

Multiple identities (e.g., sender + receiver for shared accounts):

```dart
final senderIdentity = SEP30RequestIdentity("sender", [
  SEP30AuthMethod("stellar_address", "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H"),
  SEP30AuthMethod("phone_number", "+10000000001"),
  SEP30AuthMethod("email", "person1@example.com"),
]);
final receiverIdentity = SEP30RequestIdentity("receiver", [
  SEP30AuthMethod("stellar_address", "GDIL76BC2XGDWLDPXCZVYB3AIZX4MYBN6JUBQPAX5OHRWPSNX3XMLNCS"),
  SEP30AuthMethod("phone_number", "+10000000002"),
  SEP30AuthMethod("email", "person2@example.com"),
]);

final request = SEP30Request([senderIdentity, receiverIdentity]);
SEP30AccountResponse response =
    await service.registerAccount(accountId, request, jwtToken);
```

Method signature:
```
Future<SEP30AccountResponse> registerAccount(String address, SEP30Request request, String jwt)
```

---

## 4. Adding the Recovery Signer to Your Stellar Account

After registration, add the server's signer key to your account:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final sdk = StellarSDK.TESTNET;
final accountKeyPair = KeyPair.fromSecretSeed(secretSeed);

// Signer key comes from the registerAccount() response
final signerKey = response.signers[0].key;

final account = await sdk.accounts.account(accountKeyPair.accountId);
final transaction = TransactionBuilder(account)
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(KeyPair.fromAccountId(signerKey).xdrSignerKey, 1)
          .build(),
    )
    // Optional: set thresholds so the server cannot act alone
    // (your key has weight=10, server has weight=1, threshold=2)
    .addOperation(
      SetOptionsOperationBuilder()
          .setHighThreshold(2)
          .setMediumThreshold(2)
          .setLowThreshold(2)
          .build(),
    )
    .build();

transaction.sign(accountKeyPair, Network.TESTNET);
await sdk.submitTransaction(transaction);
print("Recovery signer added.");
```

**Multi-server setup:** Register with two servers, add both signer keys with weight=1, set thresholds to 2. Either server alone cannot control the account; both must cooperate for recovery.

---

## 5. Signing a Recovery Transaction

When you need to recover an account, build a transaction that adds your new key, then get the recovery server to sign it.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");
final sdk = StellarSDK.TESTNET;

// Use a JWT from alternate authentication (email/phone), not your main key
// Step 1: Find the signing address (the server's signer key for this account)
final accountDetails = await service.accountDetails(accountId, recoveryJwt);
final signingAddress = accountDetails.signers[0].key;

// Step 2: Generate a new keypair to replace the lost key
final newKeyPair = KeyPair.random();

// Step 3: Build the recovery transaction (uses the lost account's current sequence)
final account = await sdk.accounts.account(accountId);
final transaction = TransactionBuilder(account)
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(
            newKeyPair.xdrSignerKey,
            10, // high weight to regain control
          )
          .build(),
    )
    .build();

// Step 4: Serialize to base64 XDR — this is what signTransaction() expects
final txBase64 = transaction.toEnvelopeXdrBase64();

// Step 5: Request the recovery server to sign it
SEP30SignatureResponse signatureResponse = await service.signTransaction(
  accountId,
  signingAddress,
  txBase64,
  recoveryJwt,
);

// Step 6: Attach the server's signature to the transaction
final signerKeyPair = KeyPair.fromAccountId(signingAddress);
final hint = signerKeyPair.signatureHint;
final signatureBytes = base64Decode(signatureResponse.signature);
final decoratedSignature = XdrDecoratedSignature(hint, signatureBytes);
transaction.signatures.add(decoratedSignature);

// For multi-server recovery: repeat steps 4-6 for each server, then submit
await sdk.submitTransaction(transaction);
print("Account recovered! New seed: ${newKeyPair.secretSeed}");
print("Store this seed securely!");
```

Method signature:
```
Future<SEP30SignatureResponse> signTransaction(String address, String signingAddress, String transaction, String jwt)
```

The `transaction` parameter is the base64-encoded XDR envelope string (from `transaction.toEnvelopeXdrBase64()`).

`SEP30SignatureResponse` fields:
- `signature` — base64-encoded signature bytes
- `networkPassphrase` — the Stellar network passphrase the signature is valid for

---

## 6. Updating Identity Information

Replace all existing identities on a registered account. This is a **full replacement**, not a merge — any identity not included in the request will be removed.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

// New set of identities — completely replaces existing ones
final newEmail = SEP30AuthMethod("email", "newemail@example.com");
final newPhone = SEP30AuthMethod("phone_number", "+14155559999");
final ownerIdentity = SEP30RequestIdentity("owner", [newEmail, newPhone]);

final request = SEP30Request([ownerIdentity]);
SEP30AccountResponse response =
    await service.updateIdentitiesForAccount(accountId, request, jwtToken);

print("Update successful.");
for (final identity in response.identities) {
  print("Role: ${identity.role ?? 'unspecified'}");
}
```

Method signature:
```
Future<SEP30AccountResponse> updateIdentitiesForAccount(String address, SEP30Request request, String jwt)
```

---

## 7. Getting Account Details

Retrieve the current registration state: identities, authentication status, and signer keys.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

SEP30AccountResponse response = await service.accountDetails(accountId, jwtToken);

print("Address: ${response.address}");

for (final identity in response.identities) {
  // authenticated is bool? — null when the server does not return the field
  // (typically during registration responses or when the current JWT didn't authenticate as this identity)
  final authStatus = identity.authenticated == true ? " (authenticated)" : "";
  print("  Role: ${identity.role ?? 'unspecified'}$authStatus");
}

for (final signer in response.signers) {
  print("  Signer: ${signer.key}");
}

// Use the signer key for recovery (pass to signTransaction)
final signingAddress = response.signers[0].key;
```

Method signature:
```
Future<SEP30AccountResponse> accountDetails(String address, String jwt)
```

---

## 8. Listing Accounts

List all accounts the authenticated identity has access to. Results are paginated; use the last account's address as the `after` cursor for the next page.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

// First page (no cursor)
SEP30AccountsResponse response = await service.accounts(jwtToken);

print("Found ${response.accounts.length} accounts");
for (final account in response.accounts) {
  print("  ${account.address}");
  for (final identity in account.identities) {
    final auth = identity.authenticated == true ? " (you)" : "";
    print("    Role: ${identity.role ?? 'unspecified'}$auth");
  }
}

// Next page: pass the last account address as cursor
if (response.accounts.isNotEmpty) {
  final lastAddress = response.accounts.last.address;
  SEP30AccountsResponse nextPage = await service.accounts(jwtToken, after: lastAddress);
  print("Next page: ${nextPage.accounts.length} accounts");
}
```

Method signature:
```
Future<SEP30AccountsResponse> accounts(String jwt, {String? after})
```

The `after` parameter is a cursor (account address string). Omit it or pass null for the first page.

---

## 9. Deleting a Registration

Remove an account from the recovery server. This is **irrecoverable**. After deletion, also remove the server's signer key from your Stellar account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");
final sdk = StellarSDK.TESTNET;

// Get signer key before deletion so we can remove it from the account
final details = await service.accountDetails(accountId, jwtToken);
final signerToRemove = details.signers[0].key;

// Delete from recovery server
SEP30AccountResponse response = await service.deleteAccount(accountId, jwtToken);
print("Deleted from recovery server.");

// Remove the signer from the Stellar account (weight=0 removes a signer)
final accountKeyPair = KeyPair.fromSecretSeed(secretSeed);
final account = await sdk.accounts.account(accountId);
final transaction = TransactionBuilder(account)
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(
            KeyPair.fromAccountId(signerToRemove).xdrSignerKey,
            0, // weight=0 removes the signer
          )
          .build(),
    )
    .build();
transaction.sign(accountKeyPair, Network.TESTNET);
await sdk.submitTransaction(transaction);
print("Recovery signer removed from Stellar account.");
```

Method signature:
```
Future<SEP30AccountResponse> deleteAccount(String address, String jwt)
```

Returns the final account state before deletion.

---

## 10. Error Handling

The SDK throws typed exceptions for each HTTP error code:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

try {
  final emailAuth = SEP30AuthMethod("email", "user@example.com");
  final ownerIdentity = SEP30RequestIdentity("owner", [emailAuth]);
  final request = SEP30Request([ownerIdentity]);
  SEP30AccountResponse response =
      await service.registerAccount(accountId, request, jwtToken);

} on SEP30BadRequestResponseException catch (e) {
  // HTTP 400: invalid request data, missing required fields,
  // invalid auth method types/values, or malformed transaction XDR
  print("Bad request (400): ${e.error}");

} on SEP30UnauthorizedResponseException catch (e) {
  // HTTP 401: JWT missing, invalid, expired, or does not prove account ownership
  print("Unauthorized (401): ${e.error}");

} on SEP30NotFoundResponseException catch (e) {
  // HTTP 404: account not registered, signing address not recognized,
  // or authenticated identity does not have access to this account
  print("Not found (404): ${e.error}");

} on SEP30ConflictResponseException catch (e) {
  // HTTP 409: account already registered (use updateIdentitiesForAccount() instead),
  // or update conflicts with server state
  print("Conflict (409): ${e.error}");

} on SEP30UnknownResponseException catch (e) {
  // Other HTTP errors (5xx, etc.) — raw HTTP status code and body available
  print("Unknown error (${e.code}): ${e.body}");

} catch (e) {
  // Network-level failures: connection refused, timeout, DNS failure, etc.
  print("Network error: $e");
}
```

### Exception reference

| Exception | HTTP | `.error` field | Typical cause |
|-----------|------|----------------|---------------|
| `SEP30BadRequestResponseException` | 400 | Error message string | Invalid fields, bad auth method values |
| `SEP30UnauthorizedResponseException` | 401 | Error message string | Missing/expired/invalid JWT |
| `SEP30NotFoundResponseException` | 404 | Error message string | Account not registered, signing address unknown |
| `SEP30ConflictResponseException` | 409 | Error message string | Account already registered, state conflict |
| `SEP30UnknownResponseException` | Other | `.code` (int) + `.body` (String) | 5xx errors, unexpected server responses |

`SEP30BadRequestResponseException`, `SEP30UnauthorizedResponseException`, `SEP30NotFoundResponseException`, and `SEP30ConflictResponseException` all extend `SEP30ResponseException` which implements `Exception`. Access the error string via `.error`. `SEP30UnknownResponseException` implements `Exception` directly and exposes `.code` (int) and `.body` (String).

---

## 11. Request and Response Objects

### SEP30AuthMethod

Single authentication method for an identity.

```dart
// Constructor
SEP30AuthMethod(String type, String value)

// Standard types
SEP30AuthMethod("email", "person@example.com")
SEP30AuthMethod("phone_number", "+10000000001")   // E.164 format: +[country][number], no spaces
SEP30AuthMethod("stellar_address", "GBUCA...H")   // G... Stellar address

// Access public fields directly
method.type;   // String
method.value;  // String
```

### SEP30RequestIdentity

Identity with a role and one or more authentication methods. The role is a client-defined label; the JSON key for auth methods is `auth_methods`.

```dart
// Constructor
SEP30RequestIdentity(String role, List<SEP30AuthMethod> authMethods)

identity.role;         // String
identity.authMethods;  // List<SEP30AuthMethod>
```

Common roles: `"owner"` (single user), `"sender"` / `"receiver"` (account sharing), `"other"` (additional signers with sign-only permissions).

### SEP30Request

Container for one or more identities. Serializes to `{"identities": [...]}`.

```dart
// Constructor
SEP30Request(List<SEP30RequestIdentity> identities)

request.identities;  // List<SEP30RequestIdentity>
```

### SEP30AccountResponse

Returned by `registerAccount()`, `updateIdentitiesForAccount()`, `accountDetails()`, and `deleteAccount()`.

```dart
response.address;     // String — the Stellar account address
response.identities;  // List<SEP30ResponseIdentity>
response.signers;     // List<SEP30ResponseSigner>
```

### SEP30ResponseIdentity

```dart
identity.role;           // String? — e.g. "owner", "sender", "receiver"; null if server omits
identity.authenticated;  // bool? — true if this identity authenticated the current request,
                         // false if explicitly unauthenticated, null if server did not return the field
```

### SEP30ResponseSigner

```dart
signer.key;  // String — G... public key to add as a signer on the Stellar account
```

### SEP30SignatureResponse

Returned by `signTransaction()`.

```dart
response.signature;         // String — base64-encoded signature bytes
response.networkPassphrase; // String — e.g. "Test SDF Network ; September 2015"
```

### SEP30AccountsResponse

Returned by `accounts()`.

```dart
response.accounts;  // List<SEP30AccountResponse>
```

---

## 12. Common Pitfalls

**Wrong: re-registering instead of updating**

```dart
// WRONG: calling registerAccount() on an already-registered account throws SEP30ConflictResponseException
await service.registerAccount(accountId, request, jwt);

// CORRECT: use updateIdentitiesForAccount() for changes to an existing registration
await service.updateIdentitiesForAccount(accountId, request, jwt);
```

**Wrong: passing the Transaction object instead of base64 XDR to signTransaction()**

```dart
// WRONG: signTransaction() expects a String, not a Transaction object
await service.signTransaction(accountId, signingAddress, transaction, jwt);

// CORRECT: serialize to base64 XDR envelope first
final txBase64 = transaction.toEnvelopeXdrBase64();
await service.signTransaction(accountId, signingAddress, txBase64, jwt);
```

**Wrong: using the account address instead of the signing address for the signature hint**

```dart
// WRONG: using the account address to derive the hint
final hint = KeyPair.fromAccountId(accountId).signatureHint;

// CORRECT: use the signing address (the server's signer key, from accountDetails.signers[0].key)
final hint = KeyPair.fromAccountId(signingAddress).signatureHint;
final signatureBytes = base64Decode(signatureResponse.signature);
final decoratedSig = XdrDecoratedSignature(hint, signatureBytes);
transaction.signatures.add(decoratedSig);
```

**Wrong: phone number format**

```dart
// WRONG: spaces, missing +, or missing country code
SEP30AuthMethod("phone_number", "415 555 1234");     // missing + and country code
SEP30AuthMethod("phone_number", "+1 415 555 1234");  // has spaces

// CORRECT: E.164 format — leading +, country code, digits only, no spaces
SEP30AuthMethod("phone_number", "+14155551234");
```

**Wrong: forgetting to null-check `authenticated`**

```dart
// WRONG: authenticated is bool? — direct access without null-check can throw
if (identity.authenticated) { ... }            // compile error: can't use bool? as bool
if (identity.authenticated == true) { ... }   // CORRECT: explicit comparison
// or
if (identity.authenticated ?? false) { ... }  // CORRECT: null-coalescing
```

**Wrong: forgetting to remove server signer after deleteAccount()**

```dart
// WRONG: deleting from the recovery server but leaving the signer on-chain
// The signer still exists on the Stellar account and could be misused.
await service.deleteAccount(accountId, jwt);
// (no follow-up on-chain operation)

// CORRECT: also remove the signer from the Stellar account using weight=0
final tx = TransactionBuilder(account)
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(KeyPair.fromAccountId(signerKey).xdrSignerKey, 0)
          .build(),
    )
    .build();
```

**Note: updateIdentitiesForAccount() fully replaces identities**

The PUT operation is not additive. If you have two identities and call `updateIdentitiesForAccount()` with only one, the second identity is deleted. Always include all identities you want to keep.

**Note: JWT is passed without "Bearer " prefix — the SDK adds it**

```dart
// WRONG: including the prefix yourself
await service.registerAccount(accountId, request, "Bearer eyJhbGci...");

// CORRECT: pass the raw JWT token string — the SDK adds "Bearer " to the Authorization header
await service.registerAccount(accountId, request, "eyJhbGci...");
```

---
