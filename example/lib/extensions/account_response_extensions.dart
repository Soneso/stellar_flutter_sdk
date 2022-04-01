import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

extension AccountResponseX on AccountResponse {
  void printBalances() {
    balances?.forEach((element) {
      print("${element?.assetCode}: ${element?.balance}");
    });
  }
}
