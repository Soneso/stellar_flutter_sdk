// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrAssetCode4 {
  XdrAssetCode4(this._assetCode4);

  Uint8List _assetCode4;
  Uint8List get assetCode4 => this._assetCode4;
  set assetCode4(Uint8List value) => this._assetCode4 = value;

  static void encode(XdrDataOutputStream stream, XdrAssetCode4 encodedAssetCode4) {
    stream.write(encodedAssetCode4.assetCode4);
  }

  static XdrAssetCode4 decode(XdrDataInputStream stream) {
    int assetCode4Size = 4;
    return XdrAssetCode4(stream.readBytes(assetCode4Size));
  }
}
