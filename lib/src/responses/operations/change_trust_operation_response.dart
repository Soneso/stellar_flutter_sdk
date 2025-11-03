// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../asset_type_native.dart';
import '../../assets.dart';
import '../transaction_response.dart';

/// Represents a change trust operation response from Horizon.
///
/// A change trust operation creates, updates, or removes a trustline between
/// the source account and an asset issuer or liquidity pool.
///
/// Returned by: Horizon API operations endpoint when querying change trust operations
///
/// Fields:
/// - [trustor]: Account creating/modifying the trustline (source account)
/// - [trustorMuxed]: Muxed account representation of the trustor (if applicable)
/// - [trustorMuxedId]: Muxed account ID of the trustor (if applicable)
/// - [trustee]: Issuer account of the asset being trusted (null for liquidity pools)
/// - [assetType]: Type of asset ('credit_alphanum4', 'credit_alphanum12', or 'liquidity_pool_shares')
/// - [assetCode]: Asset code being trusted (null for liquidity pools or native)
/// - [assetIssuer]: Issuer account ID of the asset (null for liquidity pools or native)
/// - [limit]: Trust limit as decimal string (0 to remove trustline)
/// - [liquidityPoolId]: ID of the liquidity pool (null for assets)
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is ChangeTrustOperationResponse) {
///     print('Trustor: ${op.trustor}');
///     print('Limit: ${op.limit}');
///     if (op.asset != null) print('Asset: ${op.asset!.code}');
///     if (op.liquidityPoolId != null) print('Pool ID: ${op.liquidityPoolId}');
///   }
/// }
/// ```
///
/// See also:
/// - [ChangeTrustOperation] for creating change trust operations
/// - [Horizon Change Trust](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/change-trust)
class ChangeTrustOperationResponse extends OperationResponse {
  /// Account creating/modifying the trustline (source account)
  String trustor;

  /// Muxed account representation of the trustor (if applicable)
  String? trustorMuxed;

  /// Muxed account ID of the trustor (if applicable)
  String? trustorMuxedId;

  /// Issuer account of the asset being trusted (null for liquidity pools)
  String? trustee;

  /// Type of asset ('credit_alphanum4', 'credit_alphanum12', or 'liquidity_pool_shares')
  String assetType;

  /// Asset code being trusted (null for liquidity pools or native)
  String? assetCode;

  /// Issuer account ID of the asset (null for liquidity pools or native)
  String? assetIssuer;

  /// Trust limit as decimal string (0 to remove trustline)
  String limit;

  /// ID of the liquidity pool (null for assets)
  String? liquidityPoolId;

  ChangeTrustOperationResponse(
      this.trustor,
      this.trustorMuxed,
      this.trustorMuxedId,
      this.trustee,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.limit,
      this.liquidityPoolId,
      super.links,
      super.id,
      super.pagingToken,
      super.transactionSuccessful,
      super.sourceAccount,
      super.sourceAccountMuxed,
      super.sourceAccountMuxedId,
      super.type,
      super.type_i,
      super.createdAt,
      super.transactionHash,
      super.transaction,
      super.sponsor);

  /// Convenience getter to retrieve the asset as an [Asset] object.
  ///
  /// Returns null for liquidity pool trustlines. For asset trustlines, returns
  /// either an [AssetTypeNative] for XLM or an [AssetTypeCreditAlphaNum] for
  /// issued assets.
  Asset? get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else if (assetType != 'liquidity_pool_shares' &&
        assetCode != null &&
        assetIssuer != null) {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
    return null;
  }

  factory ChangeTrustOperationResponse.fromJson(Map<String, dynamic> json) =>
      ChangeTrustOperationResponse(
          json['trustor'],
          json['trustor_muxed'],
          json['trustor_muxed_id'],
          json['trustee'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['limit'],
          json['liquidity_pool_id'],
          OperationResponseLinks.fromJson(json['_links']),
          json['id'],
          json['paging_token'],
          json['transaction_successful'],
          json['source_account'],
          json['source_account_muxed'],
          json['source_account_muxed_id'],
          json['type'],
          json['type_i'],
          json['created_at'],
          json['transaction_hash'],
          json['transaction'] == null
              ? null
              : TransactionResponse.fromJson(json['transaction']),
          json['sponsor']);
}
