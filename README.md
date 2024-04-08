# [Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk)

![Dart](https://img.shields.io/badge/Dart-green.svg)
![Flutter](https://img.shields.io/badge/Flutter-blue.svg)

The Soneso open source Stellar SDK for Flutter is build with Dart and provides APIs to build and sign transactions, connect and query [Horizon](https://github.com/stellar/go/tree/master/services/horizon).

## Installation

### From pub.dev
1. Add the dependency to your pubspec.yaml file:
```
dependencies:
  stellar_flutter_sdk: ^1.7.6
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

The SDK is a Flutter Dart package. Here is a step by step that we recommend:

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

#### Deterministic generation

The Stellar Ecosystem Proposal [SEP-005](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md) describes methods for key derivation for Stellar Accounts. This improves key storage and moving keys between wallets and apps.

##### Generate mnemonic

```dart
String mnemonic =  await Wallet.generate24WordsMnemonic();
print(mnemonic);
// mango debris lumber vivid bar risk prosper verify photo put ridge sell range pet indoor lava sister around panther brush twice cattle sauce romance
```

##### Generate key pairs
```dart
Wallet wallet = await Wallet.from("mango debris lumber vivid bar risk prosper verify photo put ridge sell range pet indoor lava sister around panther brush twice cattle sauce romance");

KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
print("${keyPair0.accountId} : ${keyPair0.secretSeed}");
// GBYTVBTOVXBIT23X4YUEE32QBAAA537OAF553FWABUAZHT3FNPN3FUGG : SBEQZ4XGS434POXNQYUXQYFV6JYUHV56U2MNMUZBBBLBGR5X6PUUCYO5

KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
print("${keyPair1.accountId} : ${keyPair1.secretSeed}");
// GD5JFZ6U4TBKLWOVGAJQZ4CWRHNVXIFF65BBXZG6UEQE74RUXWAKQVQN : SD3IXULYMZKB6ML7AJW4OLAXKN6U3BYDUMOZLKUZTCCGZXUFXAS7NKIO
```

Supported languages are: english, french, spanish, italian, korean, japanese, simplified chinese and traditional chinese. Find more details in our [SEP-005 examples](documentation/sdk_examples/sep-0005-key-derivation.md).

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
Transaction transaction = new TransactionBuilder(accA)
        .addOperation(createAccBuilder.build())
        .build();

/// Sign the transaction with the key pair of your existing account.
transaction.sign(keyA, Network.PUBLIC);

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

Horizon has SSE support for push data. You can use it like this:
```dart
String accountId = "GDXPJR65A6EXW7ZIWWIQPO6RKTPG3T2VWFBS3EAHJZNFW6ZXG3VWTTSK";

sdk.payments.forAccount(accountId).cursor("now").stream().listen((response) {
  if (response is PaymentOperationResponse) {
    switch (response.assetType) {
      case Asset.TYPE_NATIVE:
        print("Payment of ${response.amount} XLM from ${response.sourceAccount} received.");
        break;
      default:
        print("Payment of ${response.amount} ${response.assetCode} from ${response.sourceAccount} received.");
    }
  }
});
```
#### 3.3 Check others

Just like payments, you can check `assets`, `transactions`, `effects`, `offers`, `operations`, `ledgers` etc. 

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
Transaction transaction = new TransactionBuilder(sender)
    .addOperation(PaymentOperationBuilder(destination,Asset.NATIVE, "100").build())
    .build();

// Sign the transaction with the sender's key pair.
transaction.sign(senderKeyPair, Network.TESTNET);

// Submit the transaction to the stellar network.
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
if (response.success) {
  print("Payment sent");
}
```

### 5. Resolving a stellar address by using Federation

```dart
FederationResponse response = await Federation.resolveStellarAddress("bob*soneso.com");

print(response.stellarAddress);
// bob*soneso.com

print(response.accountId);
// GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI

print(response.memoType);
// text

print(response.memo);
// hello memo text
```

## Documentation and Examples

### Examples
| Example                                                                                                  | Description                                                                                                                                                                                                                                           | Documentation                                                                                                                                                                                                                                                                                        |
|:---------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Create a new account](documentation/sdk_examples/create_account.md)                                     | A new account is created by another account. In the testnet we can also use Freindbot.                                                                                                                                                                | [Create account](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#create-account)                                                                                                                                                                                          |
| [Send native payment](documentation/sdk_examples/send_native_payment.md)                                 | A sender sends 100 XLM (Stellar Lumens) native payment to a receiver.                                                                                                                                                                                 | [Payments](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#payment)                                                                                                                                                                                                       |
| [Create trustline](documentation/sdk_examples/trustline.md)                                              | An trustor account trusts an issuer account for a specific custom token. The issuer account can now send tokens to the trustor account.                                                                                                               | [Assets & Trustlines](https://www.stellar.org/developers/guides/concepts/assets.html) and [Change trust](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#change-trust)                                                                                                    |
| [Send tokens - non native payment](documentation/sdk_examples/send_non_native_payment.md)                | Two accounts trust the same issuer account and custom token. They can now send this custom tokens to each other.                                                                                                                                      | [Assets & Trustlines](https://www.stellar.org/developers/guides/concepts/assets.html) and [Change trust](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#change-trust) and [Payments](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#payment) |
| [Path payments](documentation/sdk_examples/path_payments.md)                                             | Two accounts trust different custom tokens. The sender wants to send token "IOM" but the receiver wants to receive token "ECO".                                                                                                                       | [Path payment strict send](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#path-payment-strict-send) and [Path payment strict receive](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#path-payment-strict-receive)                            |
| [Merge accounts](documentation/sdk_examples/merge_account.md)                                            | Merge one account into another. The first account is removed, the second receives the funds.                                                                                                                                                          | [Account merge](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#account-merge)                                                                                                                                                                                            |
| [Bump sequence number](documentation/sdk_examples/bump_sequence.md)                                      | In this example we will bump the sequence number of an account to a higher number.                                                                                                                                                                    | [Bump sequence number](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#bump-sequence)                                                                                                                                                                                     |
| [Manage data](documentation/sdk_examples/manage_data.md)                                                 | Sets, modifies, or deletes a data entry (name/value pair) that is attached to a particular account.                                                                                                                                                   | [Manage data](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-data)                                                                                                                                                                                                |
| [Manage buy offer](documentation/sdk_examples/manage_buy_offer.md)                                       | Creates, updates, or deletes an offer to buy one asset for another, otherwise known as a "bid" order on a traditional orderbook.                                                                                                                      | [Manage buy offer](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-buy-offer)                                                                                                                                                                                      |
| [Manage sell offer](documentation/sdk_examples/manage_sell_offer.md)                                     | Creates, updates, or deletes an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook.                                                                                                          | [Manage sell offer](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-sell-offer)                                                                                                                                                                                    |
| [Create passive sell offer](documentation/sdk_examples/create_passive_sell_offer.md)                     | Creates, updates and deletes an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook, _without taking a reverse offer of equal price_.                                                         | [Create passive sell offer](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#create-passive-sell-offer)                                                                                                                                                                     |
| [Change trust](documentation/sdk_examples/change_trust.md)                                               | Creates, updates, and deletes a trustline.                                                                                                                                                                                                            | [Change trust](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#change-trust) and [Assets documentation](https://www.stellar.org/developers/learn/concepts/assets.html)                                                                                                     |
| [Allow trust](documentation/sdk_examples/allow_trust.md)                                                 | Updates the authorized flag of an existing trustline.                                                                                                                                                                                                 | [Allow trust](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#allow-trust) and [Assets documentation](https://www.stellar.org/developers/learn/concepts/assets.html)                                                                                                       |
| [Stream payments](documentation/sdk_examples/stream_payments.md)                                         | Listens for payments received by a given account.                                                                                                                                                                                                     | [Streaming](https://developers.stellar.org/api/introduction/streaming/)                                                                                                                                                                                                                              |
| [Fee bump transaction](documentation/sdk_examples/fee_bump.md)                                           | Fee bump transactions allow an arbitrary account to pay the fee for a transaction.                                                                                                                                                                    | [Fee bump transactions](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0015.md)                                                                                                                                                                                                    |
| [Muxed accounts](documentation/sdk_examples/muxed_account_payment.md)                                    | In this example we will see how to use a muxed account in a payment operation.                                                                                                                                                                        | [First-class multiplexed accounts](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0027.md)                                                                                                                                                                                         |
| [SEP-0001: stellar.toml](documentation/sdk_examples/sep-0001-toml.md)                                    | In this example you can find out how to obtain data about an organization’s Stellar integration.                                                                                                                                                      | [SEP-0001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)                                                                                                                                                                                                            |
| [SEP-0002: Federation](documentation/sdk_examples/sep-0002-federation.md)                                | This example shows how to resolve a stellar address, a stellar account id, a transaction id and a forward by using the federation protocol.                                                                                                           | [SEP-0002](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md)                                                                                                                                                                                                            |
| [SEP-0005: Key derivation](documentation/sdk_examples/sep-0005-key-derivation.md)                        | In this examples you can see how to generate 12 or 24 words mnemonics for different languages using the Flutter SDK, how to generate key pairs from a mnemonic (with and without BIP 39 passphrase) and how to generate key pairs from a BIP 39 seed. | [SEP-0005](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md)                                                                                                                                                                                                            |
| [SEP-0006: Deposit and Withdrawal API](documentation/sdk_examples/sep-0006-transfer.md)                  | In this examples you can see how to use the sdk to communicate with anchors.                                                                                                                                                                          | [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)                                                                                                                                                                                                            |
| [SEP-0007: URI Scheme to facilitate delegated signing](documentation/sdk_examples/sep-0007-urischeme.md) | In this examples you can see how to use the sdk to support SEP-0007 in your wallet.                                                                                                                                                                   | [SEP-0007](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md)                                                                                                                                                                                                            |
| [SEP-0010: Stellar Web Authentication](documentation/sdk_examples/sep-0010-webauth.md)                   | This example shows how to authenticate with any web service which requires a Stellar account ownership verification.                                                                                                                                  | [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)                                                                                                                                                                                                            |
| [SEP-0011: Txrep](documentation/sdk_examples/sep-0011-txrep.md)                                          | This example shows how to  to generate Txrep (human-readable low-level representation of Stellar transactions) from a transaction and how to create a transaction object from a Txrep string.                                                         | [SEP-0011](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md)                                                                                                                                                                                                            |
| [SEP-0012: KYC API](documentation/sdk_examples/sep-0012-kyc.md)                                          | In this examples you can see how to use the sdk to send KYC data to anchors and other services.                                                                                                                                                       | [SEP-0012](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md)                                                                                                                                                                                                            |
| [SEP-0024: Hosted Deposit and Withdrawal](documentation/sdk_examples/sep-0024.md)                        | In this examples you can see how to interact with anchors in a standard way defined by SEP-0024                                                                                                                                                       | [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)                                                                                                                                                                                                            |
| [SEP-0030: Account Recovery](documentation/sdk_examples/sep-0030.md)                                     | In this examples you can learn how to recover accounts as defined by SEP-0030                                                                                                                                                                         | [SEP-0030](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md)                                                                                                                                                                                                            |
| [SEP-0038: Quotes](documentation/sdk_examples/sep-0038.md)                                               | In this examples you can learn how to get quotes as defined by SEP-0038                                                                                                                                                                               | [SEP-0038](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)                                                                                                                                                                                                            |


Additional examples can be found in the [tests](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/).

### Documentation

You can find additional documentation including the API documentation in the [documentation folder](documentation/).

### SEPs implemented

- [SEP-0001 (stellar.toml)](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
- [SEP-0002 (Federation)](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md)
- [SEP-0005 (Key derivation)](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md)
- [SEP-0006: Deposit and Withdrawal API](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md) 
- [SEP-0007: URI Scheme to facilitate delegated signing](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md)
- [SEP-0009: Standard KYC Fields](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md)
- [SEP-0010 (Stellar Web Authentication)](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)
- [SEP-0011 (Txrep)](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md)
- [SEP-0012: KYC API](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md)
- [SEP-0023: Strkeys](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md)
- [SEP-0024: Hosted Deposit and Withdrawal](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
- [SEP-0029: Account Memo Requirements](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md)
- [SEP-0030: Account Recovery](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md)
- [SEP-0038: Anchor RFQ API](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)

## Soroban support

This SDK provides [support for Soroban](https://github.com/Soneso/stellar_flutter_sdk/blob/master/soroban.md). 


## How to contribute

Please read our [Contribution Guide](https://github.com/Soneso/stellar_flutter_sdk/blob/master/CONTRIBUTING.md).

Then please [sign the Contributor License Agreement](https://goo.gl/forms/hS2KOI8d7WcelI892).

## License

The Stellar Sdk for Flutter is licensed under an MIT license. See the [LICENSE](https://github.com/Soneso/stellar_flutter_sdk/blob/master/LICENSE) file for details.
