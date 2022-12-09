// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../claimable_balance_response.dart';

/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class ClaimableBalanceCreatedEffectResponse extends EffectResponse {
  String? balanceId;
  Asset? asset;
  String? amount;

  ClaimableBalanceCreatedEffectResponse(this.balanceId, this.asset, this.amount);

  factory ClaimableBalanceCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      ClaimableBalanceCreatedEffectResponse(
          json['balance_id'],
          json['asset'] == null ? null : Asset.createFromCanonicalForm(json['asset']),
          json['amount'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class ClaimableBalanceClaimantCreatedEffectResponse extends EffectResponse {
  String? balanceId;
  Asset? asset;
  String? amount;
  ClaimantPredicateResponse? predicate;

  ClaimableBalanceClaimantCreatedEffectResponse(
      this.balanceId, this.asset, this.amount, this.predicate);

  factory ClaimableBalanceClaimantCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      ClaimableBalanceClaimantCreatedEffectResponse(
          json['balance_id'],
          json['asset'] == null ? null : Asset.createFromCanonicalForm(json['asset']),
          json['amount'],
          ClaimantPredicateResponse.fromJson(json['predicate']))
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class ClaimableBalanceClaimedEffectResponse extends EffectResponse {
  String? balanceId;
  Asset? asset;
  String? amount;

  ClaimableBalanceClaimedEffectResponse(this.balanceId, this.asset, this.amount);

  factory ClaimableBalanceClaimedEffectResponse.fromJson(Map<String, dynamic> json) =>
      ClaimableBalanceClaimedEffectResponse(
          json['balance_id'],
          json['asset'] == null ? null : Asset.createFromCanonicalForm(json['asset']),
          json['amount'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

class ClaimableBalanceClawedBackEffectResponse extends EffectResponse {
  String? balanceId;

  ClaimableBalanceClawedBackEffectResponse(this.balanceId);

  factory ClaimableBalanceClawedBackEffectResponse.fromJson(Map<String, dynamic> json) =>
      ClaimableBalanceClawedBackEffectResponse(json['balance_id'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}
