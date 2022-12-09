import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';

/// Represents the AllowTrust operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>.
class AllowTrustOperationResponse extends OperationResponse {
  String? trustor;
  String? trustee;
  String? trusteeMuxed;
  String? trusteeMuxedId;
  String? assetType;
  String? assetCode;
  String? assetIssuer;
  bool? authorize;
  bool? authorizeToMaintainLiabilities;

  AllowTrustOperationResponse(
      this.authorize,
      this.authorizeToMaintainLiabilities,
      this.assetIssuer,
      this.assetCode,
      this.assetType,
      this.trustee,
      this.trusteeMuxed,
      this.trusteeMuxedId,
      this.trustor);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  factory AllowTrustOperationResponse.fromJson(Map<String, dynamic> json) =>
      AllowTrustOperationResponse(
          json['authorize'],
          json['authorize_to_maintain_liabilities'],
          json['asset_issuer'],
          json['asset_code'],
          json['asset_type'],
          json['trustee'] == null ? null : json['trustor'],
          json['trustee_muxed'] == null ? null : json['trustee_muxed'],
          json['trustee_muxed_id'] == null ? null : json['trustee_muxed_id'],
          json['trustor'] == null ? null : json['trustor'])
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
