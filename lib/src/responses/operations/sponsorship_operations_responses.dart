// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents the BeginSponsoringFutureReserves operation response.
/// See: [Begin Sponsoring Future Reserves](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/begin-sponsoring-future-reserves)
class BeginSponsoringFutureReservesOperationResponse extends OperationResponse {
  String sponsoredId;

  BeginSponsoringFutureReservesOperationResponse(
      this.sponsoredId,
      super.links,
      super.id,
      super.pagingToken,
      super.transactionSuccessful,
      super.sourceAccount,
      super.sourceAccountMuxed,
      super.sourceAccountMuxedId,
      super.type,
      super.type_i,
      super.createdAt,
      super.transactionHash,
      super.transaction,
      super.sponsor);

  factory BeginSponsoringFutureReservesOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      BeginSponsoringFutureReservesOperationResponse(
          json['sponsored_id'],
          OperationResponseLinks.fromJson(json['_links']),
          json['id'],
          json['paging_token'],
          json['transaction_successful'],
          json['source_account'],
          json['source_account_muxed'],
          json['source_account_muxed_id'],
          json['type'],
          json['type_i'],
          json['created_at'],
          json['transaction_hash'],
          json['transaction'] == null
              ? null
              : TransactionResponse.fromJson(json['transaction']),
          json['sponsor']);
}

/// Represents the EndSponsoringFutureReserves operation response.
/// See: [End Sponsoring Future Reserves](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/end-sponsoring-future-reserves)
class EndSponsoringFutureReservesOperationResponse extends OperationResponse {
  String? beginSponsor;
  String? beginSponsorMuxed;
  String? beginSponsorMuxedId;

  EndSponsoringFutureReservesOperationResponse(
      this.beginSponsor,
      this.beginSponsorMuxed,
      this.beginSponsorMuxedId,
      super.links,
      super.id,
      super.pagingToken,
      super.transactionSuccessful,
      super.sourceAccount,
      super.sourceAccountMuxed,
      super.sourceAccountMuxedId,
      super.type,
      super.type_i,
      super.createdAt,
      super.transactionHash,
      super.transaction,
      super.sponsor);

  factory EndSponsoringFutureReservesOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      EndSponsoringFutureReservesOperationResponse(
          json['begin_sponsor'],
          json['begin_sponsor_muxed'],
          json['begin_sponsor_muxed_id'],
          OperationResponseLinks.fromJson(json['_links']),
          json['id'],
          json['paging_token'],
          json['transaction_successful'],
          json['source_account'],
          json['source_account_muxed'],
          json['source_account_muxed_id'],
          json['type'],
          json['type_i'],
          json['created_at'],
          json['transaction_hash'],
          json['transaction'] == null
              ? null
              : TransactionResponse.fromJson(json['transaction']),
          json['sponsor']);
}

/// Represents the RevokeSponsorship operation response.
/// See: [Operation documentation](https://developers.stellar.org/network/horizon/api-reference/resources/operations/object/revoke-sponsorship)
class RevokeSponsorshipOperationResponse extends OperationResponse {
  String? accountId;
  String? claimableBalanceId;
  String? dataAccountId;
  String? dataName;
  String? offerId;
  String? trustlineAccountId;
  String? trustlineLiquidityPoolID;
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
      this.trustlineLiquidityPoolID,
      this.trustlineAsset,
      this.signerAccountId,
      this.signerKey,
      super.links,
      super.id,
      super.pagingToken,
      super.transactionSuccessful,
      super.sourceAccount,
      super.sourceAccountMuxed,
      super.sourceAccountMuxedId,
      super.type,
      super.type_i,
      super.createdAt,
      super.transactionHash,
      super.transaction,
      super.sponsor);

  factory RevokeSponsorshipOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      RevokeSponsorshipOperationResponse(
          json['account_id'],
          json['claimable_balance_id'],
          json['data_account_id'],
          json['data_name'],
          json['offer_id'],
          json['trustline_account_id'],
          json['trustline_liquidity_pool_id'],
          json['trustline_asset'],
          json['signer_account_id'],
          json['signer_key'],
          OperationResponseLinks.fromJson(json['_links']),
          json['id'],
          json['paging_token'],
          json['transaction_successful'],
          json['source_account'],
          json['source_account_muxed'],
          json['source_account_muxed_id'],
          json['type'],
          json['type_i'],
          json['created_at'],
          json['transaction_hash'],
          json['transaction'] == null
              ? null
              : TransactionResponse.fromJson(json['transaction']),
          json['sponsor']);
}
