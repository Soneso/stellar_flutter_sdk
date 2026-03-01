// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrLedgerHeaderExt {
  XdrLedgerHeaderExt(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerHeaderExt encodedLedgerHeaderExt) {
    stream.writeInt(encodedLedgerHeaderExt.discriminant);
    switch (encodedLedgerHeaderExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrLedgerHeaderExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrLedgerHeaderExt decodedLedgerHeaderExt =
        XdrLedgerHeaderExt(discriminant);
    switch (decodedLedgerHeaderExt.discriminant) {
      case 0:
        break;
    }
    return decodedLedgerHeaderExt;
  }
}
