# SEP-29: Account Memo Requirements

**Purpose:** Refuse to submit a transaction without a memo when one of its payment destinations requires a memo. Exchanges and custodians set this requirement to credit incoming payments to the right customer.
**Prerequisites:** None
**SDK Class:** `StellarSDK` (`checkMemoRequired()` and the six submit methods), `AccountRequiresMemoException`
**Specification:** SEP-0029 v0.5.0, Active

## Overview

An account requires a memo on incoming payments when its data entry `config.memo_required` holds the value `1`. The SDK checks this on the sending side: every submit method of `StellarSDK` runs the check before it sends anything, and throws `AccountRequiresMemoException` when the transaction has no memo and a destination requires one. Nothing is submitted in that case.

The check is on by default: a plain `submitTransaction(transaction)` call runs it.

## Method Signatures

All methods are on `StellarSDK`:

```
Future<void> checkMemoRequired(AbstractTransaction transaction)

Future<SubmitTransactionResponse> submitTransaction(Transaction transaction, {bool skipMemoRequiredCheck = false})
Future<SubmitTransactionResponse> submitFeeBumpTransaction(FeeBumpTransaction feeBumpTransaction, {bool skipMemoRequiredCheck = false})
Future<SubmitAsyncTransactionResponse> submitAsyncTransaction(Transaction transaction, {bool skipMemoRequiredCheck = false})
Future<SubmitAsyncTransactionResponse> submitAsyncFeeBumpTransaction(FeeBumpTransaction feeBumpTransaction, {bool skipMemoRequiredCheck = false})
Future<SubmitTransactionResponse> submitTransactionEnvelopeXdrBase64(String transactionEnvelopeXdrBase64, {bool skipMemoRequiredCheck = false})
Future<SubmitAsyncTransactionResponse> submitAsyncTransactionEnvelopeXdrBase64(String transactionEnvelopeXdrBase64, {bool skipMemoRequiredCheck = false})
```

The exception:

```
class AccountRequiresMemoException implements Exception {
  final String accountId;     // G... account that requires the memo
  final int operationIndex;   // zero-based, over all operations of the checked transaction
  AccountRequiresMemoException(this.accountId, this.operationIndex);
}
```

`operationIndex` is the index of the first payment, path payment or account merge operation that names `accountId` as a non-multiplexed destination. For a fee bump, it indexes the operations of the inner transaction. `toString()` returns `Destination account <accountId> of operation <operationIndex> requires a memo in the transaction.`

`checkMemoRequired()` runs the same check without submitting. It completes normally when the transaction may be sent.

## Quick Start

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed('SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV');
// Account whose config.memo_required data entry is 1
String destinationId = 'GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF';

AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder(destinationId, Asset.NATIVE, '100.0').build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

try {
  await sdk.submitTransaction(transaction);
} on AccountRequiresMemoException catch (e) {
  print(e.accountId);      // destinationId
  print(e.operationIndex); // 0
  // Nothing was submitted. Reload the account: build() advanced its local sequence number
  senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
  transaction = TransactionBuilder(senderAccount)
      .addOperation(PaymentOperationBuilder(destinationId, Asset.NATIVE, '100.0').build())
      .addMemo(MemoText('user-123'))
      .build();
  transaction.sign(senderKeyPair, Network.TESTNET);
  SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
  print(response.success); // true
}
```

## Setting and Removing the Flag

The account that wants memos sets the data entry to the single byte `1` (the UTF-8 encoding of `"1"`):

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair exchangeKeyPair = KeyPair.fromSecretSeed('SAVSYZG4KFDZTL4OHPALGT5VVG3XKIEDFE2CJIWLWK2FTKWDNDMXT4WB');
AccountResponse exchangeAccount = await sdk.accounts.account(exchangeKeyPair.accountId);

Transaction transaction = TransactionBuilder(exchangeAccount)
    .addOperation(ManageDataOperationBuilder(
      'config.memo_required',
      Uint8List.fromList(utf8.encode('1')),
    ).build())
    .build();
transaction.sign(exchangeKeyPair, Network.TESTNET);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
print(response.success); // true
```

To remove the requirement, pass `null` as the value. This deletes the entry:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair exchangeKeyPair = KeyPair.fromSecretSeed('SAVSYZG4KFDZTL4OHPALGT5VVG3XKIEDFE2CJIWLWK2FTKWDNDMXT4WB');
AccountResponse exchangeAccount = await sdk.accounts.account(exchangeKeyPair.accountId);

Transaction transaction = TransactionBuilder(exchangeAccount)
    .addOperation(ManageDataOperationBuilder('config.memo_required', null).build())
    .build();
transaction.sign(exchangeKeyPair, Network.TESTNET);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
print(response.success); // true
```

## How the Check Works

`checkMemoRequired()` and the submit methods run these steps in order:

1. **Unwrap.** A `FeeBumpTransaction` is checked through its `innerTransaction`. Any other `AbstractTransaction` subclass that is not a `Transaction` completes without a request.
2. **Memo present?** If the transaction carries a memo, the check completes without a request. `MemoText`, `MemoId`, `MemoHash` and `MemoReturnHash` all count as a memo; `MemoNone` (also what `Transaction` stores when no memo was added) counts as no memo.
3. **Collect destinations.** For every `PaymentOperation`, `PathPaymentStrictSendOperation`, `PathPaymentStrictReceiveOperation` and `AccountMergeOperation`, take the destination. A multiplexed destination (M-address, `MuxedAccount.id != null`) is skipped. Each distinct `G...` account is kept once, with the index of the first operation that names it. The index counts all operations, including ones without a destination.
4. **Look up, one at a time, in operation order.** For each collected account, `sdk.accounts.account(accountId)` is called:
   - HTTP 404 (`ErrorResponse` with `code == 404`): the account is skipped, the check continues with the next one.
   - Any other error (`ErrorResponse` with another code, `TooManyRequestsException`, `http.ClientException`) is rethrown unchanged, and nothing is submitted.
   - The data entry `config.memo_required` exists and its base64-decoded value, read as UTF-8, is exactly `1`: throw `AccountRequiresMemoException(accountId, index)`. No further account is loaded.
5. Otherwise the check completes normally.

A transaction with a memo, or without a qualifying non-muxed destination, costs no extra request.

**Envelope-string methods.** `submitTransactionEnvelopeXdrBase64()` and `submitAsyncTransactionEnvelopeXdrBase64()` decode the string with `AbstractTransaction.fromEnvelopeXdrString()` and check the result. If decoding throws, the check is skipped and the string is posted unchanged, so Horizon reports the malformed envelope.

## Multiple Destinations

The check stops at the first account that requires a memo. Use `operationIndex` to tell the user which recipient needs one:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed('SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV');
String walletId = 'GB2HGBJLC5NL5J4REQHUXXHTYLIQLKLFA4UEPUN7X5JCPWREODUR2EWG';   // no flag
String exchangeId = 'GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF'; // config.memo_required = 1

AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder(walletId, Asset.NATIVE, '10.0').build())
    .addOperation(PaymentOperationBuilder(exchangeId, Asset.NATIVE, '25.0').build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

try {
  await sdk.submitTransaction(transaction);
} on AccountRequiresMemoException catch (e) {
  print(e.accountId);      // exchangeId
  print(e.operationIndex); // 1: the second operation
}
```

One memo applies to the whole transaction. If different recipients need different memos, send separate transactions.

## Fee Bump Transactions

The fee bump envelope carries no memo and no operations. The inner transaction is checked, and only its signer can add a memo:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed('SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV');
KeyPair feePayerKeyPair = KeyPair.fromSecretSeed('SAWVUHBTLOYJUOZO5B5PRDFYWVUCLWVTEB5MTWT5XGHUPE52WXXOFTLU');
String destinationId = 'GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF'; // config.memo_required = 1

AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
Transaction innerTransaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder(destinationId, Asset.NATIVE, '100.0').build())
    .build();
innerTransaction.sign(senderKeyPair, Network.TESTNET);

FeeBumpTransaction feeBump = FeeBumpTransactionBuilder(innerTransaction)
    .setBaseFee(200)
    .setFeeAccount(feePayerKeyPair.accountId)
    .build();
feeBump.sign(feePayerKeyPair, Network.TESTNET);

try {
  await sdk.submitFeeBumpTransaction(feeBump);
} on AccountRequiresMemoException catch (e) {
  // The inner transaction pays an account that requires a memo;
  // nothing was submitted
  print(e.accountId);      // destinationId
  print(e.operationIndex); // 0, an index into the inner transaction
}
```

## Muxed Destinations

A multiplexed destination is never looked up, even when its base account requires a memo, because the muxed id identifies the customer. This holds for `MuxedAccount` destinations, M-address strings, path payments and account merges:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed('SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV');
String baseAccountId = 'GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF'; // config.memo_required = 1

MuxedAccount muxedDestination = MuxedAccount(baseAccountId, BigInt.from(12345));

AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder.forMuxedDestinationAccount(
            muxedDestination, Asset.NATIVE, '100.0')
        .build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

// No lookup, no exception, no memo needed
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
print(response.success); // true
```

`BigInt.zero` is a valid muxed id: only `MuxedAccount.id == null` means "not multiplexed".

## Skipping the Check

`skipMemoRequiredCheck: true` submits with no lookups and no envelope decoding. The network does not enforce SEP-29, so a memo-less payment to a flagged account then succeeds:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed('SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV');
String destinationId = 'GC5K7EUJIROBOQHHG4TFUAGZVWVALJTNESW7ZQLYMEFZGZFHNWFEKTHF'; // config.memo_required = 1

AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder(destinationId, Asset.NATIVE, '100.0').build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

// No destination lookup; the network does not enforce SEP-29
SubmitTransactionResponse response =
    await sdk.submitTransaction(transaction, skipMemoRequiredCheck: true);
print(response.success); // true
```

Use it only after running `checkMemoRequired()` yourself, or for destinations you control.

## Common Pitfalls

**Catching only `ErrorResponse` around the submit call**

```dart
// WRONG: AccountRequiresMemoException is not an ErrorResponse; it escapes this handler
try {
  await sdk.submitTransaction(transaction);
} on ErrorResponse catch (e) {
  print('Horizon error ${e.code}');
}

// CORRECT: handle the memo requirement separately
try {
  SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
  print(response.success);
} on AccountRequiresMemoException catch (e) {
  // Nothing was submitted; ask the user for a memo
  print('Memo required by ${e.accountId} (operation ${e.operationIndex})');
} on ErrorResponse catch (e) {
  // A destination lookup failed with a status other than 404
  print('Horizon error ${e.code}');
}
```

**Disabling the check "to avoid the extra request"**

```dart
// WRONG: turns off SEP-29 protection for every payment
await sdk.submitTransaction(transaction, skipMemoRequiredCheck: true);

// CORRECT: keep the default. A transaction with a memo makes no lookup at all;
// lookups only happen for memo-less transactions with non-muxed payment destinations
await sdk.submitTransaction(transaction);
```

**Rebuilding after the exception with the same account object**

```dart
// WRONG: build() already advanced senderAccount's sequence number; this
// transaction skips a sequence number and fails with tx_bad_seq
transaction = TransactionBuilder(senderAccount)
    .addOperation(paymentOp)
    .addMemo(MemoText('user-123'))
    .build();

// CORRECT: reload the account before rebuilding
senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
transaction = TransactionBuilder(senderAccount)
    .addOperation(paymentOp)
    .addMemo(MemoText('user-123'))
    .build();
```

**Testing the data entry by key presence only**

```dart
// WRONG: an entry holding '0' or any other value does not require a memo
AccountResponse destination = await sdk.accounts.account(destinationId);
bool requiresMemo = destination.data.keys.contains('config.memo_required');

// CORRECT: let the SDK check it; the value must decode to exactly '1'
try {
  await sdk.checkMemoRequired(transaction);
} on AccountRequiresMemoException catch (e) {
  print('Memo required by ${e.accountId}');
}
```

**Setting the flag with a value other than `1`**

```dart
// WRONG: 'true', '1 ' or 'yes' are ignored by the check; senders are not stopped
ManageDataOperationBuilder('config.memo_required', Uint8List.fromList(utf8.encode('true'))).build();

// CORRECT: the single byte '1'
ManageDataOperationBuilder('config.memo_required', Uint8List.fromList(utf8.encode('1'))).build();
```

## Error Handling

| Situation | What happens |
|-----------|--------------|
| No memo, a destination's `config.memo_required` is `1` | `AccountRequiresMemoException`; nothing submitted |
| Destination does not exist (HTTP 404) | Skipped by the check; the network rejects the payment with `op_no_destination` |
| Lookup fails with an HTTP status other than 404 or 429 | `ErrorResponse` (its `code` is the status); nothing submitted |
| Lookup is rate limited (HTTP 429) | `TooManyRequestsException`; nothing submitted |
| Transport failure during a lookup | `http.ClientException`; nothing submitted |
| Envelope string cannot be decoded | Check skipped; Horizon's response reports the bad envelope |

The check validates memo presence, not memo type. Any memo passes.

A payment to an account that does not exist passes the check and fails on the network:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarSDK sdk = StellarSDK.TESTNET;
KeyPair senderKeyPair = KeyPair.fromSecretSeed('SDAYCKMBSHSMI5MDI3M3CUOV73ARJGPHKW7YQFCHOMSE3FGM7XNTBTVV');
String destinationId = KeyPair.random().accountId; // valid id, not on the network

AccountResponse senderAccount = await sdk.accounts.account(senderKeyPair.accountId);
Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder(destinationId, Asset.NATIVE, '10.0').build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);

await sdk.checkMemoRequired(transaction); // completes: 404 destinations are skipped

SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
print(response.success); // false
print(response.extras?.resultCodes?.operationsResultCodes); // contains op_no_destination
```

## Related SEPs

- SEP-07 ([sep-07.md](sep-07.md)) — `signAndSubmitTransaction()` submits through `submitTransaction()` or `submitFeeBumpTransaction()` when the URI has no `url:` callback, so it can throw `AccountRequiresMemoException`
- SEP-23 — muxed accounts (M-addresses), which the check skips; `MuxedAccount` is covered in `api_reference.md`
