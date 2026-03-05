@Timeout(const Duration(seconds: 600))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  // Shared accounts funded in setUpAll
  late KeyPair account1;
  late KeyPair account2;
  late String txHash;

  setUpAll(() async {
    account1 = KeyPair.random();
    account2 = KeyPair.random();
    await FriendBot.fundTestAccount(account1.accountId);
    await FriendBot.fundTestAccount(account2.accountId);

    // Create a transaction for query tests
    AccountResponse sender =
        await sdk.accounts.account(account1.accountId);
    Transaction tx = TransactionBuilder(sender)
        .addOperation(PaymentOperationBuilder(
          account2.accountId,
          Asset.NATIVE,
          "10",
        ).build())
        .addMemo(Memo.text("test-query"))
        .build();
    tx.sign(account1, Network.TESTNET);
    SubmitTransactionResponse response = await sdk.submitTransaction(tx);
    txHash = response.hash!;
  });

  test('sdk-usage: Get Single Account', () async {
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);
    expect(account.sequenceNumber, isNotNull);
    expect(account.subentryCount, isNotNull);
  });

  test('sdk-usage: Check if Account Exists', () async {
    // Existing account
    bool exists = true;
    try {
      await sdk.accounts.account(account1.accountId);
    } on ErrorResponse catch (e) {
      if (e.code == 404) exists = false;
    }
    expect(exists, true);

    // Non-existent account
    bool fakeExists = true;
    try {
      await sdk.accounts.account(KeyPair.random().accountId);
    } on ErrorResponse catch (e) {
      if (e.code == 404) fakeExists = false;
    }
    expect(fakeExists, false);
  });

  test('sdk-usage: Query Accounts by Signer', () async {
    Page<AccountResponse> accountsPage = await sdk.accounts
        .forSigner(account1.accountId)
        .limit(50)
        .order(RequestBuilderOrder.DESC)
        .execute();

    expect(accountsPage.records.isNotEmpty, true);
    // Account should be in the list (it signs for itself)
    bool found = false;
    for (AccountResponse acct in accountsPage.records) {
      if (acct.accountId == account1.accountId) found = true;
    }
    expect(found, true);
  });

  test('sdk-usage: Get Single Transaction', () async {
    TransactionResponse tx =
        await sdk.transactions.transaction(txHash);
    expect(tx.ledger, isNotNull);
    expect(tx.feeCharged, isNotNull);
    expect(tx.operationCount, 1);
  });

  test('sdk-usage: Transactions for Account', () async {
    Page<TransactionResponse> txPage = await sdk.transactions
        .forAccount(account1.accountId)
        .limit(20)
        .order(RequestBuilderOrder.DESC)
        .execute();

    expect(txPage.records.isNotEmpty, true);
    for (TransactionResponse tx in txPage.records) {
      expect(tx.hash, isNotNull);
    }
  });

  test('sdk-usage: Include Failed Transactions', () async {
    Page<TransactionResponse> txPage = await sdk.transactions
        .forAccount(account1.accountId)
        .includeFailed(true)
        .execute();

    expect(txPage.records.isNotEmpty, true);
  });

  test('sdk-usage: Get Single Operation', () async {
    // Get operations from our transaction
    Page<OperationResponse> opsPage =
        await sdk.operations.forTransaction(txHash).execute();
    expect(opsPage.records.isNotEmpty, true);

    String opId = opsPage.records.first.id;
    OperationResponse op = await sdk.operations.operation(opId);
    expect(op.transactionHash, txHash);
  });

  test('sdk-usage: Operations for Account', () async {
    Page<OperationResponse> opsPage = await sdk.operations
        .forAccount(account1.accountId)
        .limit(50)
        .order(RequestBuilderOrder.DESC)
        .execute();

    expect(opsPage.records.isNotEmpty, true);
    for (OperationResponse op in opsPage.records) {
      expect(op.id, isNotNull);
      expect(op.type, isNotNull);
    }
  });

  test('sdk-usage: Handling Operation Types', () async {
    Page<OperationResponse> opsPage =
        await sdk.operations.forAccount(account1.accountId).execute();

    bool foundPayment = false;
    for (OperationResponse op in opsPage.records) {
      if (op is PaymentOperationResponse) {
        foundPayment = true;
        expect(op.amount, isNotNull);
        expect(op.to, isNotNull);
      } else if (op is CreateAccountOperationResponse) {
        expect(op.account, isNotNull);
      }
    }
    expect(foundPayment, true);
  });

  test('sdk-usage: Effect Queries', () async {
    Page<EffectResponse> effectsPage = await sdk.effects
        .forAccount(account1.accountId)
        .limit(50)
        .execute();

    expect(effectsPage.records.isNotEmpty, true);
    for (EffectResponse effect in effectsPage.records) {
      expect(effect.type, isNotNull);
    }
  });

  test('sdk-usage: Ledger Queries', () async {
    Page<LedgerResponse> ledgersPage = await sdk.ledgers
        .limit(10)
        .order(RequestBuilderOrder.DESC)
        .execute();

    expect(ledgersPage.records.isNotEmpty, true);

    // Get specific ledger
    int ledgerSeq = ledgersPage.records.first.sequence;
    LedgerResponse ledger = await sdk.ledgers.ledger(ledgerSeq);
    expect(ledger.sequence, ledgerSeq);
  });

  test('sdk-usage: Payment Queries', () async {
    Page<OperationResponse> paymentsPage = await sdk.payments
        .forAccount(account1.accountId)
        .execute();

    expect(paymentsPage.records.isNotEmpty, true);
  });

  test('sdk-usage: Fee Statistics', () async {
    FeeStatsResponse feeStats = await sdk.feeStats.execute();

    expect(feeStats.feeCharged.min, isNotNull);
    expect(feeStats.feeCharged.mode, isNotNull);
    expect(feeStats.feeCharged.p90, isNotNull);
    expect(feeStats.maxFee.min, isNotNull);
    expect(feeStats.maxFee.mode, isNotNull);
    expect(feeStats.lastLedgerBaseFee, isNotNull);
    expect(feeStats.lastLedgerCapacityUsage, isNotNull);
  });

  test('sdk-usage: Pagination', () async {
    // First page
    Page<TransactionResponse> page = await sdk.transactions
        .forAccount(account1.accountId)
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();

    expect(page.records.isNotEmpty, true);

    // Get next page using cursor from last record
    if (page.records.isNotEmpty) {
      Page<TransactionResponse> nextPage = await sdk.transactions
          .forAccount(account1.accountId)
          .limit(5)
          .order(RequestBuilderOrder.DESC)
          .cursor(page.records.last.pagingToken)
          .execute();
      // Next page may or may not have records
      expect(nextPage, isNotNull);
    }
  });

  test('sdk-usage: Error Handling - Horizon HTTP', () async {
    try {
      await sdk.accounts.account(KeyPair.random().accountId);
      fail("Should have thrown");
    } on ErrorResponse catch (e) {
      expect(e.code, 404);
    }
  });

  test('sdk-usage: Error Handling - Transaction Submission', () async {
    // Build a transaction that will fail (send to non-existent account)
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);

    // Try to pay more than we have
    PaymentOperation paymentOp = PaymentOperationBuilder(
      account2.accountId,
      Asset.NATIVE,
      "999999999",
    ).build();

    Transaction transaction = TransactionBuilder(account)
        .addOperation(paymentOp)
        .build();
    transaction.sign(account1, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, false);
    expect(response.extras?.resultCodes?.transactionResultCode, isNotNull);
  });
}
