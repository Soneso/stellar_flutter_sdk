// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrAssetCode12 {
  XdrAssetCode12(this._assetCode12);

  Uint8List _assetCode12;
  Uint8List get assetCode12 => this._assetCode12;
  set assetCode12(Uint8List value) => this._assetCode12 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrAssetCode12 encodedAssetCode12,
  ) {
    stream.write(encodedAssetCode12.assetCode12);
  }

  static XdrAssetCode12 decode(XdrDataInputStream stream) {
    int assetCode12Size = 12;
    return XdrAssetCode12(stream.readBytes(assetCode12Size));
  }
}
