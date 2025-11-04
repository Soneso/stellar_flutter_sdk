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

/// Represents an account thresholds updated effect response from Horizon.
///
/// This effect occurs when an account changes its multi-signature thresholds via the
/// Set Options operation. Thresholds determine how much signing weight is required
/// for different operation types, enabling multi-signature authorization.
///
/// Thresholds categories:
/// - Low: Used for AllowTrust and BumpSequence operations
/// - Medium: Used for all other operations except SetOptions
/// - High: Used for SetOptions operations (changing account settings)
///
/// Each threshold value ranges from 0 to 255, where 0 means any signature works,
/// and higher values require more signing weight from account signers.
///
/// Triggered by: SetOptionsOperation
/// Returned by: Horizon API effects endpoint when querying for threshold changes
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountThresholdsUpdatedEffectResponse) {
///     print('Thresholds updated:');
///     print('  Low: ${effect.lowThreshold}');
///     print('  Medium: ${effect.medThreshold}');
///     print('  High: ${effect.highThreshold}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetOptionsOperation] for setting thresholds
/// - [Horizon Effects API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class AccountThresholdsUpdatedEffectResponse extends EffectResponse {
  /// Threshold for low security operations (AllowTrust, BumpSequence)
  int lowThreshold;

  /// Threshold for medium security operations (most operations)
  int medThreshold;

  /// Threshold for high security operations (SetOptions)
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

/// Represents an account home domain updated effect response from Horizon.
///
/// This effect occurs when an account sets or changes its home domain via the Set Options
/// operation. The home domain is used to establish a verifiable link between an account
/// and a domain name, typically pointing to where the account's stellar.toml file is hosted.
///
/// The home domain enables:
/// - Account verification and identity establishment
/// - Publishing metadata about assets and accounts
/// - Federation protocol support
/// - Trust establishment for asset issuers
///
/// Triggered by: SetOptionsOperation
/// Returned by: Horizon API effects endpoint when querying for home domain changes
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountHomeDomainUpdatedEffectResponse) {
///     print('Home domain set to: ${effect.homeDomain ?? "none"}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetOptionsOperation] for setting home domain
/// - [Horizon Effects API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class AccountHomeDomainUpdatedEffectResponse extends EffectResponse {
  /// The new home domain for the account, or null if cleared
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

/// Represents an account flags updated effect response from Horizon.
///
/// This effect occurs when an account changes its authorization flags via the Set Options
/// operation. Account flags control how the account's issued assets behave with respect
/// to authorization and revocation.
///
/// Available flags:
/// - AUTH_REQUIRED: If set, trustlines to this account's assets require explicit authorization
/// - AUTH_REVOCABLE: If set, this account can revoke authorization for its assets
/// - AUTH_IMMUTABLE: If set, none of the authorization flags can be changed (not tracked here)
///
/// These flags are primarily used by asset issuers to implement compliance requirements,
/// KYC/AML processes, or controlled distribution of assets.
///
/// Triggered by: SetOptionsOperation
/// Returned by: Horizon API effects endpoint when querying for flag changes
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('issuer_account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountFlagsUpdatedEffectResponse) {
///     print('Auth Required: ${effect.authRequiredFlag ?? "not set"}');
///     print('Auth Revocable: ${effect.authRevokableFlag ?? "not set"}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetOptionsOperation] for setting account flags
/// - [Horizon Effects API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class AccountFlagsUpdatedEffectResponse extends EffectResponse {
  /// Whether the AUTH_REQUIRED flag is set
  bool? authRequiredFlag;

  /// Whether the AUTH_REVOCABLE flag is set
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

/// Represents an account inflation destination updated effect response from Horizon.
///
/// DEPRECATED: The inflation mechanism was removed from the Stellar network in Protocol 12
/// (October 2019). This effect type remains for historical data compatibility but will not
/// appear in new transactions.
///
/// This effect occurred when an account set its inflation destination, which was the account
/// that would receive the account's share of the network's inflation pool. The inflation
/// mechanism was replaced by more efficient fee distribution methods.
///
/// Historical context:
/// - Inflation was a 1% annual increase in total lumens
/// - Accounts voted for inflation destinations by setting this field
/// - Inflation ran weekly and distributed to accounts with >0.05% of votes
///
/// Triggered by: SetOptionsOperation (historical, pre-Protocol 12)
/// Returned by: Horizon API only for historical effects before Protocol 12
///
/// Example:
/// ```dart
/// // This effect only appears in historical data
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountInflationDestinationUpdatedEffectResponse) {
///     print('Historical inflation destination change at ${effect.createdAt}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetOptionsOperation] for setting account options
/// - [Horizon Effects API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
@Deprecated('Inflation was removed in Protocol 12. This effect only appears in historical data.')
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
