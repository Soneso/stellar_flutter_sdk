import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> paymentWithChannelAccount({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SDLZPXUOODLPPD2XWUM7R6P6RZBZPOYZCFX6NODQMWLRV5OK3BC4PPHH",
  );

  final channelKeyPair = KeyPair.fromSecretSeed(
    "SC2CE4BNEGTLQQCT67FKX2YOV4UWFQCY2ZZM7I3EARE7P4CRFDUZN76E",
    // GBPETPHGYG3PLWH3YVZB6R4IOTFXKMBTT4JWLUJAMGWBJA5IDFJSMBTH
  );

  final destinationAccountId =
      "GAZ5IBV4ESG4U65ILOVWIL6SM5CEK24VSZKCTGBPZTJY2PURM32L7WAJ";

  final channelAccount = await sdk.accounts.account(
    channelKeyPair.accountId,
  );

  // So the payment is send from the source to the destination account. Note
  // that the channel account will pay the fee not the source account. Because
  // the channel account is the source account of the transaction.
  final operation = PaymentOperationBuilder(
    destinationAccountId,
    Asset.NATIVE,
    "5",
  )..setSourceAccount(sourceKeyPair.accountId);

  // The source account of the transaction always pays the fee and is called
  // channel account.
  final transactionBuilder = TransactionBuilder(channelAccount)
    ..addOperation(operation.build());

  final transaction = transactionBuilder.build()
    ..sign(sourceKeyPair, network)
    ..sign(channelKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}
