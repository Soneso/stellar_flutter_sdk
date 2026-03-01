// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrLedgerEntryV1Ext {
  XdrLedgerEntryV1Ext(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryV1Ext encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
    }
  }

  static XdrLedgerEntryV1Ext decode(XdrDataInputStream stream) {
    XdrLedgerEntryV1Ext decoded = XdrLedgerEntryV1Ext(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
    }
    return decoded;
  }
}
