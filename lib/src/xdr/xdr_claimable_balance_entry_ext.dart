// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claimable_balance_entry_ext_v1.dart';
import 'xdr_data_io.dart';

class XdrClaimableBalanceEntryExt {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrClaimableBalanceEntryExtV1? _v1;

  XdrClaimableBalanceEntryExtV1? get v1 => this._v1;

  set v1(XdrClaimableBalanceEntryExtV1? value) => this._v1 = value;

  XdrClaimableBalanceEntryExt(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrClaimableBalanceEntryExt encoded,
  ) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrClaimableBalanceEntryExtV1.encode(stream, encoded.v1!);
        break;
    }
  }

  static XdrClaimableBalanceEntryExt decode(XdrDataInputStream stream) {
    XdrClaimableBalanceEntryExt decoded = XdrClaimableBalanceEntryExt(
      stream.readInt(),
    );
    switch (decoded.discriminant) {
      case 0:
        break;
      case 1:
        decoded.v1 = XdrClaimableBalanceEntryExtV1.decode(stream);
        break;
    }
    return decoded;
  }
}
