// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents an account merge operation response from Horizon.
///
/// An account merge operation transfers the native XLM balance from the source
/// account to a destination account and removes the source account from the ledger.
///
/// Returned by: Horizon API operations endpoint when querying account merge operations
///
/// Fields:
/// - [account]: Account being merged (source account that will be deleted)
/// - [accountMuxed]: Muxed account representation of the account being merged (if applicable)
/// - [accountMuxedId]: Muxed account ID of the account being merged (if applicable)
/// - [into]: Destination account receiving the XLM balance
/// - [intoMuxed]: Muxed account representation of the destination account (if applicable)
/// - [intoMuxedId]: Muxed account ID of the destination account (if applicable)
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is AccountMergeOperationResponse) {
///     print('Account ${op.account} merged into ${op.into}');
///   }
/// }
/// ```
///
/// See also:
/// - [AccountMergeOperation] for creating account merge operations
/// - [Stellar developer docs](https://developers.stellar.org)
class AccountMergeOperationResponse extends OperationResponse {
  /// Account being merged (source account that will be deleted)
  String account;

  /// Muxed account representation of the account being merged (if applicable)
  String? accountMuxed;

  /// Muxed account ID of the account being merged (if applicable)
  String? accountMuxedId;

  /// Destination account receiving the XLM balance
  String into;

  /// Muxed account representation of the destination account (if applicable)
  String? intoMuxed;

  /// Muxed account ID of the destination account (if applicable)
  String? intoMuxedId;

  /// Creates an AccountMergeOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [account] Account being merged and removed from the ledger
  /// - [accountMuxed] Muxed account representation of the merged account (if applicable)
  /// - [accountMuxedId] Muxed account ID of the merged account (if applicable)
  /// - [into] Destination account receiving the merged account's balance
  /// - [intoMuxed] Muxed account representation of the destination (if applicable)
  /// - [intoMuxedId] Muxed account ID of the destination (if applicable)
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
  AccountMergeOperationResponse(
      this.account,
      this.accountMuxed,
      this.accountMuxedId,
      this.into,
      this.intoMuxed,
      this.intoMuxedId,
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

  /// Deserializes an account merge operation response from JSON.
  factory AccountMergeOperationResponse.fromJson(Map<String, dynamic> json) =>
      AccountMergeOperationResponse(
          json['account'],
          json['account_muxed'],
          json['account_muxed_id'],
          json['into'],
          json['into_muxed'],
          json['into_muxed_id'],
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
