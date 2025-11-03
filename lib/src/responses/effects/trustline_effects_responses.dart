// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Deprecated: use [TrustLineFlagsUpdatedEffectResponse] instead
/// Represents trust line authorized effects abstract object.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
abstract class TrustlineAuthorizationResponse extends EffectResponse {
  String trustor;
  String assetType;
  String? assetCode;

  TrustlineAuthorizationResponse(
      this.trustor,
      this.assetType,
      this.assetCode,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);
}

/// Deprecated: use [TrustLineFlagsUpdatedEffectResponse] instead.
/// Effect Trustline Authorized occurs when an anchor has AUTH_REQUIRED flag set
/// to true and it authorizes another account's trustline
/// See: [Effects](https://developers.stellar.org/api/resources/effects/).
class TrustlineAuthorizedEffectResponse extends TrustlineAuthorizationResponse {
  TrustlineAuthorizedEffectResponse(
      super.trustor,
      super.assetType,
      super.assetCode,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustlineAuthorizedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustlineAuthorizedEffectResponse(
          json['trustor'],
          json['asset_type'],
          json['asset_code'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Deprecated: use [TrustLineFlagsUpdatedEffectResponse] instead.
/// Effect Trustline Authorized To Maintain Liabilities occurs when an anchor has AUTH_REQUIRED flag set
/// to true and it authorizes another account's trustline to maintain liabilities
/// See: [Effects](https://developers.stellar.org/api/resources/effects/).
class TrustlineAuthorizedToMaintainLiabilitiesEffectResponse
    extends TrustlineAuthorizationResponse {
  TrustlineAuthorizedToMaintainLiabilitiesEffectResponse(
      super.trustor,
      super.assetType,
      super.assetCode,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustlineAuthorizedToMaintainLiabilitiesEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustlineAuthorizedToMaintainLiabilitiesEffectResponse(
          json['trustor'],
          json['asset_type'],
          json['asset_code'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Deprecated: use [TrustLineFlagsUpdatedEffectResponse] instead.
/// EffectTrustlineDeauthorized occurs when an anchor revokes access to a asset
/// it issues.
/// See: [Effects](https://developers.stellar.org/api/resources/effects/).
class TrustlineDeauthorizedEffectResponse
    extends TrustlineAuthorizationResponse {
  TrustlineDeauthorizedEffectResponse(
      super.trustor,
      super.assetType,
      super.assetCode,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustlineDeauthorizedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustlineDeauthorizedEffectResponse(
          json['trustor'],
          json['asset_type'],
          json['asset_code'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Represents trust line CUD effects abstract opbject.
/// See: [Effects](https://developers.stellar.org/api/resources/effects/).
abstract class TrustlineCUDResponse extends EffectResponse {
  String limit;

  /// The type of asset being trusted, one of native, credit_alphanum4, credit_alphanum12, or liquidity_pool_shares.
  String assetType;
  String? assetCode;
  String? assetIssuer;
  String? liquidityPoolId;

  TrustlineCUDResponse(
      this.limit,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.liquidityPoolId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

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
}

/// Effect Trustline Created occurs when an account trusts an anchor
/// See: [Effects](https://developers.stellar.org/api/resources/effects/).
class TrustlineCreatedEffectResponse extends TrustlineCUDResponse {
  TrustlineCreatedEffectResponse(
      super.limit,
      super.assetType,
      super.assetCode,
      super.assetIssuer,
      super.liquidityPoolId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustlineCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      TrustlineCreatedEffectResponse(
          json['limit'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['liquidity_pool_id'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Effect Trustline Removed occurs when an account removes struct by setting the
/// limit of a trustline to 0.
/// See: [Effects](https://developers.stellar.org/api/resources/effects/).
class TrustlineRemovedEffectResponse extends TrustlineCUDResponse {
  TrustlineRemovedEffectResponse(
      super.limit,
      super.assetType,
      super.assetCode,
      super.assetIssuer,
      super.liquidityPoolId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustlineRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      TrustlineRemovedEffectResponse(
          json['limit'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['liquidity_pool_id'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// EffectTrustlin Updated occurs when an account changes a trustline's limit
/// See: [Effects](https://developers.stellar.org/api/resources/effects/).
class TrustlineUpdatedEffectResponse extends TrustlineCUDResponse {
  TrustlineUpdatedEffectResponse(
      super.limit,
      super.assetType,
      super.assetCode,
      super.assetIssuer,
      super.liquidityPoolId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustlineUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      TrustlineUpdatedEffectResponse(
          json['limit'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['liquidity_pool_id'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Effect Trustline Flags Updated effects occur when a TrustLine changes its
/// flags, either clearing or setting.
class TrustLineFlagsUpdatedEffectResponse extends EffectResponse {
  String trustor;
  String assetType;
  String? assetCode;
  String? assetIssuer;
  bool? authorizedFlag;
  bool? authorizedToMaintainLiabilitiesFlag;
  bool? clawbackEnabledFlag;

  TrustLineFlagsUpdatedEffectResponse(
      this.trustor,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.authorizedFlag,
      this.authorizedToMaintainLiabilitiesFlag,
      this.clawbackEnabledFlag,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustLineFlagsUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustLineFlagsUpdatedEffectResponse(
          json['trustor'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['authorized_flag'],
          json['authorized_to_maintain_liabilites_flag'],
          json['clawback_enabled_flag'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}
