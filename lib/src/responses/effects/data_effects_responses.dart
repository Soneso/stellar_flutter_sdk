// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';

/// Represents data_created effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class DataCreatedEffectResponse extends EffectResponse {
  DataCreatedEffectResponse();

  factory DataCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new DataCreatedEffectResponse()
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

/// Represents data_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class DataUpdatedEffectResponse extends EffectResponse {
  DataUpdatedEffectResponse();

  factory DataUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new DataUpdatedEffectResponse()
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

///Represents data_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class DataRemovedEffectResponse extends EffectResponse {
  DataRemovedEffectResponse();

  factory DataRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      new DataRemovedEffectResponse()
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
