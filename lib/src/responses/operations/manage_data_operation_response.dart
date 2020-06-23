import 'operation_responses.dart';

/// Represents ManageDataOperation response.
/// See: <a href="https://www.stellar.org/developers/horizon/reference/resources/operation.html" target="_blank">Operation documentation</a>
class ManageDataOperationResponse extends OperationResponse {
  String name;
  String value;

  ManageDataOperationResponse(this.name, this.value);

  factory ManageDataOperationResponse.fromJson(Map<String, dynamic> json) =>
      new ManageDataOperationResponse(
          json['name'] as String, json['value'] as String)
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
