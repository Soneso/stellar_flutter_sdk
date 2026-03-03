// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrCurve25519Public {
  Uint8List _key;
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  XdrCurve25519Public(this._key);

  static void encode(
    XdrDataOutputStream stream,
    XdrCurve25519Public encodedCurve25519Public,
  ) {
    stream.write(encodedCurve25519Public.key);
  }

  static XdrCurve25519Public decode(XdrDataInputStream stream) {
    Uint8List key = stream.readBytes(32);
    return XdrCurve25519Public(key);
  }
}
