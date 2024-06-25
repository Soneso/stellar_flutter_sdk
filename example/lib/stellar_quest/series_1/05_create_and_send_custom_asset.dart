import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/extensions.dart';

Future<void> createAndSendCustomAsset({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SDLZPXUOODLPPD2XWUM7R6P6RZBZPOYZCFX6NODQMWLRV5OK3BC4PPHH",
  );

  final issuingKeyPair = KeyPair.fromSecretSeed(
    "SAW74SJ4ERDAKW4GSL63ASQAN7EVFCI4A44JMRKPPGAP6ROGPBL6SN3J",
  );

  final sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );
  print("Source account balance:");
  sourceAccount.printBalances();
  print('');

  var issuingAccount = await sdk.accounts.account(
    issuingKeyPair.accountId,
  );
  print("Issuing account balance:");
  issuingAccount.printBalances();
  print('');

  // Add asset and set the issuer account
  final asset = Asset.createNonNativeAsset(
    "JOPM",
    issuingAccount.accountId,
  );

  // Creat a trustline from the receiving account (source) to the issuing account
  final trustlineBuilder = ChangeTrustOperationBuilder(
    asset,
    '922337203685.4775807',
  );

  // Execute a payment from the issuing account to the receiving account (source)
  final fundingBuilder = PaymentOperationBuilder(
    sourceAccount.accountId,
    asset,
    "10",
  )..setSourceAccount(issuingKeyPair.accountId);

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(trustlineBuilder.build())
    ..addOperation(fundingBuilder.build());

  final transaction = transactionBuilder.build()
    ..sign(sourceKeyPair, network)
    ..sign(issuingKeyPair, network);

  final result = await sdk.submitTransaction(
    transaction,
  );

  result.printResult();
}
