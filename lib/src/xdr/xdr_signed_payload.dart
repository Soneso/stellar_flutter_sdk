// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_data_value.dart';
import 'xdr_uint256.dart';

class XdrSignedPayload {
  XdrSignedPayload(this._ed25519, this._payload);

  XdrUint256 _ed25519;
  XdrUint256 get ed25519 => this._ed25519;
  set ed25519(XdrUint256 value) => this._ed25519 = value;

  XdrDataValue _payload;
  XdrDataValue get payload => this._payload;
  set payload(XdrDataValue value) => this._payload = value;

  static void encode(XdrDataOutputStream stream, XdrSignedPayload encoded) {
    XdrUint256.encode(stream, encoded.ed25519);
    XdrDataValue.encode(stream, encoded.payload);
  }

  static XdrSignedPayload decode(XdrDataInputStream stream) {
    XdrSignedPayload decoded = XdrSignedPayload(
        XdrUint256.decode(stream), XdrDataValue.decode(stream));
    return decoded;
  }
}
