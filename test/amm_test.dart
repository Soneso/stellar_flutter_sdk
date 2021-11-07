import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK("...");
  Network network = Network("...");
  String seed = "SDO3P46RJBYH3PHVWU3CQCUARLLIBIOWJTKONBGPVDBJECQUDXDIHWIG";
  String assetAIssuingAccount =
      "GA7NMSVWZBA3HTDKRFTE34ONYNP3WWDSE7LSAMJUPSR2X4Q6JECA2NKP";
  String assetBIssuingAccount =
      "GDKY2GFRYXAQERYJTPFECOGZKWSZ6KVIFFX5CN2KB37IQAPMAWPRL7SF";
  Asset assetA = AssetTypeCreditAlphaNum4("SDK", assetAIssuingAccount);
  Asset assetB = AssetTypeCreditAlphaNum12("FLUTTER", assetBIssuingAccount);
  Asset assetNative = AssetTypeNative();
  String nonNativeLiquidityPoolId =
      "d6b10c2c204fbe9fdb348f81df56031cc095d8f37dc8757af2dcf9cbf716716f";
  String nativeLiquidityPoolId =
      "9dd21ba5453ace7ec693feb52c3e1354264afdce33e7bbab597fbf3d78324717";

  test('create pool share trustline non native', () async {
    KeyPair sourceAccountKeyPair = KeyPair.fromSecretSeed(seed);
    String sourceAccountId = sourceAccountKeyPair.accountId;

    AssetTypePoolShare poolShareAsset =
        AssetTypePoolShare(assetA: assetA, assetB: assetB);
    ChangeTrustOperationBuilder chOp =
        ChangeTrustOperationBuilder(poolShareAsset, "98398398293");

    AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(chOp.build()).build();

    transaction.sign(sourceAccountKeyPair, network);

    String envelope = transaction.toEnvelopeXdrBase64();
    print(envelope);
    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
    assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
  });

  test('create pool share trustline native', () async {
    KeyPair sourceAccountKeyPair = KeyPair.fromSecretSeed(seed);
    String sourceAccountId = sourceAccountKeyPair.accountId;

    AssetTypePoolShare poolShareAsset =
        AssetTypePoolShare(assetA: assetNative, assetB: assetB);
    ChangeTrustOperationBuilder chOp =
        ChangeTrustOperationBuilder(poolShareAsset, "98398398293");

    AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(chOp.build()).build();

    transaction.sign(sourceAccountKeyPair, network);

    String envelope = transaction.toEnvelopeXdrBase64();
    print(envelope);
    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
    assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
  });

  test('deposit non native', () async {
    KeyPair sourceAccountKeyPair = KeyPair.fromSecretSeed(seed);
    String sourceAccountId = sourceAccountKeyPair.accountId;

    LiquidityPoolDepositOperationBuilder op =
        LiquidityPoolDepositOperationBuilder(
            liquidityPoolId: nonNativeLiquidityPoolId,
            maxAmountA: "250.0",
            maxAmountB: "250.0",
            minPrice: "1.0",
            maxPrice: "2.0");

    AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(op.build()).build();

    transaction.sign(sourceAccountKeyPair, network);

    String envelope = transaction.toEnvelopeXdrBase64();
    print(envelope);
    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
    assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
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

    AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(op.build()).build();

    transaction.sign(sourceAccountKeyPair, network);

    String envelope = transaction.toEnvelopeXdrBase64();
    print(envelope);
    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
    assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
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

    AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(op.build()).build();

    transaction.sign(sourceAccountKeyPair, network);

    String envelope = transaction.toEnvelopeXdrBase64();
    print(envelope);
    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
    assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
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

    AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(op.build()).build();

    transaction.sign(sourceAccountKeyPair, network);

    String envelope = transaction.toEnvelopeXdrBase64();
    print(envelope);
    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(envelope);
    assert(envelope == envelopeXdr.toEnvelopeXdrBase64());

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
  });

  test('test liquidity pool queries', () async {

    Page<EffectResponse> effectsPage =
    await sdk.effects.forLiquidityPool(nonNativeLiquidityPoolId).limit(4).order(RequestBuilderOrder.ASC).execute();
    List<EffectResponse> effects = effectsPage.records!;
    assert(effects.length == 4);
    assert(effects[0] is TrustlineCreatedEffectResponse);
    assert(effects[1] is LiquidityPoolCreatedEffectResponse);
    assert(effects[2] is LiquidityPoolDepositedEffectResponse);
    assert(effects[3] is LiquidityPoolWithdrewEffectResponse);

    Page<TransactionResponse> transactionsPage = await sdk.transactions
        .forLiquidityPool(nonNativeLiquidityPoolId)
        .limit(1)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(transactionsPage.records!.length == 1);
    TransactionResponse transaction = transactionsPage.records!.first;
    effectsPage = await sdk.effects
        .forTransaction(transaction.hash!)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    assert(effects.length > 0);

    Page<OperationResponse> operationsPage = await sdk.operations
        .forLiquidityPool(nonNativeLiquidityPoolId)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();

    List<OperationResponse> operations = operationsPage.records!;
    assert(operations.length == 3);
    assert(operations[0] is ChangeTrustOperationResponse);
    assert(operations[1] is LiquidityPoolDepositOperationResponse);
    assert(operations[2] is LiquidityPoolWithdrawOperationResponse);

    Page<LiquidityPoolResponse> poolsPage = await sdk.liquidityPools
        .limit(4)
        .order(RequestBuilderOrder.ASC)
        .execute();

    List<LiquidityPoolResponse> pools = poolsPage.records!;
    assert(pools.length == 4);

    LiquidityPoolResponse nonNativeLiquidityPool = await sdk.liquidityPools
        .forPoolId(nonNativeLiquidityPoolId);
    assert(nonNativeLiquidityPool.fee == 30);
    assert(nonNativeLiquidityPool.poolId == nonNativeLiquidityPoolId);

    Page<LiquidityPoolResponse> myPage = await sdk.liquidityPools
        .forReserveAssets(assetA, assetB).limit(4)
        .order(RequestBuilderOrder.ASC)
        .execute();
    pools = myPage.records!;
    assert(pools.first.poolId == nonNativeLiquidityPoolId);


    Page<TradeResponse> tradesPage = await sdk.trades
        .liquidityPoolId(nonNativeLiquidityPoolId)
        .limit(2)
        .order(RequestBuilderOrder.ASC)
        .execute();

    List<TradeResponse> trades = tradesPage.records!;
    assert(trades.length == 2);
    assert(trades.first.counterLiquidityPoolId == nonNativeLiquidityPoolId);

    Page<TradeResponse> trades2Page = await sdk.liquidityPoolTrades
        .forPoolId(nonNativeLiquidityPoolId)
        .limit(2)
        .order(RequestBuilderOrder.ASC)
        .execute();

    List<TradeResponse> trades2 = trades2Page.records!;
    assert(trades2.length == 2);
    assert(trades2.first.counterLiquidityPoolId == nonNativeLiquidityPoolId);
  });
}
