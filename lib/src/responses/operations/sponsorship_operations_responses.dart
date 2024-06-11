import 'operation_responses.dart';

/// Represents the BeginSponsoringFutureReserves operation response.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/begin-sponsoring-future-reserves" target="_blank">Operation documentation</a>
class BeginSponsoringFutureReservesOperationResponse extends OperationResponse {
  String sponsoredId;

  BeginSponsoringFutureReservesOperationResponse(this.sponsoredId);

  factory BeginSponsoringFutureReservesOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      BeginSponsoringFutureReservesOperationResponse(json['sponsored_id'])
        ..id = int.tryParse(json['id'])
        ..sourceAccount = json['source_account']
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

/// Represents the EndSponsoringFutureReserves operation response.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/end-sponsoring-future-reserves" target="_blank">Operation documentation</a>
class EndSponsoringFutureReservesOperationResponse extends OperationResponse {
  String beginSponsor;
  String? beginSponsorMuxed;
  String? beginSponsorMuxedId;

  EndSponsoringFutureReservesOperationResponse(
      this.beginSponsor, this.beginSponsorMuxed, this.beginSponsorMuxedId);

  factory EndSponsoringFutureReservesOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      EndSponsoringFutureReservesOperationResponse(json['begin_sponsor'],
          json['begin_sponsor_muxed'], json['begin_sponsor_muxed_id'])
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

/// Represents the RevokeSponsorship operation response.
/// See: <a href="https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/revoke-sponsorship" target="_blank">Operation documentation</a>
class RevokeSponsorshipOperationResponse extends OperationResponse {
  String? accountId;
  String? claimableBalanceId;
  String? dataAccountId;
  String? dataName;
  String? offerId;
  String? trustlineAccountId;
  String? trustlineAsset;
  String? signerAccountId;
  String? signerKey;

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
      RevokeSponsorshipOperationResponse(
          json['account_id'],
          json['claimable_balance_id'],
          json['data_account_id'],
          json['data_name'],
          json['offer_id'],
          json['trustline_account_id'],
          json['trustline_asset'],
          json['signer_account_id'],
          json['signer_key'])
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
