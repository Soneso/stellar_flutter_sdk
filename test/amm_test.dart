import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'tests_util.dart';

void main() {
  String testOn = 'testnet'; //'futurenet';
  StellarSDK sdk =
      testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  KeyPair testAccountKeyPair = KeyPair.random();
  String seed = testAccountKeyPair.secretSeed;
  KeyPair assetAIssueAccountKeyPair = KeyPair.random();
  KeyPair assetBIssueAccountKeyPair = KeyPair.random();
  Asset assetA =
      AssetTypeCreditAlphaNum4("SDK", assetAIssueAccountKeyPair.accountId);
  Asset assetB =
      AssetTypeCreditAlphaNum12("FLUTTER", assetBIssueAccountKeyPair.accountId);
  Asset assetNative = AssetTypeNative();
  String nonNativeLiquidityPoolId = "";
  String nativeLiquidityPoolId = "";

  setUp(() async {
    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(testAccountKeyPair.accountId);
      await FriendBot.fundTestAccount(assetAIssueAccountKeyPair.accountId);
      await FriendBot.fundTestAccount(assetBIssueAccountKeyPair.accountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(testAccountKeyPair.accountId);
      await FuturenetFriendBot.fundTestAccount(
          assetAIssueAccountKeyPair.accountId);
      await FuturenetFriendBot.fundTestAccount(
          assetBIssueAccountKeyPair.accountId);
    }

    String sourceAccountId = testAccountKeyPair.accountId;
    AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);
    ChangeTrustOperationBuilder ctOpB1 = ChangeTrustOperationBuilder(
        assetA, ChangeTrustOperationBuilder.MAX_LIMIT);
    ChangeTrustOperationBuilder ctOpB2 = ChangeTrustOperationBuilder(
        assetB, ChangeTrustOperationBuilder.MAX_LIMIT);
    Transaction transaction = TransactionBuilder(sourceAccount)
        .addOperation(ctOpB1.build())
        .addOperation(ctOpB2.build())
        .build();
    transaction.sign(testAccountKeyPair, network);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    PaymentOperationBuilder pop1 =
        PaymentOperationBuilder(sourceAccountId, assetA, "19999191");
    pop1.setSourceAccount(assetAIssueAccountKeyPair.accountId);
    PaymentOperationBuilder pop2 =
        PaymentOperationBuilder(sourceAccountId, assetB, "19999191");
    pop2.setSourceAccount(assetBIssueAccountKeyPair.accountId);

    sourceAccount =
        await sdk.accounts.account(assetAIssueAccountKeyPair.accountId);
    transaction = TransactionBuilder(sourceAccount)
        .addOperation(pop1.build())
        .addOperation(pop2.build())
        .build();
    transaction.sign(assetAIssueAccountKeyPair, network);
    transaction.sign(assetBIssueAccountKeyPair, network);
    await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations
        .forAccount(assetAIssueAccountKeyPair.accountId)
        .execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects
        .forAccount(assetAIssueAccountKeyPair.accountId)
        .execute();
    assert(effectsPage.records.isNotEmpty);
  });

  group('all tests', () {
    test('create pool share trustline non native', () async {
      String sourceAccountId = testAccountKeyPair.accountId;
      AccountResponse sourceAccount =
          await sdk.accounts.account(sourceAccountId);

      AssetTypePoolShare poolShareAsset =
          AssetTypePoolShare(assetA: assetA, assetB: assetB);
      ChangeTrustOperationBuilder chOp = ChangeTrustOperationBuilder(
          poolShareAsset, ChangeTrustOperationBuilder.MAX_LIMIT);
      Transaction transaction =
          TransactionBuilder(sourceAccount).addOperation(chOp.build()).build();

      transaction.sign(testAccountKeyPair, network);

      String envelope = transaction.toEnvelopeXdrBase64();
      //print(envelope);
      XdrTransactionEnvelope envelopeXdr =
          XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
      assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);
      assert(response.success);
      TestUtils.resultDeAndEncodingTest(transaction, response);

      Page<LiquidityPoolResponse> myPage = await sdk.liquidityPools
          .forReserveAssets(assetA, assetB)
          .limit(4)
          .order(RequestBuilderOrder.ASC)
          .execute();
      List<LiquidityPoolResponse> pools = myPage.records;
      nonNativeLiquidityPoolId = pools.first.poolId;
      print("NNPID: " + nonNativeLiquidityPoolId);
      if (!nonNativeLiquidityPoolId.startsWith("L")) {
        final strKey =
            StrKey.encodeLiquidityPoolIdHex(nonNativeLiquidityPoolId);
        print("NNPID StrKey: " + strKey);
      }

      // test operation & effects responses can be parsed
      var operationsPage =
          await sdk.operations.forAccount(sourceAccountId).execute();
      assert(operationsPage.records.isNotEmpty);
      var effectsPage = await sdk.effects.forAccount(sourceAccountId).execute();
      assert(effectsPage.records.isNotEmpty);
    });

    test('create pool share trustline native', () async {
      KeyPair sourceAccountKeyPair = KeyPair.fromSecretSeed(seed);
      String sourceAccountId = sourceAccountKeyPair.accountId;

      AssetTypePoolShare poolShareAsset =
          AssetTypePoolShare(assetA: assetNative, assetB: assetB);
      ChangeTrustOperationBuilder chOp = ChangeTrustOperationBuilder(
          poolShareAsset, ChangeTrustOperationBuilder.MAX_LIMIT);

      AccountResponse sourceAccount =
          await sdk.accounts.account(sourceAccountId);
      Transaction transaction =
          TransactionBuilder(sourceAccount).addOperation(chOp.build()).build();

      transaction.sign(sourceAccountKeyPair, network);

      String envelope = transaction.toEnvelopeXdrBase64();
      //print(envelope);
      XdrTransactionEnvelope envelopeXdr =
          XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
      assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);
      assert(response.success);
      TestUtils.resultDeAndEncodingTest(transaction, response);

      Page<LiquidityPoolResponse> myPage = await sdk.liquidityPools
          .forReserveAssets(assetNative, assetB)
          .limit(4)
          .order(RequestBuilderOrder.ASC)
          .execute();
      List<LiquidityPoolResponse> pools = myPage.records;
      nativeLiquidityPoolId = pools.first.poolId;
      print("NATPID: " + nativeLiquidityPoolId);
      if (!nativeLiquidityPoolId.startsWith("L")) {
        final strKey = StrKey.encodeLiquidityPoolIdHex(nativeLiquidityPoolId);
        print("NATPID StrKey: " + strKey);
      }

      // test operation & effects responses can be parsed
      var operationsPage =
          await sdk.operations.forAccount(sourceAccountId).execute();
      assert(operationsPage.records.isNotEmpty);
      var effectsPage = await sdk.effects.forAccount(sourceAccountId).execute();
      assert(effectsPage.records.isNotEmpty);
    });

    test('deposit non native', () async {
      print("NNPID: " + nonNativeLiquidityPoolId);
      KeyPair sourceAccountKeyPair = KeyPair.fromSecretSeed(seed);
      String sourceAccountId = sourceAccountKeyPair.accountId;

      LiquidityPoolDepositOperationBuilder op =
          LiquidityPoolDepositOperationBuilder(
              liquidityPoolId: nonNativeLiquidityPoolId,
              maxAmountA: "250.0",
              maxAmountB: "250.0",
              minPrice: "1.0",
              maxPrice: "2.0");

      AccountResponse sourceAccount =
          await sdk.accounts.account(sourceAccountId);
      Transaction transaction =
          TransactionBuilder(sourceAccount).addOperation(op.build()).build();

      transaction.sign(sourceAccountKeyPair, network);

      String envelope = transaction.toEnvelopeXdrBase64();
      XdrTransactionEnvelope envelopeXdr =
          XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
      assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);
      assert(response.success);
      TestUtils.resultDeAndEncodingTest(transaction, response);

      // test operation & effects responses can be parsed
      var operationsPage =
          await sdk.operations.forAccount(sourceAccountId).execute();
      assert(operationsPage.records.isNotEmpty);
      var effectsPage = await sdk.effects.forAccount(sourceAccountId).execute();
      assert(effectsPage.records.isNotEmpty);

      if (!nonNativeLiquidityPoolId.startsWith("L")) {
        final strKey =
            StrKey.encodeLiquidityPoolIdHex(nonNativeLiquidityPoolId);
        op = LiquidityPoolDepositOperationBuilder(
            liquidityPoolId: strKey,
            maxAmountA: "10.0",
            maxAmountB: "10.0",
            minPrice: "1.0",
            maxPrice: "2.0");

        sourceAccount = await sdk.accounts.account(sourceAccountId);
        transaction =
            TransactionBuilder(sourceAccount).addOperation(op.build()).build();
        transaction.sign(sourceAccountKeyPair, network);
        response = await sdk.submitTransaction(transaction);
        assert(response.success);
      }
    });
    test('deposit native', () async {
      KeyPair sourceAccountKeyPair = KeyPair.fromSecretSeed(seed);
      String sourceAccountId = sourceAccountKeyPair.accountId;

      LiquidityPoolDepositOperationBuilder op =
          LiquidityPoolDepositOperationBuilder(
              liquidityPoolId: nativeLiquidityPoolId,
              maxAmountA: "250.0",
              maxAmountB: "250.0",
              minPrice: "1.0",
              maxPrice: "2.0");

      AccountResponse sourceAccount =
          await sdk.accounts.account(sourceAccountId);
      Transaction transaction =
          TransactionBuilder(sourceAccount).addOperation(op.build()).build();

      transaction.sign(sourceAccountKeyPair, network);

      String envelope = transaction.toEnvelopeXdrBase64();
      XdrTransactionEnvelope envelopeXdr =
          XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
      assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);
      assert(response.success);
      TestUtils.resultDeAndEncodingTest(transaction, response);

      // test operation & effects responses can be parsed
      var operationsPage =
          await sdk.operations.forAccount(sourceAccountId).execute();
      assert(operationsPage.records.isNotEmpty);
      var effectsPage = await sdk.effects.forAccount(sourceAccountId).execute();
      assert(effectsPage.records.isNotEmpty);

      if (!nativeLiquidityPoolId.startsWith("L")) {
        final strKey = StrKey.encodeLiquidityPoolIdHex(nativeLiquidityPoolId);
        op = LiquidityPoolDepositOperationBuilder(
            liquidityPoolId: strKey,
            maxAmountA: "250.0",
            maxAmountB: "250.0",
            minPrice: "1.0",
            maxPrice: "2.0");

        sourceAccount = await sdk.accounts.account(sourceAccountId);
        transaction =
            TransactionBuilder(sourceAccount).addOperation(op.build()).build();

        transaction.sign(sourceAccountKeyPair, network);
        response = await sdk.submitTransaction(transaction);
        assert(response.success);
      }
    });

    test('withdraw non native', () async {
      KeyPair sourceAccountKeyPair = KeyPair.fromSecretSeed(seed);
      String sourceAccountId = sourceAccountKeyPair.accountId;

      LiquidityPoolWithdrawOperationBuilder op =
          LiquidityPoolWithdrawOperationBuilder(
              liquidityPoolId: nonNativeLiquidityPoolId,
              amount: "100",
              minAmountA: "100",
              minAmountB: "100");

      AccountResponse sourceAccount =
          await sdk.accounts.account(sourceAccountId);
      Transaction transaction =
          TransactionBuilder(sourceAccount).addOperation(op.build()).build();

      transaction.sign(sourceAccountKeyPair, network);

      String envelope = transaction.toEnvelopeXdrBase64();
      XdrTransactionEnvelope envelopeXdr =
          XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
      assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);
      assert(response.success);
      TestUtils.resultDeAndEncodingTest(transaction, response);

      // test operation & effects responses can be parsed
      var operationsPage =
          await sdk.operations.forAccount(sourceAccountId).execute();
      assert(operationsPage.records.isNotEmpty);
      var effectsPage = await sdk.effects.forAccount(sourceAccountId).execute();
      assert(effectsPage.records.isNotEmpty);

      if (!nonNativeLiquidityPoolId.startsWith("L")) {
        final strKey =
            StrKey.encodeLiquidityPoolIdHex(nonNativeLiquidityPoolId);
        op = LiquidityPoolWithdrawOperationBuilder(
            liquidityPoolId: strKey,
            amount: "100",
            minAmountA: "100",
            minAmountB: "100");

        sourceAccount = await sdk.accounts.account(sourceAccountId);
        transaction =
            TransactionBuilder(sourceAccount).addOperation(op.build()).build();

        transaction.sign(sourceAccountKeyPair, network);
        response = await sdk.submitTransaction(transaction);
        assert(response.success);
      }
    });

    test('withdraw native', () async {
      KeyPair sourceAccountKeyPair = KeyPair.fromSecretSeed(seed);
      String sourceAccountId = sourceAccountKeyPair.accountId;

      LiquidityPoolWithdrawOperationBuilder op =
          LiquidityPoolWithdrawOperationBuilder(
              liquidityPoolId: nativeLiquidityPoolId,
              amount: "1",
              minAmountA: "1",
              minAmountB: "1");

      AccountResponse sourceAccount =
          await sdk.accounts.account(sourceAccountId);
      Transaction transaction =
          TransactionBuilder(sourceAccount).addOperation(op.build()).build();

      transaction.sign(sourceAccountKeyPair, network);

      String envelope = transaction.toEnvelopeXdrBase64();
      XdrTransactionEnvelope envelopeXdr =
          XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
      assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);
      assert(response.success);
      TestUtils.resultDeAndEncodingTest(transaction, response);

      // test operation & effects responses can be parsed
      var operationsPage =
          await sdk.operations.forAccount(sourceAccountId).execute();
      assert(operationsPage.records.isNotEmpty);
      var effectsPage = await sdk.effects.forAccount(sourceAccountId).execute();
      assert(effectsPage.records.isNotEmpty);

      if (!nativeLiquidityPoolId.startsWith("L")) {
        final strKey = StrKey.encodeLiquidityPoolIdHex(nativeLiquidityPoolId);
        op = LiquidityPoolWithdrawOperationBuilder(
            liquidityPoolId: strKey,
            amount: "1",
            minAmountA: "1",
            minAmountB: "1");

        sourceAccount = await sdk.accounts.account(sourceAccountId);
        transaction =
            TransactionBuilder(sourceAccount).addOperation(op.build()).build();

        transaction.sign(sourceAccountKeyPair, network);
        response = await sdk.submitTransaction(transaction);
        assert(response.success);
      }
    });

    test('test liquidity pool queries', () async {
      Page<EffectResponse> effectsPage = await sdk.effects
          .forLiquidityPool(nonNativeLiquidityPoolId)
          .limit(6)
          .order(RequestBuilderOrder.ASC)
          .execute();
      List<EffectResponse> effects = effectsPage.records;
      assert(effects.length == 6);
      assert(effects[0] is TrustlineCreatedEffectResponse);
      assert(effects[1] is LiquidityPoolCreatedEffectResponse);
      assert(effects[2] is LiquidityPoolDepositedEffectResponse);
      assert(effects[3] is LiquidityPoolDepositedEffectResponse);
      assert(effects[4] is LiquidityPoolWithdrewEffectResponse);
      assert(effects[5] is LiquidityPoolWithdrewEffectResponse);

      Page<TransactionResponse> transactionsPage = await sdk.transactions
          .forLiquidityPool(nonNativeLiquidityPoolId)
          .limit(1)
          .order(RequestBuilderOrder.DESC)
          .execute();
      assert(transactionsPage.records.length == 1);
      TransactionResponse transaction = transactionsPage.records.first;
      effectsPage = await sdk.effects
          .forTransaction(transaction.hash)
          .limit(3)
          .order(RequestBuilderOrder.ASC)
          .execute();
      assert(effects.length > 0);

      Page<OperationResponse> operationsPage = await sdk.operations
          .forLiquidityPool(nonNativeLiquidityPoolId)
          .limit(5)
          .order(RequestBuilderOrder.ASC)
          .execute();

      List<OperationResponse> operations = operationsPage.records;
      assert(operations.length == 5);
      assert(operations[0] is ChangeTrustOperationResponse);
      assert(operations[1] is LiquidityPoolDepositOperationResponse);
      assert(operations[2] is LiquidityPoolDepositOperationResponse);
      assert(operations[3] is LiquidityPoolWithdrawOperationResponse);
      assert(operations[4] is LiquidityPoolWithdrawOperationResponse);

      Page<LiquidityPoolResponse> poolsPage = await sdk.liquidityPools
          .limit(4)
          .order(RequestBuilderOrder.ASC)
          .execute();

      List<LiquidityPoolResponse> pools = poolsPage.records;
      assert(pools.length == 4);

      LiquidityPoolResponse nonNativeLiquidityPool =
          await sdk.liquidityPools.forPoolId(nonNativeLiquidityPoolId);
      assert(nonNativeLiquidityPool.fee == 30);
      assert(nonNativeLiquidityPool.poolId == nonNativeLiquidityPoolId);

      if (!nonNativeLiquidityPoolId.startsWith("L")) {
        final strKey =
            StrKey.encodeLiquidityPoolIdHex(nonNativeLiquidityPoolId);
        nonNativeLiquidityPool = await sdk.liquidityPools.forPoolId(strKey);
        assert(nonNativeLiquidityPool.fee == 30);
        assert(nonNativeLiquidityPool.poolId == nonNativeLiquidityPoolId);
      }

      Page<LiquidityPoolResponse> myPage = await sdk.liquidityPools
          .forReserveAssets(assetA, assetB)
          .limit(4)
          .order(RequestBuilderOrder.ASC)
          .execute();
      pools = myPage.records;
      assert(pools.first.poolId == nonNativeLiquidityPoolId);

      KeyPair accXKp = KeyPair.random();
      String accXId = accXKp.accountId;
      KeyPair accYKp = KeyPair.random();
      String accYId = accYKp.accountId;

      if (testOn == 'testnet') {
        await FriendBot.fundTestAccount(accXId);
        await FriendBot.fundTestAccount(accYId);
      } else {
        await FuturenetFriendBot.fundTestAccount(accXId);
        await FuturenetFriendBot.fundTestAccount(accYId);
      }

      AccountResponse accX = await sdk.accounts.account(accXId);
      ChangeTrustOperationBuilder ctOpB1 = ChangeTrustOperationBuilder(
          assetA, ChangeTrustOperationBuilder.MAX_LIMIT);
      ctOpB1.setSourceAccount(accXId);
      ChangeTrustOperationBuilder ctOpB2 = ChangeTrustOperationBuilder(
          assetB, ChangeTrustOperationBuilder.MAX_LIMIT);
      ctOpB2.setSourceAccount(accYId);
      Transaction tx = TransactionBuilder(accX)
          .addOperation(ctOpB1.build())
          .addOperation(ctOpB2.build())
          .build();
      tx.sign(accXKp, network);
      tx.sign(accYKp, network);
      SubmitTransactionResponse response = await sdk.submitTransaction(tx);
      assert(response.success);
      TestUtils.resultDeAndEncodingTest(tx, response);

      PaymentOperationBuilder pop1 =
          PaymentOperationBuilder(accXId, assetA, "19999191");
      pop1.setSourceAccount(assetAIssueAccountKeyPair.accountId);

      AccountResponse sc =
          await sdk.accounts.account(assetAIssueAccountKeyPair.accountId);
      tx = TransactionBuilder(sc).addOperation(pop1.build()).build();
      tx.sign(assetAIssueAccountKeyPair, network);
      await sdk.submitTransaction(tx);
      assert(response.success);
      TestUtils.resultDeAndEncodingTest(tx, response);

      PathPaymentStrictSendOperationBuilder opb =
          PathPaymentStrictSendOperationBuilder(
              assetA, "10", accYId, assetB, "1");
      accX = await sdk.accounts.account(accXId);
      tx = TransactionBuilder(accX).addOperation(opb.build()).build();
      tx.sign(accXKp, network);
      await sdk.submitTransaction(tx);
      assert(response.success);
      TestUtils.resultDeAndEncodingTest(tx, response);

      Page<TradeResponse> tradesPage = await sdk.trades
          .liquidityPoolId(nonNativeLiquidityPoolId)
          .order(RequestBuilderOrder.ASC)
          .execute();

      List<TradeResponse> trades = tradesPage.records;
      assert(trades.first.baseLiquidityPoolId == nonNativeLiquidityPoolId);

      if (!nonNativeLiquidityPoolId.startsWith("L")) {
        final strKey =
            StrKey.encodeLiquidityPoolIdHex(nonNativeLiquidityPoolId);
        tradesPage = await sdk.trades
            .liquidityPoolId(strKey)
            .order(RequestBuilderOrder.ASC)
            .execute();

        trades = tradesPage.records;
        assert(trades.first.baseLiquidityPoolId == nonNativeLiquidityPoolId);
      }

      Page<TradeResponse> trades2Page = await sdk.liquidityPoolTrades
          .forPoolId(nonNativeLiquidityPoolId)
          .order(RequestBuilderOrder.ASC)
          .execute();

      List<TradeResponse> trades2 = trades2Page.records;
      assert(trades2.first.baseLiquidityPoolId == nonNativeLiquidityPoolId);

      // test operation & effects responses can be parsed
      operationsPage = await sdk.operations.forAccount(accXId).execute();
      assert(operationsPage.records.isNotEmpty);
      effectsPage = await sdk.effects.forAccount(accXId).execute();
      assert(effectsPage.records.isNotEmpty);
    });

    test("parse liquidity pool resultXdr", () {
      final input = XdrDataInputStream(
          base64Decode("AAAAAAAAAGT/////AAAAAQAAAAAAAAAW/////AAAAAA="));
      final result = XdrTransactionResult.decode(input);
      final operationResult =
          (result.result.results.first as XdrOperationResult)
              .tr!
              .liquidityPoolDepositResult;
      assert(operationResult!.discriminant ==
          XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_UNDERFUNDED);
    });
  });
}
