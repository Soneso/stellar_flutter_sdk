// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';

/// Represents <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html#account-merge" target="_blank">AccountMerge</a> operation.
/// See: <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html" target="_blank">List of Operations</a>
class AccountMergeOperation extends Operation {
  String _destination;

  AccountMergeOperation(String destination) {
    this._destination = checkNotNull(destination, "destination cannot be null");
  }

  /// The id of the account that receives the remaining XLM balance of the source account.
  String get destination => _destination;

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body = new XdrOperationBody();
    XdrAccountID destination = new XdrAccountID();
    destination.accountID =
        KeyPair.fromAccountId(this.destination).xdrPublicKey;
    body.destination = destination;
    body.discriminant = XdrOperationType.ACCOUNT_MERGE;
    return body;
  }

  /// Builds AccountMerge operation.
  static AccountMergeOperationBuilder builder(XdrOperationBody op) {
    return AccountMergeOperationBuilder(
        KeyPair.fromXdrPublicKey(op.destination.accountID).accountId);
  }
}

class AccountMergeOperationBuilder {
  String _destination;
  String _mSourceAccount;

  /// Creates a new AccountMerge builder.
  AccountMergeOperationBuilder(String destination) {
    this._destination = destination;
  }

  /// Set source account of this operation
  AccountMergeOperationBuilder setSourceAccount(String sourceAccount) {
    _mSourceAccount = sourceAccount;
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
