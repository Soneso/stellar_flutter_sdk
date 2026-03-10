# Getting Started Guide

**Looking for a quick start? See [Quick Start](quick-start.md) to get running in 15 minutes.**

This guide covers the fundamentals of the Stellar Flutter SDK.

## Table of Contents

- [Installation](#installation)
- [Basic Concepts](#basic-concepts)
- [KeyPair Management](#keypair-management)
- [Account Operations](#account-operations)
- [Transaction Building](#transaction-building)
- [Connecting to Networks](#connecting-to-networks)
- [Soroban RPC](#soroban-rpc)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Next Steps](#next-steps)

## Installation

Add the SDK to your `pubspec.yaml`:

```yaml
dependencies:
  stellar_flutter_sdk: ^3.0.3
```

Then run:

```bash
flutter pub get
```

**Requirements:** Dart SDK >=3.8.0 <4.0.0.

## Basic Concepts

### Networks

Stellar has multiple networks with unique passphrases:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Network network = Network.TESTNET;   // Development (free test XLM via Friendbot)
Network network = Network.PUBLIC;    // Production (real assets)
Network network = Network.FUTURENET; // Upcoming protocol features
```

### Accounts

Every Stellar account has:
- **Account ID** (public key): Starts with `G`. Safe to share.
- **Secret Seed** (private key): Starts with `S`. Keep secret!

An account must hold at least 1 XLM to exist (the base reserve).

### Assets

Stellar supports two types of assets:
- **Native (XLM):** The built-in currency used for fees and account reserves.
- **Issued assets:** Tokens created by any account (the "issuer"). To hold an issued asset, you must first establish a trustline to the issuer.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Native XLM
Asset xlm = Asset.NATIVE;

// Issued asset (code + issuer account)
Asset usdc = Asset.createNonNativeAsset("USDC", "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN");
```

### Operations and Transactions

A **transaction** groups one or more **operations** that execute atomically. Common operations:

- `CreateAccountOperation` — Create a new account
- `PaymentOperation` — Send assets
- `ChangeTrustOperation` — Establish a trustline
- `ManageSellOfferOperation` — Place a DEX order

## KeyPair Management

Manage cryptographic keys for signing transactions and identifying accounts.

### Generate a Random KeyPair

Create a new wallet with a random keypair. The account ID is your public address; the secret seed is your private key for signing transactions.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.random();

String accountId = keyPair.accountId;   // GCFXHS4GXL6B... (public)
String secretSeed = keyPair.secretSeed; // SAV76USXIJOB... (private)
```

### Import from Secret Seed

If you already have a secret seed (from a backup or another wallet), you can restore the full keypair. This lets you sign transactions.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Restore keypair from seed (can sign transactions)
KeyPair keyPair = KeyPair.fromSecretSeed("SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE");
```

### Import from Account ID

You can create a keypair from just an account ID (public key). This is useful for verifying signatures or specifying destinations, but you can't sign transactions without the secret seed.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Public key only (cannot sign)
KeyPair keyPair = KeyPair.fromAccountId("GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D");
```

### Mnemonic Phrases (SEP-5)

For wallet backup and recovery. The SDK supports 12, 18, or 24 word phrases:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate mnemonic — choose your preferred length:
String mnemonic = await Wallet.generate24WordsMnemonic();  // 24 words (recommended)
// or: String mnemonic = await Wallet.generate12WordsMnemonic();  // 12 words

// Store these words securely — they control all derived accounts

// Create wallet from mnemonic
Wallet wallet = await Wallet.from(mnemonic);

// Derive multiple accounts from one mnemonic
KeyPair keyPair0 = await wallet.getKeyPair(index: 0); // First account
KeyPair keyPair1 = await wallet.getKeyPair(index: 1); // Second account

// Restore from existing words
String words = "your twelve or twenty four word phrase goes here ...";
Wallet restoredWallet = await Wallet.from(words);
KeyPair keyPair = await restoredWallet.getKeyPair(index: 0);
```

## Account Operations

Create accounts, fund them, and query their data from the network.

### Fund on Testnet

On testnet, FriendBot gives you 10,000 free test XLM to experiment with. This is the easiest way to get started.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.random();
bool funded = await FriendBot.fundTestAccount(keyPair.accountId);
```

### Create Account on Public Network

On the public network, there's no FriendBot. You need an existing funded account to create new accounts using the `CreateAccountOperation`. The new account receives a starting balance from the source account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.PUBLIC;

KeyPair sourceKeyPair = KeyPair.fromSecretSeed("SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");
KeyPair newKeyPair = KeyPair.random();

// Source account must already exist and have enough XLM for the new account's starting balance + fees
AccountResponse sourceAccount = await sdk.accounts.account(sourceKeyPair.accountId);

CreateAccountOperation createOp = CreateAccountOperationBuilder(
  newKeyPair.accountId,
  "10", // Starting balance in XLM
).build();

Transaction transaction = TransactionBuilder(sourceAccount)
    .addOperation(createOp)
    .build();

transaction.sign(sourceKeyPair, Network.PUBLIC);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

if (response.success) {
  print("Account created: ${newKeyPair.accountId}");
}
```

### Query Account Data

Load an account from the network to check its balances, sequence number, and signers. Always verify an account exists before sending payments to it.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
String accountId = "GCQHNQR2VM5OPXSTWZSF7ISDLE5XZRF73LNU6EOZXFQG2IJFU4WB7VFY";

// Check if account exists
bool exists = true;
try {
  await sdk.accounts.account(accountId);
} on ErrorResponse catch (e) {
  if (e.code == 404) exists = false;
}

if (!exists) {
  print("Account not found");
  return;
}

AccountResponse account = await sdk.accounts.account(accountId);

print("Sequence: ${account.sequenceNumber}");

// List balances
for (Balance balance in account.balances) {
  if (balance.assetType == Asset.TYPE_NATIVE) {
    print("XLM: ${balance.balance}");
  } else {
    print("${balance.assetCode}: ${balance.balance}");
  }
}

// List signers
for (Signer signer in account.signers) {
  print("Signer: ${signer.key} (weight: ${signer.weight})");
}
```

## Transaction Building

Construct transactions by adding operations, setting fees, and preparing for submission.

### Builder Pattern

Transactions are built using a fluent builder pattern:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// sourceAccount loaded via await sdk.accounts.account(...)
// operation1, operation2 built via operation builders (see below)

Transaction transaction = TransactionBuilder(sourceAccount)
    .addOperation(operation1)
    .addOperation(operation2)
    .addMemo(Memo.text("Payment reference"))
    .setMaxOperationFee(200) // 200 stroops per operation
    .build();
```

### Building Operations

Each operation type has its own builder class. Build the operations first, then add them to the transaction. Operations execute in order.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Build operations
PaymentOperation paymentOp = PaymentOperationBuilder(
  "GDESTINATION...",
  Asset.NATIVE,
  "100.50",
).build();

ChangeTrustOperation trustOp = ChangeTrustOperationBuilder(
  Asset.createNonNativeAsset("USD", "GISSUER..."),
).build();

// Add operations to transaction
Transaction transaction = TransactionBuilder(sourceAccount)
    .addOperation(trustOp)    // First: establish trustline
    .addOperation(paymentOp)  // Then: send payment
    .build();
```

### Signing and Submitting

Transactions need a valid signature before the network accepts them. The signature proves the source account authorized the transaction. Use the correct network passphrase when signing—testnet and public have different passphrases, and a mismatch causes the transaction to fail.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// After building a transaction, sign it with the source account's keypair
// Use the correct network — testnet and public have different passphrases!
transaction.sign(sourceKeyPair, Network.TESTNET);

// Multi-sig accounts: add signatures from all required signers
// transaction.sign(keyPairA, Network.TESTNET);
// transaction.sign(keyPairB, Network.TESTNET);

// Submit to the network
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

if (response.success) {
  print("Hash: ${response.hash}");
}
```

### Complete Payment Example

Here's a full example that sends 100 XLM on testnet. It loads the sender's account, builds a payment, signs it, and submits to the network.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

KeyPair senderKeyPair = KeyPair.fromSecretSeed("SA52PD5FN425CUONRMMX2CY5HB6I473A5OYNIVU67INROUZ6W4SPHXZB");
String destination = "GCRFFUKMUWWBRIA6ABRDFL5NKO6CKDB2IOX7MOS2TRLXNXQD255Z2MYG";

AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);

PaymentOperation paymentOp = PaymentOperationBuilder(destination, Asset.NATIVE, "100").build();

Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(paymentOp)
    .addMemo(Memo.text("Coffee payment"))
    .build();

transaction.sign(senderKeyPair, Network.TESTNET);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

if (response.success) {
  print("Payment sent! Hash: ${response.hash}");
}
```

## Connecting to Networks

The SDK connects to Horizon servers to query account data and submit transactions. Use testnet for development, public network for production.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Testnet (https://horizon-testnet.stellar.org)
StellarSDK sdk = StellarSDK.TESTNET;

// Public network (https://horizon.stellar.org)
StellarSDK sdk = StellarSDK.PUBLIC;

// Custom Horizon server
StellarSDK sdk = StellarSDK("https://horizon.your-company.com");
```

## Soroban RPC

Soroban is Stellar's smart contract platform. To interact with smart contracts, you connect to a Soroban RPC server instead of Horizon.

### Connecting to Soroban RPC

Create a `SorobanServer` instance to interact with the Soroban RPC endpoint.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Testnet
SorobanServer server = SorobanServer("https://soroban-testnet.stellar.org");

// Mainnet
SorobanServer server = SorobanServer("https://soroban.stellar.org");
```

### Health Check

Check if the Soroban RPC server is running and see which ledger range it has available.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer("https://soroban-testnet.stellar.org");

GetHealthResponse health = await server.getHealth();

if (health.status == GetHealthResponse.HEALTHY) {
  print("Server is healthy");
  print("Latest ledger: ${health.latestLedger}");
  print("Oldest ledger: ${health.oldestLedger}");
}
```

### Latest Ledger Info

Get the current ledger sequence and protocol version. Useful for checking network status.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer("https://soroban-testnet.stellar.org");

GetLatestLedgerResponse ledger = await server.getLatestLedger();

print("Ledger sequence: ${ledger.sequence}");
print("Protocol version: ${ledger.protocolVersion}");
```

### Smart Contract Interaction

For deploying contracts, invoking functions, and handling Soroban transactions, see the [Soroban Guide](soroban.md).

## Error Handling

### Horizon Request Errors

Network requests can fail for many reasons — invalid account IDs, network issues, or server errors. Catch `ErrorResponse` to handle these gracefully.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

try {
  AccountResponse account = await sdk.accounts.account("GINVALIDACCOUNTID");
} on ErrorResponse catch (e) {
  print("HTTP Status: ${e.code}");
  print("Error: ${e.body}");
}
```

### Transaction Failures

When a transaction fails, the response contains result codes explaining what went wrong — both at the transaction level and for each operation.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
if (response.success) {
  print("Success!");
} else {
  String? txCode = response.extras?.resultCodes?.transactionResultCode;
  List<String?>? opCodes = response.extras?.resultCodes?.operationsResultCodes;
  print("Transaction: ${txCode ?? 'unknown'}");
  if (opCodes != null) {
    for (int i = 0; i < opCodes.length; i++) {
      print("Operation $i: ${opCodes[i]}");
    }
  }
}
```

### Common Error Codes

| Code | Meaning |
|------|---------|
| `tx_bad_seq` | Wrong sequence number. Reload account and retry. |
| `tx_insufficient_fee` | Fee too low. Increase `setMaxOperationFee()`. |
| `tx_insufficient_balance` | Not enough XLM for operation + fees + reserves. |
| `op_underfunded` | Source lacks funds for payment amount. |
| `op_no_trust` | Destination lacks trustline for asset. |
| `op_line_full` | Destination trustline limit exceeded. |
| `op_no_destination` | Destination account doesn't exist. |

## Best Practices

**1. Never expose secret seeds**
```dart
// Bad
print("Error with account: ${keyPair.secretSeed}");

// Good
print("Error with account: ${keyPair.accountId}");
```

**2. Use testnet for development** — Always test against testnet first.

**3. Set appropriate fees**
```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

FeeStatsResponse feeStats = await sdk.feeStats.execute();
String recommendedFee = feeStats.lastLedgerBaseFee;
```

**4. Handle errors gracefully** — Wrap network operations in try-catch.

**5. Verify destination exists** — Before payments, check if account exists. If not, use `CreateAccountOperation`.

**6. Use memos for exchanges** — Many exchanges require a memo to credit your account.

## Next Steps

- **[Quick Start](quick-start.md)** — First transaction in 15 minutes
- **[SDK Usage](sdk-usage.md)** — All operations, queries, and patterns
- **[SEP Protocols](sep/README.md)** — Authentication, deposits, cross-border payments
- **[Soroban Guide](soroban.md)** — Smart contract interaction

---

**Navigation**: [← Quick Start](quick-start.md) | [SDK Usage →](sdk-usage.md)
