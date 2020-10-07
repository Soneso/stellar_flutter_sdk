// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'key_pair.dart';
import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';

class BeginSponsoringFutureReservesOperation extends Operation {
  String _sponsoredId;

  BeginSponsoringFutureReservesOperation(String sponsoredId) {
    this._sponsoredId = checkNotNull(sponsoredId, "sponsoredId cannot be null");
  }

  String get sponsoredId => _sponsoredId;

  @override
  XdrOperationBody toOperationBody() {
    XdrBeginSponsoringFutureReservesOp op =
        XdrBeginSponsoringFutureReservesOp();

    XdrAccountID sponsoredAId = XdrAccountID();
    sponsoredAId.accountID =
        KeyPair.fromAccountId(this.sponsoredId).xdrPublicKey;
    op.sponsoredID = sponsoredAId;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES;
    body.beginSponsoringFutureReservesOp = op;
    return body;
  }

  static BeginSponsoringFutureReservesOperation builder(
      XdrBeginSponsoringFutureReservesOp op) {
    String sponsoredId =
        KeyPair.fromXdrPublicKey(op.sponsoredID.accountID).accountId;
    return BeginSponsoringFutureReservesOperation(sponsoredId);
  }
}

class BeginSponsoringFutureReservesOperationBuilder {
  String _sponsoredId;
  MuxedAccount _mSourceAccount;

  BeginSponsoringFutureReservesOperationBuilder(this._sponsoredId);

  /// Sets the source account for this operation represented by [sourceAccount].
  BeginSponsoringFutureReservesOperationBuilder setSourceAccount(
      String sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = MuxedAccount(sourceAccount, null);
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccountId].
  BeginSponsoringFutureReservesOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount =
        checkNotNull(sourceAccount, "sourceAccount cannot be null");
    return this;
  }

  ///Builds an operation
  BeginSponsoringFutureReservesOperation build() {
    BeginSponsoringFutureReservesOperation operation =
    BeginSponsoringFutureReservesOperation(_sponsoredId);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
