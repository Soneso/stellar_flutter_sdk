import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> createSellOfferCustomAsset({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SDLZPXUOODLPPD2XWUM7R6P6RZBZPOYZCFX6NODQMWLRV5OK3BC4PPHH",
  );

  final issuingKeyPair = KeyPair.fromSecretSeed(
    "SAW74SJ4ERDAKW4GSL63ASQAN7EVFCI4A44JMRKPPGAP6ROGPBL6SN3J",
  );

  final asset = Asset.createNonNativeAsset(
    "JOPM",
    issuingKeyPair.accountId,
  );

  final operation = ManageSellOfferOperationBuilder(
    asset,
    Asset.NATIVE,
    "1",
    "1",
  );

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(operation.build());

  final transaction = transactionBuilder.build()..sign(sourceKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}
