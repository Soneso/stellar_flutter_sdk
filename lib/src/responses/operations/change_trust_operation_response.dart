// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../asset_type_native.dart';
import '../../assets.dart';
import '../transaction_response.dart';

/// Represents ChangeTrust operation response.
/// See <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/change-trust" target="_blank">Change Trust Object</a>
class ChangeTrustOperationResponse extends OperationResponse {
  String trustor;
  String? trustorMuxed;
  String? trustorMuxedId;
  String? trustee;

  /// The type of asset being trusted, one of native, credit_alphanum4, credit_alphanum12, or liquidity_pool_shares.
  String assetType;
  String? assetCode;
  String? assetIssuer;
  String limit;
  String? liquidityPoolId;

  ChangeTrustOperationResponse(
      this.trustor,
      this.trustorMuxed,
      this.trustorMuxedId,
      this.trustee,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.limit,
      this.liquidityPoolId,
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

  Asset? get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else if (assetType != 'liquidity_pool_shares' &&
        assetCode != null &&
        assetIssuer != null) {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
    return null;
  }

  factory ChangeTrustOperationResponse.fromJson(Map<String, dynamic> json) =>
      ChangeTrustOperationResponse(
          json['trustor'],
          json['trustor_muxed'],
          json['trustor_muxed_id'],
          json['trustee'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['limit'],
          json['liquidity_pool_id'],
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
