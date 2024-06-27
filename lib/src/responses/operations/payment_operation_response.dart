// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../../assets.dart';
import '../../asset_type_native.dart';
import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents Payment operation response.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/payment" target="_blank">Operation documentation</a>
class PaymentOperationResponse extends OperationResponse {
  String amount;
  String assetType;
  String? assetCode;
  String? assetIssuer;
  String from;
  String to;
  String? fromMuxed;
  String? fromMuxedId;
  String? toMuxed;
  String? toMuxedId;

  PaymentOperationResponse(
      this.amount,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.from,
      this.fromMuxed,
      this.fromMuxedId,
      this.to,
      this.toMuxed,
      this.toMuxedId,
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
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  factory PaymentOperationResponse.fromJson(Map<String, dynamic> json) =>
      PaymentOperationResponse(
          json['amount'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['from'],
          json['from_muxed'],
          json['from_muxed_id'],
          json['to'],
          json['to_muxed'],
          json['to_muxed_id'],
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
