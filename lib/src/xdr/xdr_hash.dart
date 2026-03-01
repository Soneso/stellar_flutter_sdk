// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrHash {
  XdrHash(this._hash);
  Uint8List _hash;
  Uint8List get hash => this._hash;
  set hash(Uint8List value) => this._hash = value;

  static encode(XdrDataOutputStream stream, XdrHash encodedHash) {
    stream.write(encodedHash.hash);
  }

  static XdrHash decode(XdrDataInputStream stream) {
    int hashSize = 32;
    return XdrHash(stream.readBytes(hashSize));
  }
}
