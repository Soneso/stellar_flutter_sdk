import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

extension KeyPairX on KeyPair {
  XdrSignerKey get xdrSignerKey {
    return XdrSignerKey()
      ..discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519
      ..ed25519 = xdrPublicKey.getEd25519();
  }
}
