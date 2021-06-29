// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../response.dart';

/// Represents sequence_bumped effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class SequenceBumpedEffectResponse extends EffectResponse {
  int newSequence;

  SequenceBumpedEffectResponse(this.newSequence);

  factory SequenceBumpedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new SequenceBumpedEffectResponse(convertInt(json['new_seq']))
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null
            ? null
            : json['account_muxed_id'] as String
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

class TrustLineFlagsUpdatedEffectResponse extends EffectResponse {
  String trustor;
  String assetType;
  String assetCode;
  String assetIssuer;
  bool authorizedFlag;
  bool authorizedToMaintainLiabilitiesFlag;
  bool clawbackEnabledFlag;

  TrustLineFlagsUpdatedEffectResponse(
      this.trustor,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.authorizedFlag,
      this.authorizedToMaintainLiabilitiesFlag,
      this.clawbackEnabledFlag);

  factory TrustLineFlagsUpdatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      new TrustLineFlagsUpdatedEffectResponse(
          json['trustor'] as String,
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String,
          json['authorized_flag'] == null
              ? null
              : json['authorized_flag'] as bool,
          json['authorized_to_maintain_liabilites_flag'] == null
              ? null
              : json['authorized_to_maintain_liabilites_flag'] as bool,
          json['clawback_enabled_flag'] == null
              ? null
              : json['clawback_enabled_flag'] as bool)
        ..id = json['id'] as String
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null
            ? null
            : json['account_muxed_id'] as String
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}
