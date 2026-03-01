// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';

class XdrSCNonceKey {
  XdrInt64 _nonce;
  XdrInt64 get nonce => this._nonce;
  set nonce(XdrInt64 value) => this._nonce = value;

  XdrSCNonceKey(this._nonce);

  static void encode(XdrDataOutputStream stream, XdrSCNonceKey encoded) {
    XdrInt64.encode(stream, encoded.nonce);
  }

  static XdrSCNonceKey decode(XdrDataInputStream stream) {
    return XdrSCNonceKey(XdrInt64.decode(stream));
  }
}
