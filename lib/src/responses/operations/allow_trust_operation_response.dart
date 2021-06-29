import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../response.dart';

/// Represents the AllowTrust operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>.
class AllowTrustOperationResponse extends OperationResponse {
  String trustor;
  String trustee;
  String trusteeMuxed;
  String trusteeMuxedId;
  String assetType;
  String assetCode;
  String assetIssuer;
  bool authorize;
  bool authorizeToMaintainLiabilities;

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
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }

  factory AllowTrustOperationResponse.fromJson(Map<String, dynamic> json) =>
      new AllowTrustOperationResponse(
          json['authorize'] as bool,
          json['authorize_to_maintain_liabilities'] as bool,
          json['asset_issuer'] as String,
          json['asset_code'] as String,
          json['asset_type'] as String,
          json['trustee'] == null ? null : json['trustor'],
          json['trustee_muxed'] == null ? null : json['trustee_muxed'],
          json['trustee_muxed_id'] == null
              ? null
              : json['trustee_muxed_id'] as String,
          json['trustor'] == null ? null : json['trustor'])
        ..id = int.parse(json['id'] as String)
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed = json['source_account_muxed'] == null
            ? null
            : json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id'] == null
            ? null
            : json['source_account_muxed_id'] as String
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
