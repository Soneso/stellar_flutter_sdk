// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../transaction_response.dart';
import '../response.dart';
import 'operation_responses.dart';

/// Represents SetOptions operation response.
/// See: [Set Options Object](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/set-options)
class SetOptionsOperationResponse extends OperationResponse {
  int? lowThreshold;
  int? medThreshold;
  int? highThreshold;
  String? inflationDestination;
  String? homeDomain;
  String? signerKey;
  int? signerWeight;
  int? masterKeyWeight;
  List<String>? clearFlags;
  List<String>? setFlags;
  List<int>? clearFlagsInt;
  List<int>? setFlagsInt;

  SetOptionsOperationResponse(
      this.lowThreshold,
      this.medThreshold,
      this.highThreshold,
      this.inflationDestination,
      this.homeDomain,
      this.signerKey,
      this.signerWeight,
      this.masterKeyWeight,
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

  String? get signer {
    return signerKey;
  }

  factory SetOptionsOperationResponse.fromJson(Map<String, dynamic> json) =>
      SetOptionsOperationResponse(
          convertInt(json['low_threshold']),
          convertInt(json['med_threshold']),
          convertInt(json['high_threshold']),
          json['inflation_dest'],
          json['home_domain'],
          json['signer_key'],
          convertInt(json['signer_weight']),
          convertInt(json['master_key_weight']),
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
