// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_transaction_data.dart';

class XdrTransactionExt {
  XdrTransactionExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSorobanTransactionData? _sorobanTransactionData;
  XdrSorobanTransactionData? get sorobanTransactionData =>
      this._sorobanTransactionData;
  set sorobanTransactionData(XdrSorobanTransactionData? value) =>
      this._sorobanTransactionData = value;

  static void encode(XdrDataOutputStream stream, XdrTransactionExt encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrSorobanTransactionData.encode(
            stream, encoded.sorobanTransactionData!);
        break;
    }
  }

  static XdrTransactionExt decode(XdrDataInputStream stream) {
    XdrTransactionExt decodedTransactionExt =
        XdrTransactionExt(stream.readInt());
    switch (decodedTransactionExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedTransactionExt.sorobanTransactionData =
            XdrSorobanTransactionData.decode(stream);
        break;
    }
    return decodedTransactionExt;
  }
}
