// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_contract.dart';

class RestoreFootprintOperation extends Operation {
  RestoreFootprintOperation();

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.RESTORE_FOOTPRINT);
    body.restoreFootprintOp = XdrRestoreFootprintOp(XdrExtensionPoint(0));
    return body;
  }

  static RestoreFootprintOperationBuilder builder(XdrRestoreFootprintOp op) {
    return RestoreFootprintOperationBuilder();
  }
}

class RestoreFootprintOperationBuilder {
  MuxedAccount? _mSourceAccount;

  RestoreFootprintOperationBuilder();

  /// Sets the source account for this operation represented by [sourceAccountId].
  RestoreFootprintOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  RestoreFootprintOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  RestoreFootprintOperation build() {
    RestoreFootprintOperation operation = RestoreFootprintOperation();
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
