// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_u_int256_parts_base.dart';
import 'xdr_uint64.dart';

class XdrUInt256Parts extends XdrUInt256PartsBase {
  XdrUInt256Parts(super.hiHi, super.hiLo, super.loHi, super.loLo);

  static void encode(XdrDataOutputStream stream, XdrUInt256Parts val) {
    XdrUInt256PartsBase.encode(stream, val);
  }

  static XdrUInt256Parts decode(XdrDataInputStream stream) {
    var b = XdrUInt256PartsBase.decode(stream);
    return XdrUInt256Parts(b.hiHi, b.hiLo, b.loHi, b.loLo);
  }

  static XdrUInt256Parts fromTxRep(Map<String, String> map, String prefix) {
    var b = XdrUInt256PartsBase.fromTxRep(map, prefix);
    return XdrUInt256Parts(b.hiHi, b.hiLo, b.loHi, b.loLo);
  }

  static XdrUInt256Parts forHiHiHiLoLoHiLoLo(
    BigInt hiHi,
    BigInt hiLo,
    BigInt loHi,
    BigInt loLo,
  ) {
    return XdrUInt256Parts(
      XdrUint64(hiHi),
      XdrUint64(hiLo),
      XdrUint64(loHi),
      XdrUint64(loLo),
    );
  }
}
