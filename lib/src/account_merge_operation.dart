// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#account-merge" target="_blank">AccountMerge</a> operation.
/// See: <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>
class AccountMergeOperation extends Operation {
  MuxedAccount? _destination;

  AccountMergeOperation(MuxedAccount? destination) {
    this._destination = checkNotNull(destination, "destination cannot be null");
  }

  /// The the account that receives the remaining XLM balance of the source account.
  MuxedAccount? get destination => _destination;

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body = new XdrOperationBody();
    body.destination = this.destination?.toXdr();
    body.discriminant = XdrOperationType.ACCOUNT_MERGE;
    return body;
  }

  /// Builds AccountMerge operation.
  static AccountMergeOperationBuilder builder(XdrOperationBody op) {
    MuxedAccount mux = MuxedAccount.fromXdr(op.destination!);
    return AccountMergeOperationBuilder.forMuxedDestinationAccount(mux);
  }
}

class AccountMergeOperationBuilder {
  MuxedAccount? _destination;
  MuxedAccount? _mSourceAccount;

  /// Creates a new AccountMerge builder.
  AccountMergeOperationBuilder(String destination) {
    checkNotNull(destination, "destination cannot be null");
    this._destination = MuxedAccount.fromAccountId(destination);
  }

  /// Creates a new AccountMerge builder for a muxed destination account.
  AccountMergeOperationBuilder.forMuxedDestinationAccount(MuxedAccount? destination) {
    this._destination = checkNotNull(destination, "destination cannot be null");
  }

  /// Set source account of this operation
  AccountMergeOperationBuilder setSourceAccount(String sourceAccountId) {
    checkNotNull(sourceAccountId, "sourceAccountId cannot be null");
    _mSourceAccount = MuxedAccount.fromAccountId(sourceAccountId);
    return this;
  }

  AccountMergeOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = checkNotNull(sourceAccount, "sourceAccount cannot be null");
    return this;
  }

  /// Builds an operation
  AccountMergeOperation build() {
    AccountMergeOperation operation = new AccountMergeOperation(_destination);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
