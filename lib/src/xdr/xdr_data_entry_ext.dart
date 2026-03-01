// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrDataEntryExt {

  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrDataEntryExt(this._v);

  static void encode(
      XdrDataOutputStream stream, XdrDataEntryExt encodedDataEntryExt) {
    stream.writeInt(encodedDataEntryExt.discriminant);
    switch (encodedDataEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrDataEntryExt decode(XdrDataInputStream stream) {
    XdrDataEntryExt decodedDataEntryExt = XdrDataEntryExt(stream.readInt());
    switch (decodedDataEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedDataEntryExt;
  }
}
