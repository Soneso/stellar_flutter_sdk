import '../response.dart';
import 'operation_responses.dart';

/// Represents SetOptions operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class SetOptionsOperationResponse extends OperationResponse {
  int lowThreshold;
  int medThreshold;
  int highThreshold;
  String inflationDestination;
  String homeDomain;
  String signerKey;
  int signerWeight;
  int masterKeyWeight;
  List<String> clearFlags;
  List<String> setFlags;

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

  String get signer {
    return signerKey;
  }

  factory SetOptionsOperationResponse.fromJson(Map<String, dynamic> json) =>
      new SetOptionsOperationResponse(
          convertInt(json['low_threshold']),
          convertInt(json['med_threshold']),
          convertInt(json['high_threshold']),
          json['inflation_dest'] == null
              ? null
              : json['inflation_dest'] as String,
          json['home_domain'] as String,
          json['signer_key'] as String,
          convertInt(json['signer_weight']),
          convertInt(json['master_key_weight']),
          (json['clear_flags_s'] as List)?.map((e) => e as String)?.toList(),
          (json['set_flags_s'] as List)?.map((e) => e as String)?.toList())
        ..id = int.parse(json['id'] as String)
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
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
