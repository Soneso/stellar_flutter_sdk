import 'operation_responses.dart';
import '../response.dart';

/// Represents the ClawbackOperationResponse operation response.
class ClawbackOperationResponse extends OperationResponse {
  String? amount;
  String? from;
  String? fromMuxed;
  String? fromMuxedId;
  String? assetType;
  String? assetCode;
  String? assetIssuer;

  ClawbackOperationResponse(this.amount, this.from, this.fromMuxed, this.fromMuxedId,
      this.assetType, this.assetCode, this.assetIssuer);

  factory ClawbackOperationResponse.fromJson(Map<String, dynamic> json) =>
      ClawbackOperationResponse(
          json['amount'],
          json['from'] == null ? null : json['from'],
          json['from_muxed'] == null ? null : json['from_muxed'],
          json['from_muxed_id'] == null ? null : json['from_muxed_id'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'])
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

/// Represents the ClawbackClaimableBalanceOperationResponse operation response.
class ClawbackClaimableBalanceOperationResponse extends OperationResponse {
  String? balanceId;

  ClawbackClaimableBalanceOperationResponse(this.balanceId);

  factory ClawbackClaimableBalanceOperationResponse.fromJson(Map<String, dynamic> json) =>
      ClawbackClaimableBalanceOperationResponse(
          json['balance_id'] == null ? null : json['balance_id'])
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
