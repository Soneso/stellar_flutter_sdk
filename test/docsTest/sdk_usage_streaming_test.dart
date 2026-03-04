@Timeout(const Duration(seconds: 600))

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  // Shared accounts funded in setUpAll
  late KeyPair account1;
  late KeyPair account2;

  setUpAll(() async {
    account1 = KeyPair.random();
    account2 = KeyPair.random();
    await FriendBot.fundTestAccount(account1.accountId);
    await FriendBot.fundTestAccount(account2.accountId);
  });

  test('sdk-usage: Stream Payments', () async {
    // Set up stream before sending payment
    Completer<OperationResponse> completer = Completer();

    StreamSubscription<OperationResponse> subscription = sdk.payments
        .forAccount(account2.accountId)
        .cursor("now")
        .stream()
        .listen((OperationResponse payment) {
      if (!completer.isCompleted) {
        completer.complete(payment);
      }
    });

    // Small delay to ensure stream is established
    await Future.delayed(Duration(seconds: 2));

    // Send a payment to trigger the stream
    AccountResponse sender =
        await sdk.accounts.account(account1.accountId);
    Transaction tx = TransactionBuilder(sender)
        .addOperation(PaymentOperationBuilder(
          account2.accountId,
          Asset.NATIVE,
          "1",
        ).build())
        .build();
    tx.sign(account1, Network.TESTNET);
    await sdk.submitTransaction(tx);

    // Wait for stream event (with timeout)
    OperationResponse event =
        await completer.future.timeout(Duration(seconds: 30));

    expect(event, isNotNull);
    if (event is PaymentOperationResponse) {
      expect(event.amount, "1.0000000");
    }

    await subscription.cancel();
  });

  test('sdk-usage: Stream Transactions', () async {
    Completer<TransactionResponse> completer = Completer();

    StreamSubscription<TransactionResponse> subscription = sdk.transactions
        .forAccount(account1.accountId)
        .cursor("now")
        .stream()
        .listen((TransactionResponse tx) {
      if (!completer.isCompleted) {
        completer.complete(tx);
      }
    });

    await Future.delayed(Duration(seconds: 2));

    // Send a transaction to trigger the stream
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);
    Transaction tx = TransactionBuilder(account)
        .addOperation(PaymentOperationBuilder(
          account2.accountId,
          Asset.NATIVE,
          "1",
        ).build())
        .build();
    tx.sign(account1, Network.TESTNET);
    await sdk.submitTransaction(tx);

    TransactionResponse event =
        await completer.future.timeout(Duration(seconds: 30));

    expect(event.hash, isNotNull);
    expect(event.operationCount, 1);

    await subscription.cancel();
  });

  test('sdk-usage: Stream Ledgers', () async {
    Completer<LedgerResponse> completer = Completer();

    StreamSubscription<LedgerResponse> subscription = sdk.ledgers
        .cursor("now")
        .stream()
        .listen((LedgerResponse ledger) {
      if (!completer.isCompleted) {
        completer.complete(ledger);
      }
    });

    // Wait for next ledger close (typically ~5-6 seconds on testnet)
    LedgerResponse event =
        await completer.future.timeout(Duration(seconds: 30));

    expect(event.sequence, greaterThan(0));

    await subscription.cancel();
  });

  test('sdk-usage: Stream Effects', () async {
    Completer<EffectResponse> completer = Completer();

    StreamSubscription<EffectResponse> subscription = sdk.effects
        .forAccount(account1.accountId)
        .cursor("now")
        .stream()
        .listen((EffectResponse effect) {
      if (!completer.isCompleted) {
        completer.complete(effect);
      }
    });

    await Future.delayed(Duration(seconds: 2));

    // Send a payment to generate effects
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);
    Transaction tx = TransactionBuilder(account)
        .addOperation(PaymentOperationBuilder(
          account2.accountId,
          Asset.NATIVE,
          "1",
        ).build())
        .build();
    tx.sign(account1, Network.TESTNET);
    await sdk.submitTransaction(tx);

    EffectResponse event =
        await completer.future.timeout(Duration(seconds: 30));
    expect(event.type, isNotNull);

    await subscription.cancel();
  });

  test('sdk-usage: Stream Operations', () async {
    Completer<OperationResponse> completer = Completer();

    StreamSubscription<OperationResponse> subscription = sdk.operations
        .forAccount(account1.accountId)
        .cursor("now")
        .stream()
        .listen((OperationResponse op) {
      if (!completer.isCompleted) {
        completer.complete(op);
      }
    });

    await Future.delayed(Duration(seconds: 2));

    // Send a payment to generate operations
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);
    Transaction tx = TransactionBuilder(account)
        .addOperation(PaymentOperationBuilder(
          account2.accountId,
          Asset.NATIVE,
          "1",
        ).build())
        .build();
    tx.sign(account1, Network.TESTNET);
    await sdk.submitTransaction(tx);

    OperationResponse event =
        await completer.future.timeout(Duration(seconds: 30));
    expect(event.type, isNotNull);

    await subscription.cancel();
  });
}
