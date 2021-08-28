// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../response.dart';

/// Represents an account_created effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountCreatedEffectResponse extends EffectResponse {
  String startingBalance;

  AccountCreatedEffectResponse(this.startingBalance);

  factory AccountCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountCreatedEffectResponse(json['starting_balance'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents account_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountRemovedEffectResponse extends EffectResponse {
  AccountRemovedEffectResponse();

  factory AccountRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountRemovedEffectResponse()
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents account_credited effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountCreditedEffectResponse extends EffectResponse {
  String amount;
  String assetType;
  String assetCode;
  String assetIssuer;

  AccountCreditedEffectResponse(this.amount, this.assetType, this.assetCode, this.assetIssuer);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }

  factory AccountCreditedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountCreditedEffectResponse(
          json['amount'], json['asset_type'], json['asset_code'], json['asset_issuer'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents account_debited effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountDebitedEffectResponse extends EffectResponse {
  String? amount;
  String? assetType;
  String? assetCode;
  String? assetIssuer;

  AccountDebitedEffectResponse(this.amount, this.assetType, this.assetCode, this.assetIssuer);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  factory AccountDebitedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountDebitedEffectResponse(
          json['amount'], json['asset_type'], json['asset_code'], json['asset_issuer'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents account_thresholds_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountThresholdsUpdatedEffectResponse extends EffectResponse {
  int? lowThreshold;
  int? medThreshold;
  int? highThreshold;

  AccountThresholdsUpdatedEffectResponse(this.lowThreshold, this.medThreshold, this.highThreshold);

  factory AccountThresholdsUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountThresholdsUpdatedEffectResponse(convertInt(json['low_threshold']),
          convertInt(json['med_threshold']), convertInt(json['high_threshold']))
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents account_home_domain_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountHomeDomainUpdatedEffectResponse extends EffectResponse {
  String homeDomain;

  AccountHomeDomainUpdatedEffectResponse(this.homeDomain);

  factory AccountHomeDomainUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountHomeDomainUpdatedEffectResponse(json['home_domain'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents account_flags_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountFlagsUpdatedEffectResponse extends EffectResponse {
  bool authRequiredFlag;
  bool authRevokableFlag;
  bool authClawbackEnabledFlag;

  AccountFlagsUpdatedEffectResponse(
      this.authRequiredFlag, this.authRevokableFlag, this.authClawbackEnabledFlag);

  factory AccountFlagsUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountFlagsUpdatedEffectResponse(json['auth_required_flag'], json['auth_revokable_flag'],
          json['auth_clawback_enabled_flag'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents account_inflation_destination_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountInflationDestinationUpdatedEffectResponse extends EffectResponse {
  AccountInflationDestinationUpdatedEffectResponse();

  factory AccountInflationDestinationUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      AccountInflationDestinationUpdatedEffectResponse()
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}
