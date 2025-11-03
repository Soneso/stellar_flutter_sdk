// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../response.dart';
import '../transaction_response.dart';
import 'account_merge_operation_response.dart';
import 'allow_trust_operation_response.dart';
import 'bump_sequence_operation_response.dart';
import 'change_trust_operation_response.dart';
import 'create_account_operation_response.dart';
import 'create_passive_sell_offer_response.dart';
import 'inflation_operation_response.dart';
import 'manage_data_operation_response.dart';
import 'manage_buy_offer_operation_response.dart';
import 'manage_sell_offer_operation_response.dart';
import 'path_payment_strict_receive_operation_response.dart';
import 'path_payment_strict_send_operation_response.dart';
import 'payment_operation_response.dart';
import 'set_options_operation_response.dart';
import 'claimable_balances_operations_responses.dart';
import 'sponsorship_operations_responses.dart';
import 'clawback_operations_responses.dart';
import 'set_trustline_flags_operation_response.dart';
import 'liquidity_pool_operations_responses.dart';
import 'invoke_host_function_operation_response.dart';
import 'extend_footprint_ttl_operation_response.dart';
import 'restore_footprint_operation_response.dart';

/// Abstract class for operation responses.
/// See: [Operation documentation](https://developers.stellar.org/api/resources/operations/)
/// See: https://github.com/stellar/go/blob/master/protocols/horizon/operations/main.go
abstract class OperationResponse extends Response {
  OperationResponseLinks links;
  String id;
  String pagingToken;
  bool transactionSuccessful;
  String sourceAccount;
  String? sourceAccountMuxed;
  String? sourceAccountMuxedId;
  String type;
  int type_i;
  String createdAt;
  String transactionHash;
  TransactionResponse? transaction;
  String? sponsor;

  OperationResponse(
      this.links,
      this.id,
      this.pagingToken,
      this.transactionSuccessful,
      this.sourceAccount,
      this.sourceAccountMuxed,
      this.sourceAccountMuxedId,
      this.type,
      this.type_i,
      this.createdAt,
      this.transactionHash,
      this.transaction,
      this.sponsor);

  factory OperationResponse.fromJson(Map<String, dynamic> json) {
    int type = json["type_i"];
    switch (type) {
      case 0:
        return CreateAccountOperationResponse.fromJson(json);
      case 1:
        return PaymentOperationResponse.fromJson(json);
      case 2:
        return PathPaymentStrictReceiveOperationResponse.fromJson(json);
      case 3:
        return ManageSellOfferOperationResponse.fromJson(json);
      case 4:
        return CreatePassiveSellOfferOperationResponse.fromJson(json);
      case 5:
        return SetOptionsOperationResponse.fromJson(json);
      case 6:
        return ChangeTrustOperationResponse.fromJson(json);
      case 7:
        return AllowTrustOperationResponse.fromJson(json);
      case 8:
        return AccountMergeOperationResponse.fromJson(json);
      case 9:
        return InflationOperationResponse.fromJson(json);
      case 10:
        return ManageDataOperationResponse.fromJson(json);
      case 11:
        return BumpSequenceOperationResponse.fromJson(json);
      case 12:
        return ManageBuyOfferOperationResponse.fromJson(json);
      case 13:
        return PathPaymentStrictSendOperationResponse.fromJson(json);
      case 14:
        return CreateClaimableBalanceOperationResponse.fromJson(json);
      case 15:
        return ClaimClaimableBalanceOperationResponse.fromJson(json);
      case 16:
        return BeginSponsoringFutureReservesOperationResponse.fromJson(json);
      case 17:
        return EndSponsoringFutureReservesOperationResponse.fromJson(json);
      case 18:
        return RevokeSponsorshipOperationResponse.fromJson(json);
      case 19:
        return ClawbackOperationResponse.fromJson(json);
      case 20:
        return ClawbackClaimableBalanceOperationResponse.fromJson(json);
      case 21:
        return SetTrustlineFlagsOperationResponse.fromJson(json);
      case 22:
        return LiquidityPoolDepositOperationResponse.fromJson(json);
      case 23:
        return LiquidityPoolWithdrawOperationResponse.fromJson(json);
      case 24:
        return InvokeHostFunctionOperationResponse.fromJson(json);
      case 25:
        return ExtendFootprintTTLOperationResponse.fromJson(json);
      case 26:
        return RestoreFootprintOperationResponse.fromJson(json);
      default:
        throw Exception("Unknown operation type $type in horizon response");
    }
  }
}

/// Represents the operation response links.
class OperationResponseLinks {
  Link effects;
  Link precedes;
  Link self;
  Link succeeds;
  Link transaction;

  OperationResponseLinks(
      this.effects, this.precedes, this.self, this.succeeds, this.transaction);

  factory OperationResponseLinks.fromJson(Map<String, dynamic> json) =>
      OperationResponseLinks(
          Link.fromJson(json['effects']),
          Link.fromJson(json['precedes']),
          Link.fromJson(json['self']),
          Link.fromJson(json['succeeds']),
          Link.fromJson(json['transaction']));
}
