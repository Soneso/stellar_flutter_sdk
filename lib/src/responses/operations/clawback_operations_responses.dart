// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents the ClawbackOperationResponse operation response.
class ClawbackOperationResponse extends OperationResponse {
  String amount;
  String from;
  String? fromMuxed;
  String? fromMuxedId;
  String assetType;
  String? assetCode;
  String? assetIssuer;

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

/// Represents the ClawbackClaimableBalanceOperationResponse operation response.
class ClawbackClaimableBalanceOperationResponse extends OperationResponse {
  String balanceId;

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
