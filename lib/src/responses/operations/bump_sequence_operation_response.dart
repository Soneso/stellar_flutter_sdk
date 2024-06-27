// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents BumpSequence operation response.
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/bump-sequence" target="_blank">Bump Sequence Object</a>
class BumpSequenceOperationResponse extends OperationResponse {
  String bumpTo;

  BumpSequenceOperationResponse(
      this.bumpTo,
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

  factory BumpSequenceOperationResponse.fromJson(Map<String, dynamic> json) =>
      BumpSequenceOperationResponse(
          json['bump_to'],
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
