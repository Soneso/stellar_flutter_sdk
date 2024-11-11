import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

extension StringX on String {
  AssetTypeCreditAlphaNum toAsset() {
    List<String> parts = split(':');
    final String code = parts[0];
    final String issuer = parts[1];
    if (code.length <= 4) {
      return AssetTypeCreditAlphaNum4(code, issuer);
    } else {
      return AssetTypeCreditAlphaNum12(code, issuer);
    }
  }
}
