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

class BumpFootprintExpirationOperation extends Operation {
  int _ledgersToExpire;
  int get ledgersToExpire => _ledgersToExpire;

  BumpFootprintExpirationOperation(this._ledgersToExpire);

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
    XdrOperationBody(XdrOperationType.BUMP_FOOTPRINT_EXPIRATION);
    body.bumpExpirationOp = XdrBumpFootprintExpirationOp(XdrExtensionPoint(0), XdrUint32(this._ledgersToExpire));
    return body;
  }

  static BumpFootprintExpirationOperationBuilder builder(XdrBumpFootprintExpirationOp op) {
    return BumpFootprintExpirationOperationBuilder(op.ledgersToExpire.uint32);
  }
}

class BumpFootprintExpirationOperationBuilder {
  int _ledgersToExpire;
  MuxedAccount? _mSourceAccount;

  BumpFootprintExpirationOperationBuilder(this._ledgersToExpire);

  /// Sets the source account for this operation represented by [sourceAccountId].
  BumpFootprintExpirationOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  BumpFootprintExpirationOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  BumpFootprintExpirationOperation build() {
    BumpFootprintExpirationOperation operation = BumpFootprintExpirationOperation(_ledgersToExpire);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
