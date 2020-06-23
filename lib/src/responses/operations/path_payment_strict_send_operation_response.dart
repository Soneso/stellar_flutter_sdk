import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Represents PathPaymentStrictReceive operation response.
/// See <a href="https://www.stellar.org/developers/horizon/reference/resources/operation.html" target="_blank">Operation documentation</a>.
class PathPaymentStrictSendOperationResponse extends OperationResponse {
  String amount;
  String sourceAmount;
  String destinationMin;
  String from;
  String to;

  String assetType;
  String assetCode;
  String assetIssuer;

  String sourceAssetType;
  String sourceAssetCode;
  String sourceAssetIssuer;
  List<Asset> path;

  PathPaymentStrictSendOperationResponse(
      this.amount,
      this.sourceAmount,
      this.destinationMin,
      this.from,
      this.to,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.sourceAssetType,
      this.sourceAssetCode,
      this.sourceAssetIssuer,
      this.path);

  Asset get asset {
    if (assetType == "native") {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }

  Asset get sourceAsset {
    if (sourceAssetType == "native") {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(sourceAssetCode, sourceAssetIssuer);
    }
  }

  factory PathPaymentStrictSendOperationResponse.fromJson(
      Map<String, dynamic> json) =>
      new PathPaymentStrictSendOperationResponse(
          json['amount'] as String,
          json['source_amount'] as String,
          json['destination_min'] as String,
          json['from'] == null ? null : json['from'],
          json['to'] == null ? null : json['to'],
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String,
          json['source_asset_type'] as String,
          json['source_asset_code'] as String,
          json['source_asset_issuer'] as String,
          (json['path'] as List)
              ?.map((e) => e == null
              ? null
              : new Asset.fromJson(e as Map<String, dynamic>))
              ?.toList())
        ..id = int.parse(json['id'] as String)
        ..sourceAccount =
        json['source_account'] == null ? null : json['source_account']
        ..pagingToken = json['paging_token'] as String
        ..createdAt = json['created_at'] as String
        ..transactionHash = json['transaction_hash'] as String
        ..type = json['type'] as String
        ..links = json['_links'] == null
            ? null
            : new OperationResponseLinks.fromJson(
            json['_links'] as Map<String, dynamic>);
}
