// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';

class XdrAssetAlphaNum4 {
  Uint8List _assetCode;
  Uint8List get assetCode => this._assetCode;
  set assetCode(Uint8List value) => this._assetCode = value;

  XdrAccountID _issuer;
  XdrAccountID get issuer => this._issuer;
  set issuer(XdrAccountID value) => this._issuer = value;

  XdrAssetAlphaNum4(this._assetCode, this._issuer);

  static void encode(
    XdrDataOutputStream stream,
    XdrAssetAlphaNum4 encodedAssetAlphaNum4,
  ) {
    stream.write(encodedAssetAlphaNum4.assetCode);
    XdrAccountID.encode(stream, encodedAssetAlphaNum4.issuer);
  }

  static XdrAssetAlphaNum4 decode(XdrDataInputStream stream) {
    int assetCodesize = 4;
    XdrAssetAlphaNum4 decodedAssetAlphaNum4 = XdrAssetAlphaNum4(
      stream.readBytes(assetCodesize),
      XdrAccountID.decode(stream),
    );
    return decodedAssetAlphaNum4;
  }
}
