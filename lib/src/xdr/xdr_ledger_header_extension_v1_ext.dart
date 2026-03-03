// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrLedgerHeaderExtensionV1Ext {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrLedgerHeaderExtensionV1Ext(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerHeaderExtensionV1Ext encodedLedgerHeaderExtensionV1Ext,
  ) {
    stream.writeInt(encodedLedgerHeaderExtensionV1Ext.discriminant);
    switch (encodedLedgerHeaderExtensionV1Ext.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrLedgerHeaderExtensionV1Ext decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrLedgerHeaderExtensionV1Ext decodedLedgerHeaderExtensionV1Ext =
        XdrLedgerHeaderExtensionV1Ext(discriminant);
    switch (decodedLedgerHeaderExtensionV1Ext.discriminant) {
      case 0:
        break;
      default:
        break;
    }
    return decodedLedgerHeaderExtensionV1Ext;
  }
}
