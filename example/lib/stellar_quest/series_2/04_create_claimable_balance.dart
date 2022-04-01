import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> createClaimableBalance({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SAW74SJ4ERDAKW4GSL63ASQAN7EVFCI4A44JMRKPPGAP6ROGPBL6SN3J",
    // GAS4N4UW4CU24AIVQIIGDW6ENUYZUVZ7Z3MH5GVYGQHVKXLJ2GBDP6RQ
  );

  final createClaimableBalanceBuilder = CreateClaimableBalanceOperationBuilder(
    [
      Claimant(
        sourceKeyPair.accountId,
        Claimant.predicateNot(
          Claimant.predicateBeforeRelativeTime(60),
        ),
      )
    ],
    Asset.NATIVE,
    "100",
  );

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(createClaimableBalanceBuilder.build());

  final transaction = transactionBuilder.build()..sign(sourceKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}
