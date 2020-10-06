// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../claimable_balance_response.dart';

/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class ClaimableBalanceCreatedEffectResponse extends EffectResponse {
  String balanceId;
  Asset asset;
  String amount;

  ClaimableBalanceCreatedEffectResponse(
      this.balanceId, this.asset, this.amount);

  factory ClaimableBalanceCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      new ClaimableBalanceCreatedEffectResponse(
          json['balance_id'] as String,
          json['asset'] == null
              ? null
              : Asset.createFromCanonicalForm(json['asset'] as String),
          json['amount'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

class ClaimableBalanceClaimantCreatedEffectResponse extends EffectResponse {
  String balanceId;
  Asset asset;
  String amount;
  ClaimantPredicateResponse predicate;

  ClaimableBalanceClaimantCreatedEffectResponse(
      this.balanceId, this.asset, this.amount, this.predicate);

  factory ClaimableBalanceClaimantCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      new ClaimableBalanceClaimantCreatedEffectResponse(
          json['balance_id'] as String,
          json['asset'] == null
              ? null
              : Asset.createFromCanonicalForm(json['asset'] as String),
          json['amount'] as String,
          ClaimantPredicateResponse.fromJson(
              json['predicate'] as Map<String, dynamic>))
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

class ClaimableBalanceClaimedEffectResponse extends EffectResponse {
  String balanceId;
  Asset asset;
  String amount;

  ClaimableBalanceClaimedEffectResponse(
      this.balanceId, this.asset, this.amount);

  factory ClaimableBalanceClaimedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      new ClaimableBalanceClaimedEffectResponse(
          json['balance_id'] as String,
          json['asset'] == null
              ? null
              : Asset.createFromCanonicalForm(json['asset'] as String),
          json['amount'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}
