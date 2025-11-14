// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import '../price.dart';

/// Represents aggregated trade statistics for a time period (OHLCV data).
///
/// TradeAggregationResponse provides Open-High-Low-Close-Volume (OHLCV) candlestick
/// data for a trading pair over a specific time period. This data is essential for:
/// - Building price charts and candlestick visualizations
/// - Performing technical analysis
/// - Calculating trading indicators (moving averages, RSI, etc.)
/// - Analyzing market trends and patterns
///
/// Each aggregation represents a time bucket (e.g., 1 minute, 5 minutes, 1 hour, 1 day)
/// and includes:
/// - Open/high/low/close prices during the period
/// - Trading volume in both base and counter assets
/// - Number of trades executed
///
/// Prices are provided in two formats:
/// - String format (avg, high, low, open, close): Decimal representation
/// - Price ratio format (highR, lowR, openR, closeR): Numerator/denominator fraction
///
/// Example:
/// ```dart
/// // Fetch 1-hour candlestick data for the last 7 days
/// var endTime = DateTime.now();
/// var startTime = endTime.subtract(Duration(days: 7));
///
/// var aggregations = await sdk.tradeAggregations
///   .forAssetPair(baseAsset, counterAsset)
///   .startTime(startTime)
///   .endTime(endTime)
///   .resolution(3600000) // 1 hour in milliseconds
///   .execute();
///
/// // Build OHLC candlestick chart
/// for (var candle in aggregations.records) {
///   var time = candle.getDate();
///   print('Time: $time');
///   print('  Open: ${candle.open}');
///   print('  High: ${candle.high}');
///   print('  Low: ${candle.low}');
///   print('  Close: ${candle.close}');
///   print('  Volume: ${candle.baseVolume} (base)');
///   print('  Trades: ${candle.tradeCount}');
/// }
///
/// // Calculate simple moving average
/// var prices = aggregations.records.map((c) => double.parse(c.close));
/// var sma = prices.reduce((a, b) => a + b) / prices.length;
/// print('Average price: $sma');
/// ```
///
/// See also:
/// - [TradeAggregationsRequestBuilder] for querying aggregations
/// - [Price] for price ratio representation
/// - [Stellar developer docs](https://developers.stellar.org)
class TradeAggregationResponse extends Response {
  /// Unix timestamp in milliseconds marking the start of this aggregation period.
  ///
  /// Use getDate() to convert to a DateTime object.
  String timestamp;

  /// Number of trades executed during this aggregation period.
  String tradeCount;

  /// Total volume of base asset traded during this period.
  String baseVolume;

  /// Total volume of counter asset traded during this period.
  String counterVolume;

  /// Average price during this aggregation period.
  ///
  /// Calculated as the weighted average of all trade prices.
  String avg;

  /// Highest price reached during this aggregation period.
  String high;

  /// Highest price as a ratio (numerator/denominator).
  Price highR;

  /// Lowest price reached during this aggregation period.
  String low;

  /// Lowest price as a ratio (numerator/denominator).
  Price lowR;

  /// Opening price at the start of this aggregation period.
  ///
  /// This is the price of the first trade in the period.
  String open;

  /// Opening price as a ratio (numerator/denominator).
  Price openR;

  /// Closing price at the end of this aggregation period.
  ///
  /// This is the price of the last trade in the period.
  String close;

  /// Closing price as a ratio (numerator/denominator).
  Price closeR;

  TradeAggregationResponse(
      this.timestamp,
      this.tradeCount,
      this.baseVolume,
      this.counterVolume,
      this.avg,
      this.high,
      this.highR,
      this.low,
      this.lowR,
      this.open,
      this.openR,
      this.close,
      this.closeR);

  /// Converts the timestamp to a DateTime object.
  ///
  /// Returns a DateTime representing the start of this aggregation period.
  DateTime getDate() {
    return DateTime.fromMillisecondsSinceEpoch(int.tryParse(this.timestamp)!);
  }

  factory TradeAggregationResponse.fromJson(Map<String, dynamic> json) =>
      new TradeAggregationResponse(
        json['timestamp'],
        json['trade_count'],
        json['base_volume'],
        json['counter_volume'],
        json['avg'],
        json['high'],
        Price.fromJson(json['high_r']),
        json['low'],
        Price.fromJson(json['low_r']),
        json['open'],
        Price.fromJson(json['open_r']),
        json['close'],
        Price.fromJson(json['close_r']),
      )
        ..rateLimitLimit = convertInt(json['rateLimitLimit'])
        ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
        ..rateLimitReset = convertInt(json['rateLimitReset']);
}
