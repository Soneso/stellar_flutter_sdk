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
/// - [Stellar developer docs](https://developers.stellar.org)
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
/// Adding signers enables multi-signature functionality, allowing multiple parties to
/// authorize transactions.
///
/// Triggered by: SetOptionsOperation
/// Returned by: Horizon API effects endpoint when querying for signer additions
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is SignerCreatedEffectResponse) {
///     print('New signer added:');
///     print('  Key: ${effect.key}');
///     print('  Public Key: ${effect.publicKey}');
///     print('  Weight: ${effect.weight}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetOptionsOperation] for adding signers
/// - [SignerRemovedEffectResponse] for signer removal
/// - [Stellar developer docs](https://developers.stellar.org)
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
/// This effect occurs when a signer is removed from an account by setting its weight to 0
/// through a SetOptions operation. Removing signers is used to revoke signing authority
/// from parties that should no longer be able to authorize transactions.
///
/// Triggered by: SetOptionsOperation with signer weight set to 0
/// Returned by: Horizon API effects endpoint when querying for signer removals
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is SignerRemovedEffectResponse) {
///     print('Signer removed:');
///     print('  Key: ${effect.key}');
///     print('  Public Key: ${effect.publicKey}');
///     print('  Final Weight: ${effect.weight}'); // Will be 0
///   }
/// }
/// ```
///
/// See also:
/// - [SetOptionsOperation] for removing signers
/// - [SignerCreatedEffectResponse] for signer addition
/// - [Stellar developer docs](https://developers.stellar.org)
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
/// This effect occurs when an existing signer's weight is changed through a SetOptions
/// operation. Updating signer weights allows adjusting the signing authority without
/// removing and re-adding signers, useful for changing multi-signature configurations.
///
/// Triggered by: SetOptionsOperation with new weight for existing signer
/// Returned by: Horizon API effects endpoint when querying for signer weight changes
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is SignerUpdatedEffectResponse) {
///     print('Signer weight updated:');
///     print('  Key: ${effect.key}');
///     print('  Public Key: ${effect.publicKey}');
///     print('  New Weight: ${effect.weight}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetOptionsOperation] for updating signers
/// - [SignerCreatedEffectResponse] for signer addition
/// - [Stellar developer docs](https://developers.stellar.org)
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
