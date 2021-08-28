import 'operation_responses.dart';
import '../response.dart';

/// Represents the BeginSponsoringFutureReserves operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class BeginSponsoringFutureReservesOperationResponse extends OperationResponse {
  String? sponsoredId;

  BeginSponsoringFutureReservesOperationResponse(this.sponsoredId);

  factory BeginSponsoringFutureReservesOperationResponse.fromJson(Map<String, dynamic> json) =>
      BeginSponsoringFutureReservesOperationResponse(
          json['sponsored_id'] == null ? null : json['balance_id'])
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

/// Represents the EndSponsoringFutureReserves operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class EndSponsoringFutureReservesOperationResponse extends OperationResponse {
  String? beginSponsor;
  String? beginSponsorMuxed;
  String? beginSponsorMuxedId;

  EndSponsoringFutureReservesOperationResponse(
      this.beginSponsor, this.beginSponsorMuxed, this.beginSponsorMuxedId);

  factory EndSponsoringFutureReservesOperationResponse.fromJson(Map<String, dynamic> json) =>
      EndSponsoringFutureReservesOperationResponse(
          json['begin_sponsor'] == null ? null : json['begin_sponsor'],
          json['begin_sponsor_muxed'] == null ? null : json['begin_sponsor_muxed'],
          json['begin_sponsor_muxed_id'] == null ? null : json['begin_sponsor_muxed_id'])
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

/// Represents the RevokeSponsorship operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
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

  factory RevokeSponsorshipOperationResponse.fromJson(Map<String, dynamic> json) =>
      RevokeSponsorshipOperationResponse(
          json['begin_sponsor'] == null ? null : json['begin_sponsor'],
          json['claimable_balance_id'] == null ? null : json['claimable_balance_id'],
          json['data_account_id'] == null ? null : json['data_account_id'],
          json['data_name'] == null ? null : json['data_name'],
          json['offer_id'] == null ? null : json['offer_id'],
          json['trustline_account_id'] == null ? null : json['trustline_account_id'],
          json['trustline_asset'] == null ? null : json['trustline_asset'],
          json['signer_account_id'] == null ? null : json['signer_account_id'],
          json['signer_key'] == null ? null : json['signer_key'])
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
