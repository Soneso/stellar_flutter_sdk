# SEP-29: Account Memo Requirements

SEP-29 prevents lost funds by allowing accounts to require incoming payments include a memo. Exchanges and custodians use this to identify which customer a payment belongs to. Without a memo, deposits can't be credited to the right user.

**Use SEP-29 when:**
- Sending payments to exchanges or custodial services
- Building a payment flow that needs to validate destinations before submission
- Running an exchange and requiring memos on incoming deposits

**Spec:** [SEP-0029](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md)

## Quick Example

Check whether destination accounts require a memo before submitting a payment. Query the destination account's data entries for `config.memo_required`. If the destination requires a memo and the transaction lacks one, rebuild the transaction with a memo attached:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A");
String destinationId = "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT";

AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);

PaymentOperation paymentOp = PaymentOperationBuilder(
  destinationId,
  Asset.NATIVE,
  "100.0",
).build();

// Check if destination requires a memo
AccountResponse destAccount = await sdk.accounts.account(destinationId);
bool requiresMemo = destAccount.data.keys.contains("config.memo_required");

Transaction transaction;
if (requiresMemo) {
  print("Account $destinationId requires a memo. Rebuild with one.");
  transaction = TransactionBuilder(senderAccount)
      .addOperation(paymentOp)
      .addMemo(MemoText("user-123"))
      .build();
} else {
  transaction = TransactionBuilder(senderAccount)
      .addOperation(paymentOp)
      .build();
}

transaction.sign(senderKeyPair, Network.TESTNET);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
```

## How It Works

Accounts signal memo requirement by setting a data entry with key `config.memo_required` and value `1` (following the [SEP-18](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0018.md) namespace convention).

**Checking memo requirements manually:**

The Flutter SDK does not have a built-in `checkMemoRequired()` method. Instead, query each destination account via `sdk.accounts.account(destinationId)` and check its `data` property for the `config.memo_required` key:

- Skip fee bump transactions -- check the inner transaction instead
- Skip if the transaction already has a memo
- Skip muxed accounts (M-addresses) since they encode user identification in the address
- Query Horizon for each destination's account data
- Check for the `config.memo_required` data entry key

**Checked operation types:** `PaymentOperation`, `PathPaymentStrictSendOperation`, `PathPaymentStrictReceiveOperation`, `AccountMergeOperation`

## Detailed Usage

### Setting Memo Requirement on Your Account

Exchanges and custodial services should set the `config.memo_required` data entry to ensure senders include a memo. Use a `ManageDataOperation` to add the entry:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair exchangeKeyPair = KeyPair.fromSecretSeed("SBMSVD4KKELKGZXHBUQTIROWUAPQASDX7KEJITARP4VMZ6KLUHOGPTYW");
AccountResponse exchangeAccount = await sdk.accounts.account(exchangeKeyPair.accountId);

// Set memo_required flag
ManageDataOperation setMemoRequired = ManageDataOperationBuilder(
  "config.memo_required",
  Uint8List.fromList(utf8.encode("1")),
).build();

Transaction transaction = TransactionBuilder(exchangeAccount)
    .addOperation(setMemoRequired)
    .build();

transaction.sign(exchangeKeyPair, Network.TESTNET);
await sdk.submitTransaction(transaction);
```

To remove the requirement later, pass `null` as the value. This deletes the data entry entirely:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

ManageDataOperation removeMemoRequired = ManageDataOperationBuilder(
  "config.memo_required",
  null,
).build();
```

### Checking Multiple Destinations

When a transaction contains multiple payment operations, check all destination accounts. Return the first account ID requiring a memo so you can inform the user which recipient needs one:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A");
AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);

// Batch payment to multiple recipients
List<String> destinations = [
  "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT",
  "GCKUD4BHIYSBER7DI6TPMYQ4KNDEUKVMN44VKSUQGEFXWLNTHIIQE7FB",
];

// Check each destination for memo requirement
for (String destId in destinations) {
  AccountResponse destAccount = await sdk.accounts.account(destId);
  if (destAccount.data.keys.contains("config.memo_required")) {
    print("Cannot batch: $destId requires a memo.");
    break;
  }
}
```

### Account Merge Operations

The memo check also applies to `AccountMergeOperation`, since merging sends the account balance to the destination. Validate before merging an account:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair sourceKeyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A");
String destinationId = "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT";

AccountResponse sourceAccount = await sdk.accounts.account(sourceKeyPair.accountId);

AccountMergeOperation mergeOp = AccountMergeOperationBuilder(destinationId).build();

// Check if destination requires a memo
AccountResponse destAccount = await sdk.accounts.account(destinationId);
bool requiresMemo = destAccount.data.keys.contains("config.memo_required");

Transaction transaction;
if (requiresMemo) {
  // Rebuild with memo before merging
  transaction = TransactionBuilder(sourceAccount)
      .addOperation(mergeOp)
      .addMemo(MemoText("closing-account"))
      .build();
} else {
  transaction = TransactionBuilder(sourceAccount)
      .addOperation(mergeOp)
      .build();
}

transaction.sign(sourceKeyPair, Network.TESTNET);
await sdk.submitTransaction(transaction);
```

### Multiplexed Accounts (M-addresses)

Per the SEP-29 specification, multiplexed accounts are excluded from memo requirement checks. Muxed accounts (M-addresses) already encode user identification in the address itself, making a separate memo unnecessary:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A");
AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);

// Create a muxed destination with user ID embedded
String baseAccountId = "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT";
MuxedAccount muxedDestination = MuxedAccount(baseAccountId, BigInt.from(12345));

PaymentOperation paymentOp = PaymentOperationBuilder.forMuxedDestinationAccount(
  muxedDestination,
  Asset.NATIVE,
  "100.0",
).build();

Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(paymentOp)
    .build();

// Muxed accounts encode user ID in the address, so no memo check needed
transaction.sign(senderKeyPair, Network.TESTNET);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
```

## Integration with Payment Flows

Use memo requirement checking as part of your payment validation flow. Check requirements before showing the confirmation screen to provide a better user experience:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Sends a payment, checking memo requirements first.
/// Returns a map with 'success', 'error', 'message', or 'hash'.
Future<Map<String, dynamic>> sendPayment(
  StellarSDK sdk,
  KeyPair senderKeyPair,
  String destinationId,
  String amount, {
  String? memo,
}) async {
  AccountResponse senderAccount;
  try {
    senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
  } catch (e) {
    return {
      'success': false,
      'error': 'account_not_found',
      'message': 'Sender account does not exist',
    };
  }

  // Check if destination requires a memo
  bool requiresMemo = false;
  try {
    AccountResponse destAccount = await sdk.accounts.account(destinationId);
    requiresMemo = destAccount.data.keys.contains("config.memo_required");
  } catch (e) {
    return {
      'success': false,
      'error': 'destination_lookup_failed',
      'message': 'Could not verify destination account',
    };
  }

  if (requiresMemo && memo == null) {
    return {
      'success': false,
      'error': 'memo_required',
      'account': destinationId,
    };
  }

  PaymentOperation paymentOp = PaymentOperationBuilder(
    destinationId,
    Asset.NATIVE,
    amount,
  ).build();

  TransactionBuilder builder = TransactionBuilder(senderAccount);
  builder.addOperation(paymentOp);

  if (memo != null) {
    builder.addMemo(MemoText(memo));
  }

  Transaction transaction = builder.build();
  transaction.sign(senderKeyPair, Network.TESTNET);
  SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

  return {'success': response.success, 'hash': response.hash};
}
```

## Error Handling

Querying Horizon for each destination account's data can fail. Common causes include the destination account not existing yet or Horizon being unavailable:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
String destinationId = "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOUJ3UBEZ3ENO5GT";

try {
  AccountResponse destAccount = await sdk.accounts.account(destinationId);
  bool requiresMemo = destAccount.data.keys.contains("config.memo_required");
  if (requiresMemo) {
    print("Destination requires a memo.");
  }
} catch (e) {
  // Destination account might not exist yet, or Horizon is unavailable
  print("Could not verify memo requirement: $e");
}
```

**Important notes:**
- Fee bump transactions don't carry memo information directly. Check the inner transaction before wrapping it
- The check only validates memo *presence*, not memo *type* (SEP-29 intentionally omits type validation)

## Related SEPs

- **[SEP-10](sep-10.md)** -- Web authentication (often used by exchanges that require memos)
- **[SEP-24](sep-24.md)** -- Interactive deposit/withdrawal (anchors provide deposit memos)

---

[Back to SEP Overview](README.md)
