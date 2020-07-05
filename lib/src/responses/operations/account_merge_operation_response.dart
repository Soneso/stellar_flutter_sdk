import 'operation_responses.dart';

/// Represents the AccountMerge operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class AccountMergeOperationResponse extends OperationResponse {
  String account;
  String into;

  AccountMergeOperationResponse(this.account, this.into);

  factory AccountMergeOperationResponse.fromJson(Map<String, dynamic> json) =>
      new AccountMergeOperationResponse(
          json['account'] == null ? null : json['account'],
          json['into'] == null ? null : json['into'])
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
