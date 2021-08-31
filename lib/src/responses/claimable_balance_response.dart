// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import 'response.dart';

class ClaimableBalanceResponse extends Response {
  String? balanceId;
  Asset? asset;
  String? amount;
  String? sponsor;
  int? lastModifiedLedger;
  String? lastModifiedTime;
  List<ClaimantResponse?>? claimants;
  ClaimableBalanceResponseLinks? links;

  ClaimableBalanceResponse(this.balanceId, this.asset, this.amount, this.sponsor,
      this.lastModifiedLedger, this.lastModifiedTime, this.claimants, this.links);

  factory ClaimableBalanceResponse.fromJson(Map<String, dynamic> json) => ClaimableBalanceResponse(
      json['id'],
      json['asset'] == null ? null : Asset.createFromCanonicalForm(json['asset']),
      json['amount'],
      json['sponsor'],
      convertInt(json['last_modified_ledger']),
      json['last_modified_time'],
      json['claimants'] != null
          ? List<ClaimantResponse?>.from(
              json['claimants'].map((e) => e == null ? null : ClaimantResponse.fromJson(e)))
          : null,
      json['_links'] == null ? null : ClaimableBalanceResponseLinks.fromJson(json['_links']));
}

class ClaimantResponse extends Response {
  String destination;
  ClaimantPredicateResponse predicate;

  ClaimantResponse(this.destination, this.predicate);

  factory ClaimantResponse.fromJson(Map<String, dynamic> json) =>
      ClaimantResponse(json['destination'], ClaimantPredicateResponse.fromJson(json['predicate']));
}

class ClaimantPredicateResponse extends Response {
  bool? unconditional;
  List<ClaimantPredicateResponse?>? and;
  List<ClaimantPredicateResponse?>? or;
  ClaimantPredicateResponse? not;
  String? beforeAbsoluteTime;
  String? beforeRelativeTime;

  ClaimantPredicateResponse(this.unconditional, this.and, this.or, this.not,
      this.beforeAbsoluteTime, this.beforeRelativeTime);

  factory ClaimantPredicateResponse.fromJson(Map<String, dynamic> json) =>
      ClaimantPredicateResponse(
          json['unconditional'],
          json['and'] != null
              ? List<ClaimantPredicateResponse?>.from(
                  json['and'].map((e) => e == null ? null : ClaimantPredicateResponse.fromJson(e)))
              : null,
          json['or'] != null
              ? List<ClaimantPredicateResponse?>.from(
                  json['or'].map((e) => e == null ? null : ClaimantPredicateResponse.fromJson(e)))
              : null,
          json['not'] == null ? null : ClaimantPredicateResponse.fromJson(json['not']),
          json['abs_before'] == null ? json['absBefore'] : json['abs_before'],
          json['rel_before'] == null ? json['relBefore'] : json['rel_before']);
}

/// Links from the claimable balance response.
class ClaimableBalanceResponseLinks {
  Link? self;

  ClaimableBalanceResponseLinks(this.self);

  factory ClaimableBalanceResponseLinks.fromJson(Map<String, dynamic> json) {
    return ClaimableBalanceResponseLinks(json['self'] == null ? null : Link.fromJson(json['self']));
  }
}
