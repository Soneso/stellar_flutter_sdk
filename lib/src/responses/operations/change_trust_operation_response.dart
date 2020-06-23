import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Represents ChangeTrust operation response.
/// See <a href="https://www.stellar.org/developers/horizon/reference/resources/operation.html" target="_blank">Operation documentation</a>
class ChangeTrustOperationResponse extends OperationResponse {
  String trustor;
  String trustee;
  String assetType;
  String assetCode;
  String assetIssuer;
  String limit;

  ChangeTrustOperationResponse(this.trustor, this.trustee, this.assetType,
      this.assetCode, this.assetIssuer, this.limit);

  Asset get asset {
    if (assetType == "native") {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }

  factory ChangeTrustOperationResponse.fromJson(Map<String, dynamic> json) =>
      new ChangeTrustOperationResponse(
          json['trustor'] == null ? null : json['trustor'],
          json['trustee'] == null ? null : json['trustee'],
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String,
          json['limit'] as String)
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
