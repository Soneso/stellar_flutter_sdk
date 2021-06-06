import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../response.dart';

/// Represents PathPaymentStrictReceive operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class PathPaymentStrictSendOperationResponse extends OperationResponse {
  String amount;
  String sourceAmount;
  String destinationMin;
  String from;
  String to;

  String fromMuxed;
  int fromMuxedId;
  String toMuxed;
  int toMuxedId;

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
      this.fromMuxed,
      this.fromMuxedId,
      this.to,
      this.toMuxed,
      this.toMuxedId,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.sourceAssetType,
      this.sourceAssetCode,
      this.sourceAssetIssuer,
      this.path);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }

  Asset get sourceAsset {
    if (sourceAssetType == Asset.TYPE_NATIVE) {
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
          json['from_muxed'] == null ? null : json['from_muxed'],
          json['from_muxed_id'] == null
              ? null
              : convertInt(json['from_muxed_id']),
          json['to'] == null ? null : json['to'],
          json['to_muxed'] == null ? null : json['to_muxed'],
          json['to_muxed_id'] == null ? null : convertInt(json['to_muxed_id']),
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
        ..sourceAccountMuxed = json['source_account_muxed'] == null
            ? null
            : json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id'] == null
            ? null
            : convertInt(json['source_account_muxed_id'])
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
