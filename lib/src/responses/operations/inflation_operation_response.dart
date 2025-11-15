// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents an inflation operation response from Horizon.
///
/// The inflation operation was used to distribute fees collected by the network
/// and increase the XLM supply. This operation is deprecated and disabled since
/// Protocol 12 (October 2019) following a network vote.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
class InflationOperationResponse extends OperationResponse {
  /// Creates an InflationOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [links] Hypermedia links to related resources
  /// - [id] Unique operation identifier
  /// - [pagingToken] Pagination cursor
  /// - [transactionSuccessful] Whether the parent transaction succeeded
  /// - [sourceAccount] Operation source account ID
  /// - [sourceAccountMuxed] Muxed source account (if applicable)
  /// - [sourceAccountMuxedId] Muxed source account ID (if applicable)
  /// - [type] Operation type name
  /// - [type_i] Operation type as integer
  /// - [createdAt] Creation timestamp
  /// - [transactionHash] Parent transaction hash
  /// - [transaction] Full parent transaction
  /// - [sponsor] Account sponsoring the operation (if applicable)
  InflationOperationResponse(
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

  /// Deserializes an inflation operation response from JSON.
  factory InflationOperationResponse.fromJson(Map<String, dynamic> json) =>
      InflationOperationResponse(
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
