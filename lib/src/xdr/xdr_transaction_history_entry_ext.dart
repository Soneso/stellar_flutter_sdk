// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrTransactionHistoryEntryExt {
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrTransactionHistoryEntryExt(this._v);

  static void encode(XdrDataOutputStream stream,
      XdrTransactionHistoryEntryExt encodedTransactionHistoryEntryExt) {
    stream.writeInt(encodedTransactionHistoryEntryExt.discriminant);
    switch (encodedTransactionHistoryEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionHistoryEntryExt decode(XdrDataInputStream stream) {
    XdrTransactionHistoryEntryExt decodedTransactionHistoryEntryExt =
        XdrTransactionHistoryEntryExt(stream.readInt());
    switch (decodedTransactionHistoryEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionHistoryEntryExt;
  }
}
