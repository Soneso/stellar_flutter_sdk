// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_header_extension_v1.dart';

class XdrLedgerHeaderExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrLedgerHeaderExtensionV1? _v1;

  XdrLedgerHeaderExtensionV1? get v1 => this._v1;

  XdrLedgerHeaderExt(this._v);

  set v1(XdrLedgerHeaderExtensionV1? value) => this._v1 = value;

  static void encode(XdrDataOutputStream stream, XdrLedgerHeaderExt encodedLedgerHeaderExt) {
    stream.writeInt(encodedLedgerHeaderExt.discriminant);
    switch (encodedLedgerHeaderExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrLedgerHeaderExtensionV1.encode(stream, encodedLedgerHeaderExt._v1!);
        break;
      default:
        break;
    }
  }

  static XdrLedgerHeaderExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrLedgerHeaderExt decodedLedgerHeaderExt = XdrLedgerHeaderExt(discriminant);
    switch (decodedLedgerHeaderExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedLedgerHeaderExt._v1 = XdrLedgerHeaderExtensionV1.decode(stream);
        break;
      default:
        break;
    }
    return decodedLedgerHeaderExt;
  }
}
