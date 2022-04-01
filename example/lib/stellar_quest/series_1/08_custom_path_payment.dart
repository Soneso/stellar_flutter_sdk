import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> customPathPayment({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SDLZPXUOODLPPD2XWUM7R6P6RZBZPOYZCFX6NODQMWLRV5OK3BC4PPHH",
  );

  final issuerAccountId =
      "GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B";

  final asset = Asset.createNonNativeAsset(
    "SRT",
    issuerAccountId,
  );

  // Creat a trustline from the receiving account (source) to the issuing account
  final trustlineOperationBuilder = ChangeTrustOperationBuilder(
    asset,
    "200",
  );

  final paymentsOperationBuilder = PathPaymentStrictReceiveOperationBuilder(
    Asset.NATIVE,
    "200",
    sourceKeyPair.accountId,
    asset,
    "1",
  );

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(trustlineOperationBuilder.build())
    ..addOperation(paymentsOperationBuilder.build());

  final transaction = transactionBuilder.build()..sign(sourceKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}
