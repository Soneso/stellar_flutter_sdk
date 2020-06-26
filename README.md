# [Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk)

![Beta Version](https://img.shields.io/badge/Beta-v0.8.0-yellow.svg)
![Dart](https://img.shields.io/badge/Dart-green.svg)
![Flutter](https://img.shields.io/badge/Flutter-blue.svg)
![Supports Stellar Horizon v1.4.0](https://img.shields.io/badge/Horizon-v1.4.0-blue.svg)
![Supports Stellar Core v13](https://img.shields.io/badge/Core-v13-blue.svg)

The Soneso open source Stellar SDK for Flutter is build with Dart and provides APIs to build and sign transactions, connect and query [Horizon](https://github.com/stellar/horizon).

The SDK is currently in beta stage - v. 0.8.0. 

## Installation

### From pub.dev
1. Add the dependency to your pubspec.yaml file:
```
dependencies:
  stellar_flutter_sdk: ^0.8.0
```
2. Install it (command line or IDE):
```
flutter pub get
```
3. In your source file import the SDK, initialize and use it:
```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final StellarSDK sdk = StellarSDK.TESTNET;

String accountId = "GASYKQXV47TPTB6HKXWZNB6IRVPMTQ6M6B27IM5L2LYMNYBX2O53YJAL";
AccountResponse account = await sdk.accounts.account(accountId);
print("sequence number: ${account.sequenceNumber}");
```
   
### Manual

Add the SDK is a Flutter Dart plugin. Here is a step by step that we recommend:

1. Clone this repo.
2. Open the project in your IDE (e.g. Android Studio).
3. Open the file `pubspec.yaml` and press `Pub get` in your IDE.
4. Go to the project's `test` directory, run a test from there and you are good to go!

Add it to your app:

5. In your Flutter app add the local dependency in `pubspec.yaml` and then run `pub get`:
```code
dependencies:
   flutter:
     sdk: flutter
   stellar_flutter_sdk:
     path: ../stellar_flutter_sdk
```
6. In your source file import the SDK, initialize and use it:
```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final StellarSDK sdk = StellarSDK.TESTNET;

String accountId = "GASYKQXV47TPTB6HKXWZNB6IRVPMTQ6M6B27IM5L2LYMNYBX2O53YJAL";
AccountResponse account = await sdk.accounts.account(accountId);
print("sequence number: ${account.sequenceNumber}");
```

## Quick Start

### 1. Create a Stellar key pair

#### Random generation
```dart
// create a completely new and unique pair of keys.
KeyPair keyPair = KeyPair.random();

print("${keyPair.accountId}");
// GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB

print("${keyPair.secretSeed}");
// SAV76USXIJOBMEQXPANUOQM6F5LIOTLPDIDVRJBFFE2MDJXG24TAPUU7
```

### 2. Create an account
After the key pair generation, you have already got the address, but it is not activated until someone transfers at least 1 lumen into it.

#### 2.1 Testnet
If you want to play in the Stellar test network, the SDK can ask Friendbot to create an account for you as shown below:
```dart
bool funded = await FriendBot.fundTestAccount(keyPair.accountId);
print ("funded: ${funded}");
```
#### 2.2 Public net

On the other hand, if you would like to create an account in the public net, you should buy some Stellar Lumens (XLM) from an exchange. When you withdraw the Lumens into your new account, the exchange will automatically create the account for you. However, if you want to create an account from another account of your own, you may run the following code:

```dart
/// Create a key pair for your existing account.
KeyPair keyA = KeyPair.fromSecretSeed("SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");

/// Load the data of your account from the stellar network.
AccountResponse accA = await sdk.accounts.account(keyA.accountId);

/// Create a keypair for a new account.
KeyPair keyB = KeyPair.random();

/// Create the operation builder.
CreateAccountOperationBuilder createAccBuilder = CreateAccountOperationBuilder(keyB.accountId, "3"); // send 3 XLM (lumen)

// Create the transaction.
Transaction transaction = new TransactionBuilder(accA, Network.PUBLIC)
        .addOperation(createAccBuilder.build())
        .build();

/// Sign the transaction with the key pair of your existing account.
transaction.sign(keyA);

/// Submit the transaction to the stellar network.
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

if (response.success) {
  print ("account ${keyB.accountId} created");
}
```

### 3. Check account
#### 3.1 Basic info

After creating the account, we may check the basic information of the account.

```dart
String accountId = "GASYKQXV47TPTB6HKXWZNB6IRVPMTQ6M6B27IM5L2LYMNYBX2O53YJAL";

// Request the account data.
AccountResponse account = await sdk.accounts.account(accountId);

// You can check the `balance`, `sequence`, `flags`, `signers`, `data` etc.

for (Balance balance in account.balances) {
  switch (balance.assetType) {
    case Asset.TYPE_NATIVE:
      print("Balance: ${balance.balance} XLM");
      break;
    default:
      print("Balance: ${balance.balance} ${balance
          .assetCode} Issuer: ${balance.assetIssuer}");
  }
}

print("Sequence number: ${account.sequenceNumber}");

for (Signer signer in account.signers) {
  print("Signer public key: ${signer.accountId}");
}

for (String key in account.data.keys) {
  print("Data key: ${key} value: ${account.data[key]}");
}
```

#### 3.2 Check payments

You can check the payments connected to an account:

```dart
Page<OperationResponse> payments = await sdk.payments.forAccount(accountAId).order(RequestBuilderOrder.DESC).execute();

for (OperationResponse response in payments.records) {
  if (response is PaymentOperationResponse) {
    PaymentOperationResponse por = response as PaymentOperationResponse;
    if (por.transactionSuccessful) {
      print("Transaction hash: ${por.transactionHash}");
    }
  }
}
```
You can use:`limit`, `order`, and `cursor` to customize the query. Get the most recent payments for accounts, ledgers and transactions.

#### 3.3 Check others

Just like payments, you you check `assets`, `transactions`, `effects`, `offers`, `operations`, `ledgers` etc. 

```dart
sdk.assets.
sdk.transactions.
sdk.effects.
sdk.offers.
sdk.operations.
sdk.orderBook.
sdk.trades.
// add so on ...
```
### 4. Building and submitting transactions

Example "send native payment":

```dart
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");
String destination = "GDXPJR65A6EXW7ZIWWIQPO6RKTPG3T2VWFBS3EAHJZNFW6ZXG3VWTTSK";

// Load sender account data from the stellar network.
AccountResponse sender = await sdk.accounts.account(senderKeyPair.accountId);

// Build the transaction to send 100 XLM native payment from sender to destination
Transaction transaction = new TransactionBuilder(sender, Network.TESTNET)
    .addOperation(PaymentOperationBuilder(destination,Asset.NATIVE, "100").build())
    .build();

// Sign the transaction with the sender's key pair.
transaction.sign(senderKeyPair);

// Submit the transaction to the stellar network.
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
if (response.success) {
  print("Payment sent");
}
```
## Documentation and Examples

### Examples
| Example | Description | Documentation |
| :--- | :--- | :--- |
| [Create a new account](documentation/sdk_examples/create_account.md)| A new account is created by another account. In the testnet we can also use Freindbot.|[Create account](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#create-account) |
| [Send native payment](documentation/sdk_examples/send_native_payment.md)| A sender sends 100 XLM (Stellar Lumens) native payment to a receiver. |[Payments](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#payment) |
| [Crerate trustline](documentation/sdk_examples/trustline.md) | An trustor account trusts an issuer account for a specific custom token. The issuer account can now send tokens to the trustor account. |[Assets & Trustlines](https://www.stellar.org/developers/guides/concepts/assets.html) and [Change trust](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#change-trust)|
| [Send tokens - non native payment](documentation/sdk_examples/send_non_native_payment.md) | Two accounts trust the same issuer account and custom token. They can now send this custom tokens to each other. | [Assets & Trustlines](https://www.stellar.org/developers/guides/concepts/assets.html) and [Change trust](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#change-trust) and [Payments](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#payment)|
| [Path payments](documentation/sdk_examples/path_payments.md) | Two accounts trust different custom tokens. The sender wants to send token "IOM" but the receiver wants to receive token "ECO".| [Path payment strict send](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#path-payment-strict-send) and [Path payment strict receive](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#path-payment-strict-receive)|
| [Merge accounts](documentation/sdk_examples/merge_account.md) | Merge one account into another. The first account is removed, the second receives the funds. | [Account merge](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#account-merge) |
| [Bump sequence number](documentation/sdk_examples/bump_sequence.md) | In this example we will bump the sequence number of an account to a higher number. | [Bump sequence number](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#bump-sequence) |
| [Manage data](documentation/sdk_examples/manage_data.md) | Sets, modifies, or deletes a data entry (name/value pair) that is attached to a particular account. | [Manage data](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-data) |
| [Manage buy offer](documentation/sdk_examples/manage_buy_offer.md) | Creates, updates, or deletes an offer to buy one asset for another, otherwise known as a "bid" order on a traditional orderbook. | [Manage buy offer](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-buy-offer) |
| [Manage sell offer](documentation/sdk_examples/manage_buy_offer.md) | Creates, updates, or deletes an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook. | [Manage sell offer](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-sell-offer) |
| [Create passive sell offer](documentation/sdk_examples/create_passive_sell_offer.md) | Creates, updates and deletes an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook, _without taking a reverse offer of equal price_. | [Create passive sell offer](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#create-passive-sell-offer) |
| [Change trust](documentation/sdk_examples/change_trust.md) | Creates, updates, and deletes a trustline. | [Change trust](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#change-trust) and [Assets documentation](https://www.stellar.org/developers/learn/concepts/assets.html) |
| [Allow trust](documentation/sdk_examples/allow_trust.md) | Updates the authorized flag of an existing trustline. | [Allow trust](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#allow-trust) and [Assets documentation](https://www.stellar.org/developers/learn/concepts/assets.html) |

Additional examples can be found in the [tests](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/).

### Documentation

You can fild additional documentation including the API documentation in the [documentation folder](documentation/).

## How to contribute

Please read our [Contribution Guide](https://github.com/Soneso/stellar_flutter_sdk/blob/master/CONTRIBUTING.md).

Then please [sign the Contributor License Agreement](https://goo.gl/forms/hS2KOI8d7WcelI892).

## License

The Stellar Sdk for Flutter is licensed under an MIT license. See the [LICENSE](https://github.com/Soneso/stellar_flutter_sdk/blob/master/LICENSE) file for details.
