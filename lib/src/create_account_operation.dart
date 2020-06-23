// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';


/// Represents <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html#create-account" target="_blank">CreateAccount</a> operation.
/// See: @see <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html" target="_blank">List of Operations</a>
class CreateAccountOperation extends Operation {
  String _destination;
  String _startingBalance;

  CreateAccountOperation(String destination, String startingBalance) {
    this._destination = checkNotNull(destination, "destination cannot be null");
    this._startingBalance =
        checkNotNull(startingBalance, "startingBalance cannot be null");
  }

  /// Amount of XLM to send to the newly created account.
  String get startingBalance => _startingBalance;

  /// Account that is created and funded.
  String get destination => _destination;

  @override
  XdrOperationBody toOperationBody() {
    XdrCreateAccountOp op = XdrCreateAccountOp();
    XdrAccountID destination = XdrAccountID();
    destination.accountID = KeyPair.fromAccountId(this.destination).xdrPublicKey;
    op.destination = destination;
    XdrInt64 startingBalance = XdrInt64();
    startingBalance.int64 = Operation.toXdrAmount(this.startingBalance);
    op.startingBalance = startingBalance;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.CREATE_ACCOUNT;
    body.createAccountOp = op;
    return body;
  }

  /// Builds CreateAccount operation.
  static CreateAccountOperationBuilder builder(XdrCreateAccountOp op) {
    return CreateAccountOperationBuilder(
        KeyPair.fromXdrPublicKey(op.destination.accountID).accountId,
        Operation.fromXdrAmount(op.startingBalance.int64.toInt()));
  }
}

class CreateAccountOperationBuilder {
  String _destination;
  String _startingBalance;
  String _mSourceAccount;

  /// Creates a CreateAccount builder.
  CreateAccountOperationBuilder(this._destination, this._startingBalance);

  /// Sets the source account for this operation represented by [sourceAccountId].
  CreateAccountOperationBuilder setSourceAccount(String sourceAccountId) {
    _mSourceAccount = sourceAccountId;
    return this;
  }

  ///Builds an operation
  CreateAccountOperation build() {
    CreateAccountOperation operation =
    CreateAccountOperation(_destination, _startingBalance);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}