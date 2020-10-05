// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_payment.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger.dart';
import 'xdr_offer.dart';
import 'xdr_account.dart';
import 'xdr_trustline.dart';

class XdrOperationType {
  final _value;
  const XdrOperationType._internal(this._value);
  toString() => 'OperationType.$_value';
  XdrOperationType(this._value);
  get value => this._value;

  static const CREATE_ACCOUNT = const XdrOperationType._internal(0);
  static const PAYMENT = const XdrOperationType._internal(1);
  static const PATH_PAYMENT_STRICT_RECEIVE =
      const XdrOperationType._internal(2);
  static const MANAGE_SELL_OFFER = const XdrOperationType._internal(3);
  static const CREATE_PASSIVE_SELL_OFFER = const XdrOperationType._internal(4);
  static const SET_OPTIONS = const XdrOperationType._internal(5);
  static const CHANGE_TRUST = const XdrOperationType._internal(6);
  static const ALLOW_TRUST = const XdrOperationType._internal(7);
  static const ACCOUNT_MERGE = const XdrOperationType._internal(8);
  static const INFLATION = const XdrOperationType._internal(9);
  static const MANAGE_DATA = const XdrOperationType._internal(10);
  static const BUMP_SEQUENCE = const XdrOperationType._internal(11);
  static const MANAGE_BUY_OFFER = const XdrOperationType._internal(12);
  static const PATH_PAYMENT_STRICT_SEND = const XdrOperationType._internal(13);
  static const CREATE_CLAIMABLE_BALANCE = const XdrOperationType._internal(14);
  static const CLAIM_CLAIMABLE_BALANCE = const XdrOperationType._internal(15);
  static const BEGIN_SPONSORING_FUTURE_RESERVES =
      const XdrOperationType._internal(16);
  static const END_SPONSORING_FUTURE_RESERVES =
      const XdrOperationType._internal(17);
  static const REVOKE_SPONSORSHIP = const XdrOperationType._internal(18);

  static XdrOperationType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CREATE_ACCOUNT;
      case 1:
        return PAYMENT;
      case 2:
        return PATH_PAYMENT_STRICT_RECEIVE;
      case 3:
        return MANAGE_SELL_OFFER;
      case 4:
        return CREATE_PASSIVE_SELL_OFFER;
      case 5:
        return SET_OPTIONS;
      case 6:
        return CHANGE_TRUST;
      case 7:
        return ALLOW_TRUST;
      case 8:
        return ACCOUNT_MERGE;
      case 9:
        return INFLATION;
      case 10:
        return MANAGE_DATA;
      case 11:
        return BUMP_SEQUENCE;
      case 12:
        return MANAGE_BUY_OFFER;
      case 13:
        return PATH_PAYMENT_STRICT_SEND;
      case 14:
        return CREATE_CLAIMABLE_BALANCE;
      case 15:
        return CLAIM_CLAIMABLE_BALANCE;
      case 16:
        return BEGIN_SPONSORING_FUTURE_RESERVES;
      case 17:
        return END_SPONSORING_FUTURE_RESERVES;
      case 18:
        return REVOKE_SPONSORSHIP;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrOperationType value) {
    stream.writeInt(value.value);
  }
}

class XdrOperation {
  XdrOperation();
  XdrMuxedAccount _sourceAccount;
  XdrMuxedAccount get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrMuxedAccount value) => this._sourceAccount = value;

  XdrOperationBody _body;
  XdrOperationBody get body => this._body;
  set body(XdrOperationBody value) => this._body = value;

  static void encode(
      XdrDataOutputStream stream, XdrOperation encodedOperation) {
    if (encodedOperation.sourceAccount != null) {
      stream.writeInt(1);
      XdrMuxedAccount.encode(stream, encodedOperation.sourceAccount);
    } else {
      stream.writeInt(0);
    }
    XdrOperationBody.encode(stream, encodedOperation.body);
  }

  static XdrOperation decode(XdrDataInputStream stream) {
    XdrOperation decodedOperation = XdrOperation();
    int sourceAccountPresent = stream.readInt();
    if (sourceAccountPresent != 0) {
      decodedOperation.sourceAccount = XdrMuxedAccount.decode(stream);
    }
    decodedOperation.body = XdrOperationBody.decode(stream);
    return decodedOperation;
  }
}

class XdrOperationBody {
  XdrOperationBody();
  XdrOperationType _type;
  XdrOperationType get discriminant => this._type;
  set discriminant(XdrOperationType value) => this._type = value;

  XdrCreateAccountOp _createAccountOp;
  XdrCreateAccountOp get createAccountOp => this._createAccountOp;
  set createAccountOp(XdrCreateAccountOp value) =>
      this._createAccountOp = value;

  XdrPaymentOp _paymentOp;
  XdrPaymentOp get paymentOp => this._paymentOp;
  set paymentOp(XdrPaymentOp value) => this._paymentOp = value;

  XdrPathPaymentStrictReceiveOp _pathPaymentStrictReceiveOp;
  XdrPathPaymentStrictReceiveOp get pathPaymentStrictReceiveOp =>
      this._pathPaymentStrictReceiveOp;
  set pathPaymentStrictReceiveOp(XdrPathPaymentStrictReceiveOp value) =>
      this._pathPaymentStrictReceiveOp = value;

  XdrPathPaymentStrictSendOp _pathPaymentStrictSendOp;
  XdrPathPaymentStrictSendOp get pathPaymentStrictSendOp =>
      this._pathPaymentStrictSendOp;
  set pathPaymentStrictSendOp(XdrPathPaymentStrictSendOp value) =>
      this._pathPaymentStrictSendOp = value;

  XdrManageBuyOfferOp _manageBuyOfferOp;
  XdrManageBuyOfferOp get manageBuyOfferOp => this._manageBuyOfferOp;
  set manageBuyOfferOp(XdrManageBuyOfferOp value) =>
      this._manageBuyOfferOp = value;

  XdrManageSellOfferOp _manageSellOfferOp;
  XdrManageSellOfferOp get manageSellOfferOp => this._manageSellOfferOp;
  set manageSellOfferOp(XdrManageSellOfferOp value) =>
      this._manageSellOfferOp = value;

  XdrCreatePassiveSellOfferOp _createPassiveSellOfferOp;
  XdrCreatePassiveSellOfferOp get createPassiveSellOfferOp =>
      this._createPassiveSellOfferOp;
  set createPassiveOfferOp(XdrCreatePassiveSellOfferOp value) =>
      this._createPassiveSellOfferOp = value;

  XdrSetOptionsOp _setOptionsOp;
  XdrSetOptionsOp get setOptionsOp => this._setOptionsOp;
  set setOptionsOp(XdrSetOptionsOp value) => this._setOptionsOp = value;

  XdrChangeTrustOp _changeTrustOp;
  XdrChangeTrustOp get changeTrustOp => this._changeTrustOp;
  set changeTrustOp(XdrChangeTrustOp value) => this._changeTrustOp = value;

  XdrAllowTrustOp _allowTrustOp;
  XdrAllowTrustOp get allowTrustOp => this._allowTrustOp;
  set allowTrustOp(XdrAllowTrustOp value) => this._allowTrustOp = value;

  XdrMuxedAccount _destination;
  XdrMuxedAccount get destination => this._destination;
  set destination(XdrMuxedAccount value) => this._destination = value;

  XdrManageDataOp _manageDataOp;
  XdrManageDataOp get manageDataOp => this._manageDataOp;
  set manageDataOp(XdrManageDataOp value) => this._manageDataOp = value;

  XdrBumpSequenceOp _bumpSequenceOp;
  XdrBumpSequenceOp get bumpSequenceOp => this._bumpSequenceOp;
  set bumpSequenceOp(XdrBumpSequenceOp value) => this._bumpSequenceOp = value;

  XdrCreateClaimableBalanceOp _createClaimableBalanceOp;
  XdrCreateClaimableBalanceOp get createClaimableBalanceOp =>
      this._createClaimableBalanceOp;
  set createClaimableBalanceOp(XdrCreateClaimableBalanceOp value) =>
      this._createClaimableBalanceOp = value;

  XdrClaimClaimableBalanceOp _claimClaimableBalanceOp;
  XdrClaimClaimableBalanceOp get claimClaimableBalanceOp =>
      this._claimClaimableBalanceOp;
  set claimClaimableBalanceOp(XdrClaimClaimableBalanceOp value) =>
      this._claimClaimableBalanceOp = value;

  XdrBeginSponsoringFutureReservesOp _beginSponsoringFutureReservesOp;
  XdrBeginSponsoringFutureReservesOp get beginSponsoringFutureReservesOp =>
      this._beginSponsoringFutureReservesOp;
  set beginSponsoringFutureReservesOp(
          XdrBeginSponsoringFutureReservesOp value) =>
      this._beginSponsoringFutureReservesOp = value;

  XdrRevokeSponsorshipOp _revokeSponsorshipOp;
  XdrRevokeSponsorshipOp get revokeSponsorshipOp => this._revokeSponsorshipOp;
  set revokeSponsorshipOp(XdrRevokeSponsorshipOp value) =>
      this._revokeSponsorshipOp = value;

  static void encode(
      XdrDataOutputStream stream, XdrOperationBody encodedOperationBody) {
    stream.writeInt(encodedOperationBody.discriminant.value);
    switch (encodedOperationBody.discriminant) {
      case XdrOperationType.CREATE_ACCOUNT:
        XdrCreateAccountOp.encode(stream, encodedOperationBody.createAccountOp);
        break;
      case XdrOperationType.PAYMENT:
        XdrPaymentOp.encode(stream, encodedOperationBody.paymentOp);
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE:
        XdrPathPaymentStrictReceiveOp.encode(
            stream, encodedOperationBody.pathPaymentStrictReceiveOp);
        break;
      case XdrOperationType.MANAGE_SELL_OFFER:
        XdrManageSellOfferOp.encode(
            stream, encodedOperationBody.manageSellOfferOp);
        break;
      case XdrOperationType.CREATE_PASSIVE_SELL_OFFER:
        XdrCreatePassiveSellOfferOp.encode(
            stream, encodedOperationBody.createPassiveSellOfferOp);
        break;
      case XdrOperationType.SET_OPTIONS:
        XdrSetOptionsOp.encode(stream, encodedOperationBody.setOptionsOp);
        break;
      case XdrOperationType.CHANGE_TRUST:
        XdrChangeTrustOp.encode(stream, encodedOperationBody.changeTrustOp);
        break;
      case XdrOperationType.ALLOW_TRUST:
        XdrAllowTrustOp.encode(stream, encodedOperationBody.allowTrustOp);
        break;
      case XdrOperationType.ACCOUNT_MERGE:
        XdrMuxedAccount.encode(stream, encodedOperationBody.destination);
        break;
      case XdrOperationType.INFLATION:
        break;
      case XdrOperationType.MANAGE_DATA:
        XdrManageDataOp.encode(stream, encodedOperationBody.manageDataOp);
        break;
      case XdrOperationType.BUMP_SEQUENCE:
        XdrBumpSequenceOp.encode(stream, encodedOperationBody.bumpSequenceOp);
        break;
      case XdrOperationType.MANAGE_BUY_OFFER:
        XdrManageBuyOfferOp.encode(
            stream, encodedOperationBody.manageBuyOfferOp);
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_SEND:
        XdrPathPaymentStrictSendOp.encode(
            stream, encodedOperationBody.pathPaymentStrictSendOp);
        break;
      case XdrOperationType.CREATE_CLAIMABLE_BALANCE:
        XdrCreateClaimableBalanceOp.encode(
            stream, encodedOperationBody.createClaimableBalanceOp);
        break;
      case XdrOperationType.CLAIM_CLAIMABLE_BALANCE:
        XdrClaimClaimableBalanceOp.encode(
            stream, encodedOperationBody.claimClaimableBalanceOp);
        break;
      case XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES:
        XdrBeginSponsoringFutureReservesOp.encode(
            stream, encodedOperationBody.beginSponsoringFutureReservesOp);
        break;
      case XdrOperationType.END_SPONSORING_FUTURE_RESERVES:
        break;
      case XdrOperationType.REVOKE_SPONSORSHIP:
        XdrRevokeSponsorshipOp.encode(
            stream, encodedOperationBody.revokeSponsorshipOp);
        break;
    }
  }

  static XdrOperationBody decode(XdrDataInputStream stream) {
    XdrOperationBody decodedOperationBody = XdrOperationBody();
    XdrOperationType discriminant = XdrOperationType.decode(stream);
    decodedOperationBody.discriminant = discriminant;
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
    }
    return decodedOperationBody;
  }
}

class XdrOperationMeta {
  XdrOperationMeta();
  XdrLedgerEntryChanges _changes;
  XdrLedgerEntryChanges get changes => this._changes;
  set changes(XdrLedgerEntryChanges value) => this._changes = value;

  static void encode(
      XdrDataOutputStream stream, XdrOperationMeta encodedOperationMeta) {
    XdrLedgerEntryChanges.encode(stream, encodedOperationMeta.changes);
  }

  static XdrOperationMeta decode(XdrDataInputStream stream) {
    XdrOperationMeta decodedOperationMeta = XdrOperationMeta();
    decodedOperationMeta.changes = XdrLedgerEntryChanges.decode(stream);
    return decodedOperationMeta;
  }
}

class XdrOperationResult {
  XdrOperationResult();
  XdrOperationResultCode _code;
  XdrOperationResultCode get discriminant => this._code;
  set discriminant(XdrOperationResultCode value) => this._code = value;

  XdrOperationResultTr _tr;
  XdrOperationResultTr get tr => this._tr;
  set tr(XdrOperationResultTr value) => this._tr = value;

  static void encode(
      XdrDataOutputStream stream, XdrOperationResult encodedOperationResult) {
    stream.writeInt(encodedOperationResult.discriminant.value);
    switch (encodedOperationResult.discriminant) {
      case XdrOperationResultCode.opINNER:
        XdrOperationResultTr.encode(stream, encodedOperationResult.tr);
        break;
      default:
        break;
    }
  }

  static XdrOperationResult decode(XdrDataInputStream stream) {
    XdrOperationResult decodedOperationResult = XdrOperationResult();
    XdrOperationResultCode discriminant = XdrOperationResultCode.decode(stream);
    decodedOperationResult.discriminant = discriminant;
    switch (decodedOperationResult.discriminant) {
      case XdrOperationResultCode.opINNER:
        decodedOperationResult.tr = XdrOperationResultTr.decode(stream);
        break;
      default:
        break;
    }
    return decodedOperationResult;
  }
}

class XdrOperationResultTr {
  XdrOperationResultTr();
  XdrOperationType _type;
  XdrOperationType get discriminant => this._type;
  set discriminant(XdrOperationType value) => this._type = value;

  XdrCreateAccountResult _createAccountResult;
  XdrCreateAccountResult get createAccountResult => this._createAccountResult;
  set createAccountResult(XdrCreateAccountResult value) =>
      this._createAccountResult = value;

  XdrPaymentResult _paymentResult;
  XdrPaymentResult get paymentResult => this._paymentResult;
  set paymentResult(XdrPaymentResult value) => this._paymentResult = value;

  XdrPathPaymentStrictReceiveResult _pathPaymentStrictReceiveResult;
  XdrPathPaymentStrictReceiveResult get pathPaymentStrictReceiveResult =>
      this._pathPaymentStrictReceiveResult;
  set pathPaymentStrictReceiveResult(XdrPathPaymentStrictReceiveResult value) =>
      this._pathPaymentStrictReceiveResult = value;

  XdrPathPaymentStrictSendResult _pathPaymentStrictSendResult;
  XdrPathPaymentStrictSendResult get pathPaymentStrictSendResult =>
      this._pathPaymentStrictSendResult;
  set pathPaymentStrictSendResult(XdrPathPaymentStrictSendResult value) =>
      this._pathPaymentStrictSendResult = value;

  XdrManageOfferResult _manageOfferResult;
  XdrManageOfferResult get manageOfferResult => this._manageOfferResult;
  set manageOfferResult(XdrManageOfferResult value) =>
      this._manageOfferResult = value;

  XdrManageOfferResult _createPassiveOfferResult;
  XdrManageOfferResult get createPassiveOfferResult =>
      this._createPassiveOfferResult;
  set createPassiveOfferResult(XdrManageOfferResult value) =>
      this._createPassiveOfferResult = value;

  XdrSetOptionsResult _setOptionsResult;
  XdrSetOptionsResult get setOptionsResult => this._setOptionsResult;
  set setOptionsResult(XdrSetOptionsResult value) =>
      this._setOptionsResult = value;

  XdrChangeTrustResult _changeTrustResult;
  XdrChangeTrustResult get changeTrustResult => this._changeTrustResult;
  set changeTrustResult(XdrChangeTrustResult value) =>
      this._changeTrustResult = value;

  XdrAllowTrustResult _allowTrustResult;
  XdrAllowTrustResult get allowTrustResult => this._allowTrustResult;
  set allowTrustResult(XdrAllowTrustResult value) =>
      this._allowTrustResult = value;

  XdrAccountMergeResult _accountMergeResult;
  XdrAccountMergeResult get accountMergeResult => this._accountMergeResult;
  set accountMergeResult(XdrAccountMergeResult value) =>
      this._accountMergeResult = value;

  XdrInflationResult _inflationResult;
  XdrInflationResult get inflationResult => this._inflationResult;
  set inflationResult(XdrInflationResult value) =>
      this._inflationResult = value;

  XdrManageDataResult _manageDataResult;
  XdrManageDataResult get manageDataResult => this._manageDataResult;
  set manageDataResult(XdrManageDataResult value) =>
      this._manageDataResult = value;

  XdrBumpSequenceResult _bumpSeqResult;
  XdrBumpSequenceResult get bumpSeqResult => this._bumpSeqResult;
  set bumpSeqResult(XdrBumpSequenceResult value) => this._bumpSeqResult = value;

  XdrCreateClaimableBalanceResult _createClaimableBalanceResult;
  XdrCreateClaimableBalanceResult get createClaimableBalanceResult =>
      this._createClaimableBalanceResult;
  set createClaimableBalanceResult(XdrCreateClaimableBalanceResult value) =>
      this._createClaimableBalanceResult = value;

  XdrClaimClaimableBalanceResult _claimClaimableBalanceResult;
  XdrClaimClaimableBalanceResult get claimClaimableBalanceResult =>
      this._claimClaimableBalanceResult;
  set claimClaimableBalanceResult(XdrClaimClaimableBalanceResult value) =>
      this._claimClaimableBalanceResult = value;

  XdrBeginSponsoringFutureReservesResult _beginSponsoringFutureReservesResult;
  XdrBeginSponsoringFutureReservesResult
      get beginSponsoringFutureReservesResult =>
          this._beginSponsoringFutureReservesResult;
  set beginSponsoringFutureReservesResult(
          XdrBeginSponsoringFutureReservesResult value) =>
      this._beginSponsoringFutureReservesResult = value;

  XdrEndSponsoringFutureReservesResult _endSponsoringFutureReservesResult;
  XdrEndSponsoringFutureReservesResult get endSponsoringFutureReservesResult =>
      this._endSponsoringFutureReservesResult;
  set endSponsoringFutureReservesResult(
          XdrEndSponsoringFutureReservesResult value) =>
      this._endSponsoringFutureReservesResult = value;

  XdrRevokeSponsorshipResult _revokeSponsorshipResult;
  XdrRevokeSponsorshipResult get revokeSponsorshipResult =>
      this._revokeSponsorshipResult;
  set revokeSponsorshipResult(XdrRevokeSponsorshipResult value) =>
      this._revokeSponsorshipResult = value;

  static void encode(XdrDataOutputStream stream,
      XdrOperationResultTr encodedOperationResultTr) {
    stream.writeInt(encodedOperationResultTr.discriminant.value);
    switch (encodedOperationResultTr.discriminant) {
      case XdrOperationType.CREATE_ACCOUNT:
        XdrCreateAccountResult.encode(
            stream, encodedOperationResultTr.createAccountResult);
        break;
      case XdrOperationType.PAYMENT:
        XdrPaymentResult.encode(stream, encodedOperationResultTr.paymentResult);
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE:
        XdrPathPaymentStrictReceiveResult.encode(
            stream, encodedOperationResultTr.pathPaymentStrictReceiveResult);
        break;
      case XdrOperationType.MANAGE_SELL_OFFER:
        XdrManageOfferResult.encode(
            stream, encodedOperationResultTr.manageOfferResult);
        break;
      case XdrOperationType.CREATE_PASSIVE_SELL_OFFER:
        XdrManageOfferResult.encode(
            stream, encodedOperationResultTr.createPassiveOfferResult);
        break;
      case XdrOperationType.SET_OPTIONS:
        XdrSetOptionsResult.encode(
            stream, encodedOperationResultTr.setOptionsResult);
        break;
      case XdrOperationType.CHANGE_TRUST:
        XdrChangeTrustResult.encode(
            stream, encodedOperationResultTr.changeTrustResult);
        break;
      case XdrOperationType.ALLOW_TRUST:
        XdrAllowTrustResult.encode(
            stream, encodedOperationResultTr.allowTrustResult);
        break;
      case XdrOperationType.ACCOUNT_MERGE:
        XdrAccountMergeResult.encode(
            stream, encodedOperationResultTr.accountMergeResult);
        break;
      case XdrOperationType.INFLATION:
        XdrInflationResult.encode(
            stream, encodedOperationResultTr.inflationResult);
        break;
      case XdrOperationType.MANAGE_DATA:
        XdrManageDataResult.encode(
            stream, encodedOperationResultTr.manageDataResult);
        break;
      case XdrOperationType.BUMP_SEQUENCE:
        XdrBumpSequenceResult.encode(
            stream, encodedOperationResultTr.bumpSeqResult);
        break;
      case XdrOperationType.MANAGE_BUY_OFFER:
        XdrManageOfferResult.encode(
            stream, encodedOperationResultTr.manageOfferResult);
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_SEND:
        XdrPathPaymentStrictSendResult.encode(
            stream, encodedOperationResultTr.pathPaymentStrictSendResult);
        break;
      case XdrOperationType.CREATE_CLAIMABLE_BALANCE:
        XdrCreateClaimableBalanceResult.encode(
            stream, encodedOperationResultTr.createClaimableBalanceResult);
        break;
      case XdrOperationType.CLAIM_CLAIMABLE_BALANCE:
        XdrClaimClaimableBalanceResult.encode(
            stream, encodedOperationResultTr.claimClaimableBalanceResult);
        break;
      case XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES:
        XdrBeginSponsoringFutureReservesResult.encode(stream,
            encodedOperationResultTr.beginSponsoringFutureReservesResult);
        break;
      case XdrOperationType.END_SPONSORING_FUTURE_RESERVES:
        XdrEndSponsoringFutureReservesResult.encode(
            stream, encodedOperationResultTr.endSponsoringFutureReservesResult);
        break;
      case XdrOperationType.REVOKE_SPONSORSHIP:
        XdrRevokeSponsorshipResult.encode(
            stream, encodedOperationResultTr.revokeSponsorshipResult);
        break;
    }
  }

  static XdrOperationResultTr decode(XdrDataInputStream stream) {
    XdrOperationResultTr decodedOperationResultTr = XdrOperationResultTr();
    XdrOperationType discriminant = XdrOperationType.decode(stream);
    decodedOperationResultTr.discriminant = discriminant;
    switch (decodedOperationResultTr.discriminant) {
      case XdrOperationType.CREATE_ACCOUNT:
        decodedOperationResultTr.createAccountResult =
            XdrCreateAccountResult.decode(stream);
        break;
      case XdrOperationType.PAYMENT:
        decodedOperationResultTr.paymentResult =
            XdrPaymentResult.decode(stream);
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
        decodedOperationResultTr.setOptionsResult =
            XdrSetOptionsResult.decode(stream);
        break;
      case XdrOperationType.CHANGE_TRUST:
        decodedOperationResultTr.changeTrustResult =
            XdrChangeTrustResult.decode(stream);
        break;
      case XdrOperationType.ALLOW_TRUST:
        decodedOperationResultTr.allowTrustResult =
            XdrAllowTrustResult.decode(stream);
        break;
      case XdrOperationType.ACCOUNT_MERGE:
        decodedOperationResultTr.accountMergeResult =
            XdrAccountMergeResult.decode(stream);
        break;
      case XdrOperationType.INFLATION:
        decodedOperationResultTr.inflationResult =
            XdrInflationResult.decode(stream);
        break;
      case XdrOperationType.MANAGE_DATA:
        decodedOperationResultTr.manageDataResult =
            XdrManageDataResult.decode(stream);
        break;
      case XdrOperationType.BUMP_SEQUENCE:
        decodedOperationResultTr.bumpSeqResult =
            XdrBumpSequenceResult.decode(stream);
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
    }
    return decodedOperationResultTr;
  }
}

class XdrOperationResultCode {
  final _value;
  const XdrOperationResultCode._internal(this._value);
  toString() => 'OperationResultCode.$_value';
  XdrOperationResultCode(this._value);
  get value => this._value;

  /// Inner object result is valid.
  static const opINNER = const XdrOperationResultCode._internal(0);

  /// Too few valid signatures / wrong network.
  static const opBAD_AUTH = const XdrOperationResultCode._internal(-1);

  /// Source account was not found.
  static const opNO_ACCOUNT = const XdrOperationResultCode._internal(-2);

  /// Operation not supported at this time.
  static const opNOT_SUPPORTED = const XdrOperationResultCode._internal(-3);

  /// Max number of subentries already reached.
  static const opTOO_MANY_SUBENTRIES =
      const XdrOperationResultCode._internal(-4);

  /// Operation did too much work.
  static const opEXCEEDED_WORK_LIMIT =
      const XdrOperationResultCode._internal(-5);

  static XdrOperationResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return opINNER;
      case -1:
        return opBAD_AUTH;
      case -2:
        return opNO_ACCOUNT;
      case -3:
        return opNOT_SUPPORTED;
      case -4:
        return opTOO_MANY_SUBENTRIES;
      case -5:
        return opEXCEEDED_WORK_LIMIT;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrOperationResultCode value) {
    stream.writeInt(value.value);
  }
}
