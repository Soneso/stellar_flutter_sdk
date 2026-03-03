// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrShortHashSeed {
  Uint8List _seed;
  Uint8List get seed => this._seed;
  set seed(Uint8List value) => this._seed = value;

  XdrShortHashSeed(this._seed);

  static void encode(
    XdrDataOutputStream stream,
    XdrShortHashSeed encodedShortHashSeed,
  ) {
    stream.write(encodedShortHashSeed.seed);
  }

  static XdrShortHashSeed decode(XdrDataInputStream stream) {
    Uint8List seed = stream.readBytes(16);
    return XdrShortHashSeed(seed);
  }
}
