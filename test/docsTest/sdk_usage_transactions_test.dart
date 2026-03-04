@Timeout(const Duration(seconds: 600))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  // Shared accounts funded in setUpAll
  late KeyPair sender;
  late KeyPair receiver;
  late KeyPair feePayer;

  setUpAll(() async {
    sender = KeyPair.random();
    receiver = KeyPair.random();
    feePayer = KeyPair.random();
    await FriendBot.fundTestAccount(sender.accountId);
    await FriendBot.fundTestAccount(receiver.accountId);
    await FriendBot.fundTestAccount(feePayer.accountId);
  });

  test('sdk-usage: Simple Payments', () async {
    AccountResponse senderAccount =
        await sdk.accounts.account(sender.accountId);

    PaymentOperation paymentOp = PaymentOperationBuilder(
      receiver.accountId,
      Asset.NATIVE,
      "100.50",
    ).build();

    Transaction transaction = TransactionBuilder(senderAccount)
        .addOperation(paymentOp)
        .build();

    transaction.sign(sender, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    expect(response.success, true);
    expect(response.hash, isNotNull);
  });

  test('sdk-usage: Multi-Operation Transactions', () async {
    KeyPair funderKeyPair = sender;
    KeyPair newAccountKeyPair = KeyPair.random();
    String newAccountId = newAccountKeyPair.accountId;

    AccountResponse funder =
        await sdk.accounts.account(funderKeyPair.accountId);

    // We need an issuer account for the USD asset
    KeyPair issuerKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(issuerKeyPair.accountId);

    Asset usdAsset = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

    // Set up issuer: create trustline on issuer is not needed (issuer can always send)

    // 1. Create the new account
    CreateAccountOperation createAccountOp = CreateAccountOperationBuilder(
      newAccountId,
      "5",
    ).build();

    // 2. Establish trustline for USD (new account is source)
    ChangeTrustOperation trustlineOp = ChangeTrustOperationBuilder(
      usdAsset,
      "10000",
    ).setSourceAccount(newAccountId).build();

    // Build transaction with create + trustline
    Transaction transaction = TransactionBuilder(funder)
        .addOperation(createAccountOp)
        .addOperation(trustlineOp)
        .build();

    transaction.sign(funderKeyPair, Network.TESTNET);
    transaction.sign(newAccountKeyPair, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Verify new account exists
    AccountResponse newAccount =
        await sdk.accounts.account(newAccountId);
    expect(newAccount.accountId, newAccountId);
  });

  test('sdk-usage: Memos, Time Bounds, and Fees', () async {
    AccountResponse account =
        await sdk.accounts.account(sender.accountId);

    PaymentOperation operation = PaymentOperationBuilder(
      receiver.accountId,
      Asset.NATIVE,
      "1",
    ).build();

    // Add memo
    Transaction transaction = TransactionBuilder(account)
        .addOperation(operation)
        .addMemo(Memo.text("Payment for invoice #1234"))
        .build();

    transaction.sign(sender, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Verify the memo
    TransactionResponse txResponse =
        await sdk.transactions.transaction(response.hash!);
    Memo? memo = txResponse.memo;
    expect(memo, isNotNull);
    expect(memo is MemoText, true);
    expect((memo as MemoText).text, "Payment for invoice #1234");
  });

  test('sdk-usage: Time Bounds', () async {
    AccountResponse account =
        await sdk.accounts.account(sender.accountId);

    PaymentOperation operation = PaymentOperationBuilder(
      receiver.accountId,
      Asset.NATIVE,
      "1",
    ).build();

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    TimeBounds timeBounds = TimeBounds(now - 60, now + 300);
    Transaction transaction = TransactionBuilder(account)
        .addOperation(operation)
        .addTimeBounds(timeBounds)
        .build();

    transaction.sign(sender, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);
  });

  test('sdk-usage: Custom Fee', () async {
    AccountResponse account =
        await sdk.accounts.account(sender.accountId);

    PaymentOperation operation = PaymentOperationBuilder(
      receiver.accountId,
      Asset.NATIVE,
      "1",
    ).build();

    Transaction transaction = TransactionBuilder(account)
        .addOperation(operation)
        .setMaxOperationFee(200)
        .build();

    transaction.sign(sender, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);
  });

  test('sdk-usage: Fee Bump Transactions', () async {
    // Build inner transaction
    AccountResponse userAccount =
        await sdk.accounts.account(sender.accountId);

    Transaction innerTransaction = TransactionBuilder(userAccount)
        .addOperation(PaymentOperationBuilder(
          receiver.accountId,
          Asset.NATIVE,
          "10",
        ).build())
        .build();

    innerTransaction.sign(sender, Network.TESTNET);

    // Build fee bump
    FeeBumpTransaction feeBumpTx = FeeBumpTransactionBuilder(innerTransaction)
        .setBaseFee(300)
        .setFeeAccount(feePayer.accountId)
        .build();

    feeBumpTx.sign(feePayer, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitFeeBumpTransaction(feeBumpTx);
    expect(response.success, true);
  });
}
