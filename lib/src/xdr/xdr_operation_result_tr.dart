// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_merge_result.dart';
import 'xdr_allow_trust_result.dart';
import 'xdr_begin_sponsoring_future_reserves_result.dart';
import 'xdr_bump_sequence_result.dart';
import 'xdr_change_trust_result.dart';
import 'xdr_claim_claimable_balance_result.dart';
import 'xdr_clawback_claimable_balance_result.dart';
import 'xdr_clawback_result.dart';
import 'xdr_create_account_result.dart';
import 'xdr_create_claimable_balance_result.dart';
import 'xdr_data_io.dart';
import 'xdr_end_sponsoring_future_reserves_result.dart';
import 'xdr_extend_footprint_ttl_result.dart';
import 'xdr_inflation_result.dart';
import 'xdr_invoke_host_function_result.dart';
import 'xdr_liquidity_pool_deposit_result.dart';
import 'xdr_liquidity_pool_withdraw_result.dart';
import 'xdr_manage_data_result.dart';
import 'xdr_manage_offer_result.dart';
import 'xdr_operation_type.dart';
import 'xdr_path_payment_strict_receive_result.dart';
import 'xdr_path_payment_strict_send_result.dart';
import 'xdr_payment_result.dart';
import 'xdr_restore_footprint_result.dart';
import 'xdr_revoke_sponsorship_result.dart';
import 'xdr_set_options_result.dart';
import 'xdr_set_trust_line_flags_result.dart';

class XdrOperationResultTr {
  XdrOperationResultTr(this._type);
  XdrOperationType _type;
  XdrOperationType get discriminant => this._type;
  set discriminant(XdrOperationType value) => this._type = value;

  XdrCreateAccountResult? _createAccountResult;
  XdrCreateAccountResult? get createAccountResult => this._createAccountResult;
  set createAccountResult(XdrCreateAccountResult? value) =>
      this._createAccountResult = value;

  XdrPaymentResult? _paymentResult;
  XdrPaymentResult? get paymentResult => this._paymentResult;
  set paymentResult(XdrPaymentResult? value) => this._paymentResult = value;

  XdrPathPaymentStrictReceiveResult? _pathPaymentStrictReceiveResult;
  XdrPathPaymentStrictReceiveResult? get pathPaymentStrictReceiveResult =>
      this._pathPaymentStrictReceiveResult;
  set pathPaymentStrictReceiveResult(
    XdrPathPaymentStrictReceiveResult? value,
  ) => this._pathPaymentStrictReceiveResult = value;

  XdrPathPaymentStrictSendResult? _pathPaymentStrictSendResult;
  XdrPathPaymentStrictSendResult? get pathPaymentStrictSendResult =>
      this._pathPaymentStrictSendResult;
  set pathPaymentStrictSendResult(XdrPathPaymentStrictSendResult? value) =>
      this._pathPaymentStrictSendResult = value;

  XdrManageOfferResult? _manageOfferResult;
  XdrManageOfferResult? get manageOfferResult => this._manageOfferResult;
  set manageOfferResult(XdrManageOfferResult? value) =>
      this._manageOfferResult = value;

  XdrManageOfferResult? _createPassiveOfferResult;
  XdrManageOfferResult? get createPassiveOfferResult =>
      this._createPassiveOfferResult;
  set createPassiveOfferResult(XdrManageOfferResult? value) =>
      this._createPassiveOfferResult = value;

  XdrSetOptionsResult? _setOptionsResult;
  XdrSetOptionsResult? get setOptionsResult => this._setOptionsResult;
  set setOptionsResult(XdrSetOptionsResult? value) =>
      this._setOptionsResult = value;

  XdrChangeTrustResult? _changeTrustResult;
  XdrChangeTrustResult? get changeTrustResult => this._changeTrustResult;
  set changeTrustResult(XdrChangeTrustResult? value) =>
      this._changeTrustResult = value;

  XdrAllowTrustResult? _allowTrustResult;
  XdrAllowTrustResult? get allowTrustResult => this._allowTrustResult;
  set allowTrustResult(XdrAllowTrustResult? value) =>
      this._allowTrustResult = value;

  XdrAccountMergeResult? _accountMergeResult;
  XdrAccountMergeResult? get accountMergeResult => this._accountMergeResult;
  set accountMergeResult(XdrAccountMergeResult? value) =>
      this._accountMergeResult = value;

  XdrInflationResult? _inflationResult;
  XdrInflationResult? get inflationResult => this._inflationResult;
  set inflationResult(XdrInflationResult? value) =>
      this._inflationResult = value;

  XdrManageDataResult? _manageDataResult;
  XdrManageDataResult? get manageDataResult => this._manageDataResult;
  set manageDataResult(XdrManageDataResult? value) =>
      this._manageDataResult = value;

  XdrBumpSequenceResult? _bumpSeqResult;
  XdrBumpSequenceResult? get bumpSeqResult => this._bumpSeqResult;
  set bumpSeqResult(XdrBumpSequenceResult? value) =>
      this._bumpSeqResult = value;

  XdrCreateClaimableBalanceResult? _createClaimableBalanceResult;
  XdrCreateClaimableBalanceResult? get createClaimableBalanceResult =>
      this._createClaimableBalanceResult;
  set createClaimableBalanceResult(XdrCreateClaimableBalanceResult? value) =>
      this._createClaimableBalanceResult = value;

  XdrClaimClaimableBalanceResult? _claimClaimableBalanceResult;
  XdrClaimClaimableBalanceResult? get claimClaimableBalanceResult =>
      this._claimClaimableBalanceResult;
  set claimClaimableBalanceResult(XdrClaimClaimableBalanceResult? value) =>
      this._claimClaimableBalanceResult = value;

  XdrBeginSponsoringFutureReservesResult? _beginSponsoringFutureReservesResult;
  XdrBeginSponsoringFutureReservesResult?
  get beginSponsoringFutureReservesResult =>
      this._beginSponsoringFutureReservesResult;
  set beginSponsoringFutureReservesResult(
    XdrBeginSponsoringFutureReservesResult? value,
  ) => this._beginSponsoringFutureReservesResult = value;

  XdrEndSponsoringFutureReservesResult? _endSponsoringFutureReservesResult;
  XdrEndSponsoringFutureReservesResult? get endSponsoringFutureReservesResult =>
      this._endSponsoringFutureReservesResult;
  set endSponsoringFutureReservesResult(
    XdrEndSponsoringFutureReservesResult? value,
  ) => this._endSponsoringFutureReservesResult = value;

  XdrRevokeSponsorshipResult? _revokeSponsorshipResult;
  XdrRevokeSponsorshipResult? get revokeSponsorshipResult =>
      this._revokeSponsorshipResult;
  set revokeSponsorshipResult(XdrRevokeSponsorshipResult? value) =>
      this._revokeSponsorshipResult = value;

  XdrClawbackResult? _clawbackResult;
  XdrClawbackResult? get clawbackResult => this._clawbackResult;
  set clawbackResult(XdrClawbackResult? value) => this._clawbackResult = value;

  XdrClawbackClaimableBalanceResult? _clawbackClaimableBalanceResult;
  XdrClawbackClaimableBalanceResult? get clawbackClaimableBalanceResult =>
      this._clawbackClaimableBalanceResult;
  set clawbackClaimableBalanceResult(
    XdrClawbackClaimableBalanceResult? value,
  ) => this._clawbackClaimableBalanceResult = value;

  XdrSetTrustLineFlagsResult? _setTrustLineFlagsResult;
  XdrSetTrustLineFlagsResult? get setTrustLineFlagsResult =>
      this._setTrustLineFlagsResult;
  set setTrustLineFlagsResult(XdrSetTrustLineFlagsResult? value) =>
      this._setTrustLineFlagsResult = value;

  XdrLiquidityPoolDepositResult? _liquidityPoolDepositResult;
  XdrLiquidityPoolDepositResult? get liquidityPoolDepositResult =>
      this._liquidityPoolDepositResult;
  set liquidityPoolDepositResult(XdrLiquidityPoolDepositResult? value) =>
      this._liquidityPoolDepositResult = value;

  XdrLiquidityPoolWithdrawResult? _liquidityPoolWithdrawResult;
  XdrLiquidityPoolWithdrawResult? get liquidityPoolWithdrawResult =>
      this._liquidityPoolWithdrawResult;
  set liquidityPoolWithdrawResult(XdrLiquidityPoolWithdrawResult? value) =>
      this._liquidityPoolWithdrawResult = value;

  XdrInvokeHostFunctionResult? _invokeHostFunctionResult;
  XdrInvokeHostFunctionResult? get invokeHostFunctionResult =>
      this._invokeHostFunctionResult;
  set invokeHostFunctionResult(XdrInvokeHostFunctionResult? value) =>
      this._invokeHostFunctionResult = value;

  XdrExtendFootprintTTLResult? _bumpExpirationResult;
  XdrExtendFootprintTTLResult? get bumpExpirationResult =>
      this._bumpExpirationResult;
  set bumpExpirationResult(XdrExtendFootprintTTLResult? value) =>
      this._bumpExpirationResult = value;

  XdrRestoreFootprintResult? _restoreFootprintResult;
  XdrRestoreFootprintResult? get restoreFootprintResult =>
      this._restoreFootprintResult;
  set restoreFootprintResult(XdrRestoreFootprintResult? value) =>
      this._restoreFootprintResult = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrOperationResultTr encodedOperationResultTr,
  ) {
    stream.writeInt(encodedOperationResultTr.discriminant.value);
    switch (encodedOperationResultTr.discriminant) {
      case XdrOperationType.CREATE_ACCOUNT:
        XdrCreateAccountResult.encode(
          stream,
          encodedOperationResultTr.createAccountResult!,
        );
        break;
      case XdrOperationType.PAYMENT:
        XdrPaymentResult.encode(
          stream,
          encodedOperationResultTr.paymentResult!,
        );
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE:
        XdrPathPaymentStrictReceiveResult.encode(
          stream,
          encodedOperationResultTr.pathPaymentStrictReceiveResult!,
        );
        break;
      case XdrOperationType.MANAGE_SELL_OFFER:
        XdrManageOfferResult.encode(
          stream,
          encodedOperationResultTr.manageOfferResult!,
        );
        break;
      case XdrOperationType.CREATE_PASSIVE_SELL_OFFER:
        XdrManageOfferResult.encode(
          stream,
          encodedOperationResultTr.createPassiveOfferResult!,
        );
        break;
      case XdrOperationType.SET_OPTIONS:
        XdrSetOptionsResult.encode(
          stream,
          encodedOperationResultTr.setOptionsResult!,
        );
        break;
      case XdrOperationType.CHANGE_TRUST:
        XdrChangeTrustResult.encode(
          stream,
          encodedOperationResultTr.changeTrustResult!,
        );
        break;
      case XdrOperationType.ALLOW_TRUST:
        XdrAllowTrustResult.encode(
          stream,
          encodedOperationResultTr.allowTrustResult!,
        );
        break;
      case XdrOperationType.ACCOUNT_MERGE:
        XdrAccountMergeResult.encode(
          stream,
          encodedOperationResultTr.accountMergeResult!,
        );
        break;
      case XdrOperationType.INFLATION:
        XdrInflationResult.encode(
          stream,
          encodedOperationResultTr.inflationResult!,
        );
        break;
      case XdrOperationType.MANAGE_DATA:
        XdrManageDataResult.encode(
          stream,
          encodedOperationResultTr.manageDataResult!,
        );
        break;
      case XdrOperationType.BUMP_SEQUENCE:
        XdrBumpSequenceResult.encode(
          stream,
          encodedOperationResultTr.bumpSeqResult!,
        );
        break;
      case XdrOperationType.MANAGE_BUY_OFFER:
        XdrManageOfferResult.encode(
          stream,
          encodedOperationResultTr.manageOfferResult!,
        );
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_SEND:
        XdrPathPaymentStrictSendResult.encode(
          stream,
          encodedOperationResultTr.pathPaymentStrictSendResult!,
        );
        break;
      case XdrOperationType.CREATE_CLAIMABLE_BALANCE:
        XdrCreateClaimableBalanceResult.encode(
          stream,
          encodedOperationResultTr.createClaimableBalanceResult!,
        );
        break;
      case XdrOperationType.CLAIM_CLAIMABLE_BALANCE:
        XdrClaimClaimableBalanceResult.encode(
          stream,
          encodedOperationResultTr.claimClaimableBalanceResult!,
        );
        break;
      case XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES:
        XdrBeginSponsoringFutureReservesResult.encode(
          stream,
          encodedOperationResultTr.beginSponsoringFutureReservesResult!,
        );
        break;
      case XdrOperationType.END_SPONSORING_FUTURE_RESERVES:
        XdrEndSponsoringFutureReservesResult.encode(
          stream,
          encodedOperationResultTr.endSponsoringFutureReservesResult!,
        );
        break;
      case XdrOperationType.REVOKE_SPONSORSHIP:
        XdrRevokeSponsorshipResult.encode(
          stream,
          encodedOperationResultTr.revokeSponsorshipResult!,
        );
        break;
      case XdrOperationType.CLAWBACK:
        XdrClawbackResult.encode(
          stream,
          encodedOperationResultTr.clawbackResult!,
        );
        break;
      case XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE:
        XdrClawbackClaimableBalanceResult.encode(
          stream,
          encodedOperationResultTr.clawbackClaimableBalanceResult!,
        );
        break;
      case XdrOperationType.SET_TRUST_LINE_FLAGS:
        XdrSetTrustLineFlagsResult.encode(
          stream,
          encodedOperationResultTr.setTrustLineFlagsResult!,
        );
        break;
      case XdrOperationType.LIQUIDITY_POOL_DEPOSIT:
        XdrLiquidityPoolDepositResult.encode(
          stream,
          encodedOperationResultTr.liquidityPoolDepositResult!,
        );
        break;
      case XdrOperationType.LIQUIDITY_POOL_WITHDRAW:
        XdrLiquidityPoolWithdrawResult.encode(
          stream,
          encodedOperationResultTr.liquidityPoolWithdrawResult!,
        );
        break;
      case XdrOperationType.INVOKE_HOST_FUNCTION:
        XdrInvokeHostFunctionResult.encode(
          stream,
          encodedOperationResultTr.invokeHostFunctionResult!,
        );
        break;
      case XdrOperationType.EXTEND_FOOTPRINT_TTL:
        XdrExtendFootprintTTLResult.encode(
          stream,
          encodedOperationResultTr.bumpExpirationResult!,
        );
        break;
      case XdrOperationType.RESTORE_FOOTPRINT:
        XdrRestoreFootprintResult.encode(
          stream,
          encodedOperationResultTr.restoreFootprintResult!,
        );
        break;
    }
  }

  static XdrOperationResultTr decode(XdrDataInputStream stream) {
    XdrOperationResultTr decodedOperationResultTr = XdrOperationResultTr(
      XdrOperationType.decode(stream),
    );

    switch (decodedOperationResultTr.discriminant) {
      case XdrOperationType.CREATE_ACCOUNT:
        decodedOperationResultTr.createAccountResult =
            XdrCreateAccountResult.decode(stream);
        break;
      case XdrOperationType.PAYMENT:
        decodedOperationResultTr.paymentResult = XdrPaymentResult.decode(
          stream,
        );
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE:
        decodedOperationResultTr.pathPaymentStrictReceiveResult =
            XdrPathPaymentStrictReceiveResult.decode(stream);
        break;
      case XdrOperationType.MANAGE_SELL_OFFER:
        decodedOperationResultTr.manageOfferResult =
            XdrManageOfferResult.decode(stream);
        break;
      case XdrOperationType.CREATE_PASSIVE_SELL_OFFER:
        decodedOperationResultTr.createPassiveOfferResult =
            XdrManageOfferResult.decode(stream);
        break;
      case XdrOperationType.SET_OPTIONS:
        decodedOperationResultTr.setOptionsResult = XdrSetOptionsResult.decode(
          stream,
        );
        break;
      case XdrOperationType.CHANGE_TRUST:
        decodedOperationResultTr.changeTrustResult =
            XdrChangeTrustResult.decode(stream);
        break;
      case XdrOperationType.ALLOW_TRUST:
        decodedOperationResultTr.allowTrustResult = XdrAllowTrustResult.decode(
          stream,
        );
        break;
      case XdrOperationType.ACCOUNT_MERGE:
        decodedOperationResultTr.accountMergeResult =
            XdrAccountMergeResult.decode(stream);
        break;
      case XdrOperationType.INFLATION:
        decodedOperationResultTr.inflationResult = XdrInflationResult.decode(
          stream,
        );
        break;
      case XdrOperationType.MANAGE_DATA:
        decodedOperationResultTr.manageDataResult = XdrManageDataResult.decode(
          stream,
        );
        break;
      case XdrOperationType.BUMP_SEQUENCE:
        decodedOperationResultTr.bumpSeqResult = XdrBumpSequenceResult.decode(
          stream,
        );
        break;
      case XdrOperationType.MANAGE_BUY_OFFER:
        decodedOperationResultTr.manageOfferResult =
            XdrManageOfferResult.decode(stream);
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_SEND:
        decodedOperationResultTr.pathPaymentStrictSendResult =
            XdrPathPaymentStrictSendResult.decode(stream);
        break;
      case XdrOperationType.CREATE_CLAIMABLE_BALANCE:
        decodedOperationResultTr.createClaimableBalanceResult =
            XdrCreateClaimableBalanceResult.decode(stream);
        break;
      case XdrOperationType.CLAIM_CLAIMABLE_BALANCE:
        decodedOperationResultTr.claimClaimableBalanceResult =
            XdrClaimClaimableBalanceResult.decode(stream);
        break;
      case XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES:
        decodedOperationResultTr.beginSponsoringFutureReservesResult =
            XdrBeginSponsoringFutureReservesResult.decode(stream);
        break;
      case XdrOperationType.END_SPONSORING_FUTURE_RESERVES:
        decodedOperationResultTr.endSponsoringFutureReservesResult =
            XdrEndSponsoringFutureReservesResult.decode(stream);
        break;
      case XdrOperationType.REVOKE_SPONSORSHIP:
        decodedOperationResultTr.revokeSponsorshipResult =
            XdrRevokeSponsorshipResult.decode(stream);
        break;
      case XdrOperationType.CLAWBACK:
        decodedOperationResultTr.clawbackResult = XdrClawbackResult.decode(
          stream,
        );
        break;
      case XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE:
        decodedOperationResultTr.clawbackClaimableBalanceResult =
            XdrClawbackClaimableBalanceResult.decode(stream);
        break;
      case XdrOperationType.SET_TRUST_LINE_FLAGS:
        decodedOperationResultTr.setTrustLineFlagsResult =
            XdrSetTrustLineFlagsResult.decode(stream);
        break;
      case XdrOperationType.LIQUIDITY_POOL_DEPOSIT:
        decodedOperationResultTr.liquidityPoolDepositResult =
            XdrLiquidityPoolDepositResult.decode(stream);
        break;
      case XdrOperationType.LIQUIDITY_POOL_WITHDRAW:
        decodedOperationResultTr.liquidityPoolWithdrawResult =
            XdrLiquidityPoolWithdrawResult.decode(stream);
        break;
      case XdrOperationType.INVOKE_HOST_FUNCTION:
        decodedOperationResultTr.invokeHostFunctionResult =
            XdrInvokeHostFunctionResult.decode(stream);
        break;
      case XdrOperationType.EXTEND_FOOTPRINT_TTL:
        decodedOperationResultTr.bumpExpirationResult =
            XdrExtendFootprintTTLResult.decode(stream);
        break;
      case XdrOperationType.RESTORE_FOOTPRINT:
        decodedOperationResultTr.restoreFootprintResult =
            XdrRestoreFootprintResult.decode(stream);
        break;
    }
    return decodedOperationResultTr;
  }
}
