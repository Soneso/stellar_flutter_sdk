// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';

/// Represents an account sponsorship created effect response from Horizon.
///
/// This effect occurs when an account's base reserve requirement is sponsored by another account.
/// Sponsorships help reduce the entry barrier by allowing sponsors to pay reserves for other accounts.
///
/// Triggered by: BeginSponsoringFutureReservesOperation followed by CreateAccountOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('sponsored_account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountSponsorshipCreatedEffectResponse) {
///     print('Account sponsored by: ${effect.sponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [AccountSponsorshipRemovedEffectResponse] for sponsorship removal
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class AccountSponsorshipCreatedEffectResponse extends EffectResponse {
  /// The account ID of the sponsor
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

/// Represents an account sponsorship updated effect response from Horizon.
///
/// This effect occurs when the sponsor of an account's base reserve changes from one
/// account to another. The new sponsor assumes responsibility for the reserve requirement.
///
/// Triggered by: BeginSponsoringFutureReservesOperation with RevokeSponsorship
/// Returned by: Horizon API effects endpoint when querying for sponsorship update effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('sponsored_account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountSponsorshipUpdatedEffectResponse) {
///     print('Sponsor changed from ${effect.formerSponsor} to ${effect.newSponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [RevokeSponsorshipOperation] for changing sponsorships
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class AccountSponsorshipUpdatedEffectResponse extends EffectResponse {
  /// The account ID of the new sponsor
  String newSponsor;

  /// The account ID of the former sponsor
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

/// Represents an account sponsorship removed effect response from Horizon.
///
/// This effect occurs when sponsorship of an account's base reserve is removed.
/// The account must then maintain its own reserve requirement.
///
/// Triggered by: RevokeSponsorshipOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship removal effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is AccountSponsorshipRemovedEffectResponse) {
///     print('Sponsorship removed, former sponsor: ${effect.formerSponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [RevokeSponsorshipOperation] for removing sponsorships
/// - [AccountSponsorshipCreatedEffectResponse] for sponsorship creation
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class AccountSponsorshipRemovedEffectResponse extends EffectResponse {
  /// The account ID of the former sponsor
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

/// Represents a trustline sponsorship created effect response from Horizon.
///
/// This effect occurs when a trustline's reserve requirement is sponsored by another account.
/// The sponsor pays the reserve for maintaining the trustline on the ledger.
///
/// Triggered by: BeginSponsoringFutureReservesOperation followed by ChangeTrustOperation
/// Returned by: Horizon API effects endpoint when querying for trustline sponsorship effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustlineSponsorshipCreatedEffectResponse) {
///     print('Trustline sponsored by: ${effect.sponsor}');
///     print('Asset: ${effect.asset ?? "Pool ${effect.liquidityPoolId}"}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [ChangeTrustOperation] for creating trustlines
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class TrustlineSponsorshipCreatedEffectResponse extends EffectResponse {
  /// The account ID of the sponsor
  String sponsor;

  /// The canonical asset string (e.g., 'USD:ISSUER...'), null for pool shares
  String? asset;

  /// The type of asset being trusted ('credit_alphanum4', 'credit_alphanum12', or 'liquidity_pool_shares')
  String assetType;

  /// Liquidity pool ID if the trustline is for pool shares
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

/// Represents a trustline sponsorship updated effect response from Horizon.
///
/// This effect occurs when the sponsor of a trustline's reserve changes from one
/// account to another.
///
/// Triggered by: BeginSponsoringFutureReservesOperation with RevokeSponsorshipOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship update effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustlineSponsorshipUpdatedEffectResponse) {
///     print('Trustline sponsor changed from ${effect.formerSponsor} to ${effect.newSponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [RevokeSponsorshipOperation] for changing sponsorships
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class TrustlineSponsorshipUpdatedEffectResponse extends EffectResponse {
  /// The account ID of the new sponsor
  String newSponsor;

  /// The account ID of the former sponsor
  String formerSponsor;

  /// The canonical asset string, null for pool shares
  String? asset;

  /// The type of asset being trusted
  String assetType;

  /// Liquidity pool ID if the trustline is for pool shares
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

/// Represents a trustline sponsorship removed effect response from Horizon.
///
/// This effect occurs when sponsorship of a trustline's reserve is removed.
/// The account must then pay for its own trustline reserve.
///
/// Triggered by: RevokeSponsorshipOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship removal effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is TrustlineSponsorshipRemovedEffectResponse) {
///     print('Trustline sponsorship removed, former sponsor: ${effect.formerSponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [RevokeSponsorshipOperation] for removing sponsorships
/// - [TrustlineSponsorshipCreatedEffectResponse] for sponsorship creation
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class TrustlineSponsorshipRemovedEffectResponse extends EffectResponse {
  /// The account ID of the former sponsor
  String formerSponsor;

  /// The canonical asset string, null for pool shares
  String? asset;

  /// The type of asset being trusted
  String assetType;

  /// Liquidity pool ID if the trustline is for pool shares
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

/// Represents a data entry sponsorship created effect response from Horizon.
///
/// This effect occurs when a data entry's reserve requirement is sponsored by another account.
/// The sponsor pays the reserve for maintaining the data entry on the ledger.
///
/// Triggered by: BeginSponsoringFutureReservesOperation followed by ManageDataOperation
/// Returned by: Horizon API effects endpoint when querying for data sponsorship effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is DataSponsorshipCreatedEffectResponse) {
///     print('Data entry ${effect.dataName} sponsored by: ${effect.sponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [ManageDataOperation] for creating data entries
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class DataSponsorshipCreatedEffectResponse extends EffectResponse {
  /// The name (key) of the sponsored data entry
  String dataName;

  /// The account ID of the sponsor
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

/// Represents a data entry sponsorship updated effect response from Horizon.
///
/// This effect occurs when the sponsor of a data entry's reserve changes.
///
/// Triggered by: BeginSponsoringFutureReservesOperation with RevokeSponsorshipOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship update effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is DataSponsorshipUpdatedEffectResponse) {
///     print('Data entry ${effect.dataName} sponsor changed to: ${effect.newSponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [RevokeSponsorshipOperation] for changing sponsorships
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class DataSponsorshipUpdatedEffectResponse extends EffectResponse {
  /// The name (key) of the data entry
  String dataName;

  /// The account ID of the new sponsor
  String newSponsor;

  /// The account ID of the former sponsor
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

/// Represents a data entry sponsorship removed effect response from Horizon.
///
/// This effect occurs when sponsorship of a data entry's reserve is removed.
///
/// Triggered by: RevokeSponsorshipOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship removal effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is DataSponsorshipRemovedEffectResponse) {
///     print('Data entry ${effect.dataName} sponsorship removed');
///   }
/// }
/// ```
///
/// See also:
/// - [RevokeSponsorshipOperation] for removing sponsorships
/// - [DataSponsorshipCreatedEffectResponse] for sponsorship creation
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class DataSponsorshipRemovedEffectResponse extends EffectResponse {
  /// The name (key) of the data entry
  String dataName;

  /// The account ID of the former sponsor
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

/// Represents a claimable balance sponsorship created effect response from Horizon.
///
/// This effect occurs when a claimable balance's reserve requirement is sponsored.
/// The sponsor pays the reserve for maintaining the claimable balance on the ledger.
///
/// Triggered by: BeginSponsoringFutureReservesOperation followed by CreateClaimableBalanceOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is ClaimableBalanceSponsorshipCreatedEffectResponse) {
///     print('Claimable balance ${effect.balanceId} sponsored by: ${effect.sponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [CreateClaimableBalanceOperation] for creating claimable balances
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class ClaimableBalanceSponsorshipCreatedEffectResponse extends EffectResponse {
  /// The account ID of the sponsor
  String sponsor;

  /// The unique ID of the sponsored claimable balance
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

/// Represents a claimable balance sponsorship updated effect response from Horizon.
///
/// This effect occurs when the sponsor of a claimable balance's reserve changes.
///
/// Triggered by: BeginSponsoringFutureReservesOperation with RevokeSponsorshipOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship update effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is ClaimableBalanceSponsorshipUpdatedEffectResponse) {
///     print('Claimable balance ${effect.balanceId} sponsor changed to: ${effect.newSponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [RevokeSponsorshipOperation] for changing sponsorships
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class ClaimableBalanceSponsorshipUpdatedEffectResponse extends EffectResponse {
  /// The account ID of the new sponsor
  String newSponsor;

  /// The account ID of the former sponsor
  String formerSponsor;

  /// The unique ID of the claimable balance
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

/// Represents a claimable balance sponsorship removed effect response from Horizon.
///
/// This effect occurs when sponsorship of a claimable balance's reserve is removed.
///
/// Triggered by: RevokeSponsorshipOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship removal effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is ClaimableBalanceSponsorshipRemovedEffectResponse) {
///     print('Claimable balance ${effect.balanceId} sponsorship removed');
///   }
/// }
/// ```
///
/// See also:
/// - [RevokeSponsorshipOperation] for removing sponsorships
/// - [ClaimableBalanceSponsorshipCreatedEffectResponse] for sponsorship creation
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class ClaimableBalanceSponsorshipRemovedEffectResponse extends EffectResponse {
  /// The account ID of the former sponsor
  String formerSponsor;

  /// The unique ID of the claimable balance
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

/// Represents a signer sponsorship created effect response from Horizon.
///
/// This effect occurs when a signer's reserve requirement is sponsored by another account.
/// The sponsor pays the reserve for maintaining the signer on the account.
///
/// Triggered by: BeginSponsoringFutureReservesOperation followed by SetOptionsOperation adding a signer
/// Returned by: Horizon API effects endpoint when querying for sponsorship effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is SignerSponsorshipCreatedEffectResponse) {
///     print('Signer ${effect.signer} sponsored by: ${effect.sponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [SetOptionsOperation] for adding signers
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class SignerSponsorshipCreatedEffectResponse extends EffectResponse {
  /// The public key of the sponsored signer
  String signer;

  /// The account ID of the sponsor
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

/// Represents a signer sponsorship updated effect response from Horizon.
///
/// This effect occurs when the sponsor of a signer's reserve changes from one account to another.
///
/// Triggered by: BeginSponsoringFutureReservesOperation with RevokeSponsorshipOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship update effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is SignerSponsorshipUpdatedEffectResponse) {
///     print('Signer ${effect.signer} sponsor changed to: ${effect.newSponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for sponsoring reserves
/// - [RevokeSponsorshipOperation] for changing sponsorships
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class SignerSponsorshipUpdatedEffectResponse extends EffectResponse {
  /// The public key of the signer
  String signer;

  /// The account ID of the new sponsor
  String newSponsor;

  /// The account ID of the former sponsor
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

/// Represents a signer sponsorship removed effect response from Horizon.
///
/// This effect occurs when sponsorship of a signer's reserve is removed.
/// The account must then pay for its own signer reserve.
///
/// Triggered by: RevokeSponsorshipOperation
/// Returned by: Horizon API effects endpoint when querying for sponsorship removal effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is SignerSponsorshipRemovedEffectResponse) {
///     print('Signer ${effect.signer} sponsorship removed');
///   }
/// }
/// ```
///
/// See also:
/// - [RevokeSponsorshipOperation] for removing sponsorships
/// - [SignerSponsorshipCreatedEffectResponse] for sponsorship creation
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class SignerSponsorshipRemovedEffectResponse extends EffectResponse {
  /// The public key of the signer
  String signer;

  /// The account ID of the former sponsor
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
