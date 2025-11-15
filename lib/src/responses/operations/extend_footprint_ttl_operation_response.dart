// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';
import '../response.dart';

/// Represents an extend footprint TTL operation response from Horizon.
///
/// This Soroban operation extends the time-to-live (TTL) of contract data entries,
/// preventing them from expiring and being archived.
///
/// Returned by: Horizon API operations endpoint when querying extend footprint TTL operations
///
/// See also:
/// - [ExtendFootprintTTLOperation] for extending contract data TTL
/// - [Stellar developer docs](https://developers.stellar.org)
class ExtendFootprintTTLOperationResponse extends OperationResponse {
  /// The ledger number to which the footprint entries' TTL is extended
  int extendTo;

  /// Creates an ExtendFootprintTTLOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [extendTo] The ledger number to which the footprint entries' TTL is extended
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
  ExtendFootprintTTLOperationResponse(
      this.extendTo,
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

  factory ExtendFootprintTTLOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      ExtendFootprintTTLOperationResponse(
          convertInt(json['extend_to'])!,
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
