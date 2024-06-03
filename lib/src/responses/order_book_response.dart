// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import '../assets.dart';
import '../price.dart';

/// Represents an order book response received from the horizon server. An order book is a collections of offers for a specific pair of assets.
/// See: <a href="https://developers.stellar.org/api/aggregations/order-books/" target="_blank">Order book documentation</a>
class OrderBookResponse extends Response {
  Asset base;
  Asset counter;
  List<OrderBookRow> asks;
  List<OrderBookRow> bids;

  OrderBookResponse(this.base, this.counter, this.asks, this.bids);

  factory OrderBookResponse.fromJson(Map<String, dynamic> json) => OrderBookResponse(
      Asset.fromJson(json['base']),
      Asset.fromJson(json['counter']),
      (json['asks'] as List).map((e) => OrderBookRow.fromJson(e)).toList(),
      (json['bids'] as List).map((e) => OrderBookRow.fromJson(e)).toList())
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Represents a row in the order book response received from the horizon server.
class OrderBookRow {
  String amount;
  String price;
  Price priceR;

  OrderBookRow(this.amount, this.price, this.priceR);

  factory OrderBookRow.fromJson(Map<String, dynamic> json) => OrderBookRow(json['amount'], json['price'],
      Price.fromJson(json['price_r']));
}
