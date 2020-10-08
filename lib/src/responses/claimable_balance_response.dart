// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import 'response.dart';

class ClaimableBalanceResponse extends Response {
  String balanceId;
  Asset asset;
  String amount;
  String sponsor;
  int lastModifiedLedger;
  String lastModifiedTime;
  List<ClaimantResponse> claimants;
  ClaimableBalanceResponseLinks links;

  ClaimableBalanceResponse(
      this.balanceId,
      this.asset,
      this.amount,
      this.sponsor,
      this.lastModifiedLedger,
      this.lastModifiedTime,
      this.claimants,
      this.links);

  factory ClaimableBalanceResponse.fromJson(Map<String, dynamic> json) =>
      new ClaimableBalanceResponse(
          json['id'] as String,
          json['asset'] == null
              ? null
              : Asset.createFromCanonicalForm(json['asset'] as String),
          json['amount'] as String,
          json['sponsor'] as String,
          convertInt(json['last_modified_ledger']),
          json['last_modified_time'] as String,
          (json['claimants'] as List)
              ?.map((e) => e == null
              ? null
              : new ClaimantResponse.fromJson(
              e as Map<String, dynamic>))
              ?.toList(),
          json['_links'] == null
              ? null
              : new ClaimableBalanceResponseLinks.fromJson(
              json['_links'] as Map<String, dynamic>));
}

class ClaimantResponse extends Response {
  String destination;
  ClaimantPredicateResponse predicate;

  ClaimantResponse(this.destination, this.predicate);

  factory ClaimantResponse.fromJson(Map<String, dynamic> json) =>
      new ClaimantResponse(
          json['destination'] as String,
          ClaimantPredicateResponse.fromJson(
              json['predicate'] as Map<String, dynamic>));
}

class ClaimantPredicateResponse extends Response {
  bool unconditional;
  List<ClaimantPredicateResponse> and;
  List<ClaimantPredicateResponse> or;
  ClaimantPredicateResponse not;
  String beforeAbsoluteTime;
  String beforeRelativeTime;

  ClaimantPredicateResponse(this.unconditional, this.and, this.or, this.not,
      this.beforeAbsoluteTime, this.beforeRelativeTime);

  factory ClaimantPredicateResponse.fromJson(Map<String, dynamic> json) =>
      new ClaimantPredicateResponse(
          json['unconditional'] as bool,
          (json['and'] as List)
              ?.map((e) => e == null
              ? null
              : new ClaimantPredicateResponse.fromJson(
              e as Map<String, dynamic>))
              ?.toList(),
          (json['or'] as List)
              ?.map((e) => e == null
              ? null
              : new ClaimantPredicateResponse.fromJson(
              e as Map<String, dynamic>))
              ?.toList(),
          json['not'] == null
              ? null
              : new ClaimantPredicateResponse.fromJson(
              json['not'] as Map<String, dynamic>),
          json['abs_before'] as String == null ? json['absBefore'] as String : json['abs_before'] as String,
          json['rel_before'] as String == null ? json['relBefore'] as String : json['rel_before'] as String);
}

/// Links from the claimable balance response.
class ClaimableBalanceResponseLinks {
  Link self;

  ClaimableBalanceResponseLinks(this.self);

  factory ClaimableBalanceResponseLinks.fromJson(Map<String, dynamic> json) {
    return new ClaimableBalanceResponseLinks(
        json['self'] == null
            ? null
            : new Link.fromJson(json['self'] as Map<String, dynamic>));
  }
}