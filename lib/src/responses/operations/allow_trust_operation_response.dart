// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../assets.dart';
import '../transaction_response.dart';

/// Represents the AllowTrust operation response.
/// This operation is deprecated as of Protocol 17. Prefer SetTrustLineFlags instead.
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/allow-trust" target="_blank">Allow Trust Object</a>.
class AllowTrustOperationResponse extends OperationResponse {
  String trustor;
  String trustee;
  String? trusteeMuxed;
  String? trusteeMuxedId;
  String assetType;
  String assetCode;
  String assetIssuer;
  bool authorize;
  bool authorizeToMaintainLiabilities;

  AllowTrustOperationResponse(
      this.authorize,
      this.authorizeToMaintainLiabilities,
      this.assetIssuer,
      this.assetCode,
      this.assetType,
      this.trustee,
      this.trusteeMuxed,
      this.trusteeMuxedId,
      this.trustor,
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

  Asset get asset {
    return Asset.createNonNativeAsset(assetCode, assetIssuer);
  }

  factory AllowTrustOperationResponse.fromJson(Map<String, dynamic> json) =>
      AllowTrustOperationResponse(
          json['authorize'],
          json['authorize_to_maintain_liabilities'],
          json['asset_issuer'],
          json['asset_code'],
          json['asset_type'],
          json['trustee'],
          json['trustee_muxed'],
          json['trustee_muxed_id'],
          json['trustor'],
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
