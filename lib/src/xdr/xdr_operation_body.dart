// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_allow_trust_op.dart';
import 'xdr_begin_sponsoring_future_reserves_op.dart';
import 'xdr_bump_sequence_op.dart';
import 'xdr_change_trust_op.dart';
import 'xdr_claim_claimable_balance_op.dart';
import 'xdr_clawback_claimable_balance_op.dart';
import 'xdr_clawback_op.dart';
import 'xdr_create_account_op.dart';
import 'xdr_create_claimable_balance_op.dart';
import 'xdr_create_passive_sell_offer_op.dart';
import 'xdr_data_io.dart';
import 'xdr_extend_footprint_ttl_op.dart';
import 'xdr_invoke_host_function_op.dart';
import 'xdr_liquidity_pool_deposit_op.dart';
import 'xdr_liquidity_pool_withdraw_op.dart';
import 'xdr_manage_buy_offer_op.dart';
import 'xdr_manage_data_op.dart';
import 'xdr_manage_sell_offer_op.dart';
import 'xdr_muxed_account.dart';
import 'xdr_operation_type.dart';
import 'xdr_path_payment_strict_receive_op.dart';
import 'xdr_path_payment_strict_send_op.dart';
import 'xdr_payment_op.dart';
import 'xdr_restore_footprint_op.dart';
import 'xdr_revoke_sponsorship_op.dart';
import 'xdr_set_options_op.dart';
import 'xdr_set_trust_line_flags_op.dart';

class XdrOperationBody {
  XdrOperationBody(this._type);
  XdrOperationType _type;
  XdrOperationType get discriminant => this._type;
  set discriminant(XdrOperationType value) => this._type = value;

  XdrCreateAccountOp? _createAccountOp;
  XdrCreateAccountOp? get createAccountOp => this._createAccountOp;
  set createAccountOp(XdrCreateAccountOp? value) =>
      this._createAccountOp = value;

  XdrPaymentOp? _paymentOp;
  XdrPaymentOp? get paymentOp => this._paymentOp;
  set paymentOp(XdrPaymentOp? value) => this._paymentOp = value;

  XdrPathPaymentStrictReceiveOp? _pathPaymentStrictReceiveOp;
  XdrPathPaymentStrictReceiveOp? get pathPaymentStrictReceiveOp =>
      this._pathPaymentStrictReceiveOp;
  set pathPaymentStrictReceiveOp(XdrPathPaymentStrictReceiveOp? value) =>
      this._pathPaymentStrictReceiveOp = value;

  XdrPathPaymentStrictSendOp? _pathPaymentStrictSendOp;
  XdrPathPaymentStrictSendOp? get pathPaymentStrictSendOp =>
      this._pathPaymentStrictSendOp;
  set pathPaymentStrictSendOp(XdrPathPaymentStrictSendOp? value) =>
      this._pathPaymentStrictSendOp = value;

  XdrManageBuyOfferOp? _manageBuyOfferOp;
  XdrManageBuyOfferOp? get manageBuyOfferOp => this._manageBuyOfferOp;
  set manageBuyOfferOp(XdrManageBuyOfferOp? value) =>
      this._manageBuyOfferOp = value;

  XdrManageSellOfferOp? _manageSellOfferOp;
  XdrManageSellOfferOp? get manageSellOfferOp => this._manageSellOfferOp;
  set manageSellOfferOp(XdrManageSellOfferOp? value) =>
      this._manageSellOfferOp = value;

  XdrCreatePassiveSellOfferOp? _createPassiveSellOfferOp;
  XdrCreatePassiveSellOfferOp? get createPassiveSellOfferOp =>
      this._createPassiveSellOfferOp;
  set createPassiveOfferOp(XdrCreatePassiveSellOfferOp? value) =>
      this._createPassiveSellOfferOp = value;

  XdrSetOptionsOp? _setOptionsOp;
  XdrSetOptionsOp? get setOptionsOp => this._setOptionsOp;
  set setOptionsOp(XdrSetOptionsOp? value) => this._setOptionsOp = value;

  XdrChangeTrustOp? _changeTrustOp;
  XdrChangeTrustOp? get changeTrustOp => this._changeTrustOp;
  set changeTrustOp(XdrChangeTrustOp? value) => this._changeTrustOp = value;

  XdrAllowTrustOp? _allowTrustOp;
  XdrAllowTrustOp? get allowTrustOp => this._allowTrustOp;
  set allowTrustOp(XdrAllowTrustOp? value) => this._allowTrustOp = value;

  XdrMuxedAccount? _destination;
  XdrMuxedAccount? get destination => this._destination;
  set destination(XdrMuxedAccount? value) => this._destination = value;

  XdrManageDataOp? _manageDataOp;
  XdrManageDataOp? get manageDataOp => this._manageDataOp;
  set manageDataOp(XdrManageDataOp? value) => this._manageDataOp = value;

  XdrBumpSequenceOp? _bumpSequenceOp;
  XdrBumpSequenceOp? get bumpSequenceOp => this._bumpSequenceOp;
  set bumpSequenceOp(XdrBumpSequenceOp? value) => this._bumpSequenceOp = value;

  XdrCreateClaimableBalanceOp? _createClaimableBalanceOp;
  XdrCreateClaimableBalanceOp? get createClaimableBalanceOp =>
      this._createClaimableBalanceOp;
  set createClaimableBalanceOp(XdrCreateClaimableBalanceOp? value) =>
      this._createClaimableBalanceOp = value;

  XdrClaimClaimableBalanceOp? _claimClaimableBalanceOp;
  XdrClaimClaimableBalanceOp? get claimClaimableBalanceOp =>
      this._claimClaimableBalanceOp;
  set claimClaimableBalanceOp(XdrClaimClaimableBalanceOp? value) =>
      this._claimClaimableBalanceOp = value;

  XdrBeginSponsoringFutureReservesOp? _beginSponsoringFutureReservesOp;
  XdrBeginSponsoringFutureReservesOp? get beginSponsoringFutureReservesOp =>
      this._beginSponsoringFutureReservesOp;
  set beginSponsoringFutureReservesOp(
          XdrBeginSponsoringFutureReservesOp? value) =>
      this._beginSponsoringFutureReservesOp = value;

  XdrRevokeSponsorshipOp? _revokeSponsorshipOp;
  XdrRevokeSponsorshipOp? get revokeSponsorshipOp => this._revokeSponsorshipOp;
  set revokeSponsorshipOp(XdrRevokeSponsorshipOp? value) =>
      this._revokeSponsorshipOp = value;

  XdrClawbackOp? _clawbackOp;
  XdrClawbackOp? get clawbackOp => this._clawbackOp;
  set clawbackOp(XdrClawbackOp? value) => this._clawbackOp = value;

  XdrClawbackClaimableBalanceOp? _clawbackClaimableBalanceOp;
  XdrClawbackClaimableBalanceOp? get clawbackClaimableBalanceOp =>
      this._clawbackClaimableBalanceOp;
  set clawbackClaimableBalanceOp(XdrClawbackClaimableBalanceOp? value) =>
      this._clawbackClaimableBalanceOp = value;

  XdrSetTrustLineFlagsOp? _setTrustLineFlagsOp;
  XdrSetTrustLineFlagsOp? get setTrustLineFlagsOp => this._setTrustLineFlagsOp;
  set setTrustLineFlagsOp(XdrSetTrustLineFlagsOp? value) =>
      this._setTrustLineFlagsOp = value;

  XdrLiquidityPoolDepositOp? _liquidityPoolDepositOp;
  XdrLiquidityPoolDepositOp? get liquidityPoolDepositOp =>
      this._liquidityPoolDepositOp;
  set liquidityPoolDepositOp(XdrLiquidityPoolDepositOp? value) =>
      this._liquidityPoolDepositOp = value;

  XdrLiquidityPoolWithdrawOp? _liquidityPoolWithdrawOp;
  XdrLiquidityPoolWithdrawOp? get liquidityPoolWithdrawOp =>
      this._liquidityPoolWithdrawOp;
  set liquidityPoolWithdrawOp(XdrLiquidityPoolWithdrawOp? value) =>
      this._liquidityPoolWithdrawOp = value;

  XdrInvokeHostFunctionOp? _invokeHostFunctionOp;
  XdrInvokeHostFunctionOp? get invokeHostFunctionOp =>
      this._invokeHostFunctionOp;
  set invokeHostFunctionOp(XdrInvokeHostFunctionOp? value) =>
      this._invokeHostFunctionOp = value;

  XdrExtendFootprintTTLOp? _bumpExpirationOp;
  XdrExtendFootprintTTLOp? get bumpExpirationOp => this._bumpExpirationOp;
  set bumpExpirationOp(XdrExtendFootprintTTLOp? value) =>
      this._bumpExpirationOp = value;

  XdrRestoreFootprintOp? _restoreFootprintOp;
  XdrRestoreFootprintOp? get restoreFootprintOp => this._restoreFootprintOp;
  set restoreFootprintOp(XdrRestoreFootprintOp? value) =>
      this._restoreFootprintOp = value;

  static void encode(
      XdrDataOutputStream stream, XdrOperationBody encodedOperationBody) {
    stream.writeInt(encodedOperationBody.discriminant.value);
    switch (encodedOperationBody.discriminant) {
      case XdrOperationType.CREATE_ACCOUNT:
        XdrCreateAccountOp.encode(
            stream, encodedOperationBody.createAccountOp!);
        break;
      case XdrOperationType.PAYMENT:
        XdrPaymentOp.encode(stream, encodedOperationBody.paymentOp!);
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE:
        XdrPathPaymentStrictReceiveOp.encode(
            stream, encodedOperationBody.pathPaymentStrictReceiveOp!);
        break;
      case XdrOperationType.MANAGE_SELL_OFFER:
        XdrManageSellOfferOp.encode(
            stream, encodedOperationBody.manageSellOfferOp!);
        break;
      case XdrOperationType.CREATE_PASSIVE_SELL_OFFER:
        XdrCreatePassiveSellOfferOp.encode(
            stream, encodedOperationBody.createPassiveSellOfferOp!);
        break;
      case XdrOperationType.SET_OPTIONS:
        XdrSetOptionsOp.encode(stream, encodedOperationBody.setOptionsOp!);
        break;
      case XdrOperationType.CHANGE_TRUST:
        XdrChangeTrustOp.encode(stream, encodedOperationBody.changeTrustOp!);
        break;
      case XdrOperationType.ALLOW_TRUST:
        XdrAllowTrustOp.encode(stream, encodedOperationBody.allowTrustOp!);
        break;
      case XdrOperationType.ACCOUNT_MERGE:
        XdrMuxedAccount.encode(stream, encodedOperationBody.destination!);
        break;
      case XdrOperationType.INFLATION:
        break;
      case XdrOperationType.MANAGE_DATA:
        XdrManageDataOp.encode(stream, encodedOperationBody.manageDataOp!);
        break;
      case XdrOperationType.BUMP_SEQUENCE:
        XdrBumpSequenceOp.encode(stream, encodedOperationBody.bumpSequenceOp!);
        break;
      case XdrOperationType.MANAGE_BUY_OFFER:
        XdrManageBuyOfferOp.encode(
            stream, encodedOperationBody.manageBuyOfferOp!);
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_SEND:
        XdrPathPaymentStrictSendOp.encode(
            stream, encodedOperationBody.pathPaymentStrictSendOp!);
        break;
      case XdrOperationType.CREATE_CLAIMABLE_BALANCE:
        XdrCreateClaimableBalanceOp.encode(
            stream, encodedOperationBody.createClaimableBalanceOp!);
        break;
      case XdrOperationType.CLAIM_CLAIMABLE_BALANCE:
        XdrClaimClaimableBalanceOp.encode(
            stream, encodedOperationBody.claimClaimableBalanceOp!);
        break;
      case XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES:
        XdrBeginSponsoringFutureReservesOp.encode(
            stream, encodedOperationBody.beginSponsoringFutureReservesOp!);
        break;
      case XdrOperationType.END_SPONSORING_FUTURE_RESERVES:
        break;
      case XdrOperationType.REVOKE_SPONSORSHIP:
        XdrRevokeSponsorshipOp.encode(
            stream, encodedOperationBody.revokeSponsorshipOp!);
        break;
      case XdrOperationType.CLAWBACK:
        XdrClawbackOp.encode(stream, encodedOperationBody.clawbackOp!);
        break;
      case XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE:
        XdrClawbackClaimableBalanceOp.encode(
            stream, encodedOperationBody.clawbackClaimableBalanceOp!);
        break;
      case XdrOperationType.SET_TRUST_LINE_FLAGS:
        XdrSetTrustLineFlagsOp.encode(
            stream, encodedOperationBody.setTrustLineFlagsOp!);
        break;
      case XdrOperationType.LIQUIDITY_POOL_DEPOSIT:
        XdrLiquidityPoolDepositOp.encode(
            stream, encodedOperationBody.liquidityPoolDepositOp!);
        break;
      case XdrOperationType.LIQUIDITY_POOL_WITHDRAW:
        XdrLiquidityPoolWithdrawOp.encode(
            stream, encodedOperationBody.liquidityPoolWithdrawOp!);
        break;
      case XdrOperationType.INVOKE_HOST_FUNCTION:
        XdrInvokeHostFunctionOp.encode(
            stream, encodedOperationBody.invokeHostFunctionOp!);
        break;
      case XdrOperationType.EXTEND_FOOTPRINT_TTL:
        XdrExtendFootprintTTLOp.encode(
            stream, encodedOperationBody.bumpExpirationOp!);
        break;
      case XdrOperationType.RESTORE_FOOTPRINT:
        XdrRestoreFootprintOp.encode(
            stream, encodedOperationBody.restoreFootprintOp!);
        break;
    }
  }

  static XdrOperationBody decode(XdrDataInputStream stream) {
    XdrOperationBody decodedOperationBody =
        XdrOperationBody(XdrOperationType.decode(stream));
    switch (decodedOperationBody.discriminant) {
      case XdrOperationType.CREATE_ACCOUNT:
        decodedOperationBody.createAccountOp =
            XdrCreateAccountOp.decode(stream);
        break;
      case XdrOperationType.PAYMENT:
        decodedOperationBody.paymentOp = XdrPaymentOp.decode(stream);
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE:
        decodedOperationBody.pathPaymentStrictReceiveOp =
            XdrPathPaymentStrictReceiveOp.decode(stream);
        break;
      case XdrOperationType.MANAGE_SELL_OFFER:
        decodedOperationBody.manageSellOfferOp =
            XdrManageSellOfferOp.decode(stream);
        break;
      case XdrOperationType.CREATE_PASSIVE_SELL_OFFER:
        decodedOperationBody.createPassiveOfferOp =
            XdrCreatePassiveSellOfferOp.decode(stream);
        break;
      case XdrOperationType.SET_OPTIONS:
        decodedOperationBody.setOptionsOp = XdrSetOptionsOp.decode(stream);
        break;
      case XdrOperationType.CHANGE_TRUST:
        decodedOperationBody.changeTrustOp = XdrChangeTrustOp.decode(stream);
        break;
      case XdrOperationType.ALLOW_TRUST:
        decodedOperationBody.allowTrustOp = XdrAllowTrustOp.decode(stream);
        break;
      case XdrOperationType.ACCOUNT_MERGE:
        decodedOperationBody.destination = XdrMuxedAccount.decode(stream);
        break;
      case XdrOperationType.INFLATION:
        break;
      case XdrOperationType.MANAGE_DATA:
        decodedOperationBody.manageDataOp = XdrManageDataOp.decode(stream);
        break;
      case XdrOperationType.BUMP_SEQUENCE:
        decodedOperationBody.bumpSequenceOp = XdrBumpSequenceOp.decode(stream);
        break;
      case XdrOperationType.MANAGE_BUY_OFFER:
        decodedOperationBody.manageBuyOfferOp =
            XdrManageBuyOfferOp.decode(stream);
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_SEND:
        decodedOperationBody.pathPaymentStrictSendOp =
            XdrPathPaymentStrictSendOp.decode(stream);
        break;
      case XdrOperationType.CREATE_CLAIMABLE_BALANCE:
        decodedOperationBody.createClaimableBalanceOp =
            XdrCreateClaimableBalanceOp.decode(stream);
        break;
      case XdrOperationType.CLAIM_CLAIMABLE_BALANCE:
        decodedOperationBody.claimClaimableBalanceOp =
            XdrClaimClaimableBalanceOp.decode(stream);
        break;
      case XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES:
        decodedOperationBody.beginSponsoringFutureReservesOp =
            XdrBeginSponsoringFutureReservesOp.decode(stream);
        break;
      case XdrOperationType.END_SPONSORING_FUTURE_RESERVES:
        break;
      case XdrOperationType.REVOKE_SPONSORSHIP:
        decodedOperationBody.revokeSponsorshipOp =
            XdrRevokeSponsorshipOp.decode(stream);
        break;
      case XdrOperationType.CLAWBACK:
        decodedOperationBody.clawbackOp = XdrClawbackOp.decode(stream);
        break;
      case XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE:
        decodedOperationBody.clawbackClaimableBalanceOp =
            XdrClawbackClaimableBalanceOp.decode(stream);
        break;
      case XdrOperationType.SET_TRUST_LINE_FLAGS:
        decodedOperationBody.setTrustLineFlagsOp =
            XdrSetTrustLineFlagsOp.decode(stream);
        break;
      case XdrOperationType.LIQUIDITY_POOL_DEPOSIT:
        decodedOperationBody.liquidityPoolDepositOp =
            XdrLiquidityPoolDepositOp.decode(stream);
        break;
      case XdrOperationType.LIQUIDITY_POOL_WITHDRAW:
        decodedOperationBody.liquidityPoolWithdrawOp =
            XdrLiquidityPoolWithdrawOp.decode(stream);
        break;
      case XdrOperationType.INVOKE_HOST_FUNCTION:
        decodedOperationBody.invokeHostFunctionOp =
            XdrInvokeHostFunctionOp.decode(stream);
        break;
      case XdrOperationType.EXTEND_FOOTPRINT_TTL:
        decodedOperationBody.bumpExpirationOp =
            XdrExtendFootprintTTLOp.decode(stream);
        break;
      case XdrOperationType.RESTORE_FOOTPRINT:
        decodedOperationBody.restoreFootprintOp =
            XdrRestoreFootprintOp.decode(stream);
        break;
    }
    return decodedOperationBody;
  }
}
