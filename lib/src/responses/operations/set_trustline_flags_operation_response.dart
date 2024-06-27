// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents the SetTrustlineFlagsOperationResponse operation response.
/// https://developers.stellar.org/docs/learn/fundamentals/list-of-operations#set-trustline-flags
class SetTrustlineFlagsOperationResponse extends OperationResponse {
  String trustor;
  String assetType;
  String? assetCode;
  String? assetIssuer;
  List<String>? clearFlags;
  List<String>? setFlags;
  List<int>? clearFlagsInt;
  List<int>? setFlagsInt;

  SetTrustlineFlagsOperationResponse(
      this.trustor,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.clearFlags,
      this.setFlags,
      this.clearFlagsInt,
      this.setFlagsInt,
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

  factory SetTrustlineFlagsOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      SetTrustlineFlagsOperationResponse(
          json['trustor'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['clear_flags_s'] != null
              ? List<String>.from(json['clear_flags_s'].map((e) => e))
              : null,
          json['set_flags_s'] != null
              ? List<String>.from(json['set_flags_s'].map((e) => e))
              : null,
          json['clear_flags'] != null
              ? List<int>.from(json['clear_flags'].map((e) => e))
              : null,
          json['set_flags'] != null
              ? List<int>.from(json['set_flags'].map((e) => e))
              : null,
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
