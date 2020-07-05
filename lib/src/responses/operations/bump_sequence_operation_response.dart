import 'operation_responses.dart';

/// Represents BumpSequence operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class BumpSequenceOperationResponse extends OperationResponse {
  int bumpTo;

  BumpSequenceOperationResponse(this.bumpTo);

  factory BumpSequenceOperationResponse.fromJson(Map<String, dynamic> json) =>
      new BumpSequenceOperationResponse(int.parse(json['bump_to'] as String))
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
