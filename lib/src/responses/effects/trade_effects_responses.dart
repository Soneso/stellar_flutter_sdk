// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../response.dart';

/// Represents offer_created effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class OfferCreatedEffectResponse extends EffectResponse {
  OfferCreatedEffectResponse();

  factory OfferCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new OfferCreatedEffectResponse()
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

/// Represents offer_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class OfferRemovedEffectResponse extends EffectResponse {
  OfferRemovedEffectResponse();

  factory OfferRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new OfferRemovedEffectResponse()
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

/// Represents offer_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class OfferUpdatedEffectResponse extends EffectResponse {
  OfferUpdatedEffectResponse();

  factory OfferUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new OfferUpdatedEffectResponse()
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

/// Represents trade effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TradeEffectResponse extends EffectResponse {
  String seller;
  String offerId;

  String soldAmount;
  String soldAssetType;
  String soldAssetCode;
  String soldAssetIssuer;

  String boughtAmount;
  String boughtAssetType;
  String boughtAssetCode;
  String boughtAssetIssuer;

  TradeEffectResponse(
      this.seller,
      this.offerId,
      this.soldAmount,
      this.soldAssetType,
      this.soldAssetCode,
      this.soldAssetIssuer,
      this.boughtAmount,
      this.boughtAssetType,
      this.boughtAssetCode,
      this.boughtAssetIssuer);

  Asset get soldAsset {
    if (soldAssetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(soldAssetCode, soldAssetIssuer);
    }
  }

  Asset get boughtAsset {
    if (boughtAssetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(boughtAssetCode, boughtAssetIssuer);
    }
  }

  factory TradeEffectResponse.fromJson(Map<String, dynamic> json) =>
      new TradeEffectResponse(
          json['seller'] == null ? null : json['seller'],
          json['offer_id'] as String,
          json['sold_amount'] as String,
          json['sold_asset_type'] as String,
          json['sold_asset_code'] as String,
          json['sold_asset_issuer'] as String,
          json['bought_amount'] as String,
          json['bought_asset_type'] as String,
          json['bought_asset_code'] as String,
          json['bought_asset_issuer'] as String)
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
