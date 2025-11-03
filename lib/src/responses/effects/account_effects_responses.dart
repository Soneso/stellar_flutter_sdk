// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../response.dart';

/// Represents an account created effect from Horizon.
///
/// This effect occurs when a new account is created on the Stellar network via
/// the Create Account operation. The creating account must provide a starting
/// balance of at least the minimum reserve (currently 1 XLM).
///
/// Fields:
/// - [startingBalance]: The initial XLM balance provided to the new account
///
/// Triggered by: Create Account operation
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountCreatedEffectResponse) {
///     print('Account created with ${effect.startingBalance} XLM');
///   }
/// }
/// ```
///
/// See also:
/// - [Horizon Effects API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
/// - [CreateAccountOperation] for creating accounts
class AccountCreatedEffectResponse extends EffectResponse {
  /// The initial XLM balance provided to the new account
  String startingBalance;

  AccountCreatedEffectResponse(
      this.startingBalance,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory AccountCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountCreatedEffectResponse(
          json['starting_balance'],
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

/// Represents an account removed effect from Horizon.
///
/// This effect occurs when an account is merged into another account via the
/// Account Merge operation. The merging account is deleted and its remaining
/// XLM balance is transferred to the destination account.
///
/// Triggered by: Account Merge operation
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountRemovedEffectResponse) {
///     print('Account ${effect.account} was removed');
///   }
/// }
/// ```
///
/// See also:
/// - [Horizon Effects API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
/// - [AccountMergeOperation] for merging accounts
class AccountRemovedEffectResponse extends EffectResponse {
  AccountRemovedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links);

  factory AccountRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountRemovedEffectResponse(
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

/// Represents an account credited effect from Horizon.
///
/// This effect occurs when an account receives an asset. This can happen through
/// payments, path payments, account merges, or other operations that transfer assets.
///
/// Fields:
/// - [amount]: Amount credited (as string to preserve precision)
/// - [assetType]: Type of asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
/// - [assetCode]: Asset code (e.g., 'USD', 'EUR'), null for native XLM
/// - [assetIssuer]: Asset issuer account ID, null for native XLM
///
/// Triggered by: Payment, Path Payment, Account Merge, and other operations
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountCreditedEffectResponse) {
///     print('Credited: ${effect.amount} ${effect.assetCode ?? 'XLM'}');
///   }
/// }
/// ```
///
/// See also:
/// - [Horizon Effects API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
/// - [AccountDebitedEffectResponse] for the opposite effect
class AccountCreditedEffectResponse extends EffectResponse {
  /// Amount credited (as string to preserve precision)
  String amount;

  /// Type of asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String assetType;

  /// Asset code (e.g., 'USD', 'EUR'), null for native XLM
  String? assetCode;

  /// Asset issuer account ID, null for native XLM
  String? assetIssuer;

  AccountCreditedEffectResponse(
      this.amount,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  factory AccountCreditedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountCreditedEffectResponse(
          json['amount'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
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

/// Represents an account debited effect from Horizon.
///
/// This effect occurs when an account sends an asset. This can happen through
/// payments, path payments, offers, or other operations that transfer assets.
///
/// Fields:
/// - [amount]: Amount debited (as string to preserve precision)
/// - [assetType]: Type of asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
/// - [assetCode]: Asset code (e.g., 'USD', 'EUR'), null for native XLM
/// - [assetIssuer]: Asset issuer account ID, null for native XLM
///
/// Triggered by: Payment, Path Payment, Manage Offer, and other operations
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountDebitedEffectResponse) {
///     print('Debited: ${effect.amount} ${effect.assetCode ?? 'XLM'}');
///   }
/// }
/// ```
///
/// See also:
/// - [Horizon Effects API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
/// - [AccountCreditedEffectResponse] for the opposite effect
class AccountDebitedEffectResponse extends EffectResponse {
  /// Amount debited (as string to preserve precision)
  String amount;

  /// Type of asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String assetType;

  /// Asset code (e.g., 'USD', 'EUR'), null for native XLM
  String? assetCode;

  /// Asset issuer account ID, null for native XLM
  String? assetIssuer;

  AccountDebitedEffectResponse(
      this.amount,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  factory AccountDebitedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountDebitedEffectResponse(
          json['amount'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
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

/// Account Thresholds Updated effects occur when an account changes its multisig thresholds.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class AccountThresholdsUpdatedEffectResponse extends EffectResponse {
  int lowThreshold;
  int medThreshold;
  int highThreshold;

  AccountThresholdsUpdatedEffectResponse(
      this.lowThreshold,
      this.medThreshold,
      this.highThreshold,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory AccountThresholdsUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      AccountThresholdsUpdatedEffectResponse(
          convertInt(json['low_threshold'])!,
          convertInt(json['med_threshold'])!,
          convertInt(json['high_threshold'])!,
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

/// Account Home Domain Updated effects occur when an account changes its home domain.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class AccountHomeDomainUpdatedEffectResponse extends EffectResponse {
  String? homeDomain;

  AccountHomeDomainUpdatedEffectResponse(
      this.homeDomain,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory AccountHomeDomainUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      AccountHomeDomainUpdatedEffectResponse(
          json['home_domain'],
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

/// AccountFlagsUpdated effects occur when an account changes its account flags, either clearing or setting.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class AccountFlagsUpdatedEffectResponse extends EffectResponse {
  bool? authRequiredFlag;
  bool? authRevokableFlag;

  AccountFlagsUpdatedEffectResponse(
      this.authRequiredFlag,
      this.authRevokableFlag,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory AccountFlagsUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      AccountFlagsUpdatedEffectResponse(
          json['auth_required_flag'],
          json['auth_revokable_flag'],
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

/// Unused: Account Inflation Destination Updated effects occur when an account changes its inflation destination.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class AccountInflationDestinationUpdatedEffectResponse extends EffectResponse {
  AccountInflationDestinationUpdatedEffectResponse(
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory AccountInflationDestinationUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      AccountInflationDestinationUpdatedEffectResponse(
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
