import 'operation_responses.dart';
import '../../assets.dart';

/// Represents the AllowTrust operation response.
/// This operation is deprecated as of Protocol 17. Prefer SetTrustLineFlags instead.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/allow-trust" target="_blank">Operation documentation</a>.
class AllowTrustOperationResponse extends OperationResponse {
  String trustor;
  String trustee;
  String? trusteeMuxed;
  String? trusteeMuxedId;
  String assetType;
  String assetCode;
  String assetIssuer;
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
    return Asset.createNonNativeAsset(assetCode, assetIssuer);
  }

  factory AllowTrustOperationResponse.fromJson(Map<String, dynamic> json) =>
      AllowTrustOperationResponse(
          json['authorize'],
          json['authorize_to_maintain_liabilities'],
          json['asset_issuer'],
          json['asset_code'],
          json['asset_type'],
          json['trustee'],
          json['trustee_muxed'],
          json['trustee_muxed_id'],
          json['trustor'])
        ..id = int.tryParse(json['id'])
        ..sourceAccount = json['source_account']
        ..sourceAccountMuxed = json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id']
        ..pagingToken = json['paging_token']
        ..createdAt = json['created_at']
        ..transactionHash = json['transaction_hash']
        ..transactionSuccessful = json['transaction_successful']
        ..type = json['type']
        ..links = json['_links'] == null
            ? null
            : OperationResponseLinks.fromJson(json['_links']);
}
