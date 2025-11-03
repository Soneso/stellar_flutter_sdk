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
/// - [Horizon Create Claimable Balance](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/create-claimable-balance)
class CreateClaimableBalanceOperationResponse extends OperationResponse {
  /// The asset type and issuer of the claimable balance
  Asset asset;

  /// The amount of the asset in the claimable balance
  String amount;

  /// List of accounts that can claim this balance and their predicates
  List<ClaimantResponse> claimants;

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
/// - [Horizon Claim Claimable Balance](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/claim-claimable-balance)
class ClaimClaimableBalanceOperationResponse extends OperationResponse {
  /// The unique ID of the claimable balance being claimed
  String balanceId;

  /// The account claiming the balance
  String claimantAccountId;

  /// Muxed account representation of the claimant (if applicable)
  String? claimantMuxed;

  /// Muxed account ID of the claimant (if applicable)
  String? claimantMuxedId;

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
