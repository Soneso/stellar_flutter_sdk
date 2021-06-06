import 'operation_responses.dart';
import '../response.dart';

/// Represents the ClawbackOperationResponse operation response.
class ClawbackOperationResponse extends OperationResponse {
  String amount;
  String from;
  String fromMuxed;
  int fromMuxedId;
  String assetType;
  String assetCode;
  String assetIssuer;

  ClawbackOperationResponse(this.amount, this.from, this.fromMuxed,
      this.fromMuxedId, this.assetType, this.assetCode, this.assetIssuer);

  factory ClawbackOperationResponse.fromJson(Map<String, dynamic> json) =>
      new ClawbackOperationResponse(
          json['amount'] as String,
          json['from'] == null ? null : json['from'] as String,
          json['from_muxed'] == null ? null : json['from_muxed'],
          json['from_muxed_id'] == null
              ? null
              : convertInt(json['from_muxed_id']),
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String)
        ..id = int.parse(json['id'] as String)
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed = json['source_account_muxed'] == null
            ? null
            : json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id'] == null
            ? null
            : convertInt(json['source_account_muxed_id'])
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

/// Represents the ClawbackClaimableBalanceOperationResponse operation response.
class ClawbackClaimableBalanceOperationResponse extends OperationResponse {
  String balanceId;

  ClawbackClaimableBalanceOperationResponse(this.balanceId);

  factory ClawbackClaimableBalanceOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      new ClawbackClaimableBalanceOperationResponse(
          json['balance_id'] == null ? null : json['balance_id'] as String)
        ..id = int.parse(json['id'] as String)
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed = json['source_account_muxed'] == null
            ? null
            : json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id'] == null
            ? null
            : convertInt(json['source_account_muxed_id'])
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
