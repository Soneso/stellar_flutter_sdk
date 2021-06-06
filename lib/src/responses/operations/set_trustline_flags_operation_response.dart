import 'operation_responses.dart';
import '../response.dart';

/// Represents the SetTrustlineFlagsOperationResponse operation response.
class SetTrustlineFlagsOperationResponse extends OperationResponse {
  String trustor;
  String assetType;
  String assetCode;
  String assetIssuer;
  List<String> clearFlags;
  List<String> setFlags;

  SetTrustlineFlagsOperationResponse(this.trustor, this.assetType,
      this.assetCode, this.assetIssuer, this.clearFlags, this.setFlags);

  factory SetTrustlineFlagsOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      new SetTrustlineFlagsOperationResponse(
          json['trustor'] == null ? null : json['from'] as String,
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String,
          (json['clear_flags_s'] as List)?.map((e) => e as String)?.toList(),
          (json['set_flags_s'] as List)?.map((e) => e as String)?.toList())
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
