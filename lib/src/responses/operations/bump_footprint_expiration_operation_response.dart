import 'operation_responses.dart';
import '../response.dart';

/// Represents BumpFootprintExpirationOperation response.
class BumpFootprintExpirationOperationResponse extends OperationResponse {
  int ledgersToExpire;

  BumpFootprintExpirationOperationResponse(this.ledgersToExpire);

  factory BumpFootprintExpirationOperationResponse.fromJson(Map<String, dynamic> json) =>
      BumpFootprintExpirationOperationResponse(convertInt(json['ledgers_to_expire'])!)
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
