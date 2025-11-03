// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents a begin sponsoring future reserves operation response from Horizon.
///
/// This operation begins sponsorship of future reserve requirements for another account.
/// Reserve sponsorship allows one account to pay the base reserves for another account's
/// entries (trustlines, offers, signers, data entries, etc.).
///
/// Returned by: Horizon API operations endpoint when querying begin sponsoring future reserves operations
///
/// Fields:
/// - [sponsoredId]: The account whose future reserves will be sponsored
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('sponsor_account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is BeginSponsoringFutureReservesOperationResponse) {
///     print('Sponsoring reserves for: ${op.sponsoredId}');
///   }
/// }
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] for creating sponsorship operations
/// - [Horizon Begin Sponsoring Future Reserves](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/begin-sponsoring-future-reserves)
class BeginSponsoringFutureReservesOperationResponse extends OperationResponse {
  /// The account whose future reserves will be sponsored
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

/// Represents an end sponsoring future reserves operation response from Horizon.
///
/// This operation terminates the current sponsorship relationship that was initiated
/// by a begin sponsoring future reserves operation.
///
/// Returned by: Horizon API operations endpoint when querying end sponsoring future reserves operations
///
/// Fields:
/// - [beginSponsor]: The account that initiated the sponsorship
/// - [beginSponsorMuxed]: Muxed account representation of the sponsor (if applicable)
/// - [beginSponsorMuxedId]: Muxed account ID of the sponsor (if applicable)
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is EndSponsoringFutureReservesOperationResponse) {
///     print('Ended sponsorship from: ${op.beginSponsor}');
///   }
/// }
/// ```
///
/// See also:
/// - [EndSponsoringFutureReservesOperation] for ending sponsorship
/// - [Horizon End Sponsoring Future Reserves](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/end-sponsoring-future-reserves)
class EndSponsoringFutureReservesOperationResponse extends OperationResponse {
  /// The account that initiated the sponsorship
  String? beginSponsor;

  /// Muxed account representation of the sponsor (if applicable)
  String? beginSponsorMuxed;

  /// Muxed account ID of the sponsor (if applicable)
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

/// Represents a revoke sponsorship operation response from Horizon.
///
/// This operation revokes sponsorship of a ledger entry (account, trustline, offer,
/// data entry, claimable balance, or signer). One of the entry type fields will be
/// populated depending on the type of entry being revoked.
///
/// Returned by: Horizon API operations endpoint when querying revoke sponsorship operations
///
/// Fields:
/// - [accountId]: Account ID if sponsoring an account
/// - [claimableBalanceId]: Balance ID if sponsoring a claimable balance
/// - [dataAccountId]: Account ID if sponsoring a data entry
/// - [dataName]: Data entry name if sponsoring a data entry
/// - [offerId]: Offer ID if sponsoring an offer
/// - [trustlineAccountId]: Account ID if sponsoring a trustline
/// - [trustlineLiquidityPoolID]: Pool ID if sponsoring a liquidity pool trustline
/// - [trustlineAsset]: Asset if sponsoring a trustline
/// - [signerAccountId]: Account ID if sponsoring a signer
/// - [signerKey]: Signer key if sponsoring a signer
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('sponsor_account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is RevokeSponsorshipOperationResponse) {
///     if (op.accountId != null) print('Revoked account sponsorship: ${op.accountId}');
///     if (op.trustlineAccountId != null) print('Revoked trustline sponsorship');
///   }
/// }
/// ```
///
/// See also:
/// - [RevokeSponsorshipOperation] for revoking sponsorship
/// - [Horizon Revoke Sponsorship](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/revoke-sponsorship)
class RevokeSponsorshipOperationResponse extends OperationResponse {
  /// Account ID if sponsoring an account
  String? accountId;

  /// Balance ID if sponsoring a claimable balance
  String? claimableBalanceId;

  /// Account ID if sponsoring a data entry
  String? dataAccountId;

  /// Data entry name if sponsoring a data entry
  String? dataName;

  /// Offer ID if sponsoring an offer
  String? offerId;

  /// Account ID if sponsoring a trustline
  String? trustlineAccountId;

  /// Pool ID if sponsoring a liquidity pool trustline
  String? trustlineLiquidityPoolID;

  /// Asset if sponsoring a trustline
  String? trustlineAsset;

  /// Account ID if sponsoring a signer
  String? signerAccountId;

  /// Signer key if sponsoring a signer
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
