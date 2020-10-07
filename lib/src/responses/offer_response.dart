// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import '../assets.dart';
import '../key_pair.dart';

/// Represents an offer response received from the horizon server. Offers are statements about how much of an asset an account wants to buy or sell.
/// See: <a href="https://developers.stellar.org/api/resources/offers/" target="_blank">Offer documentation</a>
class OfferResponse extends Response {
  String id;
  String pagingToken;
  KeyPair seller;
  Asset selling;
  Asset buying;
  String amount;
  String price;
  String sponsor;
  int lastModifiedLedger;
  String lastModifiedTime;
  OfferResponseLinks links;

  OfferResponse(
      this.id,
      this.pagingToken,
      this.seller,
      this.selling,
      this.buying,
      this.amount,
      this.price,
      this.sponsor,
      this.lastModifiedLedger,
      this.lastModifiedTime,
      this.links);

  factory OfferResponse.fromJson(Map<String, dynamic> json) =>
      new OfferResponse(
          json['id'] as String,
          json['paging_token'] as String,
          json['seller'] == null
              ? null
              : KeyPair.fromAccountId(json['seller'] as String),
          json['selling'] == null
              ? null
              : Asset.fromJson(json['selling'] as Map<String, dynamic>),
          json['buying'] == null
              ? null
              : Asset.fromJson(json['buying'] as Map<String, dynamic>),
          json['amount'] as String,
          json['price'] as String,
          json['sponsor'] as String,
          convertInt(json['last_modified_ledger']),
          json['last_modified_time'] as String,
          json['_links'] == null
              ? null
              : new OfferResponseLinks.fromJson(
                  json['_links'] as Map<String, dynamic>))
        ..rateLimitLimit = convertInt(json['rateLimitLimit'])
        ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
        ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Links connected to a offer response received from horizon.
class OfferResponseLinks {
  Link self;
  Link offerMaker;

  OfferResponseLinks(this.self, this.offerMaker);

  factory OfferResponseLinks.fromJson(Map<String, dynamic> json) =>
      new OfferResponseLinks(
          json['self'] == null
              ? null
              : new Link.fromJson(json['self'] as Map<String, dynamic>),
          json['offer_maker'] == null
              ? null
              : new Link.fromJson(json['offer_maker'] as Map<String, dynamic>));
}
