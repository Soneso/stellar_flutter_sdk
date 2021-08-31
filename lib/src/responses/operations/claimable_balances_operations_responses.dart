import 'operation_responses.dart';
import '../../assets.dart';
import '../claimable_balance_response.dart';
import '../response.dart';

/// Represents the CreateClaimableBalance operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class CreateClaimableBalanceOperationResponse extends OperationResponse {
  String? sponsor;
  Asset? asset;
  String? amount;
  List<ClaimantResponse?>? claimants;

  CreateClaimableBalanceOperationResponse(this.sponsor, this.asset, this.amount, this.claimants);

  factory CreateClaimableBalanceOperationResponse.fromJson(Map<String, dynamic> json) =>
      CreateClaimableBalanceOperationResponse(
          json['sponsor'] == null ? null : json['sponsor'],
          json['asset'] == null ? null : Asset.createFromCanonicalForm(json['asset']),
          json['amount'] == null ? null : json['amount'],
          json['claimants'] != null
              ? List<ClaimantResponse?>.from(
                  json['claimants'].map((e) => e == null ? null : ClaimantResponse.fromJson(e)))
              : null)
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

/// Represents the ClaimClaimableBalance operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class ClaimClaimableBalanceOperationResponse extends OperationResponse {
  String? balanceId;
  String? claimantAccountId;
  String? claimantMuxed;
  String? claimantMuxedId;

  ClaimClaimableBalanceOperationResponse(
      this.balanceId, this.claimantAccountId, this.claimantMuxed, this.claimantMuxedId);

  factory ClaimClaimableBalanceOperationResponse.fromJson(Map<String, dynamic> json) =>
      ClaimClaimableBalanceOperationResponse(
          json['balance_id'] == null ? null : json['balance_id'],
          json['claimant'] == null ? null : json['claimant'],
          json['claimant_muxed'] == null ? null : json['claimant_muxed'],
          json['claimant_muxed_id'] == null ? null : json['claimant_muxed_id'])
        ..id = int.parse(json['id'])
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
