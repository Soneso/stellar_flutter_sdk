// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../assets.dart';
import '../claimable_balance_response.dart';
import '../transaction_response.dart';

/// Represents a create claimable balance operation response from Horizon.
///
/// A create claimable balance operation creates a balance that can be claimed
/// by specified accounts once certain conditions are met. This enables deferred
/// payments and conditional transfers.
///
/// Returned by: Horizon API operations endpoint when querying create claimable balance operations
///
/// Fields:
/// - [asset]: The asset type and issuer of the claimable balance
/// - [amount]: The amount of the asset in the claimable balance
/// - [claimants]: List of accounts that can claim this balance and their predicates
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is CreateClaimableBalanceOperationResponse) {
///     print('Created claimable balance: ${op.amount} ${op.asset.code}');
///     print('Claimants: ${op.claimants.length}');
///   }
/// }
/// ```
///
/// See also:
/// - [CreateClaimableBalanceOperation] for creating claimable balances
/// - [Stellar developer docs](https://developers.stellar.org)
class CreateClaimableBalanceOperationResponse extends OperationResponse {
  /// The asset type and issuer of the claimable balance
  Asset asset;

  /// The amount of the asset in the claimable balance
  String amount;

  /// List of accounts that can claim this balance and their predicates
  List<ClaimantResponse> claimants;

  /// Creates a CreateClaimableBalanceOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [asset] The asset type and issuer of the claimable balance
  /// - [amount] The amount of the asset in the claimable balance
  /// - [claimants] List of accounts that can claim this balance
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
  CreateClaimableBalanceOperationResponse(
      this.asset,
      this.amount,
      this.claimants,
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

  factory CreateClaimableBalanceOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      CreateClaimableBalanceOperationResponse(
          Asset.createFromCanonicalForm(json['asset'])!,
          json['amount'],
          List<ClaimantResponse>.from(
              json['claimants'].map((e) => ClaimantResponse.fromJson(e))),
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

/// Represents a claim claimable balance operation response from Horizon.
///
/// A claim claimable balance operation claims a previously created claimable
/// balance, transferring the funds to the claimant's account if the conditions
/// (predicates) are met.
///
/// Returned by: Horizon API operations endpoint when querying claim claimable balance operations
///
/// Fields:
/// - [balanceId]: The unique ID of the claimable balance being claimed
/// - [claimantAccountId]: The account claiming the balance
/// - [claimantMuxed]: Muxed account representation of the claimant (if applicable)
/// - [claimantMuxedId]: Muxed account ID of the claimant (if applicable)
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is ClaimClaimableBalanceOperationResponse) {
///     print('Claimed balance ID: ${op.balanceId}');
///     print('Claimant: ${op.claimantAccountId}');
///   }
/// }
/// ```
///
/// See also:
/// - [ClaimClaimableBalanceOperation] for claiming claimable balances
/// - [Stellar developer docs](https://developers.stellar.org)
class ClaimClaimableBalanceOperationResponse extends OperationResponse {
  /// The unique ID of the claimable balance being claimed
  String balanceId;

  /// The account claiming the balance
  String claimantAccountId;

  /// Muxed account representation of the claimant (if applicable)
  String? claimantMuxed;

  /// Muxed account ID of the claimant (if applicable)
  String? claimantMuxedId;

  /// Creates a ClaimClaimableBalanceOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [balanceId] The unique ID of the claimable balance being claimed
  /// - [claimantAccountId] The account claiming the balance
  /// - [claimantMuxed] Muxed claimant account (if applicable)
  /// - [claimantMuxedId] Muxed claimant account ID (if applicable)
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
  ClaimClaimableBalanceOperationResponse(
      this.balanceId,
      this.claimantAccountId,
      this.claimantMuxed,
      this.claimantMuxedId,
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

  factory ClaimClaimableBalanceOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      ClaimClaimableBalanceOperationResponse(
          json['balance_id'],
          json['claimant'],
          json['claimant_muxed'],
          json['claimant_muxed_id'],
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
