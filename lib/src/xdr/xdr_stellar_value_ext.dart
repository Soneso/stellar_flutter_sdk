// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrStellarValueExt {
  XdrStellarValueExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrStellarValueExt encodedStellarValueExt,
  ) {
    stream.writeInt(encodedStellarValueExt.discriminant);
    switch (encodedStellarValueExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrStellarValueExt decode(XdrDataInputStream stream) {
    XdrStellarValueExt decodedStellarValueExt = XdrStellarValueExt(
      stream.readInt(),
    );
    switch (decodedStellarValueExt.discriminant) {
      case 0:
        break;
    }
    return decodedStellarValueExt;
  }
}
