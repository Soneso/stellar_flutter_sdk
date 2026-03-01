// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/key_pair.dart';

import 'xdr_data_io.dart';
import 'xdr_public_key_type.dart';
import 'xdr_uint256.dart';

class XdrPublicKey {
  XdrPublicKey(this._type);

  XdrPublicKeyType _type;
  XdrPublicKeyType getDiscriminant() => this._type;
  void setDiscriminant(XdrPublicKeyType value) => this._type = value;

  XdrUint256? _ed25519;
  XdrUint256? getEd25519() => this._ed25519;
  void setEd25519(XdrUint256? value) => this._ed25519 = value;

  static void encode(
      XdrDataOutputStream stream, XdrPublicKey encodedPublicKey) {
    stream.writeInt(encodedPublicKey.getDiscriminant().value);
    switch (encodedPublicKey.getDiscriminant()) {
      case XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519:
        XdrUint256.encode(stream, encodedPublicKey._ed25519!);
        break;
    }
  }

  static XdrPublicKey decode(XdrDataInputStream stream) {
    XdrPublicKey decodedPublicKey =
        XdrPublicKey(XdrPublicKeyType.decode(stream));
    switch (decodedPublicKey.getDiscriminant()) {
      case XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519:
        decodedPublicKey._ed25519 = XdrUint256.decode(stream);
        break;
    }
    return decodedPublicKey;
  }

  static XdrPublicKey forAccountId(String accountId) {
    var keyPair = KeyPair.fromAccountId(accountId);
    var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
    pk.setEd25519(XdrUint256(keyPair.publicKey));
    return pk;
  }
}
