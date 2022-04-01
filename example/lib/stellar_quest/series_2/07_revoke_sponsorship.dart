import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> revokeSponsorship({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sponsoringKeyPair = KeyPair.fromSecretSeed(
    "SAW74SJ4ERDAKW4GSL63ASQAN7EVFCI4A44JMRKPPGAP6ROGPBL6SN3J",
    // GAS4N4UW4CU24AIVQIIGDW6ENUYZUVZ7Z3MH5GVYGQHVKXLJ2GBDP6RQ
  );

  final sponsoredKeyPair = KeyPair.fromSecretSeed(
    "SAEK3QP7NNXS7ZI3XVDMSLGWC3TSPNSAELV42GDWVC6NAK7WFM657ARF",
    // GDJQPIBYZJKW4GSP6CCNKUFC2F3CUSRA3MY2RNWCRN7HG4RVDFN5EUJT
  );

  final revokeSponsorshipBuilder = RevokeSponsorshipOperationBuilder()
    ..revokeAccountSponsorship(sponsoredKeyPair.accountId);

  final sponsoringAccount = await sdk.accounts.account(
    sponsoringKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sponsoringAccount)
    ..addOperation(revokeSponsorshipBuilder.build());

  final transaction = transactionBuilder.build()
    ..sign(sponsoringKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
}
