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
}
