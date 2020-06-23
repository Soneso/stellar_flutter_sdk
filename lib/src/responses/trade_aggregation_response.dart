// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents a trade aggregation response from horizon server.
class TradeAggregationResponse extends Response {
  int timestamp;
  int tradeCount;
  String baseVolume;
  String counterVolume;
  String avg;
  String high;
  String low;
  String open;
  String close;

  TradeAggregationResponse(this.timestamp, this.tradeCount, this.baseVolume,
      this.counterVolume, this.avg, this.high, this.low, this.open, this.close);

  DateTime getDate() {
    return DateTime.fromMillisecondsSinceEpoch(this.timestamp);
  }

  factory TradeAggregationResponse.fromJson(Map<String, dynamic> json) =>  new TradeAggregationResponse(
        convertInt(json['timestamp']),
        convertInt(json['trade_count']),
        json['base_volume'] as String,
        json['counter_volume'] as String,
        json['avg'] as String,
        json['high'] as String,
        json['low'] as String,
        json['open'] as String,
        json['close'] as String)
      ..rateLimitLimit = convertInt(json['rateLimitLimit'])
      ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
      ..rateLimitReset = convertInt(json['rateLimitReset']);
}