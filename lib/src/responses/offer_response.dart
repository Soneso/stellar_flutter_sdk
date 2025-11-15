// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/price.dart';
import 'response.dart';
import '../assets.dart';

/// Represents an offer on Stellar's decentralized exchange (DEX).
///
/// Offers are public commitments to exchange one asset for another at a specific price.
/// They form the basis of Stellar's order book-based DEX, allowing users to trade assets
/// without intermediaries.
///
/// Each offer specifies:
/// - The asset being sold and the asset being bought
/// - The amount of the selling asset available
/// - The price (how many units of buying asset per unit of selling asset)
///
/// Offers remain active in the ledger until they are:
/// - Fully consumed by matching trades
/// - Partially or fully canceled by the seller
/// - Deleted due to insufficient balance
///
/// Example:
/// ```dart
/// // Query offers for an account
/// var offers = await sdk.offers
///     .forAccount(accountId)
///     .order(RequestBuilderOrder.DESC)
///     .limit(20)
///     .execute();
///
/// for (var offer in offers.records) {
///   print('Offer ${offer.id}');
///   print('Selling: ${offer.amount} ${offer.selling.assetCode}');
///   print('Buying: ${offer.buying.assetCode}');
///   print('Price: ${offer.price} ${offer.buying.assetCode}/${offer.selling.assetCode}');
///   print('Last modified: ${offer.lastModifiedTime}');
///
///   // Price as ratio for precise calculations
///   var priceRatio = offer.priceR.n / offer.priceR.d;
/// }
///
/// // Create a new offer
/// var operation = ManageSellOfferOperation(
///   selling: assetA,
///   buying: assetB,
///   amount: '100',
///   price: Price.fromString('2.5')
/// );
/// ```
///
/// See also:
/// - [ManageSellOfferOperation] for creating and managing sell offers
/// - [ManageBuyOfferOperation] for creating and managing buy offers
/// - [Price] for working with offer prices
/// - [Stellar developer docs](https://developers.stellar.org)
class OfferResponse extends Response {
  /// Unique identifier for this offer.
  String id;

  /// Cursor value for paginating through offer results.
  String pagingToken;

  /// Account ID of the account that created this offer.
  String seller;

  /// Asset being sold in this offer.
  Asset selling;

  /// Asset being bought in this offer.
  Asset buying;

  /// Amount of the selling asset available in this offer.
  ///
  /// Represented as a string to preserve decimal precision.
  String amount;

  /// Price of 1 unit of selling asset in terms of buying asset.
  ///
  /// Represented as a decimal string. For example, "2.5" means 1 unit of the
  /// selling asset costs 2.5 units of the buying asset.
  String price;

  /// Price as a rational number (numerator/denominator).
  ///
  /// Provides exact price representation as a fraction. More precise than the
  /// decimal string representation, especially for repeating decimals.
  Price priceR;

  /// Account sponsoring the base reserve for this offer, if any.
  ///
  /// When set, this account pays the base reserve required to maintain this offer
  /// in the ledger instead of the seller.
  String? sponsor;

  /// Ledger sequence number when this offer was last modified.
  int lastModifiedLedger;

  /// Timestamp when this offer was last modified.
  String lastModifiedTime;

  /// Hypermedia links to related resources.
  OfferResponseLinks links;

  /// Creates an OfferResponse from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing JSON responses
  /// from Horizon API endpoints.
  ///
  /// Parameters:
  /// - [id] Unique identifier for this offer
  /// - [pagingToken] Cursor for pagination
  /// - [seller] Account ID of the offer creator
  /// - [selling] Asset being sold
  /// - [buying] Asset being bought
  /// - [amount] Amount of selling asset available
  /// - [price] Price as decimal string
  /// - [priceR] Price as rational number
  /// - [sponsor] Account sponsoring the offer's reserve
  /// - [lastModifiedLedger] Ledger sequence when last modified
  /// - [lastModifiedTime] Timestamp when last modified
  /// - [links] Hypermedia links to related resources
  OfferResponse(this.id, this.pagingToken, this.seller, this.selling, this.buying, this.amount,
      this.price, this.priceR, this.sponsor, this.lastModifiedLedger, this.lastModifiedTime, this.links);

  /// Creates an offer response from Horizon API JSON.
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

/// Hypermedia links connected to an offer response.
///
/// Provides links to related resources for this offer.
class OfferResponseLinks {
  /// Link to this offer's detail endpoint.
  Link self;

  /// Link to the account that created this offer (the seller).
  Link offerMaker;

  /// Creates an OfferResponseLinks from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing JSON responses
  /// from Horizon API endpoints.
  ///
  /// Parameters:
  /// - [self] Link to this offer's detail endpoint
  /// - [offerMaker] Link to the account that created this offer
  OfferResponseLinks(this.self, this.offerMaker);

  /// Creates offer response links from Horizon API JSON.
  factory OfferResponseLinks.fromJson(Map<String, dynamic> json) => OfferResponseLinks(
      Link.fromJson(json['self']),
      Link.fromJson(json['offer_maker']));
}
