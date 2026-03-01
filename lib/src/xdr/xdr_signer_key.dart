// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_signed_payload.dart';
import 'xdr_signer_key_type.dart';
import 'xdr_uint256.dart';

class XdrSignerKey {
  XdrSignerKey(this._type);
  XdrSignerKeyType _type;
  XdrSignerKeyType get discriminant => this._type;
  set discriminant(XdrSignerKeyType value) => this._type = value;

  XdrUint256? _ed25519;
  XdrUint256? get ed25519 => this._ed25519;
  set ed25519(XdrUint256? value) => this._ed25519 = value;

  XdrUint256? _preAuthTx;
  XdrUint256? get preAuthTx => this._preAuthTx;
  set preAuthTx(XdrUint256? value) => this._preAuthTx = value;

  XdrUint256? _hashX;
  XdrUint256? get hashX => this._hashX;
  set hashX(XdrUint256? value) => this._hashX = value;

  XdrSignedPayload? _signedPayload;
  XdrSignedPayload? get signedPayload => this._signedPayload;
  set signedPayload(XdrSignedPayload? value) => this._signedPayload = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSignerKey encodedSignerKey,
  ) {
    stream.writeInt(encodedSignerKey.discriminant.value);
    switch (encodedSignerKey.discriminant) {
      case XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519:
        XdrUint256.encode(stream, encodedSignerKey.ed25519!);
        break;
      case XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX:
        XdrUint256.encode(stream, encodedSignerKey.preAuthTx!);
        break;
      case XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X:
        XdrUint256.encode(stream, encodedSignerKey.hashX!);
        break;
      case XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD:
        XdrSignedPayload.encode(stream, encodedSignerKey.signedPayload!);
        break;
    }
  }

  static XdrSignerKey decode(XdrDataInputStream stream) {
    XdrSignerKey decodedSignerKey = XdrSignerKey(
      XdrSignerKeyType.decode(stream),
    );
    switch (decodedSignerKey.discriminant) {
      case XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519:
        decodedSignerKey.ed25519 = XdrUint256.decode(stream);
        break;
      case XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX:
        decodedSignerKey.preAuthTx = XdrUint256.decode(stream);
        break;
      case XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X:
        decodedSignerKey.hashX = XdrUint256.decode(stream);
        break;
      case XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD:
        decodedSignerKey.signedPayload = XdrSignedPayload.decode(stream);
        break;
    }
    return decodedSignerKey;
  }
}
