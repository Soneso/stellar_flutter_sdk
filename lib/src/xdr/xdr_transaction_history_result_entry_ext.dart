// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrTransactionHistoryResultEntryExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrTransactionHistoryResultEntryExt(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionHistoryResultEntryExt encodedTransactionHistoryResultEntryExt,
  ) {
    stream.writeInt(encodedTransactionHistoryResultEntryExt.discriminant);
    switch (encodedTransactionHistoryResultEntryExt.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrTransactionHistoryResultEntryExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrTransactionHistoryResultEntryExt
    decodedTransactionHistoryResultEntryExt =
        XdrTransactionHistoryResultEntryExt(discriminant);
    switch (decodedTransactionHistoryResultEntryExt.discriminant) {
      case 0:
        break;
      default:
        break;
    }
    return decodedTransactionHistoryResultEntryExt;
  }
}
