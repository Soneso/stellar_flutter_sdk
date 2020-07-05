import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../response.dart';

/// Represents ManageBuyOffer operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class ManageBuyOfferOperationResponse extends OperationResponse {
  String offerId;
  String amount;
  String price;

  String buyingAssetType;
  String buyingAssetCode;
  String buyingAssetIssuer;

  String sellingAssetType;
  String sellingAssetCode;
  String sellingAssetIssuer;

  ManageBuyOfferOperationResponse(
      this.offerId,
      this.amount,
      this.price,
      this.buyingAssetType,
      this.buyingAssetCode,
      this.buyingAssetIssuer,
      this.sellingAssetType,
      this.sellingAssetCode,
      this.sellingAssetIssuer);

  Asset get buyingAsset {
    if (buyingAssetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(buyingAssetCode, buyingAssetIssuer);
    }
  }

  Asset get sellingAsset {
    if (sellingAssetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(sellingAssetCode, sellingAssetIssuer);
    }
  }

  factory ManageBuyOfferOperationResponse.fromJson(Map<String, dynamic> json) =>
      new ManageBuyOfferOperationResponse(
          json['offer_id'] as String,
          json['amount'] as String,
          json['price'] as String,
          json['buying_asset_type'] as String,
          json['buying_asset_code'] as String,
          json['buying_asset_issuer'] as String,
          json['selling_asset_type'] as String,
          json['selling_asset_code'] as String,
          json['selling_asset_issuer'] as String)
        ..id = int.parse(json['id'] as String)
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..pagingToken = json['paging_token'] as String
        ..createdAt = json['created_at'] as String
        ..transactionHash = json['transaction_hash'] as String
        ..transactionSuccessful = json['transaction_successful'] as bool
        ..type = json['type'] as String
        ..links = json['_links'] == null
            ? null
            : new OperationResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}
