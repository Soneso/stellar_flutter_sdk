// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';

/// Effect Account Sponsorship Created occurs when an account ledger entry is sponsored.
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects" target="_blank">Effects</a>.
class AccountSponsorshipCreatedEffectResponse extends EffectResponse {
  String sponsor;

  AccountSponsorshipCreatedEffectResponse(
      this.sponsor,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory AccountSponsorshipCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      AccountSponsorshipCreatedEffectResponse(
          json['sponsor'],
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

/// Effect Account Sponsorship Updated occurs when the sponsoring of an account ledger entry is updated.
class AccountSponsorshipUpdatedEffectResponse extends EffectResponse {
  String newSponsor;
  String formerSponsor;

  AccountSponsorshipUpdatedEffectResponse(
      this.newSponsor,
      this.formerSponsor,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory AccountSponsorshipUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      AccountSponsorshipUpdatedEffectResponse(
          json['new_sponsor'],
          json['former_sponsor'],
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

/// Effect Account Sponsorship Removed occurs when the sponsorship of an account ledger entry is removed.
class AccountSponsorshipRemovedEffectResponse extends EffectResponse {
  String formerSponsor;

  AccountSponsorshipRemovedEffectResponse(
      this.formerSponsor,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory AccountSponsorshipRemovedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      AccountSponsorshipRemovedEffectResponse(
          json['former_sponsor'],
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

/// Effect Trustline Sponsorship Created occurs when a trustline ledger entry is sponsored.
class TrustlineSponsorshipCreatedEffectResponse extends EffectResponse {
  String sponsor;
  String? asset;
  String assetType;
  String? liquidityPoolId;

  TrustlineSponsorshipCreatedEffectResponse(
      this.sponsor,
      this.asset,
      this.assetType,
      this.liquidityPoolId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustlineSponsorshipCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustlineSponsorshipCreatedEffectResponse(
          json['sponsor'],
          json['asset'],
          json['asset_type'],
          json['liquidity_pool_id'],
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

/// Effect Trustline Sponsorship Updated occurs when the sponsoring of a trustline ledger entry is updated.
class TrustlineSponsorshipUpdatedEffectResponse extends EffectResponse {
  String newSponsor;
  String formerSponsor;
  String? asset;
  String assetType;
  String? liquidityPoolId;

  TrustlineSponsorshipUpdatedEffectResponse(
      this.newSponsor,
      this.formerSponsor,
      this.asset,
      this.assetType,
      this.liquidityPoolId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustlineSponsorshipUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustlineSponsorshipUpdatedEffectResponse(
          json['new_sponsor'],
          json['former_sponsor'],
          json['asset'],
          json['asset_type'],
          json['liquidity_pool_id'],
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

/// Effect Trustline Sponsorship Removed occurs when the sponsorship of a trustline ledger entry is removed.
class TrustlineSponsorshipRemovedEffectResponse extends EffectResponse {
  String formerSponsor;
  String? asset;
  String assetType;
  String? liquidityPoolId;

  TrustlineSponsorshipRemovedEffectResponse(
      this.formerSponsor,
      this.asset,
      this.assetType,
      this.liquidityPoolId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory TrustlineSponsorshipRemovedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      TrustlineSponsorshipRemovedEffectResponse(
          json['former_sponsor'],
          json['asset'],
          json['asset_type'],
          json['liquidity_pool_id'],
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

/// Effect Data Sponsorship Created occurs when a trustline ledger entry is sponsored.
class DataSponsorshipCreatedEffectResponse extends EffectResponse {
  String dataName;
  String sponsor;

  DataSponsorshipCreatedEffectResponse(
      this.dataName,
      this.sponsor,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory DataSponsorshipCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      DataSponsorshipCreatedEffectResponse(
          json['data_name'],
          json['sponsor'],
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

/// Effect Data Sponsorship Updated occurs when the sponsoring of a trustline ledger entry is updated.
class DataSponsorshipUpdatedEffectResponse extends EffectResponse {
  String dataName;
  String newSponsor;
  String formerSponsor;

  DataSponsorshipUpdatedEffectResponse(
      this.dataName,
      this.newSponsor,
      this.formerSponsor,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory DataSponsorshipUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      DataSponsorshipUpdatedEffectResponse(
          json['data_name'],
          json['new_sponsor'],
          json['former_sponsor'],
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

/// Effect Data Sponsorship Removed occurs when the sponsorship of a trustline ledger entry is removed.
class DataSponsorshipRemovedEffectResponse extends EffectResponse {
  String dataName;
  String formerSponsor;

  DataSponsorshipRemovedEffectResponse(
      this.dataName,
      this.formerSponsor,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory DataSponsorshipRemovedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      DataSponsorshipRemovedEffectResponse(
          json['data_name'],
          json['former_sponsor'],
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

/// Effect Claimable Balance Sponsorship Removed occurs when the sponsorship of a claimable balance ledger entry is removed
class ClaimableBalanceSponsorshipCreatedEffectResponse extends EffectResponse {
  String sponsor;
  String balanceId;

  ClaimableBalanceSponsorshipCreatedEffectResponse(
      this.sponsor,
      this.balanceId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory ClaimableBalanceSponsorshipCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      ClaimableBalanceSponsorshipCreatedEffectResponse(
          json['sponsor'],
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

/// Effect Claimable Balance Sponsorship Updated occurs when the sponsoring of a claimable balance ledger entry is updated.
class ClaimableBalanceSponsorshipUpdatedEffectResponse extends EffectResponse {
  String newSponsor;
  String formerSponsor;
  String balanceId;

  ClaimableBalanceSponsorshipUpdatedEffectResponse(
      this.newSponsor,
      this.formerSponsor,
      this.balanceId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory ClaimableBalanceSponsorshipUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      ClaimableBalanceSponsorshipUpdatedEffectResponse(
          json['new_sponsor'],
          json['former_sponsor'],
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

/// EffectClaimableBalanceSponsorshipRemoved occurs when the sponsorship of a claimable balance ledger entry is removed
class ClaimableBalanceSponsorshipRemovedEffectResponse extends EffectResponse {
  String formerSponsor;
  String balanceId;

  ClaimableBalanceSponsorshipRemovedEffectResponse(
      this.formerSponsor,
      this.balanceId,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory ClaimableBalanceSponsorshipRemovedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      ClaimableBalanceSponsorshipRemovedEffectResponse(
          json['former_sponsor'],
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

/// Effect Signer Sponsorship Created occurs when the sponsorship of a signer is created.
class SignerSponsorshipCreatedEffectResponse extends EffectResponse {
  String signer;
  String sponsor;

  SignerSponsorshipCreatedEffectResponse(
      this.signer,
      this.sponsor,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory SignerSponsorshipCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      SignerSponsorshipCreatedEffectResponse(
          json['signer'],
          json['sponsor'],
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

/// Effect Signer Sponsorship Updated occurs when the sponsorship of a signer is updated.
class SignerSponsorshipUpdatedEffectResponse extends EffectResponse {
  String signer;
  String newSponsor;
  String formerSponsor;

  SignerSponsorshipUpdatedEffectResponse(
      this.signer,
      this.newSponsor,
      this.formerSponsor,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory SignerSponsorshipUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      SignerSponsorshipUpdatedEffectResponse(
          json['signer'],
          json['new_sponsor'],
          json['former_sponsor'],
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

/// Effect Signer Sponsorship Removed occurs when the sponsorship of a signer is removed.
class SignerSponsorshipRemovedEffectResponse extends EffectResponse {
  String signer;
  String formerSponsor;

  SignerSponsorshipRemovedEffectResponse(
      this.signer,
      this.formerSponsor,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory SignerSponsorshipRemovedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      SignerSponsorshipRemovedEffectResponse(
          json['signer'],
          json['former_sponsor'],
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
