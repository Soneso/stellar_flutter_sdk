// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrExtensionPoint {
  XdrExtensionPoint(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream, XdrExtensionPoint encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrExtensionPoint decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrExtensionPoint decoded = XdrExtensionPoint(discriminant);
    switch (decoded.discriminant) {
      case 0:
        break;
    }
    return decoded;
  }
}
