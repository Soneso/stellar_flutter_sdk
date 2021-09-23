// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'util.dart';
import 'xdr/xdr_ledger.dart';
import 'xdr/xdr_asset.dart';

/// Represents pool share assets
class AssetTypePoolShare extends Asset {
  Asset assetA;
  Asset assetB;


  AssetTypePoolShare({required this.assetA, required this.assetB});

  @override
  String get type => Asset.TYPE_POOL_SHARE;

  @override
  XdrAsset toXdr() {
    XdrChangeTrustAsset xdrAsset = XdrChangeTrustAsset();
    xdrAsset.discriminant = XdrAssetType.ASSET_TYPE_POOL_SHARE;
    XdrLiquidityPoolConstantProductParameters constantProduct = XdrLiquidityPoolConstantProductParameters();
    constantProduct.fee = XdrLiquidityPoolConstantProductParameters.LIQUIDITY_POOL_FEE_V18;
    constantProduct.assetA = assetA.toXdr();
    constantProduct.assetB = assetB.toXdr();
    XdrLiquidityPoolParameters poolParameters = XdrLiquidityPoolParameters();
    poolParameters.discriminant = XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT;
    poolParameters.constantProduct = constantProduct;
    xdrAsset.liquidityPool = poolParameters;
    return xdrAsset;
  }

  @override
  XdrChangeTrustAsset toXdrChangeTrustAsset() {
    return toXdr() as XdrChangeTrustAsset;
  }

  @override
  XdrTrustlineAsset toXdrTrustLineAsset() {
    throw Exception("Unsupported asset type");
  }

  @override
  int get hashCode {
    return assetA.hashCode + assetB.hashCode;
  }

  @override
  bool operator ==(Object object) {
    if (!(object is AssetTypePoolShare)) {
      return false;
    }
    return (assetA == object.assetA && assetB == object.assetB);
  }
}
