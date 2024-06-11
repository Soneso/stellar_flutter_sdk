import 'operation_responses.dart';

/// Represents BumpSequence operation response.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/bump-sequence" target="_blank">Operation documentation</a>
class BumpSequenceOperationResponse extends OperationResponse {
  String bumpTo;

  BumpSequenceOperationResponse(this.bumpTo);

  factory BumpSequenceOperationResponse.fromJson(Map<String, dynamic> json) =>
      BumpSequenceOperationResponse(json['bump_to'])
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
