# Quick Start Guide

Get your first Stellar transaction running in 15 minutes. This guide covers the essentials to start using the Flutter SDK.

## What You'll Build

By the end of this guide, you'll:
- Generate a Stellar keypair (wallet)
- Fund an account on testnet
- Send your first payment transaction

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

**Requirements:** Dart SDK >=3.8.0 <4.0.0. See [Getting Started](getting-started.md) for full requirements.

## Your First KeyPair

Generate a random Stellar wallet:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate a new random keypair
KeyPair keyPair = KeyPair.random();

print("Account ID: ${keyPair.accountId}");
print("Secret Seed: ${keyPair.secretSeed}");

// Example output:
// Account ID: GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB
// Secret Seed: SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7
```

**Keep the secret seed safe** — it controls your account!

## Creating Accounts

New Stellar accounts need at least 1 XLM to exist. On testnet, FriendBot gives you 10,000 free test XLM:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate a new keypair
KeyPair keyPair = KeyPair.random();

// Fund on testnet (10,000 test XLM)
bool funded = await FriendBot.fundTestAccount(keyPair.accountId);

if (funded) {
  print("Account funded: ${keyPair.accountId}");
}
```

> **Public network:** FriendBot only works on testnet. On the public network, you need an existing funded account to create new accounts using a `CreateAccountOperation`. See [Getting Started](getting-started.md#create-account-on-public-network) for details.

## Your First Transaction

Send a payment on the Stellar testnet:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Connect to testnet
StellarSDK sdk = StellarSDK.TESTNET;

// Your funded account (replace with your secret seed)
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SXXX...");
String destinationId = "GYYY..."; // Recipient address

// Load current account state from network
AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);

// Build payment operation
PaymentOperation paymentOp = PaymentOperationBuilder(
  destinationId,
  Asset.NATIVE,
  "10", // Amount in XLM
).build();

// Build and sign transaction
Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(paymentOp)
    .build();

transaction.sign(senderKeyPair, Network.TESTNET);

// Submit to network
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

if (response.success) {
  print("Payment sent! Hash: ${response.hash}");
}
```

## Complete Example

Here's everything together — two accounts, one payment:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() async {
  // 1. Generate two keypairs
  KeyPair alice = KeyPair.random();
  KeyPair bob = KeyPair.random();

  print("Alice: ${alice.accountId}");
  print("Bob: ${bob.accountId}");

  // 2. Fund both accounts on testnet
  await FriendBot.fundTestAccount(alice.accountId);
  await FriendBot.fundTestAccount(bob.accountId);

  print("Accounts funded!");

  // 3. Connect to testnet
  StellarSDK sdk = StellarSDK.TESTNET;

  // 4. Load Alice's account
  AccountResponse aliceAccount = await sdk.accounts.account(alice.accountId);

  // 5. Build payment: Alice sends 100 XLM to Bob
  PaymentOperation paymentOp = PaymentOperationBuilder(
    bob.accountId,
    Asset.NATIVE,
    "100",
  ).build();

  Transaction transaction = TransactionBuilder(aliceAccount)
      .addOperation(paymentOp)
      .build();

  // 6. Sign with Alice's key
  transaction.sign(alice, Network.TESTNET);

  // 7. Submit to network
  SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

  if (response.success) {
    print("Payment successful! Transaction: ${response.hash}");
  } else {
    print("Payment failed.");
  }

  // 8. Check Bob's new balance
  AccountResponse bobAccount = await sdk.accounts.account(bob.accountId);
  for (Balance balance in bobAccount.balances) {
    if (balance.assetType == Asset.TYPE_NATIVE) {
      print("Bob's balance: ${balance.balance} XLM");
    }
  }
}
```

Run this code and you'll see Bob receive 100 XLM from Alice.

## Next Steps

You've created wallets and sent your first Stellar payment.

**Learn more:**
- **[Getting Started Guide](getting-started.md)** — Installation details, error handling, best practices
- **[SDK Usage](sdk-usage.md)** — All SDK features organized by use case
- **[Soroban Guide](soroban.md)** — Smart contract development
- **[SEP Protocols](sep/README.md)** — Stellar Ecosystem Proposals (authentication, deposits, KYC)

**Testnet vs Public Net:**
This guide uses testnet. For production, replace:
- `StellarSDK.TESTNET` → `StellarSDK.PUBLIC`
- `Network.TESTNET` → `Network.PUBLIC`

---

**Navigation:** [← Documentation Home](README.md) | [Getting Started →](getting-started.md)
