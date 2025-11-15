// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Represents an offer created effect response from Horizon.
///
/// Note: This effect is not currently emitted by Horizon in most circumstances. Offer
/// creations are typically tracked through operation responses rather than effects.
/// This class exists for API completeness and potential future use.
///
/// This effect would occur when an account creates a new offer on the Stellar decentralized
/// exchange (DEX) through Manage Buy Offer or Manage Sell Offer operations. Offers allow
/// accounts to trade assets by placing orders in the order book.
///
/// Triggered by: ManageBuyOfferOperation, ManageSellOfferOperation (theoretically)
/// Returned by: Horizon API effects endpoint (rarely emitted in practice)
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is OfferCreatedEffectResponse) {
///     print('Offer created at ${effect.createdAt}');
///   }
/// }
/// ```
///
/// See also:
/// - [ManageBuyOfferOperation] and [ManageSellOfferOperation] for creating offers
/// - [OfferRemovedEffectResponse] for offer removal
/// - [Stellar developer docs](https://developers.stellar.org)
class OfferCreatedEffectResponse extends EffectResponse {
  /// Creates an [OfferCreatedEffectResponse] with effect details.
  OfferCreatedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links);

  /// Creates an offer created effect from Horizon API JSON response.
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

/// Represents an offer removed effect response from Horizon.
///
/// Note: This effect is not currently emitted by Horizon in most circumstances. Offer
/// removals are typically tracked through operation responses rather than effects.
/// This class exists for API completeness and potential future use.
///
/// This effect would occur when an account removes an existing offer from the Stellar
/// decentralized exchange (DEX). Offers can be removed explicitly through Manage Offer
/// operations or automatically when they are fully filled by trades.
///
/// Triggered by: ManageBuyOfferOperation, ManageSellOfferOperation with amount 0 (theoretically)
/// Returned by: Horizon API effects endpoint (rarely emitted in practice)
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is OfferRemovedEffectResponse) {
///     print('Offer removed at ${effect.createdAt}');
///   }
/// }
/// ```
///
/// See also:
/// - [ManageBuyOfferOperation] and [ManageSellOfferOperation] for removing offers
/// - [OfferCreatedEffectResponse] for offer creation
/// - [Stellar developer docs](https://developers.stellar.org)
class OfferRemovedEffectResponse extends EffectResponse {
  /// Creates an [OfferRemovedEffectResponse] with effect details.
  OfferRemovedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links);

  /// Creates an offer removed effect from Horizon API JSON response.
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

/// Represents an offer updated effect response from Horizon.
///
/// Note: This effect is not currently emitted by Horizon in most circumstances. Offer
/// updates are typically tracked through operation responses rather than effects.
/// This class exists for API completeness and potential future use.
///
/// This effect would occur when an account modifies an existing offer on the Stellar
/// decentralized exchange (DEX), changing its price or amount. Offers can be updated
/// by submitting a Manage Offer operation with the same offer ID but different parameters.
///
/// Triggered by: ManageBuyOfferOperation, ManageSellOfferOperation with existing offer ID (theoretically)
/// Returned by: Horizon API effects endpoint (rarely emitted in practice)
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is OfferUpdatedEffectResponse) {
///     print('Offer updated at ${effect.createdAt}');
///   }
/// }
/// ```
///
/// See also:
/// - [ManageBuyOfferOperation] and [ManageSellOfferOperation] for updating offers
/// - [OfferCreatedEffectResponse] for offer creation
/// - [Stellar developer docs](https://developers.stellar.org)
class OfferUpdatedEffectResponse extends EffectResponse {
  /// Creates an [OfferUpdatedEffectResponse] with effect details.
  OfferUpdatedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links);

  /// Creates an offer updated effect from Horizon API JSON response.
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
/// - [Stellar developer docs](https://developers.stellar.org)
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

  /// Creates a [TradeEffectResponse] with seller, offer ID, sold and bought asset details.
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

  /// Returns the sold asset as an Asset object.
  ///
  /// Returns: Native XLM or a non-native asset instance
  Asset get soldAsset {
    if (soldAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(soldAssetCode!, soldAssetIssuer!);
    }
  }

  /// Returns the bought asset as an Asset object.
  ///
  /// Returns: Native XLM or a non-native asset instance
  Asset get boughtAsset {
    if (boughtAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(boughtAssetCode!, boughtAssetIssuer!);
    }
  }

  /// Creates a trade effect from Horizon API JSON response.
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
