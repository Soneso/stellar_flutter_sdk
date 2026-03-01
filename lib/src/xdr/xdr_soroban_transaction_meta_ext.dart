// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_transaction_meta_ext_v1.dart';

class XdrSorobanTransactionMetaExt {
  XdrSorobanTransactionMetaExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSorobanTransactionMetaExtV1? _v1;
  XdrSorobanTransactionMetaExtV1? get v1 => this._v1;
  set v1(XdrSorobanTransactionMetaExtV1? value) => this._v1 = value;

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionMetaExt encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrSorobanTransactionMetaExtV1.encode(stream, encoded.v1!);
        break;
    }
  }

  static XdrSorobanTransactionMetaExt decode(XdrDataInputStream stream) {
    XdrSorobanTransactionMetaExt decoded =
        XdrSorobanTransactionMetaExt(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
      case 1:
        decoded.v1 = XdrSorobanTransactionMetaExtV1.decode(stream);
        break;
    }
    return decoded;
  }
}
