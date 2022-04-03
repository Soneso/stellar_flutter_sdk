import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../extensions/account_response_extensions.dart';
import '../../extensions/submit_transaction_response_extensions.dart';

Future<void> multiOperationalTransaction({
  required StellarSDK sdk,
  required Network network,
}) async {
  final sourceKeyPair = KeyPair.fromSecretSeed(
    "SAH3BXVHQY4YMJIDQWUALJVNI6J2UAIZNPMC2Z4MV6CXFKAHZ6JGVD5G",
    // GDPQJAQXFBRJ3N6EXACC2XXCRSDZHFHTLK3DX4XDYAUWD3HRWTYWADRS
  );

  final issuingKeyPair = KeyPair.fromSecretSeed(
    "SBK6NJQU5CK2IW7ALJVOE6E3FJ6TBOXDGWWVZR5B6XZCFAPFGNVGDMIJ",
    // GDPCNC4AVEAP7HBMIWMTD3D4EQS65EASDZTR3BYGVUBMKGDZGPAXDSNI
  );
  _printBalances(
    sdk: sdk,
    sourceKeyPair: sourceKeyPair,
    issuingKeyPair: issuingKeyPair,
  );

  // Add asset and set the issuer account
  final asset = Asset.createNonNativeAsset(
    "JOPM",
    issuingKeyPair.accountId,
  );

  // Creat a trustline from the receiving account (source) to the issuing account
  final trustlineOperationBuilder = ChangeTrustOperationBuilder(
    asset,
    "200",
  );

  // Execute a payment from the issuing account to the receiving account (source)
  final fundingOperationBuilder = PaymentOperationBuilder(
    sourceKeyPair.accountId,
    asset,
    "10",
  )..setSourceAccount(issuingKeyPair.accountId);

  var sourceAccount = await sdk.accounts.account(
    sourceKeyPair.accountId,
  );

  final transactionBuilder = TransactionBuilder(sourceAccount)
    ..addOperation(trustlineOperationBuilder.build())
    ..addOperation(fundingOperationBuilder.build());

  final transaction = transactionBuilder.build()
    ..sign(sourceKeyPair, network)
    ..sign(issuingKeyPair, network);

  final result = await sdk.submitTransaction(transaction);

  result.printResult();
  print('');

  _printBalances(
    sdk: sdk,
    sourceKeyPair: sourceKeyPair,
    issuingKeyPair: issuingKeyPair,
  );
}

Future<void> _printBalances({
  required StellarSDK sdk,
  required KeyPair sourceKeyPair,
  required KeyPair issuingKeyPair,
}) async {
  var sourceAccount = await sdk.accounts.account(
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
}
