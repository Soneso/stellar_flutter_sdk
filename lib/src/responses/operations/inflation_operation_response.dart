import 'operation_responses.dart';

/// Represents Inflation operation response.
/// See: <a href="https://www.stellar.org/developers/horizon/reference/resources/operation.html" target="_blank">Operation documentation</a>
class InflationOperationResponse extends OperationResponse {
  InflationOperationResponse();

  factory InflationOperationResponse.fromJson(Map<String, dynamic> json) =>
      new InflationOperationResponse()
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
