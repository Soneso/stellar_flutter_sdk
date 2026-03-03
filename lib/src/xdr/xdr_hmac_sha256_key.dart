// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrHmacSha256Key {
  Uint8List _key;
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  XdrHmacSha256Key(this._key);

  static void encode(
    XdrDataOutputStream stream,
    XdrHmacSha256Key encodedHmacSha256Key,
  ) {
    stream.write(encodedHmacSha256Key.key);
  }

  static XdrHmacSha256Key decode(XdrDataInputStream stream) {
    Uint8List key = stream.readBytes(32);
    return XdrHmacSha256Key(key);
  }
}
