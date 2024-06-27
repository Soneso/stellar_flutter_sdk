// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import '../price.dart';

/// Represents a trade aggregation response from horizon server. A trade aggregation represents aggregated statistics on an asset pair (base and counter) for a specific time period. Trade aggregations are useful to developers of trading clients and provide historical trade data.
/// See: <a href="https://developers.stellar.org/api/aggregations/trade-aggregations/" target="_blank">Trade aggregations</a>
class TradeAggregationResponse extends Response {
  String timestamp;
  String tradeCount;
  String baseVolume;
  String counterVolume;
  String avg;
  String high;
  Price highR;
  String low;
  Price lowR;
  String open;
  Price openR;
  String close;
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
