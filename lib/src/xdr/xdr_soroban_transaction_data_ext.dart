// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_resources_ext_v0.dart';

class XdrSorobanTransactionDataExt {
  XdrSorobanTransactionDataExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSorobanResourcesExtV0? _resourceExt;
  XdrSorobanResourcesExtV0? get resourceExt => this._resourceExt;
  set resourceExt(XdrSorobanResourcesExtV0? value) => this._resourceExt = value;

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionDataExt encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrSorobanResourcesExtV0.encode(stream, encoded.resourceExt!);
        break;
    }
  }

  static XdrSorobanTransactionDataExt decode(XdrDataInputStream stream) {
    XdrSorobanTransactionDataExt decoded =
        XdrSorobanTransactionDataExt(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
      case 1:
        decoded.resourceExt = XdrSorobanResourcesExtV0.decode(stream);
        break;
    }
    return decoded;
  }
}
