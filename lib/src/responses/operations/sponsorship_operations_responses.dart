import 'operation_responses.dart';

/// Represents the BeginSponsoringFutureReserves operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class BeginSponsoringFutureReservesOperationResponse extends OperationResponse {
  String sponsoredId;

  BeginSponsoringFutureReservesOperationResponse(this.sponsoredId);

  factory BeginSponsoringFutureReservesOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      new BeginSponsoringFutureReservesOperationResponse(
          json['sponsored_id'] == null ? null : json['balance_id'] as String)
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

/// Represents the EndSponsoringFutureReserves operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class EndSponsoringFutureReservesOperationResponse extends OperationResponse {
  String beginSponsor;

  EndSponsoringFutureReservesOperationResponse(this.beginSponsor);

  factory EndSponsoringFutureReservesOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      new EndSponsoringFutureReservesOperationResponse(
          json['begin_sponsor'] == null
              ? null
              : json['begin_sponsor'] as String)
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

/// Represents the RevokeSponsorship operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class RevokeSponsorshipOperationResponse extends OperationResponse {
  String accountId;
  String claimableBalanceId;
  String dataAccountId;
  String dataName;
  String offerId;
  String trustlineAccountId;
  String trustlineAsset;
  String signerAccountId;
  String signerKey;

  RevokeSponsorshipOperationResponse(
      this.accountId,
      this.claimableBalanceId,
      this.dataAccountId,
      this.dataName,
      this.offerId,
      this.trustlineAccountId,
      this.trustlineAsset,
      this.signerAccountId,
      this.signerKey);

  factory RevokeSponsorshipOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      new RevokeSponsorshipOperationResponse(
          json['begin_sponsor'] == null
              ? null
              : json['begin_sponsor'] as String,
          json['claimable_balance_id'] == null
              ? null
              : json['claimable_balance_id'] as String,
          json['data_account_id'] == null
              ? null
              : json['data_account_id'] as String,
          json['data_name'] == null ? null : json['data_name'] as String,
          json['offer_id'] == null ? null : json['offer_id'] as String,
          json['trustline_account_id'] == null
              ? null
              : json['trustline_account_id'] as String,
          json['trustline_asset'] == null
              ? null
              : json['trustline_asset'] as String,
          json['signer_account_id'] == null
              ? null
              : json['signer_account_id'] as String,
          json['signer_key'] == null ? null : json['signer_key'] as String)
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
