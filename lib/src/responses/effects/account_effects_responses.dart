// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../response.dart';

/// Account created effects occur when a new account is created
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects" target="_blank">Effects</a>.
class AccountCreatedEffectResponse extends EffectResponse {
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

/// Account removed effects occur when one account is merged into another.
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects" target="_blank">Effects</a>.
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

/// Account credited effects occur when an account receives some currency.
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects" target="_blank">Effects</a>.
class AccountCreditedEffectResponse extends EffectResponse {
  String amount;
  String assetType;
  String? assetCode;
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

/// Account debited effects occur when an account sends some currency.
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects" target="_blank">Effects</a>.
class AccountDebitedEffectResponse extends EffectResponse {
  String amount;
  String assetType;
  String? assetCode;
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
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects" target="_blank">Effects</a>.
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
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects" target="_blank">Effects</a>.
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
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects" target="_blank">Effects</a>.
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
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects" target="_blank">Effects</a>.
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
