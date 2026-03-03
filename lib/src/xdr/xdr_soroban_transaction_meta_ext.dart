// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_transaction_meta_ext_v1.dart';

class XdrSorobanTransactionMetaExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSorobanTransactionMetaExtV1? _v1;

  XdrSorobanTransactionMetaExtV1? get v1 => this._v1;

  XdrSorobanTransactionMetaExt(this._v);

  set v1(XdrSorobanTransactionMetaExtV1? value) => this._v1 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSorobanTransactionMetaExt encodedSorobanTransactionMetaExt,
  ) {
    stream.writeInt(encodedSorobanTransactionMetaExt.discriminant);
    switch (encodedSorobanTransactionMetaExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrSorobanTransactionMetaExtV1.encode(
          stream,
          encodedSorobanTransactionMetaExt._v1!,
        );
        break;
      default:
        break;
    }
  }

  static XdrSorobanTransactionMetaExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrSorobanTransactionMetaExt decodedSorobanTransactionMetaExt =
        XdrSorobanTransactionMetaExt(discriminant);
    switch (decodedSorobanTransactionMetaExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedSorobanTransactionMetaExt._v1 =
            XdrSorobanTransactionMetaExtV1.decode(stream);
        break;
      default:
        break;
    }
    return decodedSorobanTransactionMetaExt;
  }
}
