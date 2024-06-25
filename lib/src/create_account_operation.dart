// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#create-account" target="_blank">CreateAccount</a> operation.
/// See: @see <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>
class CreateAccountOperation extends Operation {
  String _destination;
  String _startingBalance;

  CreateAccountOperation(this._destination, this._startingBalance);

  /// Amount of XLM to send to the newly created account.
  String get startingBalance => _startingBalance;

  /// Account that is created and funded.
  String get destination => _destination;

  @override
  XdrOperationBody toOperationBody() {
    XdrAccountID xDestination =
        XdrAccountID(KeyPair.fromAccountId(this.destination).xdrPublicKey);
    XdrBigInt64 startingBalance =
    XdrBigInt64(Util.toXdrBigInt64Amount(this.startingBalance));

    XdrOperationBody body = XdrOperationBody(XdrOperationType.CREATE_ACCOUNT);
    body.createAccountOp = XdrCreateAccountOp(xDestination, startingBalance);
    return body;
  }

  /// Builds CreateAccount operation.
  static CreateAccountOperationBuilder builder(XdrCreateAccountOp op) {
    return CreateAccountOperationBuilder(
        KeyPair.fromXdrPublicKey(op.destination.accountID).accountId,
        Util.fromXdrBigInt64Amount(op.startingBalance.bigInt));
  }
}

class CreateAccountOperationBuilder {
  String _destination;
  String _startingBalance;
  MuxedAccount? _mSourceAccount;

  /// Creates a CreateAccount builder.
  CreateAccountOperationBuilder(this._destination, this._startingBalance);

  /// Sets the source account for this operation represented by [sourceAccountId].
  CreateAccountOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  CreateAccountOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
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
