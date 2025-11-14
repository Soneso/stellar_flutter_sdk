// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../response.dart';

/// Represents a sequence bumped effect response from Horizon.
///
/// This effect occurs when an account manually increases its sequence number using
/// the Bump Sequence operation. Bumping the sequence number is typically used to
/// invalidate any pre-signed transactions with lower sequence numbers, or to prepare
/// the account for future transactions with specific sequence requirements.
///
/// The sequence number is a transaction-level nonce that ensures transaction uniqueness
/// and ordering. Each transaction uses the account's current sequence number plus one.
///
/// Triggered by: BumpSequenceOperation
/// Returned by: Horizon API effects endpoint when querying for sequence bump effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is SequenceBumpedEffectResponse) {
///     print('Sequence bumped to: ${effect.newSequence}');
///   }
/// }
/// ```
///
/// See also:
/// - [BumpSequenceOperation] for bumping sequence numbers
/// - [Stellar developer docs](https://developers.stellar.org)
class SequenceBumpedEffectResponse extends EffectResponse {
  /// The new sequence number for the account after the bump
  int newSequence;

  SequenceBumpedEffectResponse(
      this.newSequence,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory SequenceBumpedEffectResponse.fromJson(Map<String, dynamic> json) =>
      SequenceBumpedEffectResponse(
          convertInt(json['new_seq'])!,
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
