// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int128_parts_base.dart';
import 'xdr_int64.dart';
import 'xdr_uint64.dart';

class XdrInt128Parts extends XdrInt128PartsBase {
  XdrInt128Parts(super.hi, super.lo);

  static void encode(XdrDataOutputStream stream, XdrInt128Parts val) {
    XdrInt128PartsBase.encode(stream, val);
  }

  static XdrInt128Parts decode(XdrDataInputStream stream) {
    var b = XdrInt128PartsBase.decode(stream);
    return XdrInt128Parts(b.hi, b.lo);
  }

  static XdrInt128Parts fromTxRep(Map<String, String> map, String prefix) {
    var b = XdrInt128PartsBase.fromTxRep(map, prefix);
    return XdrInt128Parts(b.hi, b.lo);
  }

  static XdrInt128Parts forHiLo(BigInt hi, BigInt lo) {
    return XdrInt128Parts(XdrInt64(hi), XdrUint64(lo));
  }
}
