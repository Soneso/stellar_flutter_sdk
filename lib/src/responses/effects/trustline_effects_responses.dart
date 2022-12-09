// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Represents trust line authorized effects abstract opbject.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
abstract class TrustlineAuthorizationResponse extends EffectResponse {
  String? trustor;
  String? assetType;
  String? assetCode;

  TrustlineAuthorizationResponse(this.trustor, this.assetType, this.assetCode);
}

/// Represents trustline_authorized effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TrustlineAuthorizedEffectResponse extends TrustlineAuthorizationResponse {
  TrustlineAuthorizedEffectResponse(
      String trustor, String assetType, String assetCode)
      : super(trustor, assetType, assetCode);

  factory TrustlineAuthorizedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustlineAuthorizedEffectResponse(
          json['trustor'] == null ? null : json['trustor'],
          json['asset_type'],
          json['asset_code'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents trustline_authorized to maintain liabilities effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TrustlineAuthorizedToMaintainLiabilitiesEffectResponse
    extends TrustlineAuthorizationResponse {
  TrustlineAuthorizedToMaintainLiabilitiesEffectResponse(
      String trustor, String assetType, String assetCode)
      : super(trustor, assetType, assetCode);

  factory TrustlineAuthorizedToMaintainLiabilitiesEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustlineAuthorizedToMaintainLiabilitiesEffectResponse(
          json['trustor'] == null ? null : json['trustor'],
          json['asset_type'],
          json['asset_code'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents trustline_deauthorized effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TrustlineDeauthorizedEffectResponse
    extends TrustlineAuthorizationResponse {
  TrustlineDeauthorizedEffectResponse(
      String trustor, String assetType, String assetCode)
      : super(trustor, assetType, assetCode);

  factory TrustlineDeauthorizedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustlineDeauthorizedEffectResponse(
          json['trustor'] == null ? null : json['trustor'],
          json['asset_type'],
          json['asset_code'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents trust line CUD effects abstract opbject.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
abstract class TrustlineCUDResponse extends EffectResponse {
  String? limit;
  String? assetType;
  String? assetCode;
  String? assetIssuer;
  String? liquidityPoolId;

  TrustlineCUDResponse(this.limit, this.assetType, this.assetCode,
      this.assetIssuer, this.liquidityPoolId);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }
}

/// Represents trustline_created effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TrustlineCreatedEffectResponse extends TrustlineCUDResponse {
  TrustlineCreatedEffectResponse(String limit, String assetType,
      String? assetCode, String? assetIssuer, String? liquidityPoolId)
      : super(limit, assetType, assetCode, assetIssuer, liquidityPoolId);

  factory TrustlineCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      TrustlineCreatedEffectResponse(
          json['limit'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['liquidity_pool_id'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents trustline_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TrustlineRemovedEffectResponse extends TrustlineCUDResponse {
  TrustlineRemovedEffectResponse(String limit, String assetType,
      String? assetCode, String? assetIssuer, String? liquidityPoolId)
      : super(limit, assetType, assetCode, assetIssuer, liquidityPoolId);

  factory TrustlineRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      TrustlineRemovedEffectResponse(json['limit'], json['asset_type'],
          json['asset_code'], json['asset_issuer'], json['liquidity_pool_id'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents trustline_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TrustlineUpdatedEffectResponse extends TrustlineCUDResponse {
  TrustlineUpdatedEffectResponse(String limit, String assetType,
      String? assetCode, String? assetIssuer, String? liquidityPoolId)
      : super(limit, assetType, assetCode, assetIssuer, liquidityPoolId);

  factory TrustlineUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      TrustlineUpdatedEffectResponse(json['limit'], json['asset_type'],
          json['asset_code'], json['asset_issuer'], json['liquidity_pool_id'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}
