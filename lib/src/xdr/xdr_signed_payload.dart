// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_data_value.dart';
import 'xdr_uint256.dart';

class XdrSignedPayload {

  XdrUint256 _ed25519;
  XdrUint256 get ed25519 => this._ed25519;
  set ed25519(XdrUint256 value) => this._ed25519 = value;

  XdrDataValue _payload;
  XdrDataValue get payload => this._payload;
  set payload(XdrDataValue value) => this._payload = value;

  XdrSignedPayload(this._ed25519, this._payload);

  static void encode(XdrDataOutputStream stream, XdrSignedPayload encodedSignedPayload) {
    XdrUint256.encode(stream, encodedSignedPayload.ed25519);
    XdrDataValue.encode(stream, encodedSignedPayload.payload);
  }

  static XdrSignedPayload decode(XdrDataInputStream stream) {
    XdrUint256 ed25519 = XdrUint256.decode(stream);
    XdrDataValue payload = XdrDataValue.decode(stream);
    return XdrSignedPayload(ed25519, payload);
  }
}
