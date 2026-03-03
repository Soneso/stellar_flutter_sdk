// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrCurve25519Secret {

  Uint8List _key;
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  XdrCurve25519Secret(this._key);

  static void encode(XdrDataOutputStream stream, XdrCurve25519Secret encodedCurve25519Secret) {
    stream.write(encodedCurve25519Secret.key);
  }

  static XdrCurve25519Secret decode(XdrDataInputStream stream) {
    Uint8List key = stream.readBytes(32);
    return XdrCurve25519Secret(key);
  }
}
