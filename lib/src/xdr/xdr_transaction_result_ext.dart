// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrTransactionResultExt {
  XdrTransactionResultExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionResultExt encodedTransactionResultExt) {
    stream.writeInt(encodedTransactionResultExt.discriminant);
    switch (encodedTransactionResultExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionResultExt decode(XdrDataInputStream stream) {
    XdrTransactionResultExt decodedTransactionResultExt =
        XdrTransactionResultExt(stream.readInt());
    switch (decodedTransactionResultExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionResultExt;
  }
}
