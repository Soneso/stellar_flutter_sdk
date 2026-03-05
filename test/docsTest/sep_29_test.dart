@Timeout(const Duration(seconds: 300))

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('sep-29: Setting Memo Requirement on Your Account', () async {
    // Snippet from sep-29.md "Setting Memo Requirement on Your Account"
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
    expect(response.success, true);

    // Verify the data entry was set
    AccountResponse updatedAccount =
        await sdk.accounts.account(exchangeKeyPair.accountId);
    expect(updatedAccount.data.keys.contains("config.memo_required"), true);
  });

  test('sep-29: Removing Memo Requirement', () async {
    // Snippet from sep-29.md "Removing memo requirement"
    KeyPair exchangeKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(exchangeKeyPair.accountId);

    // First set the memo requirement
    AccountResponse exchangeAccount =
        await sdk.accounts.account(exchangeKeyPair.accountId);

    ManageDataOperation setMemoRequired = ManageDataOperationBuilder(
      "config.memo_required",
      Uint8List.fromList(utf8.encode("1")),
    ).build();

    Transaction setTx = TransactionBuilder(exchangeAccount)
        .addOperation(setMemoRequired)
        .build();

    setTx.sign(exchangeKeyPair, Network.TESTNET);
    SubmitTransactionResponse setResponse =
        await sdk.submitTransaction(setTx);
    expect(setResponse.success, true);

    // Now remove it
    exchangeAccount =
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
    expect(removeResponse.success, true);

    // Verify the data entry was removed
    AccountResponse updatedAccount =
        await sdk.accounts.account(exchangeKeyPair.accountId);
    expect(
        updatedAccount.data.keys.contains("config.memo_required"), false);
  });

  test('sep-29: Quick Example - Check memo requirement', () async {
    // Snippet from sep-29.md "Quick Example"
    // Setup: create destination with memo_required set
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair destKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(destKeyPair.accountId);

    // Set memo_required on destination
    AccountResponse destSetupAccount =
        await sdk.accounts.account(destKeyPair.accountId);
    ManageDataOperation setFlag = ManageDataOperationBuilder(
      "config.memo_required",
      Uint8List.fromList(utf8.encode("1")),
    ).build();
    Transaction setupTx = TransactionBuilder(destSetupAccount)
        .addOperation(setFlag)
        .build();
    setupTx.sign(destKeyPair, Network.TESTNET);
    await sdk.submitTransaction(setupTx);

    // Now run the quick example logic
    String destinationId = destKeyPair.accountId;
    AccountResponse senderAccount =
        await sdk.accounts.account(senderKeyPair.accountId);

    PaymentOperation paymentOp = PaymentOperationBuilder(
      destinationId,
      Asset.NATIVE,
      "100.0",
    ).build();

    // Check if destination requires a memo
    AccountResponse destAccount =
        await sdk.accounts.account(destinationId);
    bool requiresMemo =
        destAccount.data.keys.contains("config.memo_required");

    expect(requiresMemo, true);

    Transaction transaction;
    if (requiresMemo) {
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
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);
  });

  test('sep-29: Checking Multiple Destinations', () async {
    // Snippet from sep-29.md "Checking Multiple Destinations"
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair dest1KeyPair = KeyPair.random();
    KeyPair dest2KeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(dest1KeyPair.accountId);
    await FriendBot.fundTestAccount(dest2KeyPair.accountId);

    // Set memo_required on dest1 only
    AccountResponse dest1Setup =
        await sdk.accounts.account(dest1KeyPair.accountId);
    ManageDataOperation setFlag = ManageDataOperationBuilder(
      "config.memo_required",
      Uint8List.fromList(utf8.encode("1")),
    ).build();
    Transaction setupTx = TransactionBuilder(dest1Setup)
        .addOperation(setFlag)
        .build();
    setupTx.sign(dest1KeyPair, Network.TESTNET);
    await sdk.submitTransaction(setupTx);

    // Check each destination for memo requirement
    List<String> destinations = [
      dest1KeyPair.accountId,
      dest2KeyPair.accountId,
    ];

    String? accountRequiringMemo;
    for (String destId in destinations) {
      AccountResponse destAccount = await sdk.accounts.account(destId);
      if (destAccount.data.keys.contains("config.memo_required")) {
        accountRequiringMemo = destId;
        break;
      }
    }

    expect(accountRequiringMemo, dest1KeyPair.accountId);
  });

  test('sep-29: Account Merge with memo check', () async {
    // Snippet from sep-29.md "Account Merge Operations"
    KeyPair sourceKeyPair = KeyPair.random();
    KeyPair destKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(sourceKeyPair.accountId);
    await FriendBot.fundTestAccount(destKeyPair.accountId);

    String destinationId = destKeyPair.accountId;
    AccountResponse sourceAccount =
        await sdk.accounts.account(sourceKeyPair.accountId);

    AccountMergeOperation mergeOp =
        AccountMergeOperationBuilder(destinationId).build();

    // Check if destination requires a memo (it doesn't in this case)
    AccountResponse destAccount =
        await sdk.accounts.account(destinationId);
    bool requiresMemo =
        destAccount.data.keys.contains("config.memo_required");

    expect(requiresMemo, false);

    Transaction transaction;
    if (requiresMemo) {
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
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);
  });

  test('sep-29: Multiplexed Accounts (M-addresses)', () async {
    // Snippet from sep-29.md "Multiplexed Accounts"
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair baseKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(baseKeyPair.accountId);

    AccountResponse senderAccount =
        await sdk.accounts.account(senderKeyPair.accountId);

    // Create a muxed destination with user ID embedded
    String baseAccountId = baseKeyPair.accountId;
    MuxedAccount muxedDestination =
        MuxedAccount(baseAccountId, BigInt.from(12345));

    PaymentOperation paymentOp =
        PaymentOperationBuilder.forMuxedDestinationAccount(
      muxedDestination,
      Asset.NATIVE,
      "100.0",
    ).build();

    Transaction transaction = TransactionBuilder(senderAccount)
        .addOperation(paymentOp)
        .build();

    // Muxed accounts encode user ID in the address, so no memo check needed
    // Verify the destination is a muxed account (M-address)
    expect(muxedDestination.accountId.startsWith('M'), true);

    transaction.sign(senderKeyPair, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);
  });

  test('sep-29: Integration sendPayment function', () async {
    // Snippet from sep-29.md "Integration with Payment Flows"
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair destKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(destKeyPair.accountId);

    // Set memo_required on destination
    AccountResponse destSetup =
        await sdk.accounts.account(destKeyPair.accountId);
    ManageDataOperation setFlag = ManageDataOperationBuilder(
      "config.memo_required",
      Uint8List.fromList(utf8.encode("1")),
    ).build();
    Transaction setupTx = TransactionBuilder(destSetup)
        .addOperation(setFlag)
        .build();
    setupTx.sign(destKeyPair, Network.TESTNET);
    await sdk.submitTransaction(setupTx);

    // Test: sending without memo should fail validation
    Map<String, dynamic> result1 = await _sendPayment(
      sdk,
      senderKeyPair,
      destKeyPair.accountId,
      "10.0",
    );
    expect(result1['success'], false);
    expect(result1['error'], 'memo_required');

    // Test: sending with memo should succeed
    Map<String, dynamic> result2 = await _sendPayment(
      sdk,
      senderKeyPair,
      destKeyPair.accountId,
      "10.0",
      memo: "user-123",
    );
    expect(result2['success'], true);
    expect(result2['hash'], isNotNull);
  });

  test('sep-29: Error Handling - nonexistent account', () async {
    // Snippet from sep-29.md "Error Handling"
    // Use a valid but nonexistent account ID
    KeyPair nonexistentKeyPair = KeyPair.random();
    String destinationId = nonexistentKeyPair.accountId;

    bool caughtError = false;
    try {
      await sdk.accounts.account(destinationId);
    } catch (e) {
      // Destination account does not exist
      caughtError = true;
    }

    expect(caughtError, true);
  });
}

/// Helper matching the sendPayment function from the doc.
Future<Map<String, dynamic>> _sendPayment(
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
