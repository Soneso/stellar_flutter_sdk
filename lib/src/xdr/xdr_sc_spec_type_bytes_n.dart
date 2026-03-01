// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrSCSpecTypeBytesN {
  XdrUint32 _n;
  XdrUint32 get n => this._n;
  set n(XdrUint32 value) => this._n = value;

  XdrSCSpecTypeBytesN(this._n);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeBytesN encoded) {
    XdrUint32.encode(stream, encoded.n);
  }

  static XdrSCSpecTypeBytesN decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeBytesN(XdrUint32.decode(stream));
  }
}
