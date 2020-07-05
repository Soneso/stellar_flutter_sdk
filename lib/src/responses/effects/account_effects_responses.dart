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
      new AccountCreatedEffectResponse(json['starting_balance'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents account_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountRemovedEffectResponse extends EffectResponse {
  AccountRemovedEffectResponse();

  factory AccountRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new AccountRemovedEffectResponse()
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents account_credited effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountCreditedEffectResponse extends EffectResponse {
  String amount;
  String assetType;
  String assetCode;
  String assetIssuer;

  AccountCreditedEffectResponse(
      this.amount, this.assetType, this.assetCode, this.assetIssuer);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }

  factory AccountCreditedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new AccountCreditedEffectResponse(
          json['amount'] as String,
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents account_debited effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountDebitedEffectResponse extends EffectResponse {
  String amount;
  String assetType;
  String assetCode;
  String assetIssuer;

  AccountDebitedEffectResponse(
      this.amount, this.assetType, this.assetCode, this.assetIssuer);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }

  factory AccountDebitedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new AccountDebitedEffectResponse(
          json['amount'] as String,
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents account_thresholds_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountThresholdsUpdatedEffectResponse extends EffectResponse {
  int lowThreshold;
  int medThreshold;
  int highThreshold;

  AccountThresholdsUpdatedEffectResponse(
      this.lowThreshold, this.medThreshold, this.highThreshold);

  factory AccountThresholdsUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      new AccountThresholdsUpdatedEffectResponse(
          convertInt(json['low_threshold']),
          convertInt(json['med_threshold']),
          convertInt(json['high_threshold']))
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents account_home_domain_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountHomeDomainUpdatedEffectResponse extends EffectResponse {
  String homeDomain;

  AccountHomeDomainUpdatedEffectResponse(this.homeDomain);

  factory AccountHomeDomainUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      new AccountHomeDomainUpdatedEffectResponse(json['home_domain'] as String)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents account_flags_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountFlagsUpdatedEffectResponse extends EffectResponse {
  bool authRequiredFlag;
  bool authRevokableFlag;

  AccountFlagsUpdatedEffectResponse(
      this.authRequiredFlag, this.authRevokableFlag);

  factory AccountFlagsUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      new AccountFlagsUpdatedEffectResponse(json['auth_required_flag'] as bool,
          json['auth_revokable_flag'] as bool)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Represents account_inflation_destination_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class AccountInflationDestinationUpdatedEffectResponse extends EffectResponse {
  AccountInflationDestinationUpdatedEffectResponse();

  factory AccountInflationDestinationUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      new AccountInflationDestinationUpdatedEffectResponse()
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}
