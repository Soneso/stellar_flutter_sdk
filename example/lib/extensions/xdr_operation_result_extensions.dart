import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

extension XdrOperationResultX on XdrOperationResult {
  void printResult() {
    print('CODE: ${discriminant!.value}');
    printCreateClaimableBalanceResult();
    printManageSellOfferResult();
  }

  void printCreateClaimableBalanceResult() {
    final result = tr?.createClaimableBalanceResult;
    if (result == null) {
      return;
    }
    print(
      'CLAIMABLE_BALANCE_ID: ${result.balanceID}',
    );
  }

  void printManageSellOfferResult() {
    final result = tr?.manageOfferResult?.success;
    if (result == null) {
      return;
    }
    print(
      'OFFER_ID: ${result.offer?.offer?.offerID}',
    );
  }
}
