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
  String nonNativeLiquidityPoolId =
      "d6b10c2c204fbe9fdb348f81df56031cc095d8f37dc8757af2dcf9cbf716716f";
  String nativeLiquidityPoolId =
      "9dd21ba5453ace7ec693feb52c3e1354264afdce33e7bbab597fbf3d78324717";

  test('create pool share trustline non native', () async {
    KeyPair sourceAccountKeyPair = KeyPair.fromSecretSeed(seed);
    String sourceAccountId = sourceAccountKeyPair.accountId;

    Asset assetA = AssetTypeCreditAlphaNum4("SDK", assetAIssuingAccount);
    Asset assetB = AssetTypeCreditAlphaNum12("FLUTTER", assetBIssuingAccount);

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

    Asset assetA = AssetTypeNative();
    Asset assetB = AssetTypeCreditAlphaNum12("FLUTTER", assetBIssuingAccount);

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
}
