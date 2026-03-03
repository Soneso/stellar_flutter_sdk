// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrLedgerHeaderHistoryEntryExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrLedgerHeaderHistoryEntryExt(this._v);

  static void encode(XdrDataOutputStream stream, XdrLedgerHeaderHistoryEntryExt encodedLedgerHeaderHistoryEntryExt) {
    stream.writeInt(encodedLedgerHeaderHistoryEntryExt.discriminant);
    switch (encodedLedgerHeaderHistoryEntryExt.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrLedgerHeaderHistoryEntryExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrLedgerHeaderHistoryEntryExt decodedLedgerHeaderHistoryEntryExt = XdrLedgerHeaderHistoryEntryExt(discriminant);
    switch (decodedLedgerHeaderHistoryEntryExt.discriminant) {
      case 0:
        break;
      default:
        break;
    }
    return decodedLedgerHeaderHistoryEntryExt;
  }
}
