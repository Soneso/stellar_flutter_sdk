// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_asset_alpha_num12.dart';
import 'xdr_asset_alpha_num4.dart';
import 'xdr_asset_type.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrTrustlineAssetBase extends XdrAsset {
  XdrHash? _poolId;
  XdrHash? get poolId => this._poolId;
  set poolId(XdrHash? value) => this._poolId = value;

  XdrTrustlineAssetBase(XdrAssetType type) : super(type);

  static void encode(
    XdrDataOutputStream stream,
    XdrTrustlineAssetBase encodedAsset,
  ) {
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
        XdrHash.encode(stream, encodedAsset.poolId!);
        break;
    }
  }

  static XdrTrustlineAssetBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrTrustlineAssetBase.new);
  }

  static T decodeAs<T extends XdrTrustlineAssetBase>(
    XdrDataInputStream stream,
    T Function(XdrAssetType) constructor,
  ) {
    T decodedAsset = constructor(XdrAssetType.decode(stream));
    switch (decodedAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        decodedAsset.alphaNum4 = XdrAssetAlphaNum4.decode(stream);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        decodedAsset.alphaNum12 = XdrAssetAlphaNum12.decode(stream);
        break;
      case XdrAssetType.ASSET_TYPE_POOL_SHARE:
        decodedAsset.poolId = XdrHash.decode(stream);
        break;
    }
    return decodedAsset;
  }
}
