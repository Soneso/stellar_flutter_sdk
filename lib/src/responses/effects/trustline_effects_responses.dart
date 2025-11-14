// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Deprecated: use [TrustLineFlagsUpdatedEffectResponse] instead
/// Represents trust line authorized effects abstract object.
/// See: [Stellar developer docs](https://developers.stellar.org).
abstract class TrustlineAuthorizationResponse extends EffectResponse {
  /// The account that created the trustline
  String trustor;

  /// The type of asset being trusted ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String assetType;

  /// Asset code (e.g., 'USD', 'EUR'), null for native XLM
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
/// Represents a trustline authorized effect response from Horizon.
///
/// This effect occurs when an asset issuer (anchor) authorizes a trustline for an account.
/// The issuer must have the AUTH_REQUIRED flag set on their account to control who can hold their asset.
///
/// Triggered by: SetTrustLineFlagsOperation or AllowTrustOperation (deprecated)
/// Returned by: Horizon API effects endpoint when querying for trustline authorization effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustlineAuthorizedEffectResponse) {
///     print('Trustline authorized for ${effect.trustor}');
///   }
/// }
/// ```
///
/// See also:
/// - [TrustLineFlagsUpdatedEffectResponse] for the current implementation
/// - [SetTrustLineFlagsOperation] for managing trustline authorization
/// - [Stellar developer docs](https://developers.stellar.org)
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
/// Represents a trustline authorized to maintain liabilities effect response from Horizon.
///
/// This effect occurs when an asset issuer authorizes a trustline to maintain liabilities only.
/// The account can hold existing balances and make payments but cannot receive new funds.
/// This is a middle ground between fully authorized and unauthorized.
///
/// Triggered by: SetTrustLineFlagsOperation or AllowTrustOperation (deprecated)
/// Returned by: Horizon API effects endpoint when querying for trustline authorization effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustlineAuthorizedToMaintainLiabilitiesEffectResponse) {
///     print('Trustline authorized to maintain liabilities for ${effect.trustor}');
///   }
/// }
/// ```
///
/// See also:
/// - [TrustLineFlagsUpdatedEffectResponse] for the current implementation
/// - [SetTrustLineFlagsOperation] for managing trustline authorization
/// - [Stellar developer docs](https://developers.stellar.org)
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
/// Represents a trustline deauthorized effect response from Horizon.
///
/// This effect occurs when an asset issuer revokes authorization for a trustline.
/// The account can no longer receive or hold the asset, though they may still maintain liabilities.
///
/// Triggered by: SetTrustLineFlagsOperation or AllowTrustOperation (deprecated)
/// Returned by: Horizon API effects endpoint when querying for trustline deauthorization effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustlineDeauthorizedEffectResponse) {
///     print('Trustline deauthorized for ${effect.trustor}');
///   }
/// }
/// ```
///
/// See also:
/// - [TrustLineFlagsUpdatedEffectResponse] for the current implementation
/// - [SetTrustLineFlagsOperation] for managing trustline authorization
/// - [Stellar developer docs](https://developers.stellar.org)
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

/// Base class for trustline Create, Update, Delete effect responses from Horizon.
///
/// Represents effects that occur when trustlines are created, updated, or removed.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
abstract class TrustlineCUDResponse extends EffectResponse {
  /// The maximum amount of the asset the account is willing to hold
  String limit;

  /// The type of asset being trusted ('native', 'credit_alphanum4', 'credit_alphanum12', or 'liquidity_pool_shares')
  String assetType;

  /// Asset code (e.g., 'USD', 'EUR'), null for native XLM or liquidity pool shares
  String? assetCode;

  /// Asset issuer account ID, null for native XLM or liquidity pool shares
  String? assetIssuer;

  /// Liquidity pool ID if the trustline is for liquidity pool shares
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

/// Represents a trustline created effect response from Horizon.
///
/// This effect occurs when an account establishes a new trustline to an asset or liquidity pool.
/// A trustline must be created before an account can hold non-native assets.
///
/// Triggered by: ChangeTrustOperation
/// Returned by: Horizon API effects endpoint when querying for trustline creation effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustlineCreatedEffectResponse) {
///     print('Trustline created: ${effect.assetCode ?? "Pool"} with limit ${effect.limit}');
///   }
/// }
/// ```
///
/// See also:
/// - [ChangeTrustOperation] for creating trustlines
/// - [TrustlineRemovedEffectResponse] for the opposite effect
/// - [Stellar developer docs](https://developers.stellar.org)
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

/// Represents a trustline removed effect response from Horizon.
///
/// This effect occurs when an account removes a trustline by setting its limit to 0.
/// The account must have a zero balance of the asset before the trustline can be removed.
///
/// Triggered by: ChangeTrustOperation with limit set to 0
/// Returned by: Horizon API effects endpoint when querying for trustline removal effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustlineRemovedEffectResponse) {
///     print('Trustline removed: ${effect.assetCode ?? "Pool"}');
///   }
/// }
/// ```
///
/// See also:
/// - [ChangeTrustOperation] for removing trustlines
/// - [TrustlineCreatedEffectResponse] for the opposite effect
/// - [Stellar developer docs](https://developers.stellar.org)
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

/// Represents a trustline updated effect response from Horizon.
///
/// This effect occurs when an account modifies the limit of an existing trustline.
/// This allows the account to control the maximum amount of an asset they can hold.
///
/// Triggered by: ChangeTrustOperation with a different limit
/// Returned by: Horizon API effects endpoint when querying for trustline update effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustlineUpdatedEffectResponse) {
///     print('Trustline updated: ${effect.assetCode ?? "Pool"} new limit ${effect.limit}');
///   }
/// }
/// ```
///
/// See also:
/// - [ChangeTrustOperation] for updating trustlines
/// - [TrustlineCreatedEffectResponse] for creating trustlines
/// - [Stellar developer docs](https://developers.stellar.org)
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

/// Represents a trustline flags updated effect response from Horizon.
///
/// This effect occurs when an asset issuer modifies the authorization flags on a trustline.
/// This is the current way to manage trustline authorization, replacing the deprecated
/// Allow Trust operation.
///
/// Triggered by: SetTrustLineFlagsOperation
/// Returned by: Horizon API effects endpoint when querying for trustline flag updates
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('issuer_account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustLineFlagsUpdatedEffectResponse) {
///     print('Flags updated for ${effect.trustor}: authorized=${effect.authorizedFlag}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetTrustLineFlagsOperation] for managing trustline flags
/// - [Stellar developer docs](https://developers.stellar.org)
class TrustLineFlagsUpdatedEffectResponse extends EffectResponse {
  /// The account that holds the trustline
  String trustor;

  /// The type of asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String assetType;

  /// Asset code (e.g., 'USD', 'EUR'), null for native XLM
  String? assetCode;

  /// Asset issuer account ID, null for native XLM
  String? assetIssuer;

  /// Whether the trustline is fully authorized to hold and receive the asset
  bool? authorizedFlag;

  /// Whether the trustline is authorized to maintain liabilities only
  bool? authorizedToMaintainLiabilitiesFlag;

  /// Whether the issuer can claw back this asset from the account
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
          json['authorized_to_maintain_liabilities_flag'],
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
