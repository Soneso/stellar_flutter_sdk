// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrInnerTransactionResultExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrInnerTransactionResultExt(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrInnerTransactionResultExt encodedInnerTransactionResultExt,
  ) {
    stream.writeInt(encodedInnerTransactionResultExt.discriminant);
    switch (encodedInnerTransactionResultExt.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrInnerTransactionResultExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrInnerTransactionResultExt decodedInnerTransactionResultExt =
        XdrInnerTransactionResultExt(discriminant);
    switch (decodedInnerTransactionResultExt.discriminant) {
      case 0:
        break;
      default:
        break;
    }
    return decodedInnerTransactionResultExt;
  }
}
