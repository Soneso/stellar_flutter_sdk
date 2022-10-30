// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'xdr/xdr_ledger.dart';
import 'xdr/xdr_asset.dart';
import 'asset_type_credit_alphanum.dart';

/// Represents pool share assets
class AssetTypePoolShare extends Asset {
  Asset assetA;
  Asset assetB;

  AssetTypePoolShare({required this.assetA, required this.assetB}) {
    if (Asset.TYPE_POOL_SHARE == assetA.type ||
        Asset.TYPE_POOL_SHARE == assetB.type) {
      throw Exception("Asset can not be of type Asset.TYPE_POOL_SHARE");
    }
    if (assetB.type == assetA.type && assetA.type == Asset.TYPE_NATIVE) {
      throw Exception("Assets can not be both of type Asset.TYPE_NATIVE");
    }
    bool sortError = false;
    if (assetA.type.length > assetB.type.length) {
      sortError = true;
    } else if (assetA.type.length == assetB.type.length) {
      if (assetA is AssetTypeCreditAlphaNum &&
          assetB is AssetTypeCreditAlphaNum) {
        String codeA = (assetA as AssetTypeCreditAlphaNum).code;
        String codeB = (assetB as AssetTypeCreditAlphaNum).code;
        int codeCompare = codeA.compareTo(codeB);
        if (codeCompare > 0) {
          sortError = true;
        } else if (codeCompare == 0) {
          String issuerA = (assetA as AssetTypeCreditAlphaNum).issuerId;
          String issuerB = (assetB as AssetTypeCreditAlphaNum).issuerId;
          if (issuerA.compareTo(issuerB) > 0) {
            sortError = true;
          }
        }
      }
    }
    if (sortError) {
      throw Exception(
          "Assets are in wrong order. Sort by: Native < AlphaNum4 < AlphaNum12, then by Code, then by Issuer, using lexicographic ordering.");
    }
  }

  @override
  String get type => Asset.TYPE_POOL_SHARE;

  @override
  XdrAsset toXdr() {
    XdrChangeTrustAsset xdrAsset =
        XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_POOL_SHARE);
    XdrLiquidityPoolConstantProductParameters constantProduct =
        XdrLiquidityPoolConstantProductParameters();
    constantProduct.fee =
        XdrLiquidityPoolConstantProductParameters.LIQUIDITY_POOL_FEE_V18;
    constantProduct.assetA = assetA.toXdr();
    constantProduct.assetB = assetB.toXdr();
    XdrLiquidityPoolParameters poolParameters = XdrLiquidityPoolParameters(
        XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT);
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
