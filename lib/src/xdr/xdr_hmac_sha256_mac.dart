// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrHmacSha256Mac {
  XdrHmacSha256Mac(this._key);

  Uint8List _key;
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  static encode(
    XdrDataOutputStream stream,
    XdrHmacSha256Mac encodedHmacSha256Mac,
  ) {
    stream.write(encodedHmacSha256Mac.key);
  }

  static XdrHmacSha256Mac decode(XdrDataInputStream stream) {
    int keySize = 32;
    return XdrHmacSha256Mac(stream.readBytes(keySize));
  }
}
