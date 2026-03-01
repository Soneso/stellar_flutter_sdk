// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrClaimableBalanceEntryExtV1 {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrUint32 _flags;
  XdrUint32 get flags => this._flags;
  set flags(XdrUint32 value) => this._flags = value;

  XdrClaimableBalanceEntryExtV1(this._v, this._flags);

  static void encode(
      XdrDataOutputStream stream, XdrClaimableBalanceEntryExtV1 encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
    }
    XdrUint32.encode(stream, encoded.flags);
  }

  static XdrClaimableBalanceEntryExtV1 decode(XdrDataInputStream stream) {
    int v = stream.readInt();
    switch (v) {
      case 0:
        break;
    }
    XdrUint32 flags = XdrUint32.decode(stream);
    return XdrClaimableBalanceEntryExtV1(v, flags);
  }
}
