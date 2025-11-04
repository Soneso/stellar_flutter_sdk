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

/// Represents a trade effect response from Horizon.
///
/// This effect occurs when assets are exchanged on the Stellar decentralized exchange (DEX).
/// Trades can be triggered by offer management operations or path payment operations.
///
/// Triggered by: ManageBuyOfferOperation, ManageSellOfferOperation, PathPaymentStrictSendOperation, PathPaymentStrictReceiveOperation
/// Returned by: Horizon API effects endpoint when querying for trade effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TradeEffectResponse) {
///     print('Trade: sold ${effect.soldAmount} ${effect.soldAssetCode ?? "XLM"}');
///     print('      bought ${effect.boughtAmount} ${effect.boughtAssetCode ?? "XLM"}');
///   }
/// }
/// ```
///
/// See also:
/// - [ManageBuyOfferOperation] and [ManageSellOfferOperation] for creating offers
/// - [PathPaymentStrictSendOperation] and [PathPaymentStrictReceiveOperation] for path payments
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class TradeEffectResponse extends EffectResponse {
  /// The account ID of the seller
  String seller;

  /// The muxed account address of the seller, if using muxed accounts
  String? sellerMuxed;

  /// The muxed account ID of the seller, if using muxed accounts
  String? sellerMuxedId;

  /// The ID of the offer that was filled
  String offerId;

  /// Amount of asset sold
  String soldAmount;

  /// Type of asset sold ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String soldAssetType;

  /// Code of asset sold (e.g., 'USD', 'EUR'), null for native XLM
  String? soldAssetCode;

  /// Issuer of asset sold, null for native XLM
  String? soldAssetIssuer;

  /// Amount of asset bought
  String boughtAmount;

  /// Type of asset bought ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String boughtAssetType;

  /// Code of asset bought (e.g., 'USD', 'EUR'), null for native XLM
  String? boughtAssetCode;

  /// Issuer of asset bought, null for native XLM
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
