// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Unused: Effect Offer Created occurs when an account offers to trade an asset
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class OfferCreatedEffectResponse extends EffectResponse {
  OfferCreatedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links);

  factory OfferCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      OfferCreatedEffectResponse(
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

/// Unused: Effect Offer Removed occurs when an account removes an offer
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class OfferRemovedEffectResponse extends EffectResponse {
  OfferRemovedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links);

  factory OfferRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      OfferRemovedEffectResponse(
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

/// Unused: Effect Offer Updated occurs when an offer is updated by the offering account.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class OfferUpdatedEffectResponse extends EffectResponse {
  OfferUpdatedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links);

  factory OfferUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      OfferUpdatedEffectResponse(
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

/// Effect Trade occurs when a trade is initiated because of a path payment or offer operation.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class TradeEffectResponse extends EffectResponse {
  String seller;
  String? sellerMuxed;
  String? sellerMuxedId;
  String offerId;

  String soldAmount;
  String soldAssetType;
  String? soldAssetCode;
  String? soldAssetIssuer;

  String boughtAmount;
  String boughtAssetType;
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
      this.boughtAssetIssuer,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

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

  factory TradeEffectResponse.fromJson(Map<String, dynamic> json) =>
      TradeEffectResponse(
          json['seller'],
          json['seller_muxed'],
          json['seller_muxed_id'],
          json['offer_id'],
          json['sold_amount'],
          json['sold_asset_type'],
          json['sold_asset_code'],
          json['sold_asset_issuer'],
          json['bought_amount'],
          json['bought_asset_type'],
          json['bought_asset_code'],
          json['bought_asset_issuer'],
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
