# SEP-30: Account Recovery

**Purpose:** Recover access to Stellar accounts when the owner loses their private key. Recovery servers act as cosigners: register your account with two or more servers, then call on them to sign a key-rotation transaction if you ever lose your private key.
**Prerequisites:** Requires JWT from SEP-10 (see `sep-10.md`) for registration and updates. Recovery (signing) uses a JWT from the server's alternate auth flow (email/phone/stellar_address).

## Table of Contents

1. [How Recovery Works](#1-how-recovery-works)
2. [Creating the Service](#2-creating-the-service)
3. [Registering an Account](#3-registering-an-account)
4. [Adding the Recovery Signers to Your Stellar Account](#4-adding-the-recovery-signers-to-your-stellar-account)
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

1. **Register**: Call `registerAccount()` on each of two recovery servers with your account address, one or more identities (role + auth methods), and your SEP-10 JWT. Each server returns a signer public key.
2. **Add Signers**: Add both servers' signer keys to your Stellar account via `SetOptionsOperationBuilder` with weight 1 each, give your own key weight 2 and set the thresholds to 2. No server alone can control the account; both together can sign a recovery.
3. **Recovery**: If you lose your key, authenticate to each recovery server through alternate means (email, phone number, or Stellar address). Each server issues a JWT proving that identity.
4. **Sign Transaction**: Build a transaction that adds your new key and removes the lost one. Call `signTransaction()` on each server with its recovery JWT and its signing address. Each server returns a base64 signature.
5. **Attach Signatures**: Decode both base64 signatures and attach them to the transaction envelope as `XdrDecoratedSignature`s.
6. **Submit**: Submit the signed transaction to Horizon to regain control.

---

## 2. Creating the Service

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Basic: service URL only
final service = SEP30RecoveryService("https://recovery.example.com");

// With custom HTTP client (timeouts, proxies, etc.)
final serviceWithClient = SEP30RecoveryService(
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
import 'package:http/http.dart' as http;

// From your app: myCustomClient (http.Client), recoveryServerUrl (String)
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

// From your app: accountId (String), jwtToken (String, the SEP-10 token)
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
// From your app: accountId (String), jwtToken (String, the SEP-10 token)
// From the section Creating the Service: service (SEP30RecoveryService)
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

## 4. Adding the Recovery Signers to Your Stellar Account

After registering with two servers, add both signer keys to an account whose only signer is its master key:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From your app: responseA (SEP30AccountResponse, registerAccount() on server A), responseB (SEP30AccountResponse, registerAccount() on server B), secretSeed (String, the account's S... seed, from secure storage)
final sdk = StellarSDK.TESTNET;
final accountKeyPair = KeyPair.fromSecretSeed(secretSeed);

// Signer keys from the registerAccount() responses of the two servers
final signerKeyA = responseA.signers[0].key;
final signerKeyB = responseB.signers[0].key;

final account = await sdk.accounts.account(accountKeyPair.accountId);
// The setup sets every threshold to 2, so any other signer would keep its weight
// against them. It accepts the master key alone; plan the quorum of an account
// with more signers separately.
final otherSigners = account.signers.where((s) => s.key != accountKeyPair.accountId);
if (otherSigners.isNotEmpty) {
  throw StateError('The account has other signers; this setup expects the master key alone');
}
final transaction = TransactionBuilder(account)
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(KeyPair.fromAccountId(signerKeyA).xdrSignerKey, 1)
          .build(),
    )
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(KeyPair.fromAccountId(signerKeyB).xdrSignerKey, 1)
          .build(),
    )
    // Your key weight 2 meets threshold 2 and signs alone; each server (weight 1)
    // stays below it; both servers together (1 + 1 = 2) sign the recovery
    .addOperation(
      SetOptionsOperationBuilder()
          .setMasterKeyWeight(2)
          .setLowThreshold(2)
          .setMediumThreshold(2)
          .setHighThreshold(2)
          .build(),
    )
    .build();

transaction.sign(accountKeyPair, Network.TESTNET);
await sdk.submitTransaction(transaction);
print("Recovery signers added.");
```

One server at weight 1 with thresholds of 1 would control the account alone, which is why this page uses two servers: neither can act alone, and together they can recover the account.

---

## 5. Signing a Recovery Transaction

When you need to recover an account, build a transaction that adds your new key and removes the lost one, then get both recovery servers to sign it.

```dart
import 'dart:convert';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From your app: accountId (String), recoveryJwtA (String, JWT from server A's alternate authentication by email or phone, not from the lost key), recoveryJwtB (String, the same from server B)
final serviceA = SEP30RecoveryService("https://recovery-a.example.com");
final serviceB = SEP30RecoveryService("https://recovery-b.example.com");
final sdk = StellarSDK.TESTNET;

// Step 1: Find each server's signing address for this account
final signingAddressA = (await serviceA.accountDetails(accountId, recoveryJwtA)).signers[0].key;
final signingAddressB = (await serviceB.accountDetails(accountId, recoveryJwtB)).signers[0].key;

// Step 2: Generate a new keypair to replace the lost key
final newKeyPair = KeyPair.random();
String newSecretSeed = newKeyPair.secretSeed; // S... new signing key: store securely before submitting, never log

// Step 3: Build the recovery transaction (uses the lost account's current sequence):
// the new key gets weight 2 and signs alone afterwards; the lost master key gets weight 0
final account = await sdk.accounts.account(accountId);
final transaction = TransactionBuilder(account)
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(newKeyPair.xdrSignerKey, 2)
          .setMasterKeyWeight(0)
          .build(),
    )
    .build();

// Step 4: Serialize to base64 XDR: this is what signTransaction() expects
final txBase64 = transaction.toEnvelopeXdrBase64();

// Step 5: Both servers sign the same transaction
SEP30SignatureResponse signatureA =
    await serviceA.signTransaction(accountId, signingAddressA, txBase64, recoveryJwtA);
SEP30SignatureResponse signatureB =
    await serviceB.signTransaction(accountId, signingAddressB, txBase64, recoveryJwtB);

// Step 6: Attach both signatures; the hint is taken from each server's signing key
final hintA = KeyPair.fromAccountId(signingAddressA).signatureHint;
transaction.signatures.add(
    XdrDecoratedSignature(hintA, XdrSignature(base64Decode(signatureA.signature))));
final hintB = KeyPair.fromAccountId(signingAddressB).signatureHint;
transaction.signatures.add(
    XdrDecoratedSignature(hintB, XdrSignature(base64Decode(signatureB.signature))));

// Both server signatures (1 + 1 = 2) meet the high threshold of the signer change
await sdk.submitTransaction(transaction);
print("Account recovered. New signer: ${newKeyPair.accountId}");
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

// From your app: accountId (String), jwtToken (String, the SEP-10 token)
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

// From your app: accountId (String), jwtToken (String, the SEP-10 token)
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

// From your app: jwtToken (String, the SEP-10 token)
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

// From your app: accountId (String), jwtToken (String, the SEP-10 token), secretSeed (String)
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

// From your app: accountId (String), jwtToken (String, the SEP-10 token)
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
// From your app: method (SEP30AuthMethod)
// Constructor
// SEP30AuthMethod(String type, String value)

// Standard types
SEP30AuthMethod("email", "person@example.com");
SEP30AuthMethod("phone_number", "+10000000001");   // E.164 format: +[country][number], no spaces
SEP30AuthMethod("stellar_address", "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV");   // G... Stellar address

// Access public fields directly
method.type;   // String
method.value;  // String
```

### SEP30RequestIdentity

Identity with a role and one or more authentication methods. The role is a client-defined label; the JSON key for auth methods is `auth_methods`.

```dart
// From your app: identity (SEP30RequestIdentity)
// Constructor
// SEP30RequestIdentity(String role, List<SEP30AuthMethod> authMethods)

identity.role;         // String
identity.authMethods;  // List<SEP30AuthMethod>
```

Common roles: `"owner"` (single user), `"sender"` / `"receiver"` (account sharing), `"other"` (additional signers with sign-only permissions).

### SEP30Request

Container for one or more identities. Serializes to `{"identities": [...]}`.

```dart
// From your app: request (SEP30Request)
// Constructor
// SEP30Request(List<SEP30RequestIdentity> identities)

request.identities;  // List<SEP30RequestIdentity>
```

### SEP30AccountResponse

Returned by `registerAccount()`, `updateIdentitiesForAccount()`, `accountDetails()`, and `deleteAccount()`.

```dart
// From your app: response (SEP30AccountResponse)
response.address;     // String — the Stellar account address
response.identities;  // List<SEP30ResponseIdentity>
response.signers;     // List<SEP30ResponseSigner>
```

### SEP30ResponseIdentity

```dart
// From your app: identity (SEP30ResponseIdentity)
identity.role;           // String? — e.g. "owner", "sender", "receiver"; null if server omits
identity.authenticated;  // bool? — true if this identity authenticated the current request,
                         // false if explicitly unauthenticated, null if server did not return the field
```

### SEP30ResponseSigner

```dart
// From your app: signer (SEP30ResponseSigner)
signer.key;  // String — G... public key to add as a signer on the Stellar account
```

### SEP30SignatureResponse

Returned by `signTransaction()`.

```dart
// From your app: response (SEP30SignatureResponse)
response.signature;         // String — base64-encoded signature bytes
response.networkPassphrase; // String — e.g. "Test SDF Network ; September 2015"
```

### SEP30AccountsResponse

Returned by `accounts()`.

```dart
// From your app: response (SEP30AccountsResponse)
response.accounts;  // List<SEP30AccountResponse>
```

---

## 12. Common Pitfalls

**Wrong: re-registering instead of updating**

```dart
// From your app: accountId (String), jwt (String)
// From the setup above: request (SEP30Request), service (SEP30RecoveryService)
// WRONG: calling registerAccount() on an already-registered account throws SEP30ConflictResponseException
await service.registerAccount(accountId, request, jwt);

// CORRECT: use updateIdentitiesForAccount() for changes to an existing registration
await service.updateIdentitiesForAccount(accountId, request, jwt);
```

**Wrong: passing the Transaction object instead of base64 XDR to signTransaction()**

```dart
// From your app: accountId (String), jwt (String)
// From the setup above: service (SEP30RecoveryService), signingAddress (String), transaction (Transaction)
// WRONG: signTransaction() expects a String, not a Transaction object
await service.signTransaction(accountId, signingAddress, transaction, jwt);

// CORRECT: serialize to base64 XDR envelope first
final txBase64 = transaction.toEnvelopeXdrBase64();
await service.signTransaction(accountId, signingAddress, txBase64, jwt);
```

**Wrong: using the account address instead of the signing address for the signature hint**

```dart
import 'dart:convert';

// From your app: accountId (String), signatureResponse (SEP30SignatureResponse)
// From the setup above: signingAddress (String), transaction (Transaction)
// WRONG: using the account address to derive the hint
final hint = KeyPair.fromAccountId(accountId).signatureHint;

// CORRECT: use the signing address (the server's signer key, from accountDetails.signers[0].key)
final hint = KeyPair.fromAccountId(signingAddress).signatureHint;
final signatureBytes = base64Decode(signatureResponse.signature);
final decoratedSig = XdrDecoratedSignature(hint, XdrSignature(signatureBytes));
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
// From your app: identity (SEP30ResponseIdentity)
// WRONG: authenticated is bool? — direct access without null-check can throw
if (identity.authenticated) { /* ... */ }            // compile error: can't use bool? as bool
if (identity.authenticated == true) { /* ... */ }   // CORRECT: explicit comparison
// or
if (identity.authenticated ?? false) { /* ... */ }  // CORRECT: null-coalescing
```

**Wrong: forgetting to remove server signer after deleteAccount()**

```dart
// From the setup above: account (AccountResponse), service (SEP30RecoveryService)
// From your app: accountId (String), jwt (String), signerKey (String)
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
// From your app: accountId (String), jwtToken (String, the SEP-10 token)
// From the setup above: request (SEP30Request), service (SEP30RecoveryService)
// WRONG: including the prefix yourself
await service.registerAccount(accountId, request, "Bearer $jwtToken");

// CORRECT: pass the raw JWT token string — the SDK adds "Bearer " to the Authorization header
await service.registerAccount(accountId, request, jwtToken);
```

---
