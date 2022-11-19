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

  BeginSponsoringFutureReservesOperation(this._sponsoredId);

  String get sponsoredId => _sponsoredId;

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES);
    body.beginSponsoringFutureReservesOp = XdrBeginSponsoringFutureReservesOp(
        XdrAccountID(KeyPair.fromAccountId(this.sponsoredId).xdrPublicKey));
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
  MuxedAccount? _mSourceAccount;

  BeginSponsoringFutureReservesOperationBuilder(this._sponsoredId);

  /// Sets the source account for this operation represented by [sourceAccountId].
  BeginSponsoringFutureReservesOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  BeginSponsoringFutureReservesOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
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
