// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents CreateAccount operation response.
/// See: [Create Account Object](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/create-account).
class CreateAccountOperationResponse extends OperationResponse {
  String account;
  String funder;
  String? funderMuxed;
  String? funderMuxedId;
  String startingBalance;

  CreateAccountOperationResponse(
      this.funder,
      this.funderMuxed,
      this.funderMuxedId,
      this.startingBalance,
      this.account,
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

  factory CreateAccountOperationResponse.fromJson(Map<String, dynamic> json) =>
      CreateAccountOperationResponse(
          json['funder'],
          json['funder_muxed'],
          json['funder_muxed_id'],
          json['starting_balance'],
          json['account'],
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
