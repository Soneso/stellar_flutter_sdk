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
        ..type = json['type'] as String
        ..createdAt = json['created_at'] as String
        ..pagingToken = json['paging_token'] as String
        ..links = json['_links'] == null
            ? null
            : new EffectResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}
