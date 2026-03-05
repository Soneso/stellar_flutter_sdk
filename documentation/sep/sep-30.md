# SEP-30: Account Recovery

SEP-30 defines a protocol for recovering access to Stellar accounts when the owner loses their private key. Recovery servers act as additional signers on an account, allowing the user to regain control by proving their identity through alternate methods like email, phone, or another Stellar address.

Use SEP-30 when:
- Building a wallet with account recovery features
- You want to protect users from permanent key loss
- Implementing shared account access between multiple parties
- Setting up multi-device account access with recovery options

See the [SEP-30 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md) for protocol details.

## How Recovery Works

1. **Registration**: Register your account with a recovery server, providing identity information with authentication methods
2. **Add Signer**: Add the server's signer key to your Stellar account with appropriate weight
3. **Recovery**: If you lose your key, authenticate with the recovery server via alternate methods (email, phone, etc.)
4. **Sign Transaction**: The server signs a transaction that adds your new key to the account
5. **Submit**: Submit the signed transaction to the Stellar network to regain control

## Quick Example

This example shows the basic flow: register an account with a recovery server, then add the returned signer key to your Stellar account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Connect to recovery server
final service = SEP30RecoveryService("https://recovery.example.com");

// Set up identity with authentication methods
final authMethods = [
  SEP30AuthMethod("email", "user@example.com"),
  SEP30AuthMethod("phone_number", "+14155551234"),
];
final identity = SEP30RequestIdentity("owner", authMethods);

// Register account with recovery server (requires SEP-10 JWT)
final request = SEP30Request([identity]);
SEP30AccountResponse response =
    await service.registerAccount(accountId, request, jwtToken);

// Get the signer key to add to your account
final signerKey = response.signers[0].key;
print("Add this signer to your account: $signerKey");
```

## Creating the Recovery Service

The `SEP30RecoveryService` class is the main entry point for all SEP-30 operations. Create an instance by providing the recovery server's base URL.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

// Basic usage - create service with recovery server URL
final service = SEP30RecoveryService("https://recovery.example.com");

// Advanced usage - provide a custom HTTP client for timeouts, proxies, etc.
final service2 = SEP30RecoveryService(
  "https://recovery.example.com",
  httpClient: http.Client(),
  httpRequestHeaders: {'X-Custom-Header': 'value'},
);
```

The `httpClient` can also be set directly after construction:

```dart
final service = SEP30RecoveryService("https://recovery.example.com");
service.httpClient = myCustomClient;
```

## Registering an Account

Before your account can be recovered, you must register it with one or more recovery servers. Registration requires a SEP-10 JWT token proving you control the account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

// Define how the user can prove their identity during recovery.
// Multiple authentication methods provide fallback options.
final authMethods = [
  SEP30AuthMethod("stellar_address", "GXXXX..."), // SEP-10 auth (highest security)
  SEP30AuthMethod("email", "user@example.com"),
  SEP30AuthMethod("phone_number", "+14155551234"), // E.164 format required
];

// Create identity with role "owner" - roles are client-defined labels
// that help users understand their relationship to the account.
final identity = SEP30RequestIdentity("owner", authMethods);

// Register with the recovery server
final request = SEP30Request([identity]);
SEP30AccountResponse response =
    await service.registerAccount(accountId, request, jwtToken);

// The response includes signer keys to add to your Stellar account.
// Signers are ordered from most recently added to least recently added.
print("Account address: ${response.address}");
for (final signer in response.signers) {
  print("Signer key: ${signer.key}");
}
for (final identity in response.identities) {
  print("Identity role: ${identity.role ?? 'unspecified'}");
}
```

### Adding the Recovery Signer to Your Account

After registration, you must add the recovery server's signer key to your Stellar account. Configure account thresholds so the recovery server cannot unilaterally control your account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final sdk = StellarSDK.TESTNET;

final accountKeyPair = KeyPair.fromSecretSeed("SXXXXXX...");
final accountId = accountKeyPair.accountId;
final account = await sdk.accounts.account(accountId);

// Add recovery server as a signer with weight 1.
// The signer key comes from the registration response.
final signerKey = response.signers[0].key;

final transaction = TransactionBuilder(account)
    // Add the recovery signer
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(KeyPair.fromAccountId(signerKey).xdrSignerKey, 1)
          .build(),
    )
    // Set thresholds so recovery requires multiple signers.
    // With threshold=2, both your key (weight 10) and recovery server (weight 1)
    // together can meet threshold, but recovery server alone cannot.
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

print("Recovery signer added to account");
```

## Multi-Server Recovery

For better security, register with multiple recovery servers so no single server has full control. Each server provides a signer key with weight 1, and the account threshold is set to require cooperation from multiple servers.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create identity (reused for both servers)
final authMethods = [SEP30AuthMethod("email", "user@example.com")];
final identity = SEP30RequestIdentity("owner", authMethods);
final request = SEP30Request([identity]);

// Register with first recovery server
final service1 = SEP30RecoveryService("https://recovery1.example.com");
SEP30AccountResponse response1 =
    await service1.registerAccount(accountId, request, jwtToken1);
final signerKey1 = response1.signers[0].key;

// Register with second recovery server
final service2 = SEP30RecoveryService("https://recovery2.example.com");
SEP30AccountResponse response2 =
    await service2.registerAccount(accountId, request, jwtToken2);
final signerKey2 = response2.signers[0].key;

// Add both signers to your account with combined weight
final sdk = StellarSDK.TESTNET;
final accountKeyPair = KeyPair.fromSecretSeed("SXXXXXX...");
final account = await sdk.accounts.account(accountId);

final transaction = TransactionBuilder(account)
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(KeyPair.fromAccountId(signerKey1).xdrSignerKey, 1)
          .build(),
    )
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(KeyPair.fromAccountId(signerKey2).xdrSignerKey, 1)
          .build(),
    )
    // Set threshold to 2, requiring both recovery servers to sign
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

print("Multi-server recovery configured");
```

## Recovering an Account

When you lose your private key, authenticate with the recovery server using one of your registered authentication methods (email, phone, etc.) to get a JWT. Then request the server to sign a transaction that adds your new key.

```dart
import 'dart:convert';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

// Get account details to find the signing address.
// The JWT here proves your identity via alternate auth (email/phone).
final accountDetails =
    await service.accountDetails(accountId, recoveryJwt);
final signingAddress = accountDetails.signers[0].key;

// Generate a new keypair for the recovered account
final newKeyPair = KeyPair.random();

// Build a transaction to add the new key with high weight
final sdk = StellarSDK.TESTNET;
final account = await sdk.accounts.account(accountId);

final operation = SetOptionsOperationBuilder()
    .setSigner(newKeyPair.xdrSignerKey, 10) // High weight to regain control
    .build();

final transaction = TransactionBuilder(account)
    .addOperation(operation)
    .build();

// Get the recovery server to sign the transaction
final txBase64 = transaction.toEnvelopeXdrBase64();
SEP30SignatureResponse signatureResponse = await service.signTransaction(
  accountId,
  signingAddress,
  txBase64,
  recoveryJwt, // JWT proving identity via alternate auth
);

// Add the server's signature to the transaction.
// Create the hint from the signing address (last 4 bytes of public key).
final signerKeyPair = KeyPair.fromAccountId(signingAddress);
final hint = signerKeyPair.signatureHint;
final signatureBytes = base64Decode(signatureResponse.signature);
final decoratedSignature =
    XdrDecoratedSignature(hint, XdrSignature(signatureBytes));
transaction.signatures.add(decoratedSignature);

// For multi-server recovery, repeat the signing process with each server
// and add all signatures before submitting.

// Submit the signed transaction
await sdk.submitTransaction(transaction);

print("Account recovered! New key: ${newKeyPair.secretSeed}");
print("Store this seed securely!");
```

## Updating Identity Information

Update authentication methods for a registered account. This completely replaces all existing identities - identities not included in the request will be removed.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

// New auth methods completely replace existing ones.
// Use this to add new methods, remove compromised ones, or update contact info.
final newAuthMethods = [
  SEP30AuthMethod("email", "newemail@example.com"),
  SEP30AuthMethod("phone_number", "+14155559999"),
  SEP30AuthMethod("stellar_address", "GNEWADDRESS..."),
];
final identity = SEP30RequestIdentity("owner", newAuthMethods);

final request = SEP30Request([identity]);
SEP30AccountResponse response =
    await service.updateIdentitiesForAccount(accountId, request, jwtToken);

print("Identities updated successfully");
for (final identity in response.identities) {
  print("Role: ${identity.role ?? 'unspecified'}");
}
```

## Shared Account Access

SEP-30 supports multiple parties sharing access to an account. Each party has their own identity with a unique role, allowing both to recover the account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

// Primary owner - can recover the account
final ownerAuth = [
  SEP30AuthMethod("email", "owner@example.com"),
  SEP30AuthMethod("phone_number", "+14155551111"),
];
final ownerIdentity = SEP30RequestIdentity("sender", ownerAuth);

// Shared user - can also recover the account
final receiverAuth = [
  SEP30AuthMethod("email", "partner@example.com"),
  SEP30AuthMethod("phone_number", "+14155552222"),
];
final receiverIdentity = SEP30RequestIdentity("receiver", receiverAuth);

// Register both identities - either party can initiate recovery
final request = SEP30Request([ownerIdentity, receiverIdentity]);
SEP30AccountResponse response =
    await service.registerAccount(accountId, request, jwtToken);

print("Shared account registered");
print("Both 'sender' and 'receiver' can now recover this account");
```

## Getting Account Details

Check registration status, view current signers, and see which identity is currently authenticated. Use this to monitor for key rotation and verify your recovery setup.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

SEP30AccountResponse response =
    await service.accountDetails(accountId, jwtToken);

print("Account: ${response.address}");

print("\nIdentities:");
for (final identity in response.identities) {
  final authStatus =
      identity.authenticated == true ? " (authenticated)" : "";
  print("  Role: ${identity.role ?? 'unspecified'}$authStatus");
}

print("\nSigners (ordered most recent first):");
for (final signer in response.signers) {
  print("  Key: ${signer.key}");
}

// Best practice: periodically check for new signers and update your account
// to use the most recent one (key rotation)
final latestSigner = response.signers[0].key;
print("\nLatest signer for key rotation: $latestSigner");
```

## Listing Registered Accounts

List all accounts accessible by the authenticated identity. This is useful for identity providers or users managing multiple accounts. Results are paginated using cursor-based pagination.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

// Get first page of accounts
SEP30AccountsResponse response = await service.accounts(jwtToken);

print("Found ${response.accounts.length} accounts:");
for (final account in response.accounts) {
  print("  Address: ${account.address}");
  for (final identity in account.identities) {
    final auth = identity.authenticated == true ? " (you)" : "";
    final role = identity.role ?? "(unspecified)";
    print("    Role: $role$auth");
  }
}

// Pagination: use the last account address as cursor for next page
if (response.accounts.isNotEmpty) {
  final lastAddress = response.accounts.last.address;
  SEP30AccountsResponse nextPage =
      await service.accounts(jwtToken, after: lastAddress);

  if (nextPage.accounts.isNotEmpty) {
    print("\nNext page has ${nextPage.accounts.length} more accounts");
  }
}
```

## Deleting Registration

Remove your account from the recovery server. This operation is **irrecoverable** - once deleted, you cannot recover the account through this server. Remember to also remove the server's signer from your Stellar account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

// Get the signer key before deletion so we can remove it from the account
final details = await service.accountDetails(accountId, jwtToken);
final signerToRemove = details.signers[0].key;

// Delete registration from recovery server
SEP30AccountResponse response =
    await service.deleteAccount(accountId, jwtToken);
print("Account deleted from recovery server");

// Important: also remove the server's signer from your Stellar account
final sdk = StellarSDK.TESTNET;
final accountKeyPair = KeyPair.fromSecretSeed("SXXXXXX...");
final account = await sdk.accounts.account(accountId);

final transaction = TransactionBuilder(account)
    .addOperation(
      SetOptionsOperationBuilder()
          .setSigner(
            KeyPair.fromAccountId(signerToRemove).xdrSignerKey,
            0, // Weight 0 removes the signer
          )
          .build(),
    )
    .build();

transaction.sign(accountKeyPair, Network.TESTNET);
await sdk.submitTransaction(transaction);

print("Recovery signer removed from Stellar account");
```

## Error Handling

The SDK throws specific exceptions for different error conditions. Handle these appropriately in your application.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = SEP30RecoveryService("https://recovery.example.com");

try {
  final authMethods = [SEP30AuthMethod("email", "user@example.com")];
  final identity = SEP30RequestIdentity("owner", authMethods);
  final request = SEP30Request([identity]);

  SEP30AccountResponse response =
      await service.registerAccount(accountId, request, jwtToken);
  print("Registration successful!");

} on SEP30BadRequestResponseException catch (e) {
  // HTTP 400 - Invalid request data, malformed JSON, invalid auth methods,
  // or transaction contains unauthorized operations (for signing)
  print("Bad request: ${e.error}");

} on SEP30UnauthorizedResponseException catch (e) {
  // HTTP 401 - JWT token missing, invalid, expired, or doesn't prove
  // ownership of the account
  print("Unauthorized: ${e.error}");
  print("Please obtain a valid SEP-10 JWT token");

} on SEP30NotFoundResponseException catch (e) {
  // HTTP 404 - Account not registered, signing address not recognized,
  // or authenticated identity doesn't have access
  print("Not found: ${e.error}");

} on SEP30ConflictResponseException catch (e) {
  // HTTP 409 - Account already registered (for registration),
  // or update conflicts with server state
  print("Conflict: ${e.error}");
  print("Account may already be registered. Try updateIdentitiesForAccount() instead.");

} on SEP30UnknownResponseException catch (e) {
  // Other HTTP errors (5xx, etc.) - server issues, unexpected responses
  print("Unexpected error (${e.code}): ${e.body}");

} catch (e) {
  // Network or HTTP client errors - connection refused, timeout, etc.
  print("Network error: $e");
}
```

## Authentication Methods

SEP-30 defines three standard authentication types. Recovery servers may also support custom types.

| Type | Format | Example | Security Notes |
|------|--------|---------|----------------|
| `stellar_address` | G... public key | `GDUAB...` | Highest security - requires SEP-10 cryptographic proof |
| `phone_number` | E.164 format with + | `+14155551234` | Vulnerable to SIM swapping attacks |
| `email` | Standard email | `user@example.com` | Security depends on email provider |

### Phone Number Format

Phone numbers must follow ITU-T E.164 international format:
- Include country code with leading `+`
- No spaces or formatting
- Example: `+14155551234` (not `+1 415 555 1234` or `(415) 555-1234`)

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Correct E.164 format
final phoneAuth = SEP30AuthMethod("phone_number", "+14155551234");

// These formats are INCORRECT and may fail:
// "+1 415 555 1234"  (has spaces)
// "(415) 555-1234"   (missing country code, has formatting)
// "4155551234"       (missing + and country code)
```

## Identity Roles

Roles are client-defined labels stored by the server and returned in responses. They help users understand their relationship to an account but are not validated or enforced by the server.

Common role patterns:

| Role | Use Case |
|------|----------|
| `owner` | Single-user recovery - the account owner |
| `sender` | Account sharing - the person sharing the account |
| `receiver` | Account sharing - the person receiving shared access |
| `device` | Multi-device access - represents a specific device |
| `backup` | Backup identity with alternate authentication |

## Security Considerations

### Multi-Server Setup
- Use 2+ recovery servers with account threshold set to require multiple signatures
- No single server should have enough weight to unilaterally control the account
- Example: Each server weight=1, threshold=2

### Signer Weights and Thresholds
- Give each recovery server weight=1
- Set account thresholds to require multiple signers (e.g., threshold=2 for two servers)
- Your own key should have higher weight (e.g., weight=10) for normal operations

### Authentication Security
- `stellar_address` provides cryptographic proof via SEP-10 (strongest)
- Phone numbers are vulnerable to SIM swapping - evaluate risk for high-value accounts
- Email security depends on your email provider

### Key Rotation
- Recovery servers may rotate their signing keys over time
- Periodically check `accountDetails()` for new signers
- Update your account to use the most recent signer (first in the array)
- Old signers remain valid until explicitly removed

### General Best Practices
- Always use HTTPS for recovery server communication
- Store JWT tokens securely and never log them
- After deleting registration, remove the signer from your Stellar account
- Test your recovery setup before you actually need it

## Related SEPs

- [SEP-10](sep-10.md) - Web Authentication (required for `stellar_address` auth method and registration)

## Further Reading

- [SDK test cases](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/integration/sep0030_test.dart) - Complete examples of SEP-30 operations

## SDK Classes Reference

| Class | Description |
|-------|-------------|
| `SEP30RecoveryService` | Main service class for all SEP-30 operations |
| `SEP30Request` | Request containing identities for registration/update |
| `SEP30RequestIdentity` | Identity with role and authentication methods |
| `SEP30AuthMethod` | Single authentication method (type and value) |
| `SEP30AccountResponse` | Response with account address, identities, and signers |
| `SEP30AccountsResponse` | Response containing list of accounts (pagination) |
| `SEP30SignatureResponse` | Response with signature and network passphrase |
| `SEP30ResponseIdentity` | Identity in response with role and authenticated flag |
| `SEP30ResponseSigner` | Signer key in response |
| `SEP30BadRequestResponseException` | HTTP 400 error |
| `SEP30UnauthorizedResponseException` | HTTP 401 error |
| `SEP30NotFoundResponseException` | HTTP 404 error |
| `SEP30ConflictResponseException` | HTTP 409 error |
| `SEP30UnknownResponseException` | Other HTTP errors |

---

[Back to SEP Overview](README.md)
