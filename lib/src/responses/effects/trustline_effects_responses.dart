// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Represents trust line authorized effects abstract opbject.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
abstract class TrustlineAuthorizationResponse extends EffectResponse {
  String trustor;
  String assetType;
  String assetCode;

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
      new TrustlineAuthorizedEffectResponse(
          json['trustor'] == null ? null : json['trustor'],
          json['asset_type'] as String,
          json['asset_code'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
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
      new TrustlineAuthorizedToMaintainLiabilitiesEffectResponse(
          json['trustor'] == null ? null : json['trustor'],
          json['asset_type'] as String,
          json['asset_code'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
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
      new TrustlineDeauthorizedEffectResponse(
          json['trustor'] == null ? null : json['trustor'],
          json['asset_type'] as String,
          json['asset_code'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents trust line CUD effects abstract opbject.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
abstract class TrustlineCUDResponse extends EffectResponse {
  String limit;
  String assetType;
  String assetCode;
  String assetIssuer;

  TrustlineCUDResponse(
      this.limit, this.assetType, this.assetCode, this.assetIssuer);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }
}

/// Represents trustline_created effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TrustlineCreatedEffectResponse extends TrustlineCUDResponse {
  TrustlineCreatedEffectResponse(
      String limit, String assetType, String assetCode, String assetIssuer)
      : super(limit, assetType, assetCode, assetIssuer);

  factory TrustlineCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new TrustlineCreatedEffectResponse(
          json['limit'] as String,
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents trustline_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TrustlineRemovedEffectResponse extends TrustlineCUDResponse {
  TrustlineRemovedEffectResponse(
      String limit, String assetType, String assetCode, String assetIssuer)
      : super(limit, assetType, assetCode, assetIssuer);

  factory TrustlineRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new TrustlineRemovedEffectResponse(
          json['limit'] as String,
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents trustline_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TrustlineUpdatedEffectResponse extends TrustlineCUDResponse {
  TrustlineUpdatedEffectResponse(
      String limit, String assetType, String assetCode, String assetIssuer)
      : super(limit, assetType, assetCode, assetIssuer);

  factory TrustlineUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new TrustlineUpdatedEffectResponse(
          json['limit'] as String,
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}
