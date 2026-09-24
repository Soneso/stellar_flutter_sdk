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

  test('sep-29: Quick Example', () async {
    // Setup: a funded sender and a destination that requires a memo
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair destinationKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(destinationKeyPair.accountId);
    await _setMemoRequired(sdk, destinationKeyPair);

    // Snippet from sep-29.md "Quick Example"
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
      fail("Expected AccountRequiresMemoException");
    } on AccountRequiresMemoException catch (e) {
      // The destination requires a memo; nothing was submitted
      expect(e.accountId, destinationId);
      expect(e.operationIndex, 0);
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
    expect(response.success, true);
  });

  test('sep-29: Checking Multiple Destinations', () async {
    // Setup: a sender, a destination without the flag and one with it
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair walletKeyPair = KeyPair.random();
    KeyPair exchangeKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(walletKeyPair.accountId);
    await FriendBot.fundTestAccount(exchangeKeyPair.accountId);
    await _setMemoRequired(sdk, exchangeKeyPair);

    // Snippet from sep-29.md "Checking Multiple Destinations"
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
      fail("Expected AccountRequiresMemoException");
    } on AccountRequiresMemoException catch (e) {
      // operationIndex is the zero-based index of the operation that
      // names the account, here the second payment
      expect(e.accountId, exchangeKeyPair.accountId);
      expect(e.operationIndex, 1);
    }
  });

  test('sep-29: Account Merge', () async {
    // Setup: an account to merge and a destination that requires a memo
    KeyPair sourceKeyPair = KeyPair.random();
    KeyPair destinationKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(sourceKeyPair.accountId);
    await FriendBot.fundTestAccount(destinationKeyPair.accountId);
    await _setMemoRequired(sdk, destinationKeyPair);

    // Snippet from sep-29.md "Account Merge"
    String destinationId = destinationKeyPair.accountId;
    AccountResponse sourceAccount =
        await sdk.accounts.account(sourceKeyPair.accountId);

    Transaction transaction = TransactionBuilder(sourceAccount)
        .addOperation(AccountMergeOperationBuilder(destinationId).build())
        .build();
    transaction.sign(sourceKeyPair, Network.TESTNET);

    try {
      await sdk.submitTransaction(transaction);
      fail("Expected AccountRequiresMemoException");
    } on AccountRequiresMemoException catch (e) {
      // The merge destination requires a memo; nothing was submitted
      expect(e.accountId, destinationId);
      expect(e.operationIndex, 0);
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
    expect(response.success, true);
  });

  test('sep-29: Multiplexed Accounts (M-addresses)', () async {
    // Setup: a sender and a base account that requires a memo
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair baseKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(baseKeyPair.accountId);
    await _setMemoRequired(sdk, baseKeyPair);

    // Snippet from sep-29.md "Multiplexed Accounts (M-addresses)"
    AccountResponse senderAccount =
        await sdk.accounts.account(senderKeyPair.accountId);

    // The muxed id identifies the customer, so no memo is needed
    MuxedAccount muxedDestination =
        MuxedAccount(baseKeyPair.accountId, BigInt.from(12345));
    expect(muxedDestination.accountId.startsWith("M"), true);

    Transaction transaction = TransactionBuilder(senderAccount)
        .addOperation(PaymentOperationBuilder.forMuxedDestinationAccount(
                muxedDestination, Asset.NATIVE, "100.0")
            .build())
        .build();
    transaction.sign(senderKeyPair, Network.TESTNET);

    // Muxed destinations are not looked up; the payment is submitted
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);
  });

  test('sep-29: Fee Bump Transactions', () async {
    // Setup: a sender, a fee payer and a destination that requires a memo
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair feePayerKeyPair = KeyPair.random();
    KeyPair destinationKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(feePayerKeyPair.accountId);
    await FriendBot.fundTestAccount(destinationKeyPair.accountId);
    await _setMemoRequired(sdk, destinationKeyPair);

    // Snippet from sep-29.md "Fee Bump Transactions"
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
      fail("Expected AccountRequiresMemoException");
    } on AccountRequiresMemoException catch (e) {
      // The inner transaction pays an account that requires a memo;
      // nothing was submitted
      expect(e.accountId, destinationId);
      expect(e.operationIndex, 0);
    }
  });

  test('sep-29: Skipping the Check', () async {
    // Setup: a sender and a destination that requires a memo
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair destinationKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(destinationKeyPair.accountId);
    await _setMemoRequired(sdk, destinationKeyPair);

    // Snippet from sep-29.md "Skipping the Check"
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
    expect(response.success, true);
  });

  test('sep-29: Integration sendPayment function', () async {
    // Setup: a sender and a destination that requires a memo
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair destinationKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(destinationKeyPair.accountId);
    await _setMemoRequired(sdk, destinationKeyPair);

    // Snippet from sep-29.md "Integration sendPayment function"
    Map<String, dynamic> result = await sendPayment(
      sdk,
      senderKeyPair,
      destinationKeyPair.accountId,
      "10.0",
    );
    expect(result['success'], false);
    expect(result['error'], 'memo_required');
    expect(result['account'], destinationKeyPair.accountId);

    result = await sendPayment(
      sdk,
      senderKeyPair,
      destinationKeyPair.accountId,
      "10.0",
      memo: "user-123",
    );
    expect(result['success'], true);
    expect(result['hash'], isNotNull);
  });

  test('sep-29: Error Handling', () async {
    // Setup: a funded sender
    KeyPair senderKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);

    // Snippet from sep-29.md "Error Handling"
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
    expect(response.success, false);
    expect(response.extras?.resultCodes?.operationsResultCodes,
        contains("op_no_destination"));
  });
}

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

/// Test setup: sets `config.memo_required` to `1` on [accountKeyPair].
Future<void> _setMemoRequired(StellarSDK sdk, KeyPair accountKeyPair) async {
  AccountResponse account =
      await sdk.accounts.account(accountKeyPair.accountId);
  Transaction transaction = TransactionBuilder(account)
      .addOperation(ManageDataOperationBuilder(
        "config.memo_required",
        Uint8List.fromList(utf8.encode("1")),
      ).build())
      .build();
  transaction.sign(accountKeyPair, Network.TESTNET);
  SubmitTransactionResponse response =
      await sdk.submitTransaction(transaction);
  expect(response.success, true);
}
