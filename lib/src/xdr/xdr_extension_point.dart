// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrExtensionPoint {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrExtensionPoint(this._v);

  static void encode(XdrDataOutputStream stream, XdrExtensionPoint encodedExtensionPoint) {
    stream.writeInt(encodedExtensionPoint.discriminant);
    switch (encodedExtensionPoint.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrExtensionPoint decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrExtensionPoint decodedExtensionPoint = XdrExtensionPoint(discriminant);
    switch (decodedExtensionPoint.discriminant) {
      case 0:
        break;
      default:
        break;
    }
    return decodedExtensionPoint;
  }
}
