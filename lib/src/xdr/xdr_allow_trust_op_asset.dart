// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_asset_type.dart';
import 'xdr_data_io.dart';

class XdrAllowTrustOpAsset {
  XdrAllowTrustOpAsset(this._type);

  XdrAssetType _type;
  XdrAssetType get discriminant => this._type;
  set discriminant(XdrAssetType value) => this._type = value;

  Uint8List? _assetCode4;
  Uint8List? get assetCode4 => this._assetCode4;
  set assetCode4(Uint8List? value) => this._assetCode4 = value;

  Uint8List? _assetCode12;
  Uint8List? get assetCode12 => this._assetCode12;
  set assetCode12(Uint8List? value) => this._assetCode12 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrAllowTrustOpAsset encodedAllowTrustOpAsset,
  ) {
    stream.writeInt(encodedAllowTrustOpAsset.discriminant.value);
    switch (encodedAllowTrustOpAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        stream.write(encodedAllowTrustOpAsset.assetCode4!);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        stream.write(encodedAllowTrustOpAsset.assetCode12!);
        break;
    }
  }

  static XdrAllowTrustOpAsset decode(XdrDataInputStream stream) {
    XdrAllowTrustOpAsset decodedAllowTrustOpAsset = XdrAllowTrustOpAsset(
      XdrAssetType.decode(stream),
    );
    switch (decodedAllowTrustOpAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        int assetCode4size = 4;
        decodedAllowTrustOpAsset.assetCode4 = stream.readBytes(assetCode4size);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        int assetCode12size = 12;
        decodedAllowTrustOpAsset.assetCode12 = stream.readBytes(
          assetCode12size,
        );
        break;
    }
    return decodedAllowTrustOpAsset;
  }
}
