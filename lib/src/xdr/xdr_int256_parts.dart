// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int256_parts_base.dart';
import 'xdr_int64.dart';
import 'xdr_uint64.dart';

class XdrInt256Parts extends XdrInt256PartsBase {
  XdrInt256Parts(super.hiHi, super.hiLo, super.loHi, super.loLo);

  static void encode(XdrDataOutputStream stream, XdrInt256Parts val) {
    XdrInt256PartsBase.encode(stream, val);
  }

  static XdrInt256Parts decode(XdrDataInputStream stream) {
    var b = XdrInt256PartsBase.decode(stream);
    return XdrInt256Parts(b.hiHi, b.hiLo, b.loHi, b.loLo);
  }

  static XdrInt256Parts forHiHiHiLoLoHiLoLo(
    BigInt hiHi,
    BigInt hiLo,
    BigInt loHi,
    BigInt loLo,
  ) {
    return XdrInt256Parts(
      XdrInt64(hiHi),
      XdrUint64(hiLo),
      XdrUint64(loHi),
      XdrUint64(loLo),
    );
  }
}
