import '../response.dart';
import 'operation_responses.dart';

/// Represents SetOptions operation response.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/set-options" target="_blank">Operation documentation</a>
class SetOptionsOperationResponse extends OperationResponse {
  int? lowThreshold;
  int? medThreshold;
  int? highThreshold;
  String? inflationDestination;
  String? homeDomain;
  String? signerKey;
  int? signerWeight;
  int? masterKeyWeight;
  List<String>? clearFlags;
  List<String>? setFlags;

  SetOptionsOperationResponse(
      this.lowThreshold,
      this.medThreshold,
      this.highThreshold,
      this.inflationDestination,
      this.homeDomain,
      this.signerKey,
      this.signerWeight,
      this.masterKeyWeight,
      this.clearFlags,
      this.setFlags);

  String? get signer {
    return signerKey;
  }

  factory SetOptionsOperationResponse.fromJson(Map<String, dynamic> json) =>
      SetOptionsOperationResponse(
        convertInt(json['low_threshold']),
        convertInt(json['med_threshold']),
        convertInt(json['high_threshold']),
        json['inflation_dest'] == null ? null : json['inflation_dest'],
        json['home_domain'],
        json['signer_key'],
        convertInt(json['signer_weight']),
        convertInt(json['master_key_weight']),
        json['clear_flags_s'] != null
            ? List<String>.from(json['clear_flags_s'].map((e) => e))
            : null,
        json['set_flags_s'] != null
            ? List<String>.from(json['set_flags_s'].map((e) => e))
            : null,
      )
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
