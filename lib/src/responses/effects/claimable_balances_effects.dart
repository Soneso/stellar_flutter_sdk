// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../claimable_balance_response.dart';

/// Represents a claimable balance created effect response from Horizon.
///
/// This effect occurs when an account creates a claimable balance that can be claimed
/// by one or more designated claimants. Claimable balances allow for conditional payments
/// and escrow-like functionality.
///
/// Triggered by: CreateClaimableBalanceOperation
/// Returned by: Horizon API effects endpoint when querying for claimable balance creation effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is ClaimableBalanceCreatedEffectResponse) {
///     print('Claimable balance created: ${effect.amount} ${effect.asset.code}');
///     print('Balance ID: ${effect.balanceId}');
///   }
/// }
/// ```
///
/// See also:
/// - [CreateClaimableBalanceOperation] for creating claimable balances
/// - [ClaimableBalanceClaimedEffectResponse] for claiming balances
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class ClaimableBalanceCreatedEffectResponse extends EffectResponse {
  /// The unique ID of the claimable balance
  String balanceId;

  /// The asset type and code of the claimable balance
  Asset asset;

  /// The amount of the asset in the claimable balance
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

/// Represents a claimable balance claimant created effect response from Horizon.
///
/// This effect occurs for each designated claimant when a claimable balance is created.
/// The claimant is authorized to claim the balance if the associated predicate conditions are met.
///
/// Triggered by: CreateClaimableBalanceOperation
/// Returned by: Horizon API effects endpoint when querying for claimant creation effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('claimant_account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is ClaimableBalanceClaimantCreatedEffectResponse) {
///     print('Can claim: ${effect.amount} ${effect.asset.code}');
///     print('Balance ID: ${effect.balanceId}');
///   }
/// }
/// ```
///
/// See also:
/// - [CreateClaimableBalanceOperation] for creating claimable balances
/// - [ClaimableBalanceClaimedEffectResponse] for claiming balances
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class ClaimableBalanceClaimantCreatedEffectResponse extends EffectResponse {
  /// The unique ID of the claimable balance
  String balanceId;

  /// The asset type and code of the claimable balance
  Asset asset;

  /// The amount of the asset in the claimable balance
  String amount;

  /// The predicate conditions that must be met to claim the balance
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

/// Represents a claimable balance claimed effect response from Horizon.
///
/// This effect occurs when an authorized claimant successfully claims a claimable balance.
/// The claimed amount is transferred to the claimant's account and the claimable balance is removed.
///
/// Triggered by: ClaimClaimableBalanceOperation
/// Returned by: Horizon API effects endpoint when querying for balance claim effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is ClaimableBalanceClaimedEffectResponse) {
///     print('Claimed: ${effect.amount} ${effect.asset.code}');
///     print('Balance ID: ${effect.balanceId}');
///   }
/// }
/// ```
///
/// See also:
/// - [ClaimClaimableBalanceOperation] for claiming balances
/// - [ClaimableBalanceCreatedEffectResponse] for balance creation
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class ClaimableBalanceClaimedEffectResponse extends EffectResponse {
  /// The unique ID of the claimed claimable balance
  String balanceId;

  /// The asset type and code of the claimed balance
  Asset asset;

  /// The amount claimed
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

/// Represents a claimable balance clawed back effect response from Horizon.
///
/// This effect occurs when an asset issuer claws back a claimable balance.
/// The issuer must have the CLAWBACK_ENABLED flag set to perform this operation.
///
/// Triggered by: ClawbackClaimableBalanceOperation
/// Returned by: Horizon API effects endpoint when querying for clawback effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('issuer_account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is ClaimableBalanceClawedBackEffectResponse) {
///     print('Claimable balance clawed back: ${effect.balanceId}');
///   }
/// }
/// ```
///
/// See also:
/// - [ClawbackClaimableBalanceOperation] for clawing back claimable balances
/// - [ClaimableBalanceCreatedEffectResponse] for balance creation
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class ClaimableBalanceClawedBackEffectResponse extends EffectResponse {
  /// The unique ID of the clawed back claimable balance
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
