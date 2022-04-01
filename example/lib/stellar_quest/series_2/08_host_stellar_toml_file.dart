import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> hostStellarTomlFile({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SAW74SJ4ERDAKW4GSL63ASQAN7EVFCI4A44JMRKPPGAP6ROGPBL6SN3J",
    // GAS4N4UW4CU24AIVQIIGDW6ENUYZUVZ7Z3MH5GVYGQHVKXLJ2GBDP6RQ
  );

  // Your domain that contains the .well-known/stellar.toml file.
  final domain = "88fhbx.csb.app";

  final setOptionsBuilder = SetOptionsOperationBuilder()..setHomeDomain(domain);

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(setOptionsBuilder.build());

  final transaction = transactionBuilder.build()..sign(sourceKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}
