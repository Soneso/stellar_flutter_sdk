// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';

class XdrAssetAlphaNum12 {

  Uint8List _assetCode;
  Uint8List get assetCode => this._assetCode;
  set assetCode(Uint8List value) => this._assetCode = value;

  XdrAccountID _issuer;
  XdrAccountID get issuer => this._issuer;
  set issuer(XdrAccountID value) => this._issuer = value;

  XdrAssetAlphaNum12(this._assetCode, this._issuer);

  static void encode(XdrDataOutputStream stream, XdrAssetAlphaNum12 encodedAssetAlphaNum12) {
    stream.write(encodedAssetAlphaNum12.assetCode);
    XdrAccountID.encode(stream, encodedAssetAlphaNum12.issuer);
  }

  static XdrAssetAlphaNum12 decode(XdrDataInputStream stream) {
    Uint8List assetCode = stream.readBytes(12);
    XdrAccountID issuer = XdrAccountID.decode(stream);
    return XdrAssetAlphaNum12(assetCode, issuer);
  }
}
