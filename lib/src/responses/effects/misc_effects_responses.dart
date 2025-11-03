// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../response.dart';

/// Effect Sequence Bumped occurs when an account bumps their sequence number.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class SequenceBumpedEffectResponse extends EffectResponse {
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
