// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/xdr/xdr_type.dart';

import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_contract.dart';

class ExtendFootprintTTLOperation extends Operation {
  int _extendTo;
  int get extendTo => _extendTo;

  ExtendFootprintTTLOperation(this._extendTo);

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.EXTEND_FOOTPRINT_TTL);
    body.bumpExpirationOp = XdrExtendFootprintTTLOp(
        XdrExtensionPoint(0), XdrUint32(this._extendTo));
    return body;
  }

  static ExtendFootprintTTLOperationBuilder builder(
      XdrExtendFootprintTTLOp op) {
    return ExtendFootprintTTLOperationBuilder(op.extendTo.uint32);
  }
}

class ExtendFootprintTTLOperationBuilder {
  int _extendTo;
  MuxedAccount? _mSourceAccount;

  ExtendFootprintTTLOperationBuilder(this._extendTo);

  /// Sets the source account for this operation represented by [sourceAccountId].
  ExtendFootprintTTLOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  ExtendFootprintTTLOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  ExtendFootprintTTLOperation build() {
    ExtendFootprintTTLOperation operation =
        ExtendFootprintTTLOperation(_extendTo);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
