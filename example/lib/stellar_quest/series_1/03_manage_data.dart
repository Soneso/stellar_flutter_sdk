import 'dart:typed_data';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/extensions.dart';

Future<void> manageData({
  required StellarSDK sdk,
  required Network network,
  String? value,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SDLZPXUOODLPPD2XWUM7R6P6RZBZPOYZCFX6NODQMWLRV5OK3BC4PPHH",
  );

  final manageDataBuilder = ManageDataOperationBuilder(
    "Hello",
    Uint8List.fromList("World".codeUnits),
  );

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(manageDataBuilder.build());

  final transaction = transactionBuilder.build()..sign(sourceKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}
