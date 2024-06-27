// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../transaction_response.dart';
import '../../price.dart';

/// Represents ManageSellOffer operation response.
/// See: <a href="https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/sell-offer" target="_blank">Manage Sell Offer Object</a>
class ManageSellOfferOperationResponse extends OperationResponse {
  String offerId;
  String amount;
  String price;
  Price priceR;

  String buyingAssetType;
  String? buyingAssetCode;
  String? buyingAssetIssuer;

  String sellingAssetType;
  String? sellingAssetCode;
  String? sellingAssetIssuer;

  ManageSellOfferOperationResponse(
      this.offerId,
      this.amount,
      this.price,
      this.priceR,
      this.buyingAssetType,
      this.buyingAssetCode,
      this.buyingAssetIssuer,
      this.sellingAssetType,
      this.sellingAssetCode,
      this.sellingAssetIssuer,
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

  Asset get buyingAsset {
    if (buyingAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(buyingAssetCode!, buyingAssetIssuer!);
    }
  }

  Asset get sellingAsset {
    if (sellingAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(sellingAssetCode!, sellingAssetIssuer!);
    }
  }

  factory ManageSellOfferOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      ManageSellOfferOperationResponse(
          json['offer_id'],
          json['amount'],
          json['price'],
          Price.fromJson(json['price_r']),
          json['buying_asset_type'],
          json['buying_asset_code'],
          json['buying_asset_issuer'],
          json['selling_asset_type'],
          json['selling_asset_code'],
          json['selling_asset_issuer'],
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
