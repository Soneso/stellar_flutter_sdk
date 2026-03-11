// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_u_int128_parts_base.dart';
import 'xdr_uint64.dart';

class XdrUInt128Parts extends XdrUInt128PartsBase {
  XdrUInt128Parts(super.hi, super.lo);

  static void encode(XdrDataOutputStream stream, XdrUInt128Parts val) {
    XdrUInt128PartsBase.encode(stream, val);
  }

  static XdrUInt128Parts decode(XdrDataInputStream stream) {
    var b = XdrUInt128PartsBase.decode(stream);
    return XdrUInt128Parts(b.hi, b.lo);
  }

  static XdrUInt128Parts fromTxRep(Map<String, String> map, String prefix) {
    var b = XdrUInt128PartsBase.fromTxRep(map, prefix);
    return XdrUInt128Parts(b.hi, b.lo);
  }

  static XdrUInt128Parts forHiLo(BigInt hi, BigInt lo) {
    return XdrUInt128Parts(XdrUint64(hi), XdrUint64(lo));
  }
}
