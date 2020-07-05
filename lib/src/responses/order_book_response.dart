// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import '../assets.dart';
import '../price.dart';
import '../util.dart';

/// Represents an order book response received from the horizon server. An order book is a collections of offers for a specific pair of assets.
/// See: <a href="https://developers.stellar.org/api/aggregations/order-books/" target="_blank">Order book documentation</a>
class OrderBookResponse extends Response {
  Asset base;
  Asset counter;
  List<Row> asks;
  List<Row> bids;

  OrderBookResponse(this.base, this.counter, this.asks, this.bids);

  factory OrderBookResponse.fromJson(Map<String, dynamic> json) =>
      new OrderBookResponse(
          json['base'] == null
              ? null
              : Asset.fromJson(json['base'] as Map<String, dynamic>),
          json['counter'] == null
              ? null
              : Asset.fromJson(json['counter'] as Map<String, dynamic>),
          (json['asks'] as List)
              ?.map((e) => e == null
                  ? null
                  : new Row.fromJson(e as Map<String, dynamic>))
              ?.toList(),
          (json['bids'] as List)
              ?.map((e) => e == null
                  ? null
                  : new Row.fromJson(e as Map<String, dynamic>))
              ?.toList())
        ..rateLimitLimit = convertInt(json['rateLimitLimit'])
        ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
        ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Represents a row in the order book response received from the horizon server.
class Row {
  String amount;
  String price;
  Price priceR;

  Row(String amount, String price, Price priceR) {
    this.amount = checkNotNull(amount, "amount cannot be null");
    this.price = checkNotNull(price, "price cannot be null");
    this.priceR = checkNotNull(priceR, "priceR cannot be null");
  }

  factory Row.fromJson(Map<String, dynamic> json) => new Row(
      json['amount'] as String,
      json['price'] as String,
      json['price_r'] == null
          ? null
          : new Price.fromJson(json['price_r'] as Map<String, dynamic>));
}
