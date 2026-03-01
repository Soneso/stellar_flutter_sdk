// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint64.dart';

class XdrInt256Parts {
  XdrInt64 _hiHi;
  XdrInt64 get hiHi => this._hiHi;
  set hiHi(XdrInt64 value) => this._hiHi = value;

  XdrUint64 _hiLo;
  XdrUint64 get hiLo => this._hiLo;
  set hiLo(XdrUint64 value) => this._hiLo = value;

  XdrUint64 _loHi;
  XdrUint64 get loHi => this._loHi;
  set loHi(XdrUint64 value) => this._loHi = value;

  XdrUint64 _loLo;
  XdrUint64 get loLo => this._loLo;
  set loLo(XdrUint64 value) => this._loLo = value;

  XdrInt256Parts(this._hiHi, this._hiLo, this._loHi, this._loLo);

  static void encode(XdrDataOutputStream stream, XdrInt256Parts encoded) {
    XdrInt64.encode(stream, encoded.hiHi);
    XdrUint64.encode(stream, encoded.hiLo);
    XdrUint64.encode(stream, encoded.loHi);
    XdrUint64.encode(stream, encoded.loLo);
  }

  static XdrInt256Parts decode(XdrDataInputStream stream) {
    return XdrInt256Parts(XdrInt64.decode(stream), XdrUint64.decode(stream),
        XdrUint64.decode(stream), XdrUint64.decode(stream));
  }

  static XdrInt256Parts forHiHiHiLoLoHiLoLo(
    BigInt hiHi,
    BigInt hiLo,
    BigInt loHi,
    BigInt loLo,
  ) {
    return XdrInt256Parts(
        XdrInt64(hiHi), XdrUint64(hiLo), XdrUint64(loHi), XdrUint64(loLo));
  }

}
