// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrUint256 {
  XdrUint256(this._uint256);

  Uint8List _uint256;
  Uint8List get uint256 => this._uint256;
  set uint256(Uint8List value) => this._uint256 = value;

  static void encode(XdrDataOutputStream stream, XdrUint256 encodedUint256) {
    stream.write(encodedUint256.uint256);
  }

  static XdrUint256 decode(XdrDataInputStream stream) {
    int uint256Size = 32;
    return XdrUint256(stream.readBytes(uint256Size));
  }
}
