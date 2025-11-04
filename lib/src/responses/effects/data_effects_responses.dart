// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';

/// Represents a data entry created effect response from Horizon.
///
/// This effect occurs when a new data entry (key-value pair) is added to an account's ledger entry.
/// Data entries allow accounts to store arbitrary data on the ledger.
///
/// Triggered by: ManageDataOperation
/// Returned by: Horizon API effects endpoint when querying for data creation effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is DataCreatedEffectResponse) {
///     print('Data created: ${effect.name} = ${effect.value}');
///   }
/// }
/// ```
///
/// See also:
/// - [ManageDataOperation] for managing account data
/// - [DataRemovedEffectResponse] for data removal
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class DataCreatedEffectResponse extends EffectResponse {
  /// The name (key) of the data entry
  String name;

  /// The base64-encoded value of the data entry
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

/// Represents a data entry updated effect response from Horizon.
///
/// This effect occurs when an existing data entry's value is modified on an account.
/// The data entry name remains the same, but the value is changed.
///
/// Triggered by: ManageDataOperation with a new value for an existing name
/// Returned by: Horizon API effects endpoint when querying for data update effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is DataUpdatedEffectResponse) {
///     print('Data updated: ${effect.name} = ${effect.value}');
///   }
/// }
/// ```
///
/// See also:
/// - [ManageDataOperation] for managing account data
/// - [DataCreatedEffectResponse] for data creation
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class DataUpdatedEffectResponse extends EffectResponse {
  /// The name (key) of the data entry
  String name;

  /// The new base64-encoded value of the data entry
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

/// Represents a data entry removed effect response from Horizon.
///
/// This effect occurs when a data entry is deleted from an account's ledger entry.
/// To remove a data entry, set its value to null using ManageDataOperation.
///
/// Triggered by: ManageDataOperation with null value
/// Returned by: Horizon API effects endpoint when querying for data removal effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is DataRemovedEffectResponse) {
///     print('Data removed: ${effect.name}');
///   }
/// }
/// ```
///
/// See also:
/// - [ManageDataOperation] for managing account data
/// - [DataCreatedEffectResponse] for data creation
/// - [Horizon Effects](https://developers.stellar.org/docs/data/horizon/api-reference/resources/effects)
class DataRemovedEffectResponse extends EffectResponse {
  /// The name (key) of the removed data entry
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
