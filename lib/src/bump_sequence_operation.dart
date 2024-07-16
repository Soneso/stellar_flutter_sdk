// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#bump-sequence" target="_blank">Bump Sequence</a> operation.
/// See: <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>
class BumpSequenceOperation extends Operation {
  BigInt _bumpTo;

  BumpSequenceOperation(this._bumpTo);

  BigInt get bumpTo => _bumpTo;

  @override
  XdrOperationBody toOperationBody() {
    XdrBigInt64 bumpTo = new XdrBigInt64(this._bumpTo);
    XdrOperationBody body =
        new XdrOperationBody(XdrOperationType.BUMP_SEQUENCE);
    body.bumpSequenceOp = new XdrBumpSequenceOp(XdrSequenceNumber(bumpTo));

    return body;
  }

  /// Construct a new BumpSequence builder from a BumpSequence XDR.
  static BumpSequenceOperationBuilder builder(XdrBumpSequenceOp op) {
    return BumpSequenceOperationBuilder(op.bumpTo.sequenceNumber.bigInt);
  }
}

class BumpSequenceOperationBuilder {
  BigInt _bumpTo;
  MuxedAccount? _mSourceAccount;

  /// Creates a new BumpSequence builder.
  BumpSequenceOperationBuilder(this._bumpTo);

  /// Sets the source account for this operation.
  BumpSequenceOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  BumpSequenceOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  BumpSequenceOperation build() {
    BumpSequenceOperation operation = new BumpSequenceOperation(_bumpTo);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
