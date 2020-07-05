// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../response.dart';

/// Represents signer effects abstract opbject.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
abstract class SignerEffectResponse extends EffectResponse {
  int weight;
  String publicKey;
  SignerEffectResponse(this.weight, this.publicKey);
}

/// Represents signer_created effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class SignerCreatedEffectResponse extends SignerEffectResponse {
  SignerCreatedEffectResponse(int weight, String publicKey)
      : super(weight, publicKey);
  factory SignerCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new SignerCreatedEffectResponse(
          convertInt(json['weight']), json['public_key'] as String)
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

/// Represents signer_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class SignerRemovedEffectResponse extends SignerEffectResponse {
  SignerRemovedEffectResponse(int weight, String publicKey)
      : super(weight, publicKey);
  factory SignerRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new SignerRemovedEffectResponse(
          convertInt(json['weight']), json['public_key'] as String)
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

/// Represents signed_updated effect response.
///  See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class SignerUpdatedEffectResponse extends SignerEffectResponse {
  SignerUpdatedEffectResponse(int weight, String publicKey)
      : super(weight, publicKey);
  factory SignerUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new SignerUpdatedEffectResponse(
          convertInt(json['weight']), json['public_key'] as String)
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
