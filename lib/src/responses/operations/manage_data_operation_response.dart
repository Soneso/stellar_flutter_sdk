// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents a manage data operation response from Horizon.
///
/// A manage data operation sets, modifies, or deletes a data entry (key-value pair)
/// associated with an account. Each account can store up to 1000 data entries.
///
/// Returned by: Horizon API operations endpoint when querying manage data operations
///
/// Fields:
/// - [name]: The key name of the data entry
/// - [value]: The base64-encoded value (empty string to delete the entry)
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is ManageDataOperationResponse) {
///     print('Data entry: ${op.name}');
///     print('Value: ${op.value}');
///   }
/// }
/// ```
///
/// See also:
/// - [ManageDataOperation] for creating manage data operations
/// - [Stellar developer docs](https://developers.stellar.org)
class ManageDataOperationResponse extends OperationResponse {
  /// The key name of the data entry
  String name;

  /// The base64-encoded value (empty string to delete the entry)
  String value;

  /// Creates a manage data operation response with the specified parameters.
  ManageDataOperationResponse(
      this.name,
      this.value,
      super.links,
      super.id,
      super.pagingToken,
      super.transactionSuccessful,
      super.sourceAccount,
      super.sourceAccountMuxed,
      super.sourceAccountMuxedId,
      super.type,
      super.type_i,
      super.createdAt,
      super.transactionHash,
      super.transaction,
      super.sponsor);

  /// Deserializes a manage data operation response from JSON.
  factory ManageDataOperationResponse.fromJson(Map<String, dynamic> json) =>
      ManageDataOperationResponse(
          json['name'],
          json['value'],
          OperationResponseLinks.fromJson(json['_links']),
          json['id'],
          json['paging_token'],
          json['transaction_successful'],
          json['source_account'],
          json['source_account_muxed'],
          json['source_account_muxed_id'],
          json['type'],
          json['type_i'],
          json['created_at'],
          json['transaction_hash'],
          json['transaction'] == null
              ? null
              : TransactionResponse.fromJson(json['transaction']),
          json['sponsor']);
}
