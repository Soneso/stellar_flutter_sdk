import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> feeBumpTransaction({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SAH3BXVHQY4YMJIDQWUALJVNI6J2UAIZNPMC2Z4MV6CXFKAHZ6JGVD5G",
    // GDPQJAQXFBRJ3N6EXACC2XXCRSDZHFHTLK3DX4XDYAUWD3HRWTYWADRS
  );
  final destinationKeyPair = KeyPair.fromSecretSeed(
    "SC4ZAPNZWUDVJ5MUCUXS7CTBZUZNUOURLWCKQQEFACFQU7B3CMMOKTPW",
    // GAGMPYL7DN4F2GPS2QVF2PWP7J2Y77UICLLBBHNTYSLO6V3GGMQCUIRW
  );
  final payerKeyPair = KeyPair.fromSecretSeed(
    "SBYZTGYUUU2XIY5AFRAQABADYC4WAIDT4XAJGVQFSA7UEA64XLD7KJAJ",
    // GAVPCUFA3VKW2UBSLW2GTMWUJ5CHYGAYK67CWQBFALJ3UNC2HCPBOI2D
  );

  await FriendBot.fundTestAccount(sourceKeyPair.accountId);
  await FriendBot.fundTestAccount(destinationKeyPair.accountId);
  await FriendBot.fundTestAccount(payerKeyPair.accountId);

  final paymentBuilder = PaymentOperationBuilder(
    destinationKeyPair.accountId,
    Asset.NATIVE,
    "10",
  );

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(paymentBuilder.build());

  final transaction = transactionBuilder.build()..sign(sourceKeyPair, network);

  final feeBumpTransactionBuilder = FeeBumpTransactionBuilder(transaction)
    ..setBaseFee(200)
    ..setFeeAccount(payerKeyPair.accountId);

  final feeBumpTransaction = feeBumpTransactionBuilder.build()
    ..sign(payerKeyPair, network);

  final result = await sdk.submitFeeBumpTransaction(feeBumpTransaction);

  result.printResult();
}
