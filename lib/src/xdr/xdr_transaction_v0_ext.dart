// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrTransactionV0Ext {
  XdrTransactionV0Ext(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionV0Ext encodedTransactionExt,
  ) {
    stream.writeInt(encodedTransactionExt.discriminant);
    switch (encodedTransactionExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionV0Ext decode(XdrDataInputStream stream) {
    XdrTransactionV0Ext decodedTransactionExt = XdrTransactionV0Ext(
      stream.readInt(),
    );
    switch (decodedTransactionExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionExt;
  }
}
