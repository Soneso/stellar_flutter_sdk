// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../claimable_balance_response.dart';

/// Effect Claimable Balance Created occurs when a claimable balance is created.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class ClaimableBalanceCreatedEffectResponse extends EffectResponse {
  String balanceId;
  Asset asset;
  String amount;

  ClaimableBalanceCreatedEffectResponse(
      this.balanceId,
      this.asset,
      this.amount,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory ClaimableBalanceCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      ClaimableBalanceCreatedEffectResponse(
          json['balance_id'],
          Asset.createFromCanonicalForm(json['asset'])!,
          json['amount'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Effect Claimable Balance Claimant Created occurs when a claimable balance claimant is created.
class ClaimableBalanceClaimantCreatedEffectResponse extends EffectResponse {
  String balanceId;
  Asset asset;
  String amount;
  ClaimantPredicateResponse predicate;

  ClaimableBalanceClaimantCreatedEffectResponse(
      this.balanceId,
      this.asset,
      this.amount,
      this.predicate,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory ClaimableBalanceClaimantCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      ClaimableBalanceClaimantCreatedEffectResponse(
          json['balance_id'],
          Asset.createFromCanonicalForm(json['asset'])!,
          json['amount'],
          ClaimantPredicateResponse.fromJson(json['predicate']),
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Effect Claimable Balance Claimed occurs when a claimable balance is claimed.
class ClaimableBalanceClaimedEffectResponse extends EffectResponse {
  String balanceId;
  Asset asset;
  String amount;

  ClaimableBalanceClaimedEffectResponse(
      this.balanceId,
      this.asset,
      this.amount,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory ClaimableBalanceClaimedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      ClaimableBalanceClaimedEffectResponse(
          json['balance_id'],
          Asset.createFromCanonicalForm(json['asset'])!,
          json['amount'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Effect Claimable Balance Clawed Back occurs when a claimable balance is clawed back.
class ClaimableBalanceClawedBackEffectResponse extends EffectResponse {
  String balanceId;

  ClaimableBalanceClawedBackEffectResponse(
      this.balanceId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory ClaimableBalanceClawedBackEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      ClaimableBalanceClawedBackEffectResponse(
          json['balance_id'],
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}
