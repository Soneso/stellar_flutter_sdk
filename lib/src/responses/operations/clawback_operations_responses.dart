// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents a clawback operation response from Horizon.
///
/// A clawback operation burns a specified amount of an asset from another account.
/// Only the asset issuer can perform clawbacks, and the asset must have the
/// CLAWBACK_ENABLED flag set.
///
/// Returned by: Horizon API operations endpoint when querying clawback operations
///
/// Fields:
/// - [amount]: The amount of the asset clawed back
/// - [from]: The account from which the asset was clawed back
/// - [fromMuxed]: Muxed account representation of the from account (if applicable)
/// - [fromMuxedId]: Muxed account ID of the from account (if applicable)
/// - [assetType]: Type of asset ('credit_alphanum4' or 'credit_alphanum12')
/// - [assetCode]: Code of the asset being clawed back
/// - [assetIssuer]: Issuer account ID of the asset
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('issuer_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is ClawbackOperationResponse) {
///     print('Clawed back ${op.amount} ${op.assetCode} from ${op.from}');
///   }
/// }
/// ```
///
/// See also:
/// - [ClawbackOperation] for creating clawback operations
/// - [Stellar developer docs](https://developers.stellar.org)
class ClawbackOperationResponse extends OperationResponse {
  /// The amount of the asset clawed back
  String amount;

  /// The account from which the asset was clawed back
  String from;

  /// Muxed account representation of the from account (if applicable)
  String? fromMuxed;

  /// Muxed account ID of the from account (if applicable)
  String? fromMuxedId;

  /// Type of asset ('credit_alphanum4' or 'credit_alphanum12')
  String assetType;

  /// Code of the asset being clawed back
  String? assetCode;

  /// Issuer account ID of the asset
  String? assetIssuer;

  /// Creates a ClawbackOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [amount] The amount of the asset clawed back
  /// - [from] The account from which the asset was clawed back
  /// - [fromMuxed] Muxed from account (if applicable)
  /// - [fromMuxedId] Muxed from account ID (if applicable)
  /// - [assetType] Type of asset
  /// - [assetCode] Code of the asset being clawed back
  /// - [assetIssuer] Issuer account ID of the asset
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
  ClawbackOperationResponse(
      this.amount,
      this.from,
      this.fromMuxed,
      this.fromMuxedId,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
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

  /// Deserializes a clawback operation response from JSON.
  factory ClawbackOperationResponse.fromJson(Map<String, dynamic> json) =>
      ClawbackOperationResponse(
          json['amount'],
          json['from'],
          json['from_muxed'],
          json['from_muxed_id'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
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

/// Represents a clawback claimable balance operation response from Horizon.
///
/// This operation claws back a claimable balance, removing it from the ledger
/// and burning the contained funds. Only the asset issuer can perform this operation.
///
/// Returned by: Horizon API operations endpoint when querying clawback claimable balance operations
///
/// Fields:
/// - [balanceId]: The unique ID of the claimable balance being clawed back
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('issuer_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is ClawbackClaimableBalanceOperationResponse) {
///     print('Clawed back balance: ${op.balanceId}');
///   }
/// }
/// ```
///
/// See also:
/// - [ClawbackClaimableBalanceOperation] for creating clawback claimable balance operations
/// - [Stellar developer docs](https://developers.stellar.org)
class ClawbackClaimableBalanceOperationResponse extends OperationResponse {
  /// The unique ID of the claimable balance being clawed back
  String balanceId;

  /// Creates a ClawbackClaimableBalanceOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [balanceId] The unique ID of the claimable balance being clawed back
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
  ClawbackClaimableBalanceOperationResponse(
      this.balanceId,
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

  /// Deserializes a clawback claimable balance operation response from JSON.
  factory ClawbackClaimableBalanceOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      ClawbackClaimableBalanceOperationResponse(
          json['balance_id'],
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
