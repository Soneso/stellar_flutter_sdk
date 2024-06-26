// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';

/// Effect Contract Credited occurs when a contract receives some
/// currency from SAC events involving transfers, mints, and burns.
class ContractCreditedEffectResponse extends EffectResponse {
  String contract;
  String amount;
  String assetType;
  String? assetCode;
  String? assetIssuer;

  ContractCreditedEffectResponse(
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links,
      this.contract,
      this.amount,
      this.assetType,
      {this.assetCode,
        this.assetIssuer});

  factory ContractCreditedEffectResponse.fromJson(Map<String, dynamic> json) =>
      ContractCreditedEffectResponse(
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']),
          json['contract'],
          json['amount'],
          json['asset_type'],
          assetCode: json['asset_code'],
          assetIssuer: json['asset_issuer'])
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Effect Contract Debited occurs when a contract sends some currency
/// from SAC events involving transfers, mints, and burns.
class ContractDebitedEffectResponse extends EffectResponse {
  String contract;
  String amount;
  String assetType;
  String? assetCode;
  String? assetIssuer;

  ContractDebitedEffectResponse(
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links,
      this.contract,
      this.amount,
      this.assetType,
      {this.assetCode,
        this.assetIssuer});

  factory ContractDebitedEffectResponse.fromJson(Map<String, dynamic> json) =>
      ContractDebitedEffectResponse(
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']),
          json['contract'],
          json['amount'],
          json['asset_type'],
          assetCode: json['asset_code'],
          assetIssuer: json['asset_issuer'])
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}