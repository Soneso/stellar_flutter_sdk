// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../response.dart';

/// Represents signer effects abstract object.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
abstract class SignerEffectResponse extends EffectResponse {
  int weight;
  String publicKey;
  String key;

  SignerEffectResponse(
      this.weight,
      this.publicKey,
      this.key,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);
}

/// Effect Signer Created occurs when an account gains a signer.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class SignerCreatedEffectResponse extends SignerEffectResponse {
  SignerCreatedEffectResponse(
      super.weight,
      super.publicKey,
      super.key,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory SignerCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SignerCreatedEffectResponse(
          convertInt(json['weight'])!,
          json['public_key'],
          json['key'],
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

/// Effect Signer Removed occurs when an account loses a signer.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class SignerRemovedEffectResponse extends SignerEffectResponse {
  SignerRemovedEffectResponse(
      super.weight,
      super.publicKey,
      super.key,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory SignerRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SignerRemovedEffectResponse(
          convertInt(json['weight'])!,
          json['public_key'],
          json['key'],
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

/// EffectSignerUpdated occurs when an account changes the weight of one of its signers.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class SignerUpdatedEffectResponse extends SignerEffectResponse {
  SignerUpdatedEffectResponse(
      super.weight,
      super.publicKey,
      super.key,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory SignerUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SignerUpdatedEffectResponse(
          convertInt(json['weight'])!,
          json['public_key'],
          json['key'],
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
