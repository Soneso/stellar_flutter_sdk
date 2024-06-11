import 'operation_responses.dart';

/// Represents the AccountMerge operation response.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/account-merge" target="_blank">Operation documentation</a>
class AccountMergeOperationResponse extends OperationResponse {
  String account;
  String? accountMuxed;
  String? accountMuxedId;
  String into;
  String? intoMuxed;
  String? intoMuxedId;

  AccountMergeOperationResponse(this.account, this.accountMuxed,
      this.accountMuxedId, this.into, this.intoMuxed, this.intoMuxedId);

  factory AccountMergeOperationResponse.fromJson(Map<String, dynamic> json) =>
      AccountMergeOperationResponse(
          json['account'],
          json['account_muxed'],
          json['account_muxed_id'],
          json['into'],
          json['into_muxed'],
          json['into_muxed_id'])
        ..id = int.parse(json['id'])
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
