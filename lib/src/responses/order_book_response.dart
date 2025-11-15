// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import '../assets.dart';
import '../price.dart';

/// Represents an order book for a trading pair on Stellar's DEX.
///
/// An order book aggregates all offers for a specific pair of assets, organizing
/// them into bids (buy orders) and asks (sell orders). This provides a snapshot
/// of the current market depth and available liquidity for the trading pair.
///
/// Structure:
/// - Base asset: The asset being priced (e.g., USD in a USD/XLM pair)
/// - Counter asset: The asset used for pricing (e.g., XLM in a USD/XLM pair)
/// - Bids: Orders to buy the base asset (sell counter asset)
/// - Asks: Orders to sell the base asset (buy counter asset)
///
/// Order books are sorted by price:
/// - Asks: Ascending order (best sell price first)
/// - Bids: Descending order (best buy price first)
///
/// Example:
/// ```dart
/// // Query order book for a trading pair
/// var orderBook = await sdk.orderBook
///     .forAssetPair(usdAsset, xlmAsset)
///     .execute();
///
/// print('Trading pair: ${orderBook.base.assetCode}/${orderBook.counter.assetCode}');
///
/// // Check best ask (lowest sell price)
/// if (orderBook.asks.isNotEmpty) {
///   var bestAsk = orderBook.asks.first;
///   print('Best ask: ${bestAsk.amount} @ ${bestAsk.price}');
/// }
///
/// // Check best bid (highest buy price)
/// if (orderBook.bids.isNotEmpty) {
///   var bestBid = orderBook.bids.first;
///   print('Best bid: ${bestBid.amount} @ ${bestBid.price}');
/// }
///
/// // Calculate spread
/// if (orderBook.asks.isNotEmpty && orderBook.bids.isNotEmpty) {
///   var spread = double.parse(orderBook.asks.first.price) -
///                double.parse(orderBook.bids.first.price);
///   print('Spread: $spread');
/// }
///
/// // Stream order book updates
/// var subscription = sdk.orderBook
///     .forAssetPair(usdAsset, xlmAsset)
///     .stream()
///     .listen((orderBook) {
///       print('Order book updated');
///     });
/// ```
///
/// See also:
/// - [OrderBookRow] for individual price levels
/// - [OfferResponse] for detailed offer information
/// - [Stellar developer docs](https://developers.stellar.org)
class OrderBookResponse extends Response {
  /// The base asset in this trading pair.
  ///
  /// This is the asset being priced. In a USD/XLM pair, USD is the base asset.
  Asset base;

  /// The counter asset in this trading pair.
  ///
  /// This is the asset used for pricing. In a USD/XLM pair, XLM is the counter asset.
  Asset counter;

  /// List of ask orders (offers to sell the base asset).
  ///
  /// Sorted in ascending order by price (best ask first). Each row represents
  /// aggregated offers at a specific price level.
  List<OrderBookRow> asks;

  /// List of bid orders (offers to buy the base asset).
  ///
  /// Sorted in descending order by price (best bid first). Each row represents
  /// aggregated offers at a specific price level.
  List<OrderBookRow> bids;

  /// Creates an OrderBookResponse from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing JSON responses
  /// from Horizon API endpoints.
  ///
  /// Parameters:
  /// - [base] The base asset in this trading pair
  /// - [counter] The counter asset in this trading pair
  /// - [asks] List of ask orders (offers to sell)
  /// - [bids] List of bid orders (offers to buy)
  OrderBookResponse(this.base, this.counter, this.asks, this.bids);

  /// Constructs an OrderBookResponse from JSON returned by Horizon API.
  factory OrderBookResponse.fromJson(Map<String, dynamic> json) => OrderBookResponse(
      Asset.fromJson(json['base']),
      Asset.fromJson(json['counter']),
      (json['asks'] as List).map((e) => OrderBookRow.fromJson(e)).toList(),
      (json['bids'] as List).map((e) => OrderBookRow.fromJson(e)).toList())
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Represents a single price level in an order book.
///
/// Each row aggregates all offers at a specific price level, showing the total
/// amount available at that price. Order book rows provide a summary view of
/// market depth without individual offer details.
class OrderBookRow {
  /// Total amount of the base asset available at this price level.
  ///
  /// This is the sum of all offer amounts at this price. Represented as a
  /// string to preserve decimal precision.
  String amount;

  /// Price at this level as a decimal string.
  ///
  /// Represents the exchange rate between base and counter assets.
  /// For example, "2.5" means 1 unit of base costs 2.5 units of counter.
  String price;

  /// Price as a rational number (numerator/denominator).
  ///
  /// Provides exact price representation as a fraction, more precise than
  /// the decimal string for repeating decimals.
  Price priceR;

  /// Creates an OrderBookRow from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing JSON responses
  /// from Horizon API endpoints.
  ///
  /// Parameters:
  /// - [amount] Total amount of base asset at this price level
  /// - [price] Price as decimal string
  /// - [priceR] Price as rational number
  OrderBookRow(this.amount, this.price, this.priceR);

  /// Constructs an OrderBookRow from JSON returned by Horizon API.
  factory OrderBookRow.fromJson(Map<String, dynamic> json) => OrderBookRow(json['amount'], json['price'],
      Price.fromJson(json['price_r']));
}
