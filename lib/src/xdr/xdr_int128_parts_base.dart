// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint64.dart';

class XdrInt128PartsBase {
  // Both signed and unsigned 128-bit ints
  // are transported in a pair of uint64s
  // to reduce the risk of sign-extension.
  XdrInt64 _hi;
  XdrInt64 get hi => this._hi;
  set hi(XdrInt64 value) => this._hi = value;

  XdrUint64 _lo;
  XdrUint64 get lo => this._lo;
  set lo(XdrUint64 value) => this._lo = value;

  XdrInt128PartsBase(this._hi, this._lo);

  static void encode(XdrDataOutputStream stream, XdrInt128PartsBase encoded) {
    XdrInt64.encode(stream, encoded.hi);
    XdrUint64.encode(stream, encoded.lo);
  }

  static XdrInt128PartsBase decode(XdrDataInputStream stream) {
    return XdrInt128PartsBase(
      XdrInt64.decode(stream),
      XdrUint64.decode(stream),
    );
  }
}
