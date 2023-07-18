// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'muxed_account.dart';
import 'xdr/xdr_data_io.dart';
import 'xdr/xdr_operation.dart';
import 'create_account_operation.dart';
import 'payment_operation.dart';
import 'path_payment_strict_receive_operation.dart';
import 'path_payment_strict_send_operation.dart';
import 'manage_buy_offer_operation.dart';
import 'manage_sell_offer_operation.dart';
import 'create_passive_sell_offer_operation.dart';
import 'set_options_operation.dart';
import 'change_trust_operation.dart';
import 'allow_trust_operation.dart';
import 'account_merge_operation.dart';
import 'manage_data_operation.dart';
import 'bump_sequence_operation.dart';
import 'price.dart';
import 'begin_sponsoring_future_reserves_operation.dart';
import 'end_sponsoring_future_reserves_operation.dart';
import 'create_claimable_balance_operation.dart';
import 'claim_claimable_balance_operation.dart';
import 'revoke_sponsorship_operation.dart';
import 'clawback_operation.dart';
import 'clawback_claimable_balance_operation.dart';
import 'set_trustline_flags_operation.dart';
import 'liquidity_pool_deposit_operation.dart';
import 'liquidity_pool_withdraw_operation.dart';
import 'invoke_host_function_operation.dart';
import 'bump_footprint_expiration_operation.dart';
import 'restore_footprint_operation.dart';

/// Abstract class for operations.
abstract class Operation {
  Operation();

  MuxedAccount? sourceAccount;

  static final BigInt one = BigInt.from(10).pow(7);

  static int toXdrAmount(String value) {
    List<String> two = value.split(".");
    BigInt amount = BigInt.parse(two[0]) * BigInt.from(10000000);

    if (two.length == 2) {
      int pos = 0;
      String point = two[1];
      for (int i = point.length - 1; i >= 0; i--) {
        if (point[i] == '0')
          pos++;
        else
          break;
      }
      point = point.substring(0, point.length - pos);
      int length = 7 - point.length;
      if (length < 0)
        throw Exception("The decimal point cannot exceed seven digits.");
      for (; length > 0; length--) point += "0";
      amount += BigInt.parse(point);
    }

    return amount.toInt();
  }

  static String fromXdrAmount(int value) {
    String amoutString = value.toString();
    if (amoutString.length > 7) {
      amoutString = amoutString.substring(0, amoutString.length - 7) +
          "." +
          amoutString.substring(amoutString.length - 7, amoutString.length);
    } else {
      int length = 7 - amoutString.length;
      String point = "0.";
      for (; length > 0; length--) point += "0";
      amoutString = point + amoutString;
    }
    return removeTailZero(amoutString);
  }

  // Generates an Operation XDR object from this operation.
  XdrOperation toXdr() {
    XdrOperation xdrOp = XdrOperation(toOperationBody());
    if (sourceAccount != null) {
      xdrOp.sourceAccount = sourceAccount?.toXdr();
    }
    return xdrOp;
  }

  /// Returns base64-encoded Operation XDR object from this operation.
  String toXdrBase64() {
    try {
      XdrOperation operation = this.toXdr();
      var xdrOutputStream = XdrDataOutputStream();
      XdrOperation.encode(xdrOutputStream, operation);
      return base64Encode(xdrOutputStream.data);
    } catch (e) {
      throw AssertionError(e);
    }
  }

  /// Returns Operation object from an Operation XDR object [xdrOp].
  static Operation fromXdr(XdrOperation xdrOp) {
    XdrOperationBody body = xdrOp.body;
    Operation operation;
    switch (body.discriminant) {
      case XdrOperationType.CREATE_ACCOUNT:
        operation =
            CreateAccountOperation.builder(body.createAccountOp!).build();
        break;
      case XdrOperationType.PAYMENT:
        operation = PaymentOperation.builder(body.paymentOp!).build();
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE:
        operation = PathPaymentStrictReceiveOperation.builder(
                body.pathPaymentStrictReceiveOp!)
            .build();
        break;
      case XdrOperationType.MANAGE_SELL_OFFER:
        operation =
            ManageSellOfferOperation.builder(body.manageSellOfferOp!).build();
        break;
      case XdrOperationType.CREATE_PASSIVE_SELL_OFFER:
        operation = CreatePassiveSellOfferOperation.builder(
                body.createPassiveSellOfferOp!)
            .build();
        break;
      case XdrOperationType.SET_OPTIONS:
        operation = SetOptionsOperation.builder(body.setOptionsOp!).build();
        break;
      case XdrOperationType.CHANGE_TRUST:
        operation = ChangeTrustOperation.builder(body.changeTrustOp!).build();
        break;
      case XdrOperationType.ALLOW_TRUST:
        operation = AllowTrustOperation.builder(body.allowTrustOp!).build();
        break;
      case XdrOperationType.ACCOUNT_MERGE:
        operation = AccountMergeOperation.builder(body).build();
        break;
      case XdrOperationType.MANAGE_DATA:
        operation = ManageDataOperation.builder(body.manageDataOp!).build();
        break;
      case XdrOperationType.BUMP_SEQUENCE:
        operation = BumpSequenceOperation.builder(body.bumpSequenceOp!).build();
        break;
      case XdrOperationType.MANAGE_BUY_OFFER:
        operation =
            ManageBuyOfferOperation.builder(body.manageBuyOfferOp!).build();
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_SEND:
        operation = PathPaymentStrictSendOperation.builder(
                body.pathPaymentStrictSendOp!)
            .build();
        break;
      case XdrOperationType.CREATE_CLAIMABLE_BALANCE:
        operation = CreateClaimableBalanceOperation.builder(
                body.createClaimableBalanceOp!)
            .build();
        break;
      case XdrOperationType.CLAIM_CLAIMABLE_BALANCE:
        operation = ClaimClaimableBalanceOperation.builder(
                body.claimClaimableBalanceOp!)
            .build();
        break;
      case XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES:
        final op = BeginSponsoringFutureReservesOperation.builder(
            body.beginSponsoringFutureReservesOp!);
        operation =
            BeginSponsoringFutureReservesOperationBuilder(op.sponsoredId)
                .build();
        break;
      case XdrOperationType.END_SPONSORING_FUTURE_RESERVES:
        operation = EndSponsoringFutureReservesOperationBuilder().build();
        break;
      case XdrOperationType.REVOKE_SPONSORSHIP:
        operation =
            RevokeSponsorshipOperation.fromXdr(body.revokeSponsorshipOp!)!;
        break;
      case XdrOperationType.CLAWBACK:
        operation = ClawbackOperation.builder(body.clawbackOp!).build();
        break;
      case XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE:
        operation = ClawbackClaimableBalanceOperation.builder(
                body.clawbackClaimableBalanceOp!)
            .build();
        break;
      case XdrOperationType.SET_TRUST_LINE_FLAGS:
        operation =
            SetTrustLineFlagsOperation.builder(body.setTrustLineFlagsOp!)
                .build();
        break;
      case XdrOperationType.LIQUIDITY_POOL_DEPOSIT:
        operation =
            LiquidityPoolDepositOperation.builder(body.liquidityPoolDepositOp!)
                .build();
        break;
      case XdrOperationType.LIQUIDITY_POOL_WITHDRAW:
        operation = LiquidityPoolWithdrawOperation.builder(
                body.liquidityPoolWithdrawOp!)
            .build();
        break;
      case XdrOperationType.INVOKE_HOST_FUNCTION:
        operation =
            InvokeHostFunctionOperation.builder(body.invokeHostFunctionOp!)
                .build();
        break;
      case XdrOperationType.BUMP_FOOTPRINT_EXPIRATION:
        operation =
            BumpFootprintExpirationOperation.builder(body.bumpExpirationOp!)
                .build();
        break;
      case XdrOperationType.RESTORE_FOOTPRINT:
        operation =
            RestoreFootprintOperation.builder(body.restoreFootprintOp!)
                .build();
        break;
      default:
        throw Exception("Unknown operation body ${body.discriminant}");
    }
    if (xdrOp.sourceAccount != null) {
      operation.sourceAccount = MuxedAccount.fromXdr(xdrOp.sourceAccount!);
    }
    return operation;
  }

  /// Generates OperationBody XDR object.
  XdrOperationBody toOperationBody();
}
