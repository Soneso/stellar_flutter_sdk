// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrFeeBumpTransactionExt {
  XdrFeeBumpTransactionExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream,
      XdrFeeBumpTransactionExt encodedTransactionExt) {
    stream.writeInt(encodedTransactionExt.discriminant);
    switch (encodedTransactionExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrFeeBumpTransactionExt decode(XdrDataInputStream stream) {
    XdrFeeBumpTransactionExt decodedTransactionExt =
        XdrFeeBumpTransactionExt(stream.readInt());
    switch (decodedTransactionExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionExt;
  }
}
