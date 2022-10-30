// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Represents offer_created effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class OfferCreatedEffectResponse extends EffectResponse {
  OfferCreatedEffectResponse();

  factory OfferCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      OfferCreatedEffectResponse()
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents offer_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class OfferRemovedEffectResponse extends EffectResponse {
  OfferRemovedEffectResponse();

  factory OfferRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      OfferRemovedEffectResponse()
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents offer_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class OfferUpdatedEffectResponse extends EffectResponse {
  OfferUpdatedEffectResponse();

  factory OfferUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      OfferUpdatedEffectResponse()
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents trade effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class TradeEffectResponse extends EffectResponse {
  String? seller;
  String? sellerMuxed;
  String? sellerMuxedId;
  String? offerId;

  String? soldAmount;
  String? soldAssetType;
  String? soldAssetCode;
  String? soldAssetIssuer;

  String? boughtAmount;
  String? boughtAssetType;
  String? boughtAssetCode;
  String? boughtAssetIssuer;

  TradeEffectResponse(
      this.seller,
      this.sellerMuxed,
      this.sellerMuxedId,
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
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(soldAssetCode!, soldAssetIssuer!);
    }
  }

  Asset get boughtAsset {
    if (boughtAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(boughtAssetCode!, boughtAssetIssuer!);
    }
  }

  factory TradeEffectResponse.fromJson(Map<String, dynamic> json) => TradeEffectResponse(
      json['seller'] == null ? null : json['seller'],
      json['seller_muxed'] == null ? null : json['seller_muxed'],
      json['seller_muxed_id'] == null ? null : json['seller_muxed_id'],
      json['offer_id'],
      json['sold_amount'],
      json['sold_asset_type'],
      json['sold_asset_code'],
      json['sold_asset_issuer'],
      json['bought_amount'],
      json['bought_asset_type'],
      json['bought_asset_code'],
      json['bought_asset_issuer'])
    ..id = json['id']
    ..account = json['account'] == null ? null : json['account']
    ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
    ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
    ..type = json['type']
    ..createdAt = json['created_at']
    ..pagingToken = json['paging_token']
    ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}
