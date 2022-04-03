import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/extensions.dart';

Future<void> multisign({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SAH3BXVHQY4YMJIDQWUALJVNI6J2UAIZNPMC2Z4MV6CXFKAHZ6JGVD5G",
    // GDPQJAQXFBRJ3N6EXACC2XXCRSDZHFHTLK3DX4XDYAUWD3HRWTYWADRS
  );

  final extraSignerKeyPair = KeyPair.fromSecretSeed(
    "SBK6NJQU5CK2IW7ALJVOE6E3FJ6TBOXDGWWVZR5B6XZCFAPFGNVGDMIJ",
    // GDPCNC4AVEAP7HBMIWMTD3D4EQS65EASDZTR3BYGVUBMKGDZGPAXDSNI
  );

  final setOptionsBuilder = SetOptionsOperationBuilder()
    ..setSourceAccount(sourceKeyPair.accountId)
    ..setSigner(extraSignerKeyPair.xdrSignerKey, 1);

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(setOptionsBuilder.build());

  final transaction = transactionBuilder.build()..sign(sourceKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}
