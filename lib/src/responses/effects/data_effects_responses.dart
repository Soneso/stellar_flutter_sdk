// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';

/// Effect Data Created occurs when an account gets a new data field.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class DataCreatedEffectResponse extends EffectResponse {
  String name;
  String value;

  DataCreatedEffectResponse(
      this.name,
      this.value,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory DataCreatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      DataCreatedEffectResponse(
          json['name'],
          json['value'],
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

/// Effect Data Updated occurs when an account changes a data field's value.
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class DataUpdatedEffectResponse extends EffectResponse {
  String name;
  String value;

  DataUpdatedEffectResponse(
      this.name,
      this.value,
      super.id,
      super.type_i,
      super.type,
      super.createdAt,
      super.pagingToken,
      super.account,
      super.links);

  factory DataUpdatedEffectResponse.fromJson(Map<String, dynamic> json) =>
      DataUpdatedEffectResponse(
          json['name'],
          json['value'],
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

/// Effect Data Removed occurs when an account removes a data field
/// See: [Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects).
class DataRemovedEffectResponse extends EffectResponse {
  String name;

  DataRemovedEffectResponse(this.name, super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links);

  factory DataRemovedEffectResponse.fromJson(Map<String, dynamic> json) =>
      DataRemovedEffectResponse(
          json['name'],
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
