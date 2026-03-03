// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/key_pair.dart';

import 'xdr_data_io.dart';
import 'xdr_public_key_base.dart';
import 'xdr_public_key_type.dart';
import 'xdr_uint256.dart';

class XdrPublicKey extends XdrPublicKeyBase {
  XdrPublicKey(super.type);

  /// Method-style accessor for backward compatibility with existing SDK code.
  XdrUint256? getEd25519() => ed25519;

  /// Method-style accessor for backward compatibility with existing SDK code.
  void setEd25519(XdrUint256 value) {
    ed25519 = value;
  }

  static void encode(XdrDataOutputStream stream, XdrPublicKey val) {
    XdrPublicKeyBase.encode(stream, val);
  }

  static XdrPublicKey decode(XdrDataInputStream stream) {
    return XdrPublicKeyBase.decodeAs(stream, XdrPublicKey.new);
  }

  static XdrPublicKey forAccountId(String accountId) {
    var keyPair = KeyPair.fromAccountId(accountId);
    var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
    pk.setEd25519(XdrUint256(keyPair.publicKey));
    return pk;
  }
}
