// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../transaction_response.dart';
import '../../price.dart';

/// Represents a create passive sell offer operation response from Horizon.
///
/// A create passive sell offer operation creates an offer that does not take
/// existing offers at the same price. It will only execute when matched by
/// another operation at a better price.
///
/// Returned by: Horizon API operations endpoint when querying create passive sell offer operations
///
/// Fields:
/// - [amount]: The amount of the selling asset being offered
/// - [price]: The price as a decimal string representing selling/buying ratio
/// - [priceR]: The price as a rational number (numerator/denominator)
/// - [buyingAssetType]: Type of asset being bought ('native', 'credit_alphanum4', or 'credit_alphanum12')
/// - [buyingAssetCode]: Asset code of the asset being bought (null for native XLM)
/// - [buyingAssetIssuer]: Issuer account ID of the asset being bought (null for native XLM)
/// - [sellingAssetType]: Type of asset being sold
/// - [sellingAssetCode]: Asset code of the asset being sold (null for native XLM)
/// - [sellingAssetIssuer]: Issuer account ID of the asset being sold (null for native XLM)
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is CreatePassiveSellOfferOperationResponse) {
///     print('Passive offer: ${op.amount} ${op.sellingAsset.code} at price ${op.price}');
///     print('Buying: ${op.buyingAsset.code}');
///   }
/// }
/// ```
///
/// See also:
/// - [CreatePassiveSellOfferOperation] for creating passive sell offers
/// - [Horizon Create Passive Sell Offer](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/passive-sell-offer)
class CreatePassiveSellOfferOperationResponse extends OperationResponse {
  /// The amount of the selling asset being offered
  String amount;

  /// The price as a decimal string representing selling/buying ratio
  String price;

  /// The price as a rational number (numerator/denominator)
  Price priceR;

  /// Type of asset being bought ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String buyingAssetType;

  /// Asset code of the asset being bought (null for native XLM)
  String? buyingAssetCode;

  /// Issuer account ID of the asset being bought (null for native XLM)
  String? buyingAssetIssuer;

  /// Type of asset being sold ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String sellingAssetType;

  /// Asset code of the asset being sold (null for native XLM)
  String? sellingAssetCode;

  /// Issuer account ID of the asset being sold (null for native XLM)
  String? sellingAssetIssuer;

  CreatePassiveSellOfferOperationResponse(
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

  /// Convenience getter to retrieve the buying asset as an [Asset] object.
  ///
  /// Returns either an [AssetTypeNative] for XLM or an [AssetTypeCreditAlphaNum]
  /// for issued assets.
  Asset get buyingAsset {
    if (buyingAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(buyingAssetCode!, buyingAssetIssuer!);
    }
  }

  /// Convenience getter to retrieve the selling asset as an [Asset] object.
  ///
  /// Returns either an [AssetTypeNative] for XLM or an [AssetTypeCreditAlphaNum]
  /// for issued assets.
  Asset get sellingAsset {
    if (sellingAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(sellingAssetCode!, sellingAssetIssuer!);
    }
  }

  factory CreatePassiveSellOfferOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      CreatePassiveSellOfferOperationResponse(
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
