import 'operation_responses.dart';

/// Represents CreateAccount operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>.
class CreateAccountOperationResponse extends OperationResponse {
  String account;
  String funder;
  String startingBalance;

  CreateAccountOperationResponse(
      this.funder, this.startingBalance, this.account);

  factory CreateAccountOperationResponse.fromJson(Map<String, dynamic> json) =>
      new CreateAccountOperationResponse(
          json['funder'] == null ? null : json['funder'],
          json['starting_balance'] as String,
          json['account'] == null ? null : json['account'])
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
