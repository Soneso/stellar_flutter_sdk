# SDK Usage Guide

This guide covers SDK features organized by use case. For detailed method signatures, see the [DartDoc API Reference](https://pub.dev/documentation/stellar_flutter_sdk/latest/).

## Table of Contents

- [Keypairs & Accounts](#keypairs--accounts)
- [Building Transactions](#building-transactions)
- [Operations](#operations)
- [Querying Horizon Data](#querying-horizon-data)
- [Streaming (SSE)](#streaming-sse)
- [Network Communication](#network-communication)
- [Assets](#assets)
- [Soroban (Smart Contracts)](#soroban-smart-contracts)

---

## Keypairs & Accounts

### Creating Keypairs

Every Stellar account has a keypair: a public key (the account ID, starts with G) and a secret seed (starts with S). The secret seed signs transactions; keep it secure and never share it.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate new random keypair
KeyPair keyPair = KeyPair.random();
print(keyPair.accountId);   // G... public key
print(keyPair.secretSeed);  // S... secret seed

// Create from existing secret seed
KeyPair keyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34JFD6XVEAEPTBED53FETV");

// Create public-key-only keypair (cannot sign)
KeyPair publicOnly = KeyPair.fromAccountId("GABC123...");
```

### Loading an Account

Load an account from the network to check its balances, sequence number, and other data. The sequence number is required when building transactions.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Load account data from network
AccountResponse account = await sdk.accounts.account("GABC123...");
print("Sequence: ${account.sequenceNumber}");

// Check balances
for (Balance balance in account.balances) {
  if (balance.assetType == Asset.TYPE_NATIVE) {
    print("XLM: ${balance.balance}");
  } else {
    print("${balance.assetCode}: ${balance.balance}");
  }
}

// Check if account exists (no built-in helper -- use try/catch)
bool exists = true;
try {
  await sdk.accounts.account("GABC123...");
} on ErrorResponse catch (e) {
  if (e.code == 404) exists = false;
}
```

### Funding Testnet Accounts

FriendBot is a testnet service that funds new accounts with 10,000 test XLM. Only works on testnet; on mainnet you need an existing funded account to create new ones.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.random();
await FriendBot.fundTestAccount(keyPair.accountId);
```

### HD Wallets (SEP-5)

Derive multiple Stellar accounts from a single mnemonic phrase. Follows BIP-39 and SLIP-0010 standards, so the same phrase always produces the same accounts.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate 24-word mnemonic
String mnemonic = await Wallet.generate24WordsMnemonic();
print(mnemonic);

// Create wallet from existing words
Wallet wallet = await Wallet.from("cable spray genius state float ...");

// Derive keypairs: m/44'/148'/{index}'
KeyPair account0 = await wallet.getKeyPair(index: 0);
KeyPair account1 = await wallet.getKeyPair(index: 1);
```

With an optional BIP-39 passphrase, the same mnemonic produces completely different accounts. The passphrase acts as a second factor: someone with only the mnemonic words can't access these accounts.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create wallet from existing words with passphrase
Wallet wallet = await Wallet.from(
  "cable spray genius state float ...",
  passphrase: "my-secret-passphrase",
);

// Derive with passphrase - produces completely different accounts than without
KeyPair account0 = await wallet.getKeyPair(index: 0);
KeyPair account1 = await wallet.getKeyPair(index: 1);

// Without the exact passphrase, you get different (wrong) accounts
// Keep both the mnemonic AND the passphrase safe
```

### Muxed Accounts

Muxed accounts let multiple virtual users share one Stellar account. Useful for exchanges and payment processors that need to track many users without creating separate accounts for each. The muxed address (M...) encodes both the base account and a 64-bit user ID.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create muxed account from base account + ID
MuxedAccount muxedAccount = MuxedAccount("GABC...", BigInt.from(123456789));

print(muxedAccount.accountId);         // M... address
print(muxedAccount.id);                // 123456789
print(muxedAccount.ed25519AccountId);  // GABC... (base account)

// Parse existing muxed address
MuxedAccount? muxed = MuxedAccount.fromAccountId("MABC...");
print(muxed?.accountId);         // M... address
print(muxed?.ed25519AccountId);  // Underlying G... address
print(muxed?.id);                // The 64-bit ID

// Use in payments
PaymentOperationBuilder paymentBuilder =
    PaymentOperationBuilder(muxedAccount.accountId, Asset.NATIVE, "100");
Operation paymentOp = paymentBuilder.build();
```

### Connecting to Networks

Stellar has multiple networks, each with its own Horizon server and network passphrase. Use testnet for development, public for production. The network passphrase is used when signing transactions.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Testnet (development and testing)
StellarSDK sdk = StellarSDK.TESTNET;
Network network = Network.TESTNET;

// Public network (production)
StellarSDK sdk = StellarSDK.PUBLIC;
Network network = Network.PUBLIC;

// Futurenet (preview upcoming features)
StellarSDK sdk = StellarSDK.FUTURENET;
Network network = Network.FUTURENET;

// Custom Horizon server
StellarSDK sdk = StellarSDK("https://my-horizon-server.example.com");
```

---

## Building Transactions

Transactions group one or more operations together. All operations in a transaction execute atomically: either all succeed or all fail. Every transaction needs a source account (which pays the fee) and must be signed before submission.

### Simple Payments

The most common transaction: send XLM or another asset from one account to another.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

KeyPair senderKeyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34JFD6XVEAEPTBED53FETV");
AccountResponse sender = await sdk.accounts.account(senderKeyPair.accountId);

// Build payment
PaymentOperation paymentOp = PaymentOperationBuilder(
  "GDEST...",     // destination account
  Asset.NATIVE,   // asset (XLM)
  "100.50",       // amount
).build();

// Build, sign, submit
Transaction transaction = TransactionBuilder(sender)
    .addOperation(paymentOp)
    .build();

transaction.sign(senderKeyPair, Network.TESTNET);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

if (response.success) {
  print("Payment sent! Hash: ${response.hash}");
}
```

### Multi-Operation Transactions

Bundle multiple operations into one transaction. This example creates an account, sets up a trustline, and sends an initial payment, all in one atomic transaction. If any operation fails, the entire transaction is rolled back.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

KeyPair funderKeyPair = KeyPair.fromSecretSeed("SFUNDER...");
KeyPair newAccountKeyPair = KeyPair.random();
String newAccountId = newAccountKeyPair.accountId;

AccountResponse funder = await sdk.accounts.account(funderKeyPair.accountId);

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// 1. Create the new account
CreateAccountOperation createAccountOp = CreateAccountOperationBuilder(
  newAccountId, // destination
  "5",          // starting balance in XLM
).build();

// 2. Establish trustline for USD
// The new account must be the source (not the funder) because trustlines
// are created by the account that wants to hold the asset
ChangeTrustOperation trustlineOp = ChangeTrustOperationBuilder(
  usdAsset, // asset to trust
  "10000",  // limit
)
    .setSourceAccount(newAccountId)
    .build();

// 3. Send initial USD to new account
PaymentOperation paymentOp = PaymentOperationBuilder(
  newAccountId, // destination
  usdAsset,     // asset
  "100",        // amount
).build();

// Build transaction with all operations
Transaction transaction = TransactionBuilder(funder)
    .addOperation(createAccountOp)
    .addOperation(trustlineOp)
    .addOperation(paymentOp)
    .build();

// Both accounts must sign:
// - Funder: transaction source (pays fees) + creates account + sends payment
// - New account: source of the trustline operation
transaction.sign(funderKeyPair, Network.TESTNET);
transaction.sign(newAccountKeyPair, Network.TESTNET);

// Submit to network
await sdk.submitTransaction(transaction);
```

### Memos, Time Bounds, and Fees

Memos attach data to transactions (payment references, user IDs). Time bounds limit when a transaction is valid, preventing old signed transactions from being submitted later. Fees are paid in stroops (1 XLM = 10,000,000 stroops).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Add memo
Transaction transaction = TransactionBuilder(account)
    .addOperation(operation)
    .addMemo(Memo.text("Payment for invoice #1234"))
    .build();

// Memo types: Memo.text(), Memo.id(), Memo.hash(), Memo.returnHash()

// Time bounds (valid for next 5 minutes)
int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
TimeBounds timeBounds = TimeBounds(now, now + 300);
Transaction transaction = TransactionBuilder(account)
    .addOperation(operation)
    .addTimeBounds(timeBounds)
    .build();

// Custom fee (stroops per operation, default 100)
Transaction transaction = TransactionBuilder(account)
    .addOperation(operation)
    .setMaxOperationFee(200)
    .build();
```

### Fee Bump Transactions

Fee bump transactions let a different account pay the fee for an existing transaction. Useful when the source account of the inner transaction doesn't have enough XLM to cover fees, or when a service wants to pay fees on behalf of users.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// The user wants to send a payment but has no XLM for fees
KeyPair userKeyPair = KeyPair.fromSecretSeed("SUSER...");
AccountResponse userAccount = await sdk.accounts.account(userKeyPair.accountId);

// Build and sign the inner transaction (user signs their own transaction)
Transaction innerTransaction = TransactionBuilder(userAccount)
    .addOperation(PaymentOperationBuilder(
      "GDEST1...",
      Asset.NATIVE,
      "10",
    ).build())
    .addOperation(PaymentOperationBuilder(
      "GDEST2...",
      Asset.NATIVE,
      "20",
    ).build())
    .build();

innerTransaction.sign(userKeyPair, Network.TESTNET);

// A service (fee payer) wraps the transaction and pays the fee
KeyPair feePayerKeyPair = KeyPair.fromSecretSeed("SFEEPAYER...");

// Build fee bump transaction
// Base fee must be >= (inner tx base fee * number of operations) + 100
// Inner tx: 100 * 2 ops = 200, plus 100 for fee bump = 300 minimum
FeeBumpTransaction feeBumpTx = FeeBumpTransactionBuilder(innerTransaction)
    .setBaseFee(300)
    .setFeeAccount(feePayerKeyPair.accountId)
    .build();

// Only the fee payer signs the fee bump
feeBumpTx.sign(feePayerKeyPair, Network.TESTNET);

// Submit the fee bump transaction
await sdk.submitFeeBumpTransaction(feeBumpTx);
```

---

## Operations

Operations are the individual actions within a transaction. Each operation type has its own builder class. Build the operation, then add it to a transaction.

### Payment Operations

Transfer XLM or custom assets between accounts.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Native XLM payment
PaymentOperation paymentOp = PaymentOperationBuilder(
  "GDEST...",    // destination
  Asset.NATIVE,  // asset (XLM)
  "100",         // amount
).build();

// Custom asset payment
Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");
PaymentOperation paymentOp = PaymentOperationBuilder(
  "GDEST...", // destination
  usdAsset,   // asset
  "50.25",    // amount
).build();
```

### Path Payment Operations

Path payments convert assets through the DEX during transfer. You send one asset and the recipient receives a different asset. Query Horizon for available paths, then choose the best one for your transaction.

First, query available paths to get the exchange route and expected amounts:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Asset xlm = Asset.NATIVE;
Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Find paths: "If I send 100 XLM, how much USD will the recipient get?"
Page<PathResponse> pathsPage = await sdk.strictSendPaths
    .sourceAsset(xlm)
    .sourceAmount("100")
    .destinationAssets([usdAsset])
    .execute();

// Find the path with the best destination amount
List<PathResponse> paths = pathsPage.records;
if (paths.isNotEmpty) {
  PathResponse bestPath = paths[0];
  for (PathResponse p in paths) {
    if (double.parse(p.destinationAmount) > double.parse(bestPath.destinationAmount)) {
      bestPath = p;
    }
  }
  String destMin = bestPath.destinationAmount; // expected USD amount
  List<Asset> path = bestPath.path;            // intermediate assets
}
```

Then build the path payment operation:

```dart
// Strict send: send exactly 100 XLM, receive at least $destMin USD
PathPaymentStrictSendOperation pathPaymentOp = PathPaymentStrictSendOperationBuilder(
  xlm,        // send asset
  "100",      // send amount (exact)
  "GDEST...", // destination
  usdAsset,   // destination asset
  destMin,    // minimum amount to receive
)
    .setPath(path) // intermediate assets from path query
    .build();
```

For strict receive (recipient gets exact amount, you pay variable):

```dart
// Find paths: "If recipient needs exactly 100 USD, how much XLM do I send?"
Page<PathResponse> pathsPage = await sdk.strictReceivePaths
    .sourceAccount("GSENDER...")
    .destinationAsset(usdAsset)
    .destinationAmount("100")
    .execute();

// Find the path with the lowest source amount (least XLM to send)
List<PathResponse> paths = pathsPage.records;
if (paths.isNotEmpty) {
  PathResponse bestPath = paths[0];
  for (PathResponse p in paths) {
    if (double.parse(p.sourceAmount) < double.parse(bestPath.sourceAmount)) {
      bestPath = p;
    }
  }
  String sendMax = bestPath.sourceAmount; // max XLM needed
  List<Asset> path = bestPath.path;
}

// Strict receive: receive exactly 100 USD, send at most $sendMax XLM
PathPaymentStrictReceiveOperation pathPaymentOp = PathPaymentStrictReceiveOperationBuilder(
  xlm,        // send asset
  sendMax,    // maximum amount to send
  "GDEST...", // destination
  usdAsset,   // destination asset
  "100",      // destination amount (exact)
)
    .setPath(path)
    .build();
```

### Account Operations

#### Create Account

Create a new account on the network. The source account funds the new account with a starting balance.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

CreateAccountOperation createOp = CreateAccountOperationBuilder(
  "GNEWACCOUNT...", // new account ID
  "10",             // starting balance in XLM (minimum ~1 XLM for base reserve)
).build();
```

#### Merge Account

Close an account and transfer all its assets to another account. The merged account is removed from the ledger.

The account being merged is the operation's source account. If not set, it defaults to the transaction's source account.

The destination account must have trustlines for all non-XLM assets the account to be merged holds, otherwise the operation fails.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Merge the transaction's source account into destination
AccountMergeOperation mergeOp = AccountMergeOperationBuilder(
  "GDEST...", // destination receives all XLM and other assets
).build();

// Or merge a different account (must also sign the transaction)
AccountMergeOperation mergeOp = AccountMergeOperationBuilder("GDEST...")
    .setSourceAccount("GACCOUNT_TO_MERGE...")
    .build();
```

#### Manage Data

Store key-value data on your account (max 64 bytes per entry). Useful for app-specific metadata.

```dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Store a string value
ManageDataOperation setDataOp = ManageDataOperationBuilder(
  "config",                                           // key (string)
  Uint8List.fromList(utf8.encode("production")),      // value (max 64 bytes)
).build();

// Store binary data (e.g., a hash)
ManageDataOperation setHashOp = ManageDataOperationBuilder(
  "data_hash",
  Uint8List.fromList(utf8.encode("some data")),
).build();

// Delete an entry (set value to null)
ManageDataOperation deleteDataOp = ManageDataOperationBuilder(
  "temp_key", // key to delete
  null,       // null removes the entry
).build();
```

#### Set Options

Configure account settings: home domain, thresholds, signers, and flags.

**Set Home Domain**

The home domain is used for SEP protocols like federation (SEP-2) and stellar.toml discovery.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SetOptionsOperation setDomainOp = SetOptionsOperationBuilder()
    .setHomeDomain("example.com")
    .build();
```

**Configure Multi-Sig Thresholds**

Operations require signatures with combined weight >= the operation's threshold. Each operation type has a threshold level:

- **Low:** Allow Trust, Set Trustline Flags, Bump Sequence
- **Medium:** Payments, Create Account, Path Payments, Manage Offers, most other operations
- **High:** Account Merge, Set Options (when changing signers or thresholds)

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SetOptionsOperation setThresholdsOp = SetOptionsOperationBuilder()
    .setMasterKeyWeight(10) // weight of the master key
    .setLowThreshold(10)    // e.g., bump sequence
    .setMediumThreshold(20) // e.g., payments
    .setHighThreshold(30)   // e.g., account merge, adding signers
    .build();
```

**Add or Remove Signers**

Add additional signers to create a multi-sig account. Each signer has a weight that contributes to meeting thresholds.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Add a signer with weight 10
XdrSignerKey signerKey = KeyPair.fromAccountId("GSIGNER...").xdrSignerKey;
SetOptionsOperation addSignerOp = SetOptionsOperationBuilder()
    .setSigner(signerKey, 10)
    .build();

// Remove a signer (set weight to 0)
SetOptionsOperation removeSignerOp = SetOptionsOperationBuilder()
    .setSigner(signerKey, 0)
    .build();
```

**Set Account Flags**

Flags control asset issuance behavior. Typically set by asset issuers.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Enable authorization required and revocable (for regulated assets)
SetOptionsOperation setFlagsOp = SetOptionsOperationBuilder()
    .setSetFlags(1 | 2) // AUTH_REQUIRED_FLAG | AUTH_REVOCABLE_FLAG
    .build();

// Clear a flag
SetOptionsOperation clearFlagsOp = SetOptionsOperationBuilder()
    .setClearFlags(2) // AUTH_REVOCABLE_FLAG
    .build();

// Available flags:
// AUTH_REQUIRED_FLAG (1)         - Trustlines must be authorized by issuer
// AUTH_REVOCABLE_FLAG (2)        - Issuer can revoke authorization
// AUTH_IMMUTABLE_FLAG (4)        - Flags can never be changed (irreversible!)
// AUTH_CLAWBACK_ENABLED_FLAG (8) - Issuer can clawback assets
```

#### Bump Sequence

Manually set the account's sequence number. Useful for invalidating pre-signed transactions that use older sequence numbers.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Get the current sequence number
AccountResponse account = await sdk.accounts.account("GABC...");
BigInt currentSequence = account.sequenceNumber;

// Bump to current + 100 (invalidates any pre-signed tx with sequence <= current + 100)
BumpSequenceOperation bumpOp = BumpSequenceOperationBuilder(
  currentSequence + BigInt.from(100),
).build();
```

### Asset Operations

Before receiving a custom asset, an account must create a trustline for it. Trustlines specify which assets the account accepts and set optional limits.

#### Create Trustline

Create a trustline to allow your account to hold a custom asset. The limit specifies the maximum amount you're willing to hold. If omitted, the limit defaults to the maximum possible value (unlimited).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// With a specific limit
ChangeTrustOperation trustOp = ChangeTrustOperationBuilder(
  usdAsset, // asset to trust
  "10000",  // limit (max amount you can hold)
).build();

// Without limit (defaults to maximum possible value)
ChangeTrustOperation trustOpUnlimited = ChangeTrustOperationBuilder(
  usdAsset,
  ChangeTrustOperationBuilder.MAX_LIMIT,
).build();
```

#### Modify Trustline Limit

Change the maximum amount of an asset your account can hold.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Increase or decrease the limit
ChangeTrustOperation modifyTrustOp = ChangeTrustOperationBuilder(
  usdAsset,
  "50000", // new limit
).build();
```

#### Remove Trustline

Remove a trustline by setting the limit to zero. Your balance must be zero first.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Balance must be zero before removing
ChangeTrustOperation removeTrustOp = ChangeTrustOperationBuilder(
  usdAsset,
  "0", // zero limit removes the trustline
).build();
```

#### Authorize Trustline (Issuer Only)

If an asset has the AUTH_REQUIRED flag, the issuer must authorize trustlines before holders can receive the asset. Use `SetTrustLineFlagsOperationBuilder` to authorize or revoke.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Authorize a trustline (allow holder to receive the asset)
SetTrustLineFlagsOperation authorizeOp = SetTrustLineFlagsOperationBuilder(
  "GTRUSTOR...",  // account to authorize
  usdAsset,       // asset
  0,              // flags to clear
  1,              // flags to set (1 = AUTHORIZED_FLAG)
).build();

// Revoke authorization (holder can no longer receive, but can send)
SetTrustLineFlagsOperation revokeOp = SetTrustLineFlagsOperationBuilder(
  "GTRUSTOR...",
  usdAsset,
  1,  // flags to clear (AUTHORIZED_FLAG)
  0,  // flags to set
).build();
```

### Trading Operations

Place, update, or cancel offers on Stellar's built-in decentralized exchange (DEX).

#### Create Sell Offer

Sell a specific amount of an asset at a given price. You specify how much you want to sell.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Sell 100 XLM at 0.20 USD per XLM (receive 20 USD total)
ManageSellOfferOperation sellOp = ManageSellOfferOperationBuilder(
  Asset.NATIVE, // selling asset
  usdAsset,     // buying asset
  "100",        // amount to sell
  "0.20",       // price (buying asset per selling asset)
).build();
```

#### Create Buy Offer

Buy a specific amount of an asset at a given price. You specify how much you want to receive.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Buy 50 USD at 0.20 USD per XLM (spend 250 XLM total)
ManageBuyOfferOperation buyOp = ManageBuyOfferOperationBuilder(
  Asset.NATIVE, // selling asset (what you pay with)
  usdAsset,     // buying asset (what you receive)
  "50",         // amount to buy
  "0.20",       // price (buying asset per selling asset)
).build();
```

#### Update Offer

Modify an existing offer by providing its offer ID. You can change the amount or price.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Update offer 12345: change amount to 150 XLM at new price 0.22 USD
ManageSellOfferOperation updateOp = ManageSellOfferOperationBuilder(
  Asset.NATIVE,
  usdAsset,
  "150",  // new amount
  "0.22", // new price
)
    .setOfferId("12345") // existing offer to update
    .build();
```

**How to get the offer ID**

You can get the offer ID by querying your account's existing offers:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Get all offers for an account
Page<OfferResponse> offersPage = await sdk.offers
    .forAccount("GABC...")
    .execute();

for (OfferResponse offer in offersPage.records) {
  print("Offer ID: ${offer.id}");
  print("Selling: ${offer.amount}");
  print("Price: ${offer.price}");
}
```

#### Cancel Offer

Cancel an existing offer by setting the amount to zero.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Cancel offer 12345
ManageSellOfferOperation cancelOp = ManageSellOfferOperationBuilder(
  Asset.NATIVE,
  usdAsset,
  "0",    // zero amount cancels the offer
  "0.20", // price doesn't matter when canceling
)
    .setOfferId("12345")
    .build();
```

#### Passive Sell Offer

A passive offer doesn't immediately match existing offers at the same price. Use it for market making when you want to provide liquidity without taking from the order book.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Passive offer: sell 100 XLM at 0.20 USD per XLM
// Won't match existing offers, waits for a counterparty
CreatePassiveSellOfferOperation passiveOp = CreatePassiveSellOfferOperationBuilder(
  Asset.NATIVE, // selling asset
  usdAsset,     // buying asset
  "100",        // amount to sell
  "0.20",       // price
).build();
```

### Claimable Balance Operations

Send funds that recipients claim later, with optional time-based conditions. Useful for escrow, scheduled payments, or sending to accounts that don't exist yet.

#### Create Claimable Balance

Lock funds that one or more claimants can claim. Each claimant has a predicate that defines when they can claim.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create claimants (who can claim and under what conditions)
Claimant claimant1 = Claimant(
  "GCLAIMER1...",                    // claimant account
  Claimant.predicateUnconditional(), // can claim anytime
);

int thirtyDaysFromNow = DateTime.now()
    .add(Duration(days: 30))
    .millisecondsSinceEpoch ~/ 1000;
Claimant claimant2 = Claimant(
  "GCLAIMER2...",
  Claimant.predicateBeforeAbsoluteTime(thirtyDaysFromNow), // must claim within 30 days
);

// Create the claimable balance
CreateClaimableBalanceOperation createOp = CreateClaimableBalanceOperationBuilder(
  [claimant1, claimant2], // list of claimants
  Asset.NATIVE,           // asset
  "100",                  // amount
).build();
```

#### Predicates

Predicates control when a claimant can claim. You can combine them for complex conditions.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Unconditional: can claim anytime
var anytime = Claimant.predicateUnconditional();

// Before absolute time: must claim before this Unix timestamp
int thirtyDaysFromNow = DateTime.now()
    .add(Duration(days: 30))
    .millisecondsSinceEpoch ~/ 1000;
var before = Claimant.predicateBeforeAbsoluteTime(thirtyDaysFromNow);

// Before relative time: must claim within X seconds of balance creation
var withinOneHour = Claimant.predicateBeforeRelativeTime(3600);

// NOT: inverts a predicate (e.g., can claim AFTER a time)
var afterOneDay = Claimant.predicateNot(
  Claimant.predicateBeforeRelativeTime(86400), // NOT "before 1 day" = "after 1 day"
);

// AND: both conditions must be true
// Example: can claim after 1 day AND before 30 days (a time window)
var timeWindow = Claimant.predicateAnd(
  Claimant.predicateNot(Claimant.predicateBeforeRelativeTime(86400)),     // after 1 day
  Claimant.predicateBeforeRelativeTime(86400 * 30),                       // before 30 days
);

// OR: either condition can be true
var eitherCondition = Claimant.predicateOr(anytime, before);
```

#### Claim Balance

To claim a balance, you need its balance ID. Get it from the transaction response when created, or query claimable balances for your account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Find claimable balances you can claim
Page<ClaimableBalanceResponse> balancesPage = await sdk.claimableBalances
    .forClaimant("GCLAIMER1...")
    .execute();

for (ClaimableBalanceResponse balance in balancesPage.records) {
  print("Balance ID: ${balance.balanceId}"); // hex string
  print("Amount: ${balance.amount}");
  print("Asset: ${Asset.canonicalForm(balance.asset)}");
}
```

Then claim it:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Claim the balance
String balanceId = "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072";
ClaimClaimableBalanceOperation claimOp = ClaimClaimableBalanceOperationBuilder(balanceId).build();
```

### Liquidity Pool Operations

Provide liquidity to Stellar's automated market maker (AMM) pools and earn trading fees.

#### Pool Share Trustline

Before depositing to a liquidity pool, you need a trustline for the pool shares. Create a pool share asset from the two assets in the pool.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Create pool share asset (assets must be in lexicographic order)
AssetTypePoolShare poolShareAsset = AssetTypePoolShare(Asset.NATIVE, usdAsset);

// Establish trustline for pool shares
ChangeTrustOperation trustPoolOp = ChangeTrustOperationBuilder(
  poolShareAsset,
  ChangeTrustOperationBuilder.MAX_LIMIT,
).build();
```

#### Get Pool ID

Query the pool ID by the reserve assets, or find pools your account participates in.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Find pool by reserve assets
Page<LiquidityPoolResponse> poolsPage = await sdk.liquidityPools
    .forReserveAssets(Asset.NATIVE, usdAsset)
    .execute();

for (LiquidityPoolResponse pool in poolsPage.records) {
  print("Pool ID: ${pool.poolId}");
  print("Total shares: ${pool.totalShares}");
}
```

#### Deposit Liquidity

Add liquidity to a pool. You specify the maximum amounts of each asset to deposit and price bounds to protect against slippage.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

LiquidityPoolDepositOperation depositOp = LiquidityPoolDepositOperationBuilder(
  liquidityPoolId: "poolid123abc...", // pool ID from query above
  maxAmountA: "1000",                // max amount of asset A (XLM)
  maxAmountB: "500",                 // max amount of asset B (USD)
  minPrice: "1.9",                   // min price (A per B) - slippage protection
  maxPrice: "2.1",                   // max price (A per B) - slippage protection
).build();

// The actual amounts deposited depend on the current pool ratio
// Price bounds reject the transaction if the pool price moves outside your range
```

#### Withdraw Liquidity

Remove liquidity by burning pool shares. You receive both assets back proportionally.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

LiquidityPoolWithdrawOperation withdrawOp = LiquidityPoolWithdrawOperationBuilder(
  liquidityPoolId: "poolid123abc...", // pool ID
  amount: "100",                     // amount of pool shares to burn
  minAmountA: "180",                 // min amount of asset A to receive (slippage protection)
  minAmountB: "90",                  // min amount of asset B to receive (slippage protection)
).build();

// If you would receive less than the minimums, the transaction fails
```

### Sponsorship Operations

Sponsorship lets one account pay base reserves for another account's ledger entries. This enables user onboarding without requiring new users to hold XLM for reserves.

#### Sponsor Account Creation

Create a new account where the sponsor pays the base reserve. The new account can start with 0 XLM.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Sponsor: existing funded account that will pay reserves
KeyPair sponsorKeyPair = KeyPair.fromSecretSeed("SSPONSOR...");
AccountResponse sponsorAccount = await sdk.accounts.account(sponsorKeyPair.accountId);

// New account to be sponsored
KeyPair newAccountKeyPair = KeyPair.random();
String newAccountId = newAccountKeyPair.accountId;

Transaction transaction = TransactionBuilder(sponsorAccount)
    // 1. Begin sponsoring - sponsor declares intent to pay reserves
    .addOperation(BeginSponsoringFutureReservesOperationBuilder(newAccountId).build())
    // 2. Create account with 0 XLM (sponsor pays the reserve)
    .addOperation(CreateAccountOperationBuilder(newAccountId, "0").build())
    // 3. End sponsoring - new account must confirm (source = new account)
    .addOperation(
      EndSponsoringFutureReservesOperationBuilder()
          .setSourceAccount(newAccountId)
          .build(),
    )
    .build();

// Both must sign:
// - Sponsor: authorizes paying reserves and funds the transaction
// - New account: confirms acceptance of sponsorship (required for EndSponsoring)
transaction.sign(sponsorKeyPair, Network.TESTNET);
transaction.sign(newAccountKeyPair, Network.TESTNET);

await sdk.submitTransaction(transaction);
```

#### Sponsor Trustline

Sponsor a trustline for an existing account. Useful when users want to hold an asset but don't have XLM for the trustline reserve.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

KeyPair sponsorKeyPair = KeyPair.fromSecretSeed("SSPONSOR...");
AccountResponse sponsorAccount = await sdk.accounts.account(sponsorKeyPair.accountId);

KeyPair userKeyPair = KeyPair.fromSecretSeed("SUSER...");
String userId = userKeyPair.accountId;

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

Transaction transaction = TransactionBuilder(sponsorAccount)
    .addOperation(BeginSponsoringFutureReservesOperationBuilder(userId).build())
    .addOperation(
      ChangeTrustOperationBuilder(usdAsset)
          .setSourceAccount(userId) // user creates the trustline
          .build(),
    )
    .addOperation(
      EndSponsoringFutureReservesOperationBuilder()
          .setSourceAccount(userId)
          .build(),
    )
    .build();

// Both sign
transaction.sign(sponsorKeyPair, Network.TESTNET);
transaction.sign(userKeyPair, Network.TESTNET);

await sdk.submitTransaction(transaction);
```

#### Revoke Sponsorship

Transfer the reserve responsibility back to the sponsored account. The operation fails if the account doesn't have enough XLM to cover its own reserves after revoking.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Revoke account sponsorship
RevokeSponsorshipOperation revokeAccountOp = RevokeSponsorshipOperationBuilder()
    .revokeAccountSponsorship("GSPONSORED...")
    .build();

// Revoke trustline sponsorship
Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");
RevokeSponsorshipOperation revokeTrustlineOp = RevokeSponsorshipOperationBuilder()
    .revokeTrustlineSponsorship("GSPONSORED...", usdAsset)
    .build();

// Revoke data entry sponsorship
RevokeSponsorshipOperation revokeDataOp = RevokeSponsorshipOperationBuilder()
    .revokeDataSponsorship("GSPONSORED...", "data_key")
    .build();
```

---

## Querying Horizon Data

Horizon is the API server for Stellar. Query it for accounts, transactions, operations, and other network data. All query builders support `limit()`, `order()`, and `cursor()` for pagination (see [Pagination](#pagination) at the end of this section).

### Account Queries

Look up accounts by ID, signer, asset holdings, or sponsor.

#### Get Single Account

Fetch a specific account by its public key.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

AccountResponse account = await sdk.accounts.account("GABC...");
print("Sequence: ${account.sequenceNumber}");
print("Subentry count: ${account.subentryCount}");
```

#### Check if Account Exists

Check whether an account exists on the network before attempting operations. Useful for deciding between `CreateAccountOperation` (new account) vs `PaymentOperation` (existing account).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

bool exists = true;
try {
  await sdk.accounts.account("GABC...");
} on ErrorResponse catch (e) {
  if (e.code == 404) exists = false;
}

if (exists) {
  print("Account exists - use PaymentOperation");
} else {
  print("Account does not exist - use CreateAccountOperation");
}
```

#### Query by Signer

Find all accounts that have a specific key as a signer. Useful for discovering accounts controlled by a key.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<AccountResponse> accountsPage = await sdk.accounts
    .forSigner("GSIGNER...")
    .limit(50)
    .order(RequestBuilderOrder.DESC)
    .execute();

for (AccountResponse account in accountsPage.records) {
  print(account.accountId);
}
```

#### Query by Asset

Find all accounts holding a specific asset. Useful for asset issuers to find their token holders.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Asset usdAsset = Asset.createNonNativeAsset("USD", "GISSUER...");
Page<AccountResponse> accountsPage = await sdk.accounts
    .forAsset(usdAsset)
    .execute();

for (AccountResponse account in accountsPage.records) {
  print(account.accountId);
}
```

#### Query by Sponsor

Find all accounts sponsored by a specific account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<AccountResponse> accountsPage = await sdk.accounts
    .forSponsor("GSPONSOR...")
    .execute();

for (AccountResponse account in accountsPage.records) {
  print(account.accountId);
}
```

#### Get Account Data Entry

Retrieve a specific data entry stored on an account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

AccountDataResponse data = await sdk.accounts.accountData("GABC...", "config");
print("Value: ${data.value}");
```

### Transaction Queries

Fetch transactions by hash, account, ledger, or related resources.

#### Get Single Transaction

Fetch a specific transaction by its hash.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

TransactionResponse tx = await sdk.transactions.transaction("abc123hash...");
print("Ledger: ${tx.ledger}");
print("Fee paid: ${tx.feeCharged}");
print("Operation count: ${tx.operationCount}");
```

#### Transactions for Account

Get all transactions involving a specific account (as source or in any operation).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<TransactionResponse> txPage = await sdk.transactions
    .forAccount("GABC...")
    .limit(20)
    .order(RequestBuilderOrder.DESC)
    .execute();

for (TransactionResponse tx in txPage.records) {
  print(tx.hash);
}
```

#### Include Failed Transactions

By default, only successful transactions are returned. Use `includeFailed(true)` to also get failed ones.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<TransactionResponse> txPage = await sdk.transactions
    .forAccount("GABC...")
    .includeFailed(true)
    .execute();

for (TransactionResponse tx in txPage.records) {
  print("${tx.hash} - ${tx.successful ? "success" : "failed"}");
}
```

#### Transactions by Related Resource

Find transactions related to a ledger, claimable balance, or liquidity pool.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Transactions in a specific ledger
Page<TransactionResponse> txPage = await sdk.transactions
    .forLedger(12345678)
    .execute();

// Transactions affecting a claimable balance
Page<TransactionResponse> txPage = await sdk.transactions
    .forClaimableBalance("00000000abc...")
    .execute();

// Transactions affecting a liquidity pool
Page<TransactionResponse> txPage = await sdk.transactions
    .forLiquidityPool("poolid...")
    .execute();
```

### Operation Queries

Query operations by ID, account, transaction, or ledger.

#### Get Single Operation

Fetch a specific operation by its ID.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

OperationResponse op = await sdk.operations.operation("123456789");
print("Transaction: ${op.transactionHash}");
```

#### Operations for Account

Get all operations involving a specific account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<OperationResponse> opsPage = await sdk.operations
    .forAccount("GABC...")
    .limit(50)
    .order(RequestBuilderOrder.DESC)
    .execute();

for (OperationResponse op in opsPage.records) {
  print("${op.id}: ${op.type}");
}
```

#### Operations in Transaction

Get all operations within a specific transaction.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<OperationResponse> opsPage = await sdk.operations
    .forTransaction("txhash...")
    .execute();

for (OperationResponse op in opsPage.records) {
  print(op.type);
}
```

#### Handling Operation Types

Operations are returned as specific response types based on their kind. Use `is` to handle each type appropriately.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<OperationResponse> opsPage = await sdk.operations.forAccount("GABC...").execute();

for (OperationResponse op in opsPage.records) {
  if (op is PaymentOperationResponse) {
    print("Payment: ${op.amount} to ${op.to}");
  } else if (op is CreateAccountOperationResponse) {
    print("Account created: ${op.account}");
  } else if (op is ChangeTrustOperationResponse) {
    print("Trustline changed for: ${op.assetCode}");
  } else if (op is ManageSellOfferOperationResponse) {
    print("Offer: ${op.amount} at ${op.price}");
  } else if (op is PathPaymentStrictReceiveOperationResponse) {
    print("Path payment: ${op.sourceAmount} -> ${op.amount}");
  }
  // Many other operation types available
}
```

### Effect Queries

Effects are the results of operations (account credited, trustline created, etc.).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Effects for an account
Page<EffectResponse> effectsPage = await sdk.effects
    .forAccount("GABC...")
    .limit(50)
    .execute();

// Effects for a specific operation
Page<EffectResponse> effectsPage = await sdk.effects
    .forOperation("123456789")
    .execute();

for (EffectResponse effect in effectsPage.records) {
  print(effect.type);
}
```

### Ledger & Payment Queries

Ledgers are blocks of transactions. The payments endpoint filters for payment-type operations only.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Ledgers
LedgerResponse ledger = await sdk.ledgers.ledger(12345678);
Page<LedgerResponse> ledgersPage = await sdk.ledgers
    .limit(10)
    .order(RequestBuilderOrder.DESC)
    .execute();

// Payments (Payment, PathPayment, CreateAccount, AccountMerge)
Page<OperationResponse> paymentsPage = await sdk.payments
    .forAccount("GABC...")
    .execute();
```

### Offer Queries

Query open offers on the DEX by account, asset, or sponsor.

#### Get Single Offer

Fetch a specific offer by its ID.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

OfferResponse offer = await sdk.offers.offer("12345");
print("Selling: ${offer.amount} ${Asset.canonicalForm(offer.selling)}");
print("Buying: ${Asset.canonicalForm(offer.buying)}");
print("Price: ${offer.price}");
```

#### Offers by Account

Get all open offers for a specific account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<OfferResponse> offersPage = await sdk.offers
    .forAccount("GABC...")
    .limit(50)
    .execute();

for (OfferResponse offer in offersPage.records) {
  print("${offer.id}: ${offer.amount} at ${offer.price}");
}
```

#### Offers by Asset

Find all offers selling or buying a specific asset.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
Asset usdAsset = Asset.createNonNativeAsset("USD", "GISSUER...");

// Find offers selling XLM
Page<OfferResponse> offersPage = await sdk.offers
    .forSellingAsset(Asset.NATIVE)
    .execute();

// Find offers buying USD
Page<OfferResponse> offersPage = await sdk.offers
    .forBuyingAsset(usdAsset)
    .execute();

for (OfferResponse offer in offersPage.records) {
  print("${offer.id}: ${offer.amount} at ${offer.price}");
}
```

#### Offers by Sponsor

Find all offers sponsored by a specific account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<OfferResponse> offersPage = await sdk.offers
    .forSponsor("GSPONSOR...")
    .execute();

for (OfferResponse offer in offersPage.records) {
  print(offer.id);
}
```

### Trade Queries

Query executed trades by account, asset pair, or offer.

#### Trades by Account

Get all trades involving a specific account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<TradeResponse> tradesPage = await sdk.trades
    .forAccount("GABC...")
    .limit(50)
    .order(RequestBuilderOrder.DESC)
    .execute();

for (TradeResponse trade in tradesPage.records) {
  print("${trade.baseAmount} ${trade.baseAssetCode}"
      " for ${trade.counterAmount} ${trade.counterAssetCode}");
}
```

#### Trades by Asset Pair

Get all trades between two specific assets. Useful for analyzing market activity.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
Asset usdAsset = Asset.createNonNativeAsset("USD", "GISSUER...");

Page<TradeResponse> tradesPage = await sdk.trades
    .baseAsset(Asset.NATIVE)
    .counterAsset(usdAsset)
    .limit(50)
    .order(RequestBuilderOrder.DESC)
    .execute();

for (TradeResponse trade in tradesPage.records) {
  print("${trade.baseAmount} XLM for ${trade.counterAmount} USD");
}
```

#### Trades by Offer

Get all trades that filled a specific offer.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<TradeResponse> tradesPage = await sdk.trades
    .offerId("12345")
    .execute();

for (TradeResponse trade in tradesPage.records) {
  print("${trade.baseAmount} at ${trade.price.n / trade.price.d}");
}
```

#### Trade Aggregations (OHLCV)

Get OHLCV (Open, High, Low, Close, Volume) candles for charting. Useful for building price charts and analyzing market trends.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
Asset usdAsset = Asset.createNonNativeAsset("USD", "GISSUER...");

// Get hourly candles for a time range
int startTime = DateTime.now()
    .subtract(Duration(hours: 24))
    .millisecondsSinceEpoch;
int endTime = DateTime.now().millisecondsSinceEpoch;

Page<TradeAggregationResponse> aggregations = await sdk.tradeAggregations(
  Asset.NATIVE,  // base asset
  usdAsset,      // counter asset
  startTime,     // start time in ms
  endTime,       // end time in ms
  3600000,       // resolution: 1 hour in ms
  0,             // offset
).limit(24).execute();

for (TradeAggregationResponse candle in aggregations.records) {
  print("Open: ${candle.open}");
  print("High: ${candle.high}");
  print("Low: ${candle.low}");
  print("Close: ${candle.close}");
  print("Volume: ${candle.baseVolume}");
}

// Common resolutions (in milliseconds):
// 60000 (1 min), 300000 (5 min), 900000 (15 min),
// 3600000 (1 hour), 86400000 (1 day), 604800000 (1 week)
```

### Asset Queries

Look up assets by code or issuer. Useful for discovering all issuers of a token or all assets from an issuer.

#### Find by Code

Find all assets with a specific code. Different issuers can have the same asset code.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Find all USD assets (from different issuers)
Page<AssetResponse> assetsPage = await sdk.assets
    .assetCode("USD")
    .limit(20)
    .execute();

for (AssetResponse asset in assetsPage.records) {
  print("${asset.assetCode} by ${asset.assetIssuer}");

  // Account statistics by authorization status
  print("Authorized holders: ${asset.accounts.authorized}");

  // Balance totals by authorization status
  print("Authorized supply: ${asset.balances.authorized}");
}
```

#### Find by Issuer

Find all assets issued by a specific account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<AssetResponse> assetsPage = await sdk.assets
    .assetIssuer("GISSUER...")
    .execute();

for (AssetResponse asset in assetsPage.records) {
  String totalSupply = asset.balances.authorized;
  print("${asset.assetCode}: $totalSupply total");
}
```

### Order Book Queries

Get the current order book for an asset pair. Returns bids (buy orders) and asks (sell orders) sorted by price.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
Asset usdAsset = Asset.createNonNativeAsset("USD", "GISSUER...");

// Get order book: people selling XLM for USD
OrderBookResponse orderBook = await sdk.orderBook
    .sellingAsset(Asset.NATIVE)
    .buyingAsset(usdAsset)
    .execute();

// Bids: offers to buy the base asset (XLM)
for (var bid in orderBook.bids) {
  print("Bid: ${bid.amount} XLM at ${bid.price} USD");
}

// Asks: offers to sell the base asset (XLM)
for (var ask in orderBook.asks) {
  print("Ask: ${ask.amount} XLM at ${ask.price} USD");
}
```

### Payment Path Queries

Find payment paths for cross-asset transfers. Used with path payment operations.

#### Strict Send Paths

Find paths when you know how much you want to send. Returns what the recipient can receive.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
Asset usdAsset = Asset.createNonNativeAsset("USD", "GISSUER...");

// "If I send 100 XLM, how much USD can the recipient get?"
Page<PathResponse> pathsPage = await sdk.strictSendPaths
    .sourceAsset(Asset.NATIVE)
    .sourceAmount("100")
    .destinationAssets([usdAsset])
    .execute();

for (PathResponse path in pathsPage.records) {
  print("Send 100 XLM, receive ${path.destinationAmount} USD");
}
```

#### Strict Receive Paths

Find paths when you know how much the recipient needs. Returns what you need to send.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
Asset usdAsset = Asset.createNonNativeAsset("USD", "GISSUER...");

// "If recipient needs 100 USD, how much XLM do I send?"
Page<PathResponse> pathsPage = await sdk.strictReceivePaths
    .sourceAccount("GSENDER...")
    .destinationAsset(usdAsset)
    .destinationAmount("100")
    .execute();

for (PathResponse path in pathsPage.records) {
  print("Send ${path.sourceAmount} XLM to receive 100 USD");
}

// See "Path Payment Operations" section for how to use these paths
```

### Claimable Balance Queries

Find claimable balances you can claim, or look up a specific balance by ID.

#### Get Single Balance

Fetch a specific claimable balance by its ID.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Using hex format
ClaimableBalanceResponse balance = await sdk.claimableBalances
    .claimableBalance("00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072");
print("Amount: ${balance.amount}");
print("Asset: ${Asset.canonicalForm(balance.asset)}");
```

#### Find by Claimant

Find all claimable balances that a specific account can claim.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<ClaimableBalanceResponse> balancesPage = await sdk.claimableBalances
    .forClaimant("GCLAIMER...")
    .execute();

for (ClaimableBalanceResponse balance in balancesPage.records) {
  print("${balance.balanceId}: ${balance.amount}");
}
```

#### Find by Sponsor

Find all claimable balances sponsored by a specific account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Page<ClaimableBalanceResponse> balancesPage = await sdk.claimableBalances
    .forSponsor("GSPONSOR...")
    .execute();

for (ClaimableBalanceResponse balance in balancesPage.records) {
  print(balance.balanceId);
}
```

#### Find by Asset

Find all claimable balances for a specific asset.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Asset usdAsset = Asset.createNonNativeAsset("USD", "GISSUER...");
Page<ClaimableBalanceResponse> balancesPage = await sdk.claimableBalances
    .forAsset(usdAsset)
    .execute();

for (ClaimableBalanceResponse balance in balancesPage.records) {
  print("${balance.amount} ${Asset.canonicalForm(balance.asset)}");
}
```

### Liquidity Pool Queries

Find liquidity pools by reserve assets or by account participation.

#### Get Single Pool

Fetch a specific liquidity pool by its ID.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

LiquidityPoolResponse pool = await sdk.liquidityPools
    .liquidityPool("poolid123...");
print("Total shares: ${pool.totalShares}");
print("Total trustlines: ${pool.totalTrustlines}");
```

#### Find by Reserve Assets

Find pools containing specific reserve assets.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

Page<LiquidityPoolResponse> poolsPage = await sdk.liquidityPools
    .forReserveAssets(Asset.NATIVE, usdAsset)
    .execute();

for (LiquidityPoolResponse pool in poolsPage.records) {
  print("Pool ID: ${pool.poolId}");
  print("Total shares: ${pool.totalShares}");
}
```

### Pagination

Navigate through large result sets using cursors. Each record has a paging token you can use to fetch the next page.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// First page
Page<TransactionResponse> page = await sdk.transactions
    .forAccount("GABC...")
    .limit(20)
    .order(RequestBuilderOrder.DESC)
    .execute();

// Process results
for (TransactionResponse tx in page.records) {
  print(tx.hash);
}

// Get next page using cursor from last record
if (page.records.isNotEmpty) {
  Page<TransactionResponse> nextPage = await sdk.transactions
      .forAccount("GABC...")
      .limit(20)
      .order(RequestBuilderOrder.DESC)
      .cursor(page.records.last.pagingToken)
      .execute();
}
```

---

## Streaming (SSE)

Get real-time updates via Server-Sent Events. The SDK wraps SSE connections as Dart `Stream` objects that automatically reconnect on connection drops. Use `cursor("now")` to start from the current position rather than replaying historical data.

Always store the `StreamSubscription` to cancel later when you no longer need updates.

### Stream Payments

Stream payment-type operations (payments, path payments, create account, account merge) for an account.

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

StreamSubscription<OperationResponse> subscription = sdk.payments
    .forAccount("GABC...")
    .cursor("now")
    .stream()
    .listen((OperationResponse payment) {
  if (payment is PaymentOperationResponse) {
    print("Payment: ${payment.amount} from ${payment.from}");
  } else if (payment is PathPaymentStrictReceiveOperationResponse) {
    print("Path payment: ${payment.amount}");
  }
});

// Cancel when done
// subscription.cancel();
```

### Stream Transactions

Stream transactions for an account or all transactions on the network.

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Stream transactions for a specific account
StreamSubscription<TransactionResponse> subscription = sdk.transactions
    .forAccount("GABC...")
    .cursor("now")
    .stream()
    .listen((TransactionResponse tx) {
  print("Transaction: ${tx.hash}");
  print("Operations: ${tx.operationCount}");
});

// Stream all transactions on the network
StreamSubscription<TransactionResponse> subscription = sdk.transactions
    .cursor("now")
    .stream()
    .listen((TransactionResponse tx) {
  print("New transaction in ledger ${tx.ledger}");
});
```

### Stream Ledgers

Stream ledger closes to track network progress.

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

StreamSubscription<LedgerResponse> subscription = sdk.ledgers
    .cursor("now")
    .stream()
    .listen((LedgerResponse ledger) {
  print("Ledger ${ledger.sequence} closed");
  print("Transactions: ${ledger.successfulTransactionCount}");
});
```

### Stream Operations

Stream all operations for an account.

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

StreamSubscription<OperationResponse> subscription = sdk.operations
    .forAccount("GABC...")
    .cursor("now")
    .stream()
    .listen((OperationResponse op) {
  print("Operation: ${op.type}");
});
```

### Stream Effects

Stream effects (account credited, trustline created, etc.) for an account.

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

StreamSubscription<EffectResponse> subscription = sdk.effects
    .forAccount("GABC...")
    .cursor("now")
    .stream()
    .listen((EffectResponse effect) {
  print("Effect: ${effect.type}");
});
```

### Stream Trades

Stream trades for an account or trading pair.

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

// Stream trades for an account
StreamSubscription<TradeResponse> subscription = sdk.trades
    .forAccount("GABC...")
    .cursor("now")
    .stream()
    .listen((TradeResponse trade) {
  print("Trade: ${trade.baseAmount} for ${trade.counterAmount}");
});
```

### Stream Order Book

Stream order book updates for an asset pair.

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
Asset usdAsset = Asset.createNonNativeAsset("USD", "GISSUER...");

StreamSubscription<OrderBookResponse> subscription = sdk.orderBook
    .sellingAsset(Asset.NATIVE)
    .buyingAsset(usdAsset)
    .stream()
    .listen((OrderBookResponse orderBook) {
  print("Bids: ${orderBook.bids.length}");
  print("Asks: ${orderBook.asks.length}");
});
```

### Stream Offers

Stream offer updates for an account.

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

StreamSubscription<OfferResponse> subscription = sdk.offers
    .forAccount("GABC...")
    .cursor("now")
    .stream()
    .listen((OfferResponse offer) {
  print("Offer ${offer.id}: ${offer.amount} at ${offer.price}");
});
```

---

## Network Communication

Submit transactions, check fees, and handle network responses.

### Transaction Submission

Submit signed transactions to the network. The response includes the transaction hash and ledger number on success.

#### Synchronous Submission

The standard submission method waits for the transaction to be validated and included in a ledger before returning.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

if (response.success) {
  print("Hash: ${response.hash}");
  print("Ledger: ${response.ledger}");
}
```

#### Asynchronous Submission

Submit without waiting for ledger inclusion. Returns immediately after Stellar Core accepts the transaction. Useful for high-throughput applications.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

SubmitAsyncTransactionResponse asyncResponse =
    await sdk.submitAsyncTransaction(transaction);

// Status: PENDING, DUPLICATE, TRY_AGAIN_LATER, or ERROR
print("Status: ${asyncResponse.txStatus}");
print("Hash: ${asyncResponse.hash}");

if (asyncResponse.txStatus == SubmitAsyncTransactionResponse.txStatusPending) {
  // Transaction accepted - poll for result later
  await Future.delayed(Duration(seconds: 5));
  try {
    TransactionResponse tx = await sdk.transactions.transaction(asyncResponse.hash);
    print("Transaction confirmed in ledger ${tx.ledger}");
  } on ErrorResponse catch (e) {
    if (e.code == 404) {
      // Not yet ingested - retry later
    }
  }
}
```

### Fee Statistics

Query current network fee levels to set appropriate fees for your transactions. All values are in stroops (1 XLM = 10,000,000 stroops).

#### Fee Charged Statistics

Get statistics on fees actually charged in recent ledgers.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

FeeStatsResponse feeStats = await sdk.feeStats.execute();

// Fees actually charged in recent transactions
print("Min fee charged: ${feeStats.feeCharged.min} stroops");
print("Mode fee charged: ${feeStats.feeCharged.mode} stroops");
print("P90 fee charged: ${feeStats.feeCharged.p90} stroops");
```

#### Max Fee Statistics

Get statistics on maximum fees users were willing to pay.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

FeeStatsResponse feeStats = await sdk.feeStats.execute();

// Max fees users set (what they were willing to pay)
print("Min max fee: ${feeStats.maxFee.min} stroops");
print("Mode max fee: ${feeStats.maxFee.mode} stroops");
print("P90 max fee: ${feeStats.maxFee.p90} stroops");

// Network capacity and base fee
print("Base fee: ${feeStats.lastLedgerBaseFee} stroops");
print("Capacity usage: ${feeStats.lastLedgerCapacityUsage}");
```

### Error Handling

When transactions fail, Horizon returns detailed error information including result codes for the transaction and each operation.

#### Handling Submission Errors

Check the response for success or failure after submitting a transaction.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

if (response.success) {
  print("Success! Hash: ${response.hash}");
} else {
  // Transaction failed
  String? txResult = response.extras?.resultCodes?.transactionResultCode;
  List<String?>? opResults = response.extras?.resultCodes?.operationsResultCodes;
  print("Transaction result: $txResult");
  print("Operation results: $opResults");
}
```

#### Horizon HTTP Errors

Handle HTTP-level errors when querying Horizon.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;

try {
  AccountResponse account = await sdk.accounts.account("GABC...");
} on ErrorResponse catch (e) {
  // HTTP error: e.code (404, 400, etc.), e.body
  print("Horizon error ${e.code}: ${e.body}");
}
```

#### Common Result Codes

**Transaction-level codes:**
- `tx_success` -- Transaction succeeded
- `tx_failed` -- One or more operations failed
- `tx_bad_seq` -- Sequence number mismatch (reload account and retry)
- `tx_insufficient_fee` -- Fee too low for current network load
- `tx_insufficient_balance` -- Not enough XLM to cover fee + reserves

**Operation-level codes:**
- `op_success` -- Operation succeeded
- `op_underfunded` -- Not enough balance for payment
- `op_no_trust` -- Destination missing trustline for asset
- `op_line_full` -- Destination trustline limit exceeded
- `op_low_reserve` -- Would leave account below minimum reserve

### Message Signing (SEP-53)

Sign and verify arbitrary messages with Stellar keypairs following the [SEP-53](sep/sep-53.md) specification. Useful for authentication and proving ownership of an account without creating a transaction.

#### Sign a Message

Create a cryptographic signature for any text using your secret key.

```dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34JFD6XVEAEPTBED53FETV");

// Sign a message
String message = "Please sign this message to verify your identity";
Uint8List signature = keyPair.signMessageString(message);

// Encode signature for transmission (e.g., in HTTP header or JSON)
String signatureBase64 = base64Encode(signature);
print("Signature: $signatureBase64");
```

#### Verify a Message

Confirm a signature matches the message and was created by a specific account.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Verify with the signing keypair
KeyPair keyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34JFD6XVEAEPTBED53FETV");

String message = "Please sign this message to verify your identity";
Uint8List signature = keyPair.signMessageString(message);

bool isValid = keyPair.verifyMessageString(message, signature);
if (isValid) {
  print("Signature is valid");
}
```

#### Verify with Public Key Only

When verifying, you only need the public key (account ID). This is typical for server-side verification.

```dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Only have the public key (account ID)
KeyPair publicKey = KeyPair.fromAccountId("GABC...");

// Signature received from client (base64 encoded)
String signatureBase64 = "...";
Uint8List signature = base64Decode(signatureBase64);

String message = "Please sign this message to verify your identity";
bool isValid = publicKey.verifyMessageString(message, signature);

if (isValid) {
  print("User owns this account");
}
```

---

## Assets

Stellar supports native XLM and custom assets issued by accounts. Asset codes are 1-4 characters (alphanumeric4) or 5-12 characters (alphanumeric12). Every custom asset is uniquely identified by its code plus issuer account.

### Native XLM

The native asset (XLM) has no issuer and doesn't require a trustline.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset xlm = Asset.NATIVE;
```

### Credit Assets

Custom assets issued by Stellar accounts. Use `AssetTypeCreditAlphaNum4` for 1-4 character codes or `AssetTypeCreditAlphaNum12` for 5-12 character codes.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// 1-4 character code
Asset usd = AssetTypeCreditAlphaNum4("USD", "GISSUER...");
Asset btc = AssetTypeCreditAlphaNum4("BTC", "GISSUER...");

// 5-12 character code
Asset myToken = AssetTypeCreditAlphaNum12("MYTOKEN", "GISSUER...");
```

### Auto-Detect Code Length

Use `createNonNativeAsset()` to automatically choose the correct type based on code length.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Automatically creates AssetTypeCreditAlphaNum4
Asset usd = Asset.createNonNativeAsset("USD", "GISSUER...");

// Automatically creates AssetTypeCreditAlphaNum12
Asset myToken = Asset.createNonNativeAsset("MYTOKEN", "GISSUER...");
```

### Canonical Form

Convert assets to/from canonical string format (`CODE:ISSUER`). Useful for storage, display, configuration, and SEP protocols like [SEP-38](sep/sep-38.md) (Anchor RFQ API).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usd = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Convert to canonical string
String canonical = Asset.canonicalForm(usd);  // "USD:GISSUER..."

// Parse from canonical string
Asset? asset = Asset.createFromCanonicalForm("USD:GISSUER...");

// Native asset canonical form
String xlmCanonical = Asset.canonicalForm(Asset.NATIVE);  // "native"
```

### Pool Share Assets

Liquidity pool share assets represent ownership in an AMM pool. Created from the two reserve assets.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset usdAsset = AssetTypeCreditAlphaNum4("USD", "GISSUER...");

// Create pool share asset (assets must be in lexicographic order)
AssetTypePoolShare poolShareAsset = AssetTypePoolShare(Asset.NATIVE, usdAsset);
```

### Trustlines

Before receiving a custom asset, an account must create a trustline for it. Trustlines specify which assets the account accepts and set optional limits.

For detailed trustline operations (create, modify, remove, authorize), see [Asset Operations](#asset-operations) in the Operations chapter.

---

## Soroban (Smart Contracts)

Soroban is Stellar's smart contract platform. Smart contract transactions differ from classic transactions: they require a simulation step to determine resource requirements and fees before submission.

For complete documentation, see the dedicated [Soroban Guide](soroban.md).

### Quick Example

Deploy a contract and call a method with minimal setup.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.fromSecretSeed('SXXX...');
String rpcUrl = 'https://soroban-testnet.stellar.org:443';

// Install WASM and deploy contract
Uint8List wasmBytes = ...; // load your contract WASM bytes
String wasmHash = await SorobanClient.install(
  installRequest: InstallRequest(
    wasmBytes: wasmBytes,
    rpcUrl: rpcUrl,
    network: Network.TESTNET,
    sourceAccountKeyPair: keyPair,
  ),
);

SorobanClient client = await SorobanClient.deploy(
  deployRequest: DeployRequest(
    rpcUrl: rpcUrl,
    network: Network.TESTNET,
    sourceAccountKeyPair: keyPair,
    wasmHash: wasmHash,
  ),
);

// Invoke contract method
XdrSCVal result = await client.invokeMethod(
  name: 'hello',
  args: [XdrSCVal.forSymbol('World')],
);
print('${result.vec![0].sym}, ${result.vec![1].sym}'); // Hello, World
```

### Soroban RPC Server

Direct communication with Soroban RPC nodes for low-level operations.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// Check server health
GetHealthResponse health = await server.getHealth();
if (health.status == GetHealthResponse.HEALTHY) {
  print("Soroban RPC is healthy");
}

// Get latest ledger
GetLatestLedgerResponse ledger = await server.getLatestLedger();
print("Latest ledger: ${ledger.sequence}");
```

### What's Covered in the Soroban Guide

The [Soroban Guide](soroban.md) covers:

- **SorobanServer** -- Direct RPC communication, contract data queries
- **SorobanClient** -- High-level contract interaction API
- **Installing & Deploying** -- WASM installation and contract deployment
- **AssembledTransaction** -- Transaction lifecycle with simulation
- **Authorization** -- Signing auth entries for contract calls
- **Type Conversions** -- XdrSCVal creation and parsing
- **Events** -- Reading contract events
- **Error Handling** -- Simulation and submission errors

---

## Further Reading

- [Quick Start Guide](quick-start.md) -- First transaction in 15 minutes
- [Getting Started](getting-started.md) -- Installation and fundamentals
- [Soroban Guide](soroban.md) -- Smart contract development
- [SEP Protocols](sep/README.md) -- Stellar Ecosystem Proposals
- [DartDoc Reference](https://pub.dev/documentation/stellar_flutter_sdk/latest/) -- Full API documentation

---

**Navigation:** [Getting Started](getting-started.md) | [Soroban Guide](soroban.md)
