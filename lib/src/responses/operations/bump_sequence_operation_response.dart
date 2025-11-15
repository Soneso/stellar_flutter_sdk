// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents a bump sequence operation response from Horizon.
///
/// A bump sequence operation advances the sequence number of the source account
/// to a specified value, invalidating any transactions with lower sequence numbers.
///
/// Returned by: Horizon API operations endpoint when querying bump sequence operations
///
/// Fields:
/// - [bumpTo]: The new sequence number for the source account
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is BumpSequenceOperationResponse) {
///     print('Sequence bumped to: ${op.bumpTo}');
///   }
/// }
/// ```
///
/// See also:
/// - [BumpSequenceOperation] for creating bump sequence operations
/// - [Stellar developer docs](https://developers.stellar.org)
class BumpSequenceOperationResponse extends OperationResponse {
  /// The new sequence number for the source account
  String bumpTo;

  /// Creates a BumpSequenceOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [bumpTo]: The new sequence number for the source account
  /// - [links]: Hypermedia links to related resources
  /// - [id]: Unique operation identifier
  /// - [pagingToken]: Pagination cursor
  /// - [transactionSuccessful]: Whether the parent transaction succeeded
  /// - [sourceAccount]: Operation source account ID
  /// - [sourceAccountMuxed]: Muxed source account (if applicable)
  /// - [sourceAccountMuxedId]: Muxed source account ID (if applicable)
  /// - [type]: Operation type name
  /// - [type_i]: Operation type as integer
  /// - [createdAt]: Creation timestamp
  /// - [transactionHash]: Parent transaction hash
  /// - [transaction]: Full parent transaction
  /// - [sponsor]: Account sponsoring the operation (if applicable)
  BumpSequenceOperationResponse(
      this.bumpTo,
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

  /// Deserializes a bump sequence operation response from JSON.
  factory BumpSequenceOperationResponse.fromJson(Map<String, dynamic> json) =>
      BumpSequenceOperationResponse(
          json['bump_to'],
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
