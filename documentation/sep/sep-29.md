# SEP-29: Account Memo Requirements

SEP-29 prevents lost funds by allowing accounts to require incoming payments include a memo. Exchanges and custodians use this to identify which customer a payment belongs to. Without a memo, deposits can't be credited to the right user.

**Use SEP-29 when:**
- Sending payments to exchanges or custodial services
- Building a payment flow that needs to validate destinations before submission
- Running an exchange and requiring memos on incoming deposits

**Spec:** [SEP-0029](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md)

## Quick Example

The submit methods of `StellarSDK` check the destinations before sending. If the transaction has no memo and a destination account requires one, `submitTransaction()` throws `AccountRequiresMemoException` and nothing is submitted. Catch it and rebuild the transaction with a memo:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV");
// An account whose config.memo_required data entry is set to 1
KeyPair destinationKeyPair = KeyPair.fromAccountId("GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF");

String destinationId = destinationKeyPair.accountId;
AccountResponse senderAccount =
    await sdk.accounts.account(senderKeyPair.accountId);

Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(
        PaymentOperationBuilder(destinationId, Asset.NATIVE, "100.0")
            .build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

try {
  await sdk.submitTransaction(transaction);
} on AccountRequiresMemoException catch (e) {
  // The destination requires a memo; nothing was submitted
}

// Reload the sender account: build() advanced its local sequence number
senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
transaction = TransactionBuilder(senderAccount)
    .addOperation(
        PaymentOperationBuilder(destinationId, Asset.NATIVE, "100.0")
            .build())
    .addMemo(MemoText("user-123"))
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

SubmitTransactionResponse response =
    await sdk.submitTransaction(transaction);
```

In the catch block, `e.accountId` is `destinationId` and `e.operationIndex` is `0`, the index of the payment.

## How It Works

Accounts signal a memo requirement by setting a data entry with key `config.memo_required` and value `1` (following the [SEP-18](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0018.md) namespace convention).

All six submit methods of `StellarSDK` run the check before they send anything: `submitTransaction()`, `submitFeeBumpTransaction()`, `submitAsyncTransaction()`, `submitAsyncFeeBumpTransaction()`, `submitTransactionEnvelopeXdrBase64()` and `submitAsyncTransactionEnvelopeXdrBase64()`. The check works like this:

- A fee bump transaction is checked through its inner transaction.
- A transaction that carries a memo passes without any request. Every memo type counts (`MemoText`, `MemoId`, `MemoHash`, `MemoReturnHash`); `MemoNone` counts as no memo.
- Multiplexed destinations (M-addresses) are skipped. The muxed id already identifies the customer.
- Each remaining destination account is loaded from Horizon once, in operation order, one request at a time. An account named by several operations is loaded only once.
- A destination Horizon does not know (HTTP 404) is skipped. The network decides about the submission, and a payment to a missing account fails with `op_no_destination`.
- The first destination whose `config.memo_required` entry decodes to `1` ends the check with `AccountRequiresMemoException`. No further account is loaded and nothing is submitted.

The exception has two fields. `accountId` is the account (`G...`) that requires the memo. `operationIndex` is the zero-based index, over all operations of the checked transaction, of the first payment, path payment or account merge operation that names that account as a non-multiplexed destination.

**Checked operation types:** `PaymentOperation`, `PathPaymentStrictSendOperation`, `PathPaymentStrictReceiveOperation`, `AccountMergeOperation`

The two envelope-string methods decode the base64 envelope to check it. An envelope the SDK cannot decode is submitted unchecked, so Horizon reports the malformed envelope in its response.

Pass `skipMemoRequiredCheck: true` to any submit method to submit without the check and without any account lookup.

To run the check without submitting, call `sdk.checkMemoRequired(transaction)`. It takes a `Transaction` or a `FeeBumpTransaction`, throws the same `AccountRequiresMemoException`, and completes normally when the transaction may be sent. Use it to validate a payment before you show a confirmation screen.

## Detailed Usage

### Setting Memo Requirement on Your Account

Exchanges and custodial services set the `config.memo_required` data entry so that senders include a memo. Use a `ManageDataOperation` to add the entry:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

StellarSDK sdk = StellarSDK.TESTNET;

KeyPair exchangeKeyPair = KeyPair.random();
await FriendBot.fundTestAccount(exchangeKeyPair.accountId);

AccountResponse exchangeAccount =
    await sdk.accounts.account(exchangeKeyPair.accountId);

// Set memo_required flag
ManageDataOperation setMemoRequired = ManageDataOperationBuilder(
  "config.memo_required",
  Uint8List.fromList(utf8.encode("1")),
).build();

Transaction transaction = TransactionBuilder(exchangeAccount)
    .addOperation(setMemoRequired)
    .build();

transaction.sign(exchangeKeyPair, Network.TESTNET);
SubmitTransactionResponse response =
    await sdk.submitTransaction(transaction);
```

The value must be the single character `1`. The check ignores any other value.

### Removing Memo Requirement

To remove the requirement, pass `null` as the value. This deletes the data entry:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair exchangeKeyPair = KeyPair.fromSecretSeed("SAVSYZG4KFDZTL4OHPALGT5VVG3XKIEDFE2CJIWLWK2FTKWDNDMXT4WB");

AccountResponse exchangeAccount =
    await sdk.accounts.account(exchangeKeyPair.accountId);

ManageDataOperation removeMemoRequired = ManageDataOperationBuilder(
  "config.memo_required",
  null,
).build();

Transaction removeTx = TransactionBuilder(exchangeAccount)
    .addOperation(removeMemoRequired)
    .build();

removeTx.sign(exchangeKeyPair, Network.TESTNET);
SubmitTransactionResponse removeResponse =
    await sdk.submitTransaction(removeTx);
```

### Checking Multiple Destinations

When a transaction pays several accounts, the exception tells you which one needs the memo. Here the first payment goes to a wallet without the flag and the second to an exchange that sets it:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV");
KeyPair walletKeyPair = KeyPair.fromAccountId("GB2HGBJLC5NL5J4REQHUXXHTYLIQLKLFA4UEPUN7X5JCPWREODUR2EWG");
// An account whose config.memo_required data entry is set to 1
KeyPair exchangeKeyPair = KeyPair.fromAccountId("GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF");

AccountResponse senderAccount =
    await sdk.accounts.account(senderKeyPair.accountId);

Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder(
            walletKeyPair.accountId, Asset.NATIVE, "10.0")
        .build())
    .addOperation(PaymentOperationBuilder(
            exchangeKeyPair.accountId, Asset.NATIVE, "25.0")
        .build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

try {
  await sdk.submitTransaction(transaction);
} on AccountRequiresMemoException catch (e) {
  // operationIndex is the zero-based index of the operation that
  // names the account, here the second payment
}
```

The exception carries the exchange's account id in `e.accountId` and `1` in `e.operationIndex`. The index counts every operation of the transaction, including operations that have no destination.

### Account Merge

The check also covers `AccountMergeOperation`, since a merge sends the whole balance to the destination:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair sourceKeyPair = KeyPair.fromSecretSeed("SCHGTSKTV3BRZCWCFHBVDRVBHII3LB52KNRG2TP4FIKGTNACZP5OL3VT");
// An account whose config.memo_required data entry is set to 1
KeyPair destinationKeyPair = KeyPair.fromAccountId("GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF");

String destinationId = destinationKeyPair.accountId;
AccountResponse sourceAccount =
    await sdk.accounts.account(sourceKeyPair.accountId);

Transaction transaction = TransactionBuilder(sourceAccount)
    .addOperation(AccountMergeOperationBuilder(destinationId).build())
    .build();
transaction.sign(sourceKeyPair, Network.TESTNET);

try {
  await sdk.submitTransaction(transaction);
} on AccountRequiresMemoException catch (e) {
  // The merge destination requires a memo; nothing was submitted
}

// Reload the source account and merge with a memo
sourceAccount = await sdk.accounts.account(sourceKeyPair.accountId);
transaction = TransactionBuilder(sourceAccount)
    .addOperation(AccountMergeOperationBuilder(destinationId).build())
    .addMemo(MemoText("closing-account"))
    .build();
transaction.sign(sourceKeyPair, Network.TESTNET);

SubmitTransactionResponse response =
    await sdk.submitTransaction(transaction);
```

The first submission throws with `e.accountId` set to `destinationId` and `e.operationIndex` set to `0`. The merge with the memo goes through.

### Multiplexed Accounts (M-addresses)

SEP-29 excludes multiplexed destinations from the check. A muxed account (M-address) encodes the customer id in the address, so a separate memo is not needed, even when the base account sets `config.memo_required`:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV");
// An account whose config.memo_required data entry is set to 1
KeyPair baseKeyPair = KeyPair.fromAccountId("GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF");

AccountResponse senderAccount =
    await sdk.accounts.account(senderKeyPair.accountId);

// The muxed id identifies the customer, so no memo is needed
MuxedAccount muxedDestination =
    MuxedAccount(baseKeyPair.accountId, BigInt.from(12345));

Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder.forMuxedDestinationAccount(
            muxedDestination, Asset.NATIVE, "100.0")
        .build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

// Muxed destinations are not looked up; the payment is submitted
SubmitTransactionResponse response =
    await sdk.submitTransaction(transaction);
```

The same applies to an M-address passed as a string destination, and to muxed destinations of path payments and account merges.

### Fee Bump Transactions

A fee bump envelope carries no memo and no operations of its own, so `submitFeeBumpTransaction()` checks the inner transaction. The example has three accounts: the sender signs the inner payment, a separate fee payer signs the fee bump, and the destination requires a memo:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV");
KeyPair feePayerKeyPair = KeyPair.fromSecretSeed("SAWVUHBTLOYJUOZO5B5PRDFYWVUCLWVTEB5MTWT5XGHUPE52WXXOFTLU");
// An account whose config.memo_required data entry is set to 1
KeyPair destinationKeyPair = KeyPair.fromAccountId("GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF");

String destinationId = destinationKeyPair.accountId;
AccountResponse senderAccount =
    await sdk.accounts.account(senderKeyPair.accountId);

Transaction innerTransaction = TransactionBuilder(senderAccount)
    .addOperation(
        PaymentOperationBuilder(destinationId, Asset.NATIVE, "100.0")
            .build())
    .build();
innerTransaction.sign(senderKeyPair, Network.TESTNET);

FeeBumpTransaction feeBump = FeeBumpTransactionBuilder(innerTransaction)
    .setBaseFee(200)
    .setFeeAccount(feePayerKeyPair.accountId)
    .build();
feeBump.sign(feePayerKeyPair, Network.TESTNET);

// The inner transaction is checked: it has no memo
try {
  await sdk.submitFeeBumpTransaction(feeBump);
} on AccountRequiresMemoException catch (e) {
  // The inner transaction pays an account that requires a memo;
  // nothing was submitted
}
```

The exception reports `destinationId` and operation index `0` of the inner transaction. The memo belongs to the inner transaction, so a fee payer cannot add one: the sender has to rebuild and sign the inner transaction with a memo.

### Skipping the Check

Pass `skipMemoRequiredCheck: true` to submit without the check. No destination account is loaded. The network itself does not enforce SEP-29, so this payment to an account that requires a memo succeeds:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV");
// An account whose config.memo_required data entry is set to 1
KeyPair destinationKeyPair = KeyPair.fromAccountId("GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF");

AccountResponse senderAccount =
    await sdk.accounts.account(senderKeyPair.accountId);

Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder(
            destinationKeyPair.accountId, Asset.NATIVE, "100.0")
        .build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

// No destination lookup; the network does not enforce SEP-29
SubmitTransactionResponse response = await sdk
    .submitTransaction(transaction, skipMemoRequiredCheck: true);
```

Skip the check only when you have already run it, for example with `checkMemoRequired()` before a confirmation screen, or when the destinations are accounts you control. The check makes no request for a transaction that carries a memo, so there is nothing to save there.

## Integration with Payment Flows

### Integration sendPayment function

A payment helper can turn the exception into a result the UI understands. This one loads the sender account on every call, so a retry with a memo uses the current sequence number:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Sends a payment and reports a SEP-29 memo requirement as a result map.
Future<Map<String, dynamic>> sendPayment(
  StellarSDK sdk,
  KeyPair senderKeyPair,
  String destinationId,
  String amount, {
  String? memo,
}) async {
  // Load the sender on every call so each transaction uses the current
  // sequence number
  AccountResponse senderAccount =
      await sdk.accounts.account(senderKeyPair.accountId);

  TransactionBuilder builder = TransactionBuilder(senderAccount)
      .addOperation(
          PaymentOperationBuilder(destinationId, Asset.NATIVE, amount)
              .build());
  if (memo != null) {
    builder.addMemo(MemoText(memo));
  }

  Transaction transaction = builder.build();
  transaction.sign(senderKeyPair, Network.TESTNET);

  try {
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    return {'success': response.success, 'hash': response.hash};
  } on AccountRequiresMemoException catch (e) {
    return {
      'success': false,
      'error': 'memo_required',
      'account': e.accountId,
      'operationIndex': e.operationIndex,
    };
  }
}
```

Calling it without a memo for an account that requires one returns `'success': false`, `'error': 'memo_required'` and the account id. After the user enters a memo, the second call goes through:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV");
// An account whose config.memo_required data entry is set to 1
KeyPair destinationKeyPair = KeyPair.fromAccountId("GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF");

Map<String, dynamic> result = await sendPayment(
  sdk,
  senderKeyPair,
  destinationKeyPair.accountId,
  "10.0",
);

result = await sendPayment(
  sdk,
  senderKeyPair,
  destinationKeyPair.accountId,
  "10.0",
  memo: "user-123",
);
```

## Error Handling

The check skips destinations Horizon does not know. A payment to an account that does not exist passes the check, and the network rejects it on submission:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV");

// A valid account id that does not exist on the network
String destinationId = KeyPair.random().accountId;
AccountResponse senderAccount =
    await sdk.accounts.account(senderKeyPair.accountId);

Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(
        PaymentOperationBuilder(destinationId, Asset.NATIVE, "10.0")
            .build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

// The check skips destinations Horizon does not know
await sdk.checkMemoRequired(transaction);

// The network rejects the payment to the missing account
SubmitTransactionResponse response =
    await sdk.submitTransaction(transaction);
```

`response.success` is `false`, and `response.extras?.resultCodes?.operationsResultCodes` contains `op_no_destination`.

A destination lookup that fails for another reason stops the check, and the submit method throws that error without submitting: `ErrorResponse` for an HTTP status other than 404 or 429, `TooManyRequestsException` when Horizon rate limits the lookup, or `http.ClientException` (from `package:http`) for a transport failure. `checkMemoRequired()` throws the same errors.

**Important notes:**
- The check validates memo *presence*, not memo *type*. SEP-29 leaves the memo type to the recipient, so any memo passes.

## Related SEPs

- **[SEP-07](sep-07.md)** -- URI scheme (`signAndSubmitTransaction()` runs the check when it submits to the network)
- **[SEP-10](sep-10.md)** -- Web authentication (often used by exchanges that require memos)
- **[SEP-23](sep-23.md)** -- Muxed accounts (M-addresses, which the check skips)
- **[SEP-24](sep-24.md)** -- Interactive deposit/withdrawal (anchors provide deposit memos)

---

[Back to SEP Overview](README.md)
