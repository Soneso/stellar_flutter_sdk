// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'xdr/xdr_ledger.dart';
import 'xdr/xdr_asset.dart';
import 'asset_type_credit_alphanum.dart';

/// Represents a liquidity pool share asset.
///
/// Liquidity pool share assets represent ownership in automated market maker (AMM)
/// liquidity pools on Stellar. These shares are issued when liquidity providers
/// deposit assets into a pool and can be redeemed for a proportional share of
/// pool reserves.
///
/// Pool characteristics:
/// - Created from two assets (assetA and assetB)
/// - Assets must be sorted: Native < AlphaNum4 < AlphaNum12, then by code, then by issuer
/// - Pool shares can be used in payment and trustline operations
/// - Share value fluctuates with pool reserves and trading activity
///
/// Use cases:
/// - Providing liquidity to earn trading fees
/// - Participating in automated market making
/// - Pool share trading and transfers
///
/// Introduced in: Protocol 18 (CAP-38)
///
/// Protocol specification:
/// - [CAP-38](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0038.md)
///
/// Example:
/// ```dart
/// // Create a pool share asset for XLM:USDC pool
/// Asset xlm = Asset.native();
/// Asset usdc = AssetTypeCreditAlphaNum4(
///   "USDC",
///   "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"
/// );
///
/// AssetTypePoolShare poolShare = AssetTypePoolShare(
///   assetA: xlm,
///   assetB: usdc
/// );
///
/// // Add trustline for pool shares
/// ChangeTrustOperation trustOp = ChangeTrustOperationBuilder(
///   poolShare,
///   "1000000"
/// ).build();
///
/// // Deposit liquidity
/// LiquidityPoolDepositOperation depositOp =
///   LiquidityPoolDepositOperationBuilder(
///     poolId,
///     "100",  // XLM amount
///     "500",  // USDC amount
///     "0.99", // min price
///     "1.01"  // max price
///   ).build();
/// ```
///
/// Important notes:
/// - Assets must be in correct sort order (constructor validates)
/// - Pool shares cannot contain other pool shares as components
/// - Both assets cannot be native (XLM)
///
/// See also:
/// - [Asset] for base asset class
/// - [LiquidityPoolDepositOperation] for adding liquidity
/// - [LiquidityPoolWithdrawOperation] for removing liquidity
class AssetTypePoolShare extends Asset {
  /// First asset in the pool (must be sorted before assetB).
  Asset assetA;

  /// Second asset in the pool (must be sorted after assetA).
  Asset assetB;

  /// Creates a liquidity pool share asset from two assets.
  ///
  /// The assets must be provided in sorted order according to:
  /// 1. Asset type: Native < AlphaNum4 < AlphaNum12
  /// 2. Asset code: Lexicographic ordering
  /// 3. Issuer: Lexicographic ordering of account IDs
  ///
  /// Parameters:
  /// - [assetA] The first asset (must sort before assetB)
  /// - [assetB] The second asset (must sort after assetA)
  ///
  /// Throws:
  /// - [Exception] If assets are not in correct sort order
  /// - [Exception] If either asset is a pool share
  /// - [Exception] If both assets are native (XLM)
  ///
  /// Example:
  /// ```dart
  /// Asset xlm = Asset.native();
  /// Asset usdc = AssetTypeCreditAlphaNum4("USDC", issuerId);
  ///
  /// // Correct order: Native before AlphaNum4
  /// AssetTypePoolShare pool = AssetTypePoolShare(
  ///   assetA: xlm,
  ///   assetB: usdc
  /// );
  /// ```
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

  /// Converts this asset to its XDR Asset representation.
  ///
  /// Returns: XDR Asset for this liquidity pool share.
  @override
  XdrAsset toXdr() {
    XdrChangeTrustAsset xdrAsset =
        XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_POOL_SHARE);

    XdrLiquidityPoolConstantProductParameters constantProduct =
        XdrLiquidityPoolConstantProductParameters(
            assetA.toXdr(),
            assetB.toXdr(),
            XdrLiquidityPoolConstantProductParameters.LIQUIDITY_POOL_FEE_V18);
    XdrLiquidityPoolParameters poolParameters = XdrLiquidityPoolParameters(
        XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT);
    poolParameters.constantProduct = constantProduct;
    xdrAsset.liquidityPool = poolParameters;
    return xdrAsset;
  }

  /// Converts this asset to its XDR ChangeTrustAsset representation.
  ///
  /// Returns: XDR ChangeTrustAsset for this liquidity pool share.
  @override
  XdrChangeTrustAsset toXdrChangeTrustAsset() {
    return toXdr() as XdrChangeTrustAsset;
  }

  /// Converts this asset to its XDR TrustlineAsset representation.
  ///
  /// Throws: Exception as pool shares cannot be converted to TrustlineAsset.
  @override
  XdrTrustlineAsset toXdrTrustLineAsset() {
    throw Exception("Unsupported asset type");
  }

  /// Returns the hash code for this instance based on its fields.
  @override
  int get hashCode {
    return assetA.hashCode + assetB.hashCode;
  }

  /// Compares this instance to another for equality.
  ///
  /// Returns `true` if [object] is of the same type and all fields are equal, `false` otherwise.
  @override
  bool operator ==(Object object) {
    if (!(object is AssetTypePoolShare)) {
      return false;
    }
    return (assetA == object.assetA && assetB == object.assetB);
  }
}
