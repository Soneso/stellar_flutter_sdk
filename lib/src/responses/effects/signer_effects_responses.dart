// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../response.dart';

/// Base class for signer-related effect responses from Horizon.
///
/// Represents effects that occur when signers are added, removed, or updated on an account.
///
/// See also:
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
abstract class SignerEffectResponse extends EffectResponse {
  /// The weight of the signer (0-255)
  int weight;

  /// The public key of the signer
  String publicKey;

  /// The signer key
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

/// Represents a signer created effect response from Horizon.
///
/// This effect occurs when a new signer is added to an account through a SetOptions operation.
///
/// Triggered by: SetOptionsOperation
///
/// See also:
/// - [SetOptionsOperation] for adding signers
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
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

/// Represents a signer removed effect response from Horizon.
///
/// This effect occurs when a signer is removed from an account (weight set to 0).
///
/// Triggered by: SetOptionsOperation
///
/// See also:
/// - [SetOptionsOperation] for removing signers
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
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

/// Represents a signer updated effect response from Horizon.
///
/// This effect occurs when an existing signer's weight is changed.
///
/// Triggered by: SetOptionsOperation
///
/// See also:
/// - [SetOptionsOperation] for updating signers
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
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
