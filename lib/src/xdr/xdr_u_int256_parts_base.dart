// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint64.dart';

class XdrUInt256PartsBase {
  XdrUint64 _hiHi;
  XdrUint64 get hiHi => this._hiHi;
  set hiHi(XdrUint64 value) => this._hiHi = value;

  XdrUint64 _hiLo;
  XdrUint64 get hiLo => this._hiLo;
  set hiLo(XdrUint64 value) => this._hiLo = value;

  XdrUint64 _loHi;
  XdrUint64 get loHi => this._loHi;
  set loHi(XdrUint64 value) => this._loHi = value;

  XdrUint64 _loLo;
  XdrUint64 get loLo => this._loLo;
  set loLo(XdrUint64 value) => this._loLo = value;

  XdrUInt256PartsBase(this._hiHi, this._hiLo, this._loHi, this._loLo);

  static void encode(
    XdrDataOutputStream stream,
    XdrUInt256PartsBase encodedUInt256Parts,
  ) {
    XdrUint64.encode(stream, encodedUInt256Parts.hiHi);
    XdrUint64.encode(stream, encodedUInt256Parts.hiLo);
    XdrUint64.encode(stream, encodedUInt256Parts.loHi);
    XdrUint64.encode(stream, encodedUInt256Parts.loLo);
  }

  static XdrUInt256PartsBase decode(XdrDataInputStream stream) {
    XdrUint64 hiHi = XdrUint64.decode(stream);
    XdrUint64 hiLo = XdrUint64.decode(stream);
    XdrUint64 loHi = XdrUint64.decode(stream);
    XdrUint64 loLo = XdrUint64.decode(stream);
    return XdrUInt256PartsBase(hiHi, hiLo, loHi, loLo);
  }
}
