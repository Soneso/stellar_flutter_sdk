// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrTransactionV0Ext {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrTransactionV0Ext(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionV0Ext encodedTransactionV0Ext,
  ) {
    stream.writeInt(encodedTransactionV0Ext.discriminant);
    switch (encodedTransactionV0Ext.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrTransactionV0Ext decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrTransactionV0Ext decodedTransactionV0Ext = XdrTransactionV0Ext(
      discriminant,
    );
    switch (decodedTransactionV0Ext.discriminant) {
      case 0:
        break;
      default:
        break;
    }
    return decodedTransactionV0Ext;
  }
}
