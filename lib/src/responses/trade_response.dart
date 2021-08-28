// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import '../price.dart';
import 'response.dart';

/// Represents trades response from the horizon server. When an offer is fully or partially fulfilled, a trade happens. Trades can also be caused by successful path payments, because path payments involve fulfilling offers.
/// See: <a href="https://developers.stellar.org/api/resources/trades/" target="_blank">Trades documentation</a>
class TradeResponse extends Response {
  String? id;
  String? pagingToken;
  String? ledgerCloseTime;
  String? offerId;
  bool? baseIsSeller;

  String? baseAccount;
  String? baseOfferId;
  String? baseAmount;
  String? baseAssetType;
  String? baseAssetCode;
  String? baseAssetIssuer;

  String? counterAccount;
  String? counterOfferId;
  String? counterAmount;
  String? counterAssetType;
  String? counterAssetCode;
  String? counterAssetIssuer;

  Price? price;

  TradeResponseLinks? links;

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
      this.price);

  Asset get baseAsset {
    return Asset.create(this.baseAssetType!, this.baseAssetCode!, this.baseAssetIssuer!);
  }

  Asset get counterAsset {
    return Asset.create(this.counterAssetType!, this.counterAssetCode!, this.counterAssetIssuer!);
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
      json['price'] == null ? null : Price.fromJson(json['price']))
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset'])
    ..links = json['_links'] == null ? null : TradeResponseLinks.fromJson(json['_links']);
}

/// Links connected to a trade response from the horizon server.
class TradeResponseLinks {
  Link? base;
  Link? counter;
  Link? operation;

  TradeResponseLinks(this.base, this.counter, this.operation);

  factory TradeResponseLinks.fromJson(Map<String, dynamic> json) => TradeResponseLinks(
      json['base'] == null ? null : Link.fromJson(json['base']),
      json['counter'] == null ? null : Link.fromJson(json['counter']),
      json['operation'] == null ? null : Link.fromJson(json['operation']));
}
