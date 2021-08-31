// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../response.dart';

/// Represents signer effects abstract opbject.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
abstract class SignerEffectResponse extends EffectResponse {
  int? weight;
  String? publicKey;

  SignerEffectResponse(this.weight, this.publicKey);
}

/// Represents signer_created effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class SignerCreatedEffectResponse extends SignerEffectResponse {
  SignerCreatedEffectResponse(int? weight, String publicKey) : super(weight, publicKey);

  factory SignerCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SignerCreatedEffectResponse(convertInt(json['weight']), json['public_key'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents signer_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class SignerRemovedEffectResponse extends SignerEffectResponse {
  SignerRemovedEffectResponse(int? weight, String publicKey) : super(weight, publicKey);

  factory SignerRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SignerRemovedEffectResponse(convertInt(json['weight']), json['public_key'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents signed_updated effect response.
///  See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class SignerUpdatedEffectResponse extends SignerEffectResponse {
  SignerUpdatedEffectResponse(int? weight, String publicKey) : super(weight, publicKey);

  factory SignerUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SignerUpdatedEffectResponse(convertInt(json['weight']), json['public_key'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}
