// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_asset_alpha_num12.dart';
import 'xdr_asset_alpha_num4.dart';
import 'xdr_asset_type.dart';
import 'xdr_data_io.dart';
import 'xdr_liquidity_pool_parameters.dart';

class XdrChangeTrustAsset extends XdrAsset {
  XdrLiquidityPoolParameters? _liquidityPool;
  XdrLiquidityPoolParameters? get liquidityPool => this._liquidityPool;
  set liquidityPool(XdrLiquidityPoolParameters? value) =>
      this._liquidityPool = value;

  XdrChangeTrustAsset(XdrAssetType type) : super(type);

  static void encode(
      XdrDataOutputStream stream, XdrChangeTrustAsset encodedAsset) {
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
        XdrLiquidityPoolParameters.encode(stream, encodedAsset.liquidityPool!);
        break;
    }
  }

  static XdrChangeTrustAsset decode(XdrDataInputStream stream) {
    XdrChangeTrustAsset decodedAsset =
        XdrChangeTrustAsset(XdrAssetType.decode(stream));
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
        decodedAsset.liquidityPool = XdrLiquidityPoolParameters.decode(stream);
        break;
    }
    return decodedAsset;
  }

  static XdrChangeTrustAsset fromXdrAsset(XdrAsset asset) {
    XdrChangeTrustAsset result = XdrChangeTrustAsset(asset.discriminant);
    switch (asset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        result.alphaNum4 = asset.alphaNum4;
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        result.alphaNum12 = asset.alphaNum12;
        break;
      case XdrAssetType.ASSET_TYPE_POOL_SHARE:
        result = asset as XdrChangeTrustAsset;
        break;
    }
    return result;
  }
}
