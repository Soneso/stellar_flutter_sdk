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
      new CreateClaimableBalanceOperationResponse(
          json['sponsor'] == null ? null : json['sponsor'] as String,
          json['asset'] == null ? null : Asset.createFromCanonicalForm(json['asset'] as String),
          json['amount'] == null ? null : json['amount'] as String,
          (json['claimants'] as List)
              .map((e) =>
                  e == null ? null : new ClaimantResponse.fromJson(e as Map<String, dynamic>))
              .toList())
        ..id = int.parse(json['id'] as String)
        ..sourceAccount = json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed =
            json['source_account_muxed'] == null ? null : json['source_account_muxed']
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
            : new OperationResponseLinks.fromJson(json['_links'] as Map<String, dynamic>);
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
      new ClaimClaimableBalanceOperationResponse(
          json['balance_id'] == null ? null : json['balance_id'] as String,
          json['claimant'] == null ? null : json['claimant'] as String,
          json['claimant_muxed'] == null ? null : json['claimant_muxed'],
          json['claimant_muxed_id'] == null ? null : json['claimant_muxed_id'] as String)
        ..id = int.parse(json['id'] as String)
        ..sourceAccount = json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed =
            json['source_account_muxed'] == null ? null : json['source_account_muxed']
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
            : new OperationResponseLinks.fromJson(json['_links'] as Map<String, dynamic>);
}
