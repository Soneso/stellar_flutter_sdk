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
  int _bumpTo;

  BumpSequenceOperation(int bumpTo) {
    this._bumpTo = bumpTo;
  }

  int get bumpTo => _bumpTo;

  @override
  XdrOperationBody toOperationBody() {
    XdrBumpSequenceOp op = new XdrBumpSequenceOp();
    XdrInt64 bumpTo = new XdrInt64();
    bumpTo.int64 = this._bumpTo;
    XdrSequenceNumber sequenceNumber = new XdrSequenceNumber();
    sequenceNumber.sequenceNumber = bumpTo;
    op.bumpTo = sequenceNumber;

    XdrOperationBody body = new XdrOperationBody();
    body.discriminant = XdrOperationType.BUMP_SEQUENCE;
    body.bumpSequenceOp = op;

    return body;
  }

  /// Construct a new BumpSequence builder from a BumpSequence XDR.
  static BumpSequenceOperationBuilder builder(XdrBumpSequenceOp op) {
    return BumpSequenceOperationBuilder(op.bumpTo.sequenceNumber.int64);
  }
}

class BumpSequenceOperationBuilder {
  int _bumpTo;
  MuxedAccount _mSourceAccount;

  /// Creates a new BumpSequence builder.
  BumpSequenceOperationBuilder(int bumpTo) {
    this._bumpTo = bumpTo;
  }

  /// Sets the source account for this operation.
  BumpSequenceOperationBuilder setSourceAccount(String sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = MuxedAccount(sourceAccount, null);
    return this;
  }

  /// Sets the muxed source account for this operation.
  BumpSequenceOperationBuilder setMuxedSourceAccount(MuxedAccount? sourceAccount) {
    _mSourceAccount = checkNotNull(sourceAccount, "sourceAccount cannot be null");
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
