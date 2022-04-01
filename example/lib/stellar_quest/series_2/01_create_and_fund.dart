import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> createAndFundAccount({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SAH3BXVHQY4YMJIDQWUALJVNI6J2UAIZNPMC2Z4MV6CXFKAHZ6JGVD5G",
    // GDPQJAQXFBRJ3N6EXACC2XXCRSDZHFHTLK3DX4XDYAUWD3HRWTYWADRS
  );

  final newAccountKeyPair = KeyPair.fromSecretSeed(
    "SBK6NJQU5CK2IW7ALJVOE6E3FJ6TBOXDGWWVZR5B6XZCFAPFGNVGDMIJ",
    // GDPCNC4AVEAP7HBMIWMTD3D4EQS65EASDZTR3BYGVUBMKGDZGPAXDSNI
  );

  final createAccountBuilder = CreateAccountOperationBuilder(
    newAccountKeyPair.accountId,
    "5000",
  );

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(createAccountBuilder.build())
    ..addMemo(MemoHash.string(
      "e3366fcb087bdb2381b7069a19405b748da831c18145eba25654d1092e93ef37",
    ));

  final transaction = transactionBuilder.build()..sign(sourceKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}
