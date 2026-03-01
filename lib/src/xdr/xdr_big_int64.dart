// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrBigInt64 {
  XdrBigInt64(this._bigInt);

  BigInt _bigInt;
  BigInt get bigInt => this._bigInt;
  set bigInt(BigInt value) => this._bigInt = value;

  static encode(XdrDataOutputStream stream, XdrBigInt64 encodedInt64) {
    stream.writeBigInt64(encodedInt64.bigInt);
  }

  static XdrBigInt64 decode(XdrDataInputStream stream) {
    return XdrBigInt64(stream.readBigInt64());
  }
}
