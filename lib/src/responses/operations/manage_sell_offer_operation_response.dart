import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Represents ManageSellOffer operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class ManageSellOfferOperationResponse extends OperationResponse {
  String? offerId;
  String? amount;
  String? price;

  String? buyingAssetType;
  String? buyingAssetCode;
  String? buyingAssetIssuer;

  String? sellingAssetType;
  String? sellingAssetCode;
  String? sellingAssetIssuer;

  ManageSellOfferOperationResponse(
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

  factory ManageSellOfferOperationResponse.fromJson(Map<String, dynamic> json) =>
      ManageSellOfferOperationResponse(
          json['offer_id'],
          json['amount'],
          json['price'],
          json['buying_asset_type'],
          json['buying_asset_code'],
          json['buying_asset_issuer'],
          json['selling_asset_type'],
          json['selling_asset_code'],
          json['selling_asset_issuer'])
        ..id = int.tryParse(json['id'])
        ..sourceAccount = json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed =
            json['source_account_muxed'] == null ? null : json['source_account_muxed']
        ..sourceAccountMuxedId =
            json['source_account_muxed_id'] == null ? null : json['source_account_muxed_id']
        ..pagingToken = json['paging_token']
        ..createdAt = json['created_at']
        ..transactionHash = json['transaction_hash']
        ..transactionSuccessful = json['transaction_successful']
        ..type = json['type']
        ..links = json['_links'] == null ? null : OperationResponseLinks.fromJson(json['_links']);
}
