// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';

class EndSponsoringFutureReservesOperation extends Operation {
  EndSponsoringFutureReservesOperationOperation() {}

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.END_SPONSORING_FUTURE_RESERVES;
    return body;
  }

  static EndSponsoringFutureReservesOperation builder() {
    return EndSponsoringFutureReservesOperation();
  }
}

class EndSponsoringFutureReservesOperationBuilder {
  MuxedAccount _mSourceAccount;

  EndSponsoringFutureReservesOperationBuilder();

  /// Sets the source account for this operation represented by [sourceAccount].
  EndSponsoringFutureReservesOperationBuilder setSourceAccount(
      String sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = MuxedAccount(sourceAccount, null);
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccountId].
  EndSponsoringFutureReservesOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount =
        checkNotNull(sourceAccount, "sourceAccount cannot be null");
    return this;
  }

  ///Builds an operation
  EndSponsoringFutureReservesOperation build() {
    EndSponsoringFutureReservesOperation operation =
        EndSponsoringFutureReservesOperation();
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
