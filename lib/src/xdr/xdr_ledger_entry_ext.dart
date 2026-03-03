// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_v1.dart';

class XdrLedgerEntryExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrLedgerEntryV1? _v1;

  XdrLedgerEntryV1? get v1 => this._v1;

  XdrLedgerEntryExt(this._v);

  set v1(XdrLedgerEntryV1? value) => this._v1 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerEntryExt encodedLedgerEntryExt,
  ) {
    stream.writeInt(encodedLedgerEntryExt.discriminant);
    switch (encodedLedgerEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrLedgerEntryV1.encode(stream, encodedLedgerEntryExt._v1!);
        break;
      default:
        break;
    }
  }

  static XdrLedgerEntryExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrLedgerEntryExt decodedLedgerEntryExt = XdrLedgerEntryExt(discriminant);
    switch (decodedLedgerEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedLedgerEntryExt._v1 = XdrLedgerEntryV1.decode(stream);
        break;
      default:
        break;
    }
    return decodedLedgerEntryExt;
  }
}
