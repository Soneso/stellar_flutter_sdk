import 'operation_responses.dart';
import '../response.dart';

/// Represents the SetTrustlineFlagsOperationResponse operation response.
class SetTrustlineFlagsOperationResponse extends OperationResponse {
  String? trustor;
  String? assetType;
  String? assetCode;
  String? assetIssuer;
  List<String?>? clearFlags;
  List<String?>? setFlags;

  SetTrustlineFlagsOperationResponse(this.trustor, this.assetType, this.assetCode, this.assetIssuer,
      this.clearFlags, this.setFlags);

  factory SetTrustlineFlagsOperationResponse.fromJson(Map<String, dynamic> json) =>
      SetTrustlineFlagsOperationResponse(
        json['trustor'] == null ? null : json['from'],
        json['asset_type'],
        json['asset_code'],
        json['asset_issuer'],
        json['clear_flags_s'] != null
            ? List<String?>.from(json['clear_flags_s'].map((e) => e == null ? null : e))
            : null,
        json['set_flags_s'] != null
            ? List<String?>.from(json['set_flags_s'].map((e) => e == null ? null : e))
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
