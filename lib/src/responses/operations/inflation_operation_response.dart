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
  /// Creates an inflation operation response with the specified parameters.
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
