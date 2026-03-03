// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_close_meta_ext_v1.dart';

class XdrLedgerCloseMetaExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrLedgerCloseMetaExtV1? _v1;

  XdrLedgerCloseMetaExtV1? get v1 => this._v1;

  XdrLedgerCloseMetaExt(this._v);

  set v1(XdrLedgerCloseMetaExtV1? value) => this._v1 = value;

  static void encode(XdrDataOutputStream stream, XdrLedgerCloseMetaExt encodedLedgerCloseMetaExt) {
    stream.writeInt(encodedLedgerCloseMetaExt.discriminant);
    switch (encodedLedgerCloseMetaExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrLedgerCloseMetaExtV1.encode(stream, encodedLedgerCloseMetaExt._v1!);
        break;
      default:
        break;
    }
  }

  static XdrLedgerCloseMetaExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrLedgerCloseMetaExt decodedLedgerCloseMetaExt = XdrLedgerCloseMetaExt(discriminant);
    switch (decodedLedgerCloseMetaExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedLedgerCloseMetaExt._v1 = XdrLedgerCloseMetaExtV1.decode(stream);
        break;
      default:
        break;
    }
    return decodedLedgerCloseMetaExt;
  }
}
