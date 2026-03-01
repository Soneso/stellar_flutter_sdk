// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrUint64 {
  XdrUint64(this._uint64);

  BigInt _uint64;
  BigInt get uint64 => this._uint64;
  set uint64(BigInt value) => this._uint64 = value;

  static encode(XdrDataOutputStream stream, XdrUint64 encodedUint64) {
    stream.writeBigInt64(encodedUint64.uint64);
  }

  static XdrUint64 decode(XdrDataInputStream stream) {
    return XdrUint64(stream.readBigInt64());
  }
}
