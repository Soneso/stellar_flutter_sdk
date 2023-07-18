import 'operation_responses.dart';

/// Represents RestoreFootprintOperation response.
class RestoreFootprintOperationResponse extends OperationResponse {

  RestoreFootprintOperationResponse();

  factory RestoreFootprintOperationResponse.fromJson(Map<String, dynamic> json) =>
      RestoreFootprintOperationResponse()
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