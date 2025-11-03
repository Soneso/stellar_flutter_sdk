// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/price.dart';
import 'response.dart';
import '../assets.dart';

/// Represents an offer response received from the horizon server. Offers are statements about how much of an asset an account wants to buy or sell.
/// See: [Offer documentation](https://developers.stellar.org/api/resources/offers/)
class OfferResponse extends Response {
  String id;
  String pagingToken;
  String seller;
  Asset selling;
  Asset buying;
  String amount;
  String price;
  Price priceR;
  String? sponsor;
  int lastModifiedLedger;
  String lastModifiedTime;
  OfferResponseLinks links;

  OfferResponse(this.id, this.pagingToken, this.seller, this.selling, this.buying, this.amount,
      this.price, this.priceR, this.sponsor, this.lastModifiedLedger, this.lastModifiedTime, this.links);

  factory OfferResponse.fromJson(Map<String, dynamic> json) => OfferResponse(
      json['id'],
      json['paging_token'],
      json['seller'],
      Asset.fromJson(json['selling']),
      Asset.fromJson(json['buying']),
      json['amount'],
      json['price'],
      Price.fromJson(json['price_r']),
      json['sponsor'],
      convertInt(json['last_modified_ledger'])!,
      json['last_modified_time'],
      OfferResponseLinks.fromJson(json['_links']))
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Links connected to a offer response received from horizon.
class OfferResponseLinks {
  Link self;
  Link offerMaker;

  OfferResponseLinks(this.self, this.offerMaker);

  factory OfferResponseLinks.fromJson(Map<String, dynamic> json) => OfferResponseLinks(
      Link.fromJson(json['self']),
      Link.fromJson(json['offer_maker']));
}
