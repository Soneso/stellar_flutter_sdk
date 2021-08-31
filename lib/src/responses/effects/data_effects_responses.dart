// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../response.dart';

/// Represents data_created effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class DataCreatedEffectResponse extends EffectResponse {
  String? name;
  String? value;

  DataCreatedEffectResponse(this.name, this.value);

  factory DataCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      DataCreatedEffectResponse(json['name'], json['value'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

/// Represents data_updated effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class DataUpdatedEffectResponse extends EffectResponse {
  String? name;
  String? value;

  DataUpdatedEffectResponse(this.name, this.value);

  factory DataUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      DataUpdatedEffectResponse(json['name'], json['value'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}

///Represents data_removed effect response.
/// See: <a href="https://developers.stellar.org/api/resources/effects/" target="_blank">Effects</a>.
class DataRemovedEffectResponse extends EffectResponse {
  String? name;

  DataRemovedEffectResponse(this.name);

  factory DataRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      DataRemovedEffectResponse(json['name'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed = json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null ? null : EffectResponseLinks.fromJson(json['_links']);
}
