import 'operation_responses.dart';
import '../../assets.dart';
import '../claimable_balance_response.dart';

/// Represents the CreateClaimableBalance operation response.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/create-claimable-balance" target="_blank">Operation documentation</a>
class CreateClaimableBalanceOperationResponse extends OperationResponse {
  String? sponsor; // TODO find out what happened to the sponsor
  Asset asset;
  String amount;
  List<ClaimantResponse> claimants;

  CreateClaimableBalanceOperationResponse(
      this.sponsor, this.asset, this.amount, this.claimants);

  factory CreateClaimableBalanceOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      CreateClaimableBalanceOperationResponse(
          json['sponsor'],
          Asset.createFromCanonicalForm(json['asset'])!,
          json['amount'] == null ? null : json['amount'],
          List<ClaimantResponse>.from(
              json['claimants'].map((e) => ClaimantResponse.fromJson(e))))
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

/// Represents the ClaimClaimableBalance operation response.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/claim-claimable-balance" target="_blank">Operation documentation</a>
class ClaimClaimableBalanceOperationResponse extends OperationResponse {
  String balanceId;
  String claimantAccountId;
  String? claimantMuxed;
  String? claimantMuxedId;

  ClaimClaimableBalanceOperationResponse(this.balanceId, this.claimantAccountId,
      this.claimantMuxed, this.claimantMuxedId);

  factory ClaimClaimableBalanceOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      ClaimClaimableBalanceOperationResponse(json['balance_id'],
          json['claimant'], json['claimant_muxed'], json['claimant_muxed_id'])
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
