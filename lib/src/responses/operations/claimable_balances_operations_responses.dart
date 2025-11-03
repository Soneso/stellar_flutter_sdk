// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../assets.dart';
import '../claimable_balance_response.dart';
import '../transaction_response.dart';

/// Represents the CreateClaimableBalance operation response.
/// See: [Operation documentation](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/create-claimable-balance)
class CreateClaimableBalanceOperationResponse extends OperationResponse {
  Asset asset;
  String amount;
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

/// Represents the ClaimClaimableBalance operation response.
/// See: [Operation documentation](https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/claim-claimable-balance)
class ClaimClaimableBalanceOperationResponse extends OperationResponse {
  String balanceId;
  String claimantAccountId;
  String? claimantMuxed;
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
