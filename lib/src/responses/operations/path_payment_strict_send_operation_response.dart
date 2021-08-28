import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../response.dart';

/// Represents PathPaymentStrictReceive operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class PathPaymentStrictSendOperationResponse extends OperationResponse {
  String? amount;
  String? sourceAmount;
  String? destinationMin;
  String? from;
  String? to;

  String? fromMuxed;
  String? fromMuxedId;
  String? toMuxed;
  String? toMuxedId;

  String? assetType;
  String? assetCode;
  String? assetIssuer;

  String? sourceAssetType;
  String? sourceAssetCode;
  String? sourceAssetIssuer;
  List<Asset?>? path;

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
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  Asset get sourceAsset {
    if (sourceAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(sourceAssetCode!, sourceAssetIssuer!);
    }
  }

  factory PathPaymentStrictSendOperationResponse.fromJson(Map<String, dynamic> json) =>
      PathPaymentStrictSendOperationResponse(
        json['amount'],
        json['source_amount'],
        json['destination_min'],
        json['from'] == null ? null : json['from'],
        json['from_muxed'] == null ? null : json['from_muxed'],
        json['from_muxed_id'] == null ? null : json['from_muxed_id'],
        json['to'] == null ? null : json['to'],
        json['to_muxed'] == null ? null : json['to_muxed'],
        json['to_muxed_id'] == null ? null : json['to_muxed_id'],
        json['asset_type'],
        json['asset_code'],
        json['asset_issuer'],
        json['source_asset_type'],
        json['source_asset_code'],
        json['source_asset_issuer'],
        json['path'] != null
            ? List<Asset?>.from(json['path'].map((e) => e == null ? null : Asset.fromJson(e)))
            : null,
      )
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
