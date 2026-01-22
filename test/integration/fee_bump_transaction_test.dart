@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../tests_util.dart';

void main() {
  String testOn = 'testnet'; //'futurenet';
  StellarSDK sdk =
      testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  test('submit fee bump transaction', () async {
    KeyPair sourceKeyPair = KeyPair.random();
    String sourceId = sourceKeyPair.accountId;
    KeyPair destinationKeyPair = KeyPair.random();
    String destinationId = destinationKeyPair.accountId;
    KeyPair payerKeyPair = KeyPair.random();
    String payerId = payerKeyPair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(sourceId);
      await FriendBot.fundTestAccount(payerId);
    } else {
      await FuturenetFriendBot.fundTestAccount(sourceId);
      await FuturenetFriendBot.fundTestAccount(payerId);
    }

    AccountResponse sourceAccount = await sdk.accounts.account(sourceId);

    // fund account C.
    Transaction innerTx = new TransactionBuilder(sourceAccount)
        .addOperation(
            new CreateAccountOperationBuilder(destinationId, "10").build())
        .build();

    innerTx.sign(sourceKeyPair, network);

    FeeBumpTransaction feeBump = new FeeBumpTransactionBuilder(innerTx)
        .setBaseFee(200)
        .setFeeAccount(payerId)
        .build();
    feeBump.sign(payerKeyPair, network);

    SubmitTransactionResponse response =
        await sdk.submitFeeBumpTransaction(feeBump);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(feeBump, response);

    AccountResponse destination = await sdk.accounts.account(destinationId);
    for (Balance balance in destination.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        assert(double.parse(balance.balance) > 9);
        break;
      }
    }

    TransactionResponse transaction =
        await sdk.transactions.transaction(response.hash!);
    assert(transaction.feeBumpTransaction != null);
    assert(transaction.feeBumpTransaction!.signatures.length > 0);
    assert(transaction.innerTransaction!.maxFee == 100);

    transaction =
        await sdk.transactions.transaction(transaction.innerTransaction!.hash);
    assert(transaction.sourceAccount == sourceId);

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations.forAccount(sourceId).execute();
    assert(operationsPage.records.isNotEmpty);
    operationsPage = await sdk.operations.forAccount(payerId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(sourceId).execute();
    assert(effectsPage.records.isNotEmpty);
    effectsPage = await sdk.effects.forAccount(payerId).execute();
    assert(effectsPage.records.isNotEmpty);
  });

  test('submit fee bump transaction - muxed accounts', () async {
    KeyPair sourceKeyPair = KeyPair.random();
    String sourceId = sourceKeyPair.accountId;
    KeyPair destinationKeyPair = KeyPair.random();
    String destinationId = destinationKeyPair.accountId;
    KeyPair payerKeyPair = KeyPair.random();
    String payerId = payerKeyPair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(sourceId);
      await FriendBot.fundTestAccount(payerId);
    } else {
      await FuturenetFriendBot.fundTestAccount(sourceId);
      await FuturenetFriendBot.fundTestAccount(payerId);
    }

    MuxedAccount muxedSourceAccount = MuxedAccount(sourceId, BigInt.from(97839283928292));
    MuxedAccount muxedPayerAccount = MuxedAccount(payerId, BigInt.from(24242423737333));

    AccountResponse sourceAccount = await sdk.accounts.account(sourceId);

    // fund account C.
    Transaction innerTx = new TransactionBuilder(sourceAccount)
        .addOperation(new CreateAccountOperationBuilder(destinationId, "10")
            .setMuxedSourceAccount(muxedSourceAccount)
            .build())
        .build();

    innerTx.sign(sourceKeyPair, network);

    FeeBumpTransaction feeBump = new FeeBumpTransactionBuilder(innerTx)
        .setBaseFee(200)
        .setMuxedFeeAccount(muxedPayerAccount)
        .build();
    feeBump.sign(payerKeyPair, network);

    SubmitTransactionResponse response =
        await sdk.submitFeeBumpTransaction(feeBump);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(feeBump, response);
    print(response.hash);

    bool found = false;
    AccountResponse destination = await sdk.accounts.account(destinationId);
    for (Balance balance in destination.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        assert(double.parse(balance.balance) > 9);
        found = true;
        break;
      }
    }

    assert(found);

    TransactionResponse transaction =
        await sdk.transactions.transaction(response.hash!);
    assert(transaction.feeBumpTransaction != null);
    assert(transaction.feeBumpTransaction!.signatures.length > 0);
    assert(transaction.innerTransaction!.maxFee == 100);

    transaction =
        await sdk.transactions.transaction(transaction.innerTransaction!.hash);
    assert(transaction.sourceAccount == sourceId);

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations.forAccount(sourceId).execute();
    assert(operationsPage.records.isNotEmpty);
    operationsPage = await sdk.operations.forAccount(payerId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(sourceId).execute();
    assert(effectsPage.records.isNotEmpty);
    effectsPage = await sdk.effects.forAccount(payerId).execute();
    assert(effectsPage.records.isNotEmpty);
  });
}
