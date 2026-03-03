// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint64.dart';

class XdrUInt128PartsBase {

  XdrUint64 _hi;
  XdrUint64 get hi => this._hi;
  set hi(XdrUint64 value) => this._hi = value;

  XdrUint64 _lo;
  XdrUint64 get lo => this._lo;
  set lo(XdrUint64 value) => this._lo = value;

  XdrUInt128PartsBase(this._hi, this._lo);

  static void encode(XdrDataOutputStream stream, XdrUInt128PartsBase encodedUInt128Parts) {
    XdrUint64.encode(stream, encodedUInt128Parts.hi);
    XdrUint64.encode(stream, encodedUInt128Parts.lo);
  }

  static XdrUInt128PartsBase decode(XdrDataInputStream stream) {
    XdrUint64 hi = XdrUint64.decode(stream);
    XdrUint64 lo = XdrUint64.decode(stream);
    return XdrUInt128PartsBase(hi, lo);
  }
}
