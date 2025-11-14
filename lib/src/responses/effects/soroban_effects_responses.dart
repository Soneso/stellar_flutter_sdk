// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';

/// Represents a contract credited effect response from Horizon.
///
/// This effect occurs when a Soroban smart contract receives assets through Stellar Asset Contract (SAC)
/// operations such as transfers, mints, or burns. SAC provides a standardized interface for interacting
/// with Stellar assets from within Soroban smart contracts.
///
/// Triggered by: InvokeHostFunctionOperation calling SAC transfer, mint, or burn functions
/// Returned by: Horizon API effects endpoint when querying for contract credit effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('contract_id').execute();
/// for (var effect in effects.records) {
///   if (effect is ContractCreditedEffectResponse) {
///     print('Contract ${effect.contract} received ${effect.amount} ${effect.assetCode ?? "XLM"}');
///   }
/// }
/// ```
///
/// See also:
/// - [InvokeHostFunctionOperation] for invoking Soroban contracts
/// - [ContractDebitedEffectResponse] for the opposite effect
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class ContractCreditedEffectResponse extends EffectResponse {
  /// The contract ID that received the assets
  String contract;

  /// The amount credited to the contract
  String amount;

  /// The type of asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String assetType;

  /// Asset code (e.g., 'USD', 'EUR'), null for native XLM
  String? assetCode;

  /// Asset issuer account ID, null for native XLM
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

/// Represents a contract debited effect response from Horizon.
///
/// This effect occurs when a Soroban smart contract sends assets through Stellar Asset Contract (SAC)
/// operations such as transfers, mints, or burns. SAC provides a standardized interface for interacting
/// with Stellar assets from within Soroban smart contracts.
///
/// Triggered by: InvokeHostFunctionOperation calling SAC transfer, mint, or burn functions
/// Returned by: Horizon API effects endpoint when querying for contract debit effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('contract_id').execute();
/// for (var effect in effects.records) {
///   if (effect is ContractDebitedEffectResponse) {
///     print('Contract ${effect.contract} sent ${effect.amount} ${effect.assetCode ?? "XLM"}');
///   }
/// }
/// ```
///
/// See also:
/// - [InvokeHostFunctionOperation] for invoking Soroban contracts
/// - [ContractCreditedEffectResponse] for the opposite effect
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class ContractDebitedEffectResponse extends EffectResponse {
  /// The contract ID that sent the assets
  String contract;

  /// The amount debited from the contract
  String amount;

  /// The type of asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String assetType;

  /// Asset code (e.g., 'USD', 'EUR'), null for native XLM
  String? assetCode;

  /// Asset issuer account ID, null for native XLM
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