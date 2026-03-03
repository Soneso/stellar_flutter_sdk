// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset_alpha_num12.dart';
import 'xdr_asset_alpha_num4.dart';
import 'xdr_asset_type.dart';
import 'xdr_data_io.dart';

class XdrAsset {
  XdrAssetType _type;
  XdrAssetType get discriminant => this._type;
  set discriminant(XdrAssetType value) => this._type = value;

  XdrAssetAlphaNum4? _alphaNum4;
  XdrAssetAlphaNum4? get alphaNum4 => this._alphaNum4;
  set alphaNum4(XdrAssetAlphaNum4? value) => this._alphaNum4 = value;

  XdrAssetAlphaNum12? _alphaNum12;
  XdrAssetAlphaNum12? get alphaNum12 => this._alphaNum12;
  set alphaNum12(XdrAssetAlphaNum12? value) => this._alphaNum12 = value;

  XdrAsset(this._type);

  static void encode(XdrDataOutputStream stream, XdrAsset encodedAsset) {
    stream.writeInt(encodedAsset.discriminant.value);
    switch (encodedAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        XdrAssetAlphaNum4.encode(stream, encodedAsset.alphaNum4!);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        XdrAssetAlphaNum12.encode(stream, encodedAsset.alphaNum12!);
        break;
      case XdrAssetType.ASSET_TYPE_POOL_SHARE:
        break;
    }
  }

  static XdrAsset decode(XdrDataInputStream stream) {
    XdrAsset decodedAsset = XdrAsset(XdrAssetType.decode(stream));
    switch (decodedAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        decodedAsset.alphaNum4 = XdrAssetAlphaNum4.decode(stream);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        decodedAsset.alphaNum12 = XdrAssetAlphaNum12.decode(stream);
        break;
    }
    return decodedAsset;
  }
}
