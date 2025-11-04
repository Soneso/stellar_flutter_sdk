// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import '../price.dart';
import 'response.dart';

/// Represents a trade executed on the Stellar network.
///
/// TradeResponse contains information about a completed trade between two assets.
/// Trades occur when offers are matched in the orderbook or through liquidity pools,
/// and can be triggered by:
/// - Manage buy/sell offer operations
/// - Path payment operations
/// - Liquidity pool swaps
///
/// Each trade involves two parties:
/// - Base account: The account that created the offer being taken
/// - Counter account: The account that is taking the offer
///
/// Trade types:
/// - "orderbook": Traditional order book trade between two accounts
/// - "liquidity_pool": Swap executed through a liquidity pool
/// - "all": Query parameter to include both types
///
/// Example:
/// ```dart
/// // Query recent trades for an asset pair
/// var trades = await sdk.trades
///   .forAssetPair(baseAsset, counterAsset)
///   .order(RequestBuilderOrder.DESC)
///   .limit(10)
///   .execute();
///
/// for (var trade in trades.records) {
///   print('Trade ID: ${trade.id}');
///   print('Type: ${trade.tradeType}');
///   print('Price: ${trade.price.n}/${trade.price.d}');
///
///   // Orderbook trade
///   if (trade.tradeType == 'orderbook') {
///     print('Base account: ${trade.baseAccount}');
///     print('Counter account: ${trade.counterAccount}');
///     print('Direction: ${trade.baseIsSeller ? 'Sell' : 'Buy'}');
///   }
///
///   // Liquidity pool trade
///   if (trade.tradeType == 'liquidity_pool') {
///     print('Base pool: ${trade.baseLiquidityPoolId}');
///     print('Fee: ${trade.liquidityPoolFeeBp} basis points');
///   }
/// }
/// ```
///
/// See also:
/// - [TradesRequestBuilder] for querying trades
/// - [Price] for price representation
/// - [Horizon Trades API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/trades)
class TradeResponse extends Response {
  /// Unique identifier for this trade.
  String id;

  /// Cursor value for paginating through trades.
  String pagingToken;

  /// ISO 8601 timestamp when the ledger containing this trade closed.
  String ledgerCloseTime;

  /// Offer ID that was filled (deprecated, use baseOfferId or counterOfferId).
  String? offerId;

  /// Indicates the direction of the trade from the base account's perspective.
  ///
  /// - true: Base account is selling base asset (receiving counter asset)
  /// - false: Base account is buying base asset (sending counter asset)
  bool baseIsSeller;

  /// Account ID of the base party (null for liquidity pool trades).
  ///
  /// For orderbook trades, this is the account that created the offer.
  String? baseAccount;

  /// Offer ID of the base party (null for liquidity pool trades).
  String? baseOfferId;

  /// Amount of base asset exchanged.
  String baseAmount;

  /// Asset type of the base asset (native, credit_alphanum4, credit_alphanum12).
  String baseAssetType;

  /// Asset code of the base asset (null for native XLM).
  String? baseAssetCode;

  /// Issuer account ID of the base asset (null for native XLM).
  String? baseAssetIssuer;

  /// Account ID of the counter party (null for liquidity pool trades).
  ///
  /// For orderbook trades, this is the account taking the offer.
  String? counterAccount;

  /// Offer ID of the counter party (null for liquidity pool trades).
  String? counterOfferId;

  /// Amount of counter asset exchanged.
  String counterAmount;

  /// Asset type of the counter asset (native, credit_alphanum4, credit_alphanum12).
  String counterAssetType;

  /// Asset code of the counter asset (null for native XLM).
  String? counterAssetCode;

  /// Issuer account ID of the counter asset (null for native XLM).
  String? counterAssetIssuer;

  /// Exchange rate between the base and counter assets.
  ///
  /// Expressed as a fraction (n/d) representing how much counter asset
  /// was exchanged per unit of base asset.
  Price price;

  /// Type of trade execution.
  ///
  /// Values:
  /// - "orderbook": Trade between two accounts via order book
  /// - "liquidity_pool": Trade executed through a liquidity pool
  String tradeType;

  /// Liquidity pool ID on the base side (only for liquidity pool trades).
  String? baseLiquidityPoolId;

  /// Liquidity pool ID on the counter side (only for liquidity pool trades).
  String? counterLiquidityPoolId;

  /// Liquidity pool fee in basis points (only for liquidity pool trades).
  ///
  /// One basis point = 0.01%. For example, 30 basis points = 0.30% fee.
  int? liquidityPoolFeeBp;

  /// Hypermedia links to related resources.
  TradeResponseLinks links;

  TradeResponse(
      this.id,
      this.pagingToken,
      this.ledgerCloseTime,
      this.offerId,
      this.baseIsSeller,
      this.baseAccount,
      this.baseOfferId,
      this.baseAmount,
      this.baseAssetType,
      this.baseAssetCode,
      this.baseAssetIssuer,
      this.counterAccount,
      this.counterOfferId,
      this.counterAmount,
      this.counterAssetType,
      this.counterAssetCode,
      this.counterAssetIssuer,
      this.tradeType,
      this.baseLiquidityPoolId,
      this.counterLiquidityPoolId,
      this.liquidityPoolFeeBp,
      this.price,
      this.links);

  /// The base asset as an Asset object.
  ///
  /// Convenience getter that constructs an Asset from the base
  /// asset type, code, and issuer fields.
  Asset get baseAsset {
    return Asset.create(
        this.baseAssetType, this.baseAssetCode!, this.baseAssetIssuer!);
  }

  /// The counter asset as an Asset object.
  ///
  /// Convenience getter that constructs an Asset from the counter
  /// asset type, code, and issuer fields.
  Asset get counterAsset {
    return Asset.create(this.counterAssetType, this.counterAssetCode!,
        this.counterAssetIssuer!);
  }

  factory TradeResponse.fromJson(Map<String, dynamic> json) => TradeResponse(
      json['id'],
      json['paging_token'],
      json['ledger_close_time'],
      json['offer_id'],
      json['base_is_seller'],
      json['base_account'] == null ? null : json['base_account'],
      json['base_offer_id'],
      json['base_amount'],
      json['base_asset_type'],
      json['base_asset_code'],
      json['base_asset_issuer'],
      json['counter_account'] == null ? null : json['counter_account'],
      json['counter_offer_id'],
      json['counter_amount'],
      json['counter_asset_type'],
      json['counter_asset_code'],
      json['counter_asset_issuer'],
      json['trade_type'],
      json['base_liquidity_pool_id'],
      json['counter_liquidity_pool_id'],
      json['liquidity_pool_fee_bp'] == null
          ? null
          : json['liquidity_pool_fee_bp'],
      Price.fromJson(json['price']),
    TradeResponseLinks.fromJson(json['_links']))
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Hypermedia links related to this trade response.
///
/// Contains links to related resources following the HAL (Hypertext Application Language)
/// specification, enabling navigation through the Horizon API.
class TradeResponseLinks {
  /// Link to the base account or liquidity pool involved in this trade.
  Link base;

  /// Link to the counter account or liquidity pool involved in this trade.
  Link counter;

  /// Link to the operation that triggered this trade.
  Link operation;

  TradeResponseLinks(this.base, this.counter, this.operation);

  factory TradeResponseLinks.fromJson(Map<String, dynamic> json) =>
      TradeResponseLinks(
          Link.fromJson(json['base']),
          Link.fromJson(json['counter']),
          Link.fromJson(json['operation']));
}
