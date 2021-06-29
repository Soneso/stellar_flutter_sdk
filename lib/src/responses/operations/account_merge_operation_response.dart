import '../response.dart';
import 'operation_responses.dart';

/// Represents the AccountMerge operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class AccountMergeOperationResponse extends OperationResponse {
  String account;
  String accountMuxed;
  String accountMuxedId;
  String into;
  String intoMuxed;
  String intoMuxedId;

  AccountMergeOperationResponse(this.account, this.accountMuxed,
      this.accountMuxedId, this.into, this.intoMuxed, this.intoMuxedId);

  factory AccountMergeOperationResponse.fromJson(Map<String, dynamic> json) =>
      new AccountMergeOperationResponse(
          json['account'] == null ? null : json['account'],
          json['account_muxed'] == null ? null : json['account_muxed'],
          json['account_muxed_id'] == null
              ? null
              : json['account_muxed_id'] as String,
          json['into'] == null ? null : json['into'],
          json['into_muxed'] == null ? null : json['into_muxed'],
          json['into_muxed_id'] == null
              ? null
              : json['into_muxed_id'] as String)
        ..id = int.parse(json['id'] as String)
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed = json['source_account_muxed'] == null
            ? null
            : json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id'] == null
            ? null
            : json['source_account_muxed_id'] as String
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
