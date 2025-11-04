// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';

/// Represents [AccountMerge](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object#account-merge) operation.
/// See: [List of Operations](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object)
class AccountMergeOperation extends Operation {
  MuxedAccount _destination;

  AccountMergeOperation(this._destination);

  /// The the account that receives the remaining XLM balance of the source account.
  MuxedAccount get destination => _destination;

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        new XdrOperationBody(XdrOperationType.ACCOUNT_MERGE);
    body.destination = this.destination.toXdr();
    return body;
  }

  /// Builds AccountMerge operation.
  static AccountMergeOperationBuilder builder(XdrOperationBody op) {
    MuxedAccount mux = MuxedAccount.fromXdr(op.destination!);
    return AccountMergeOperationBuilder.forMuxedDestinationAccount(mux);
  }
}

class AccountMergeOperationBuilder {
  late MuxedAccount _destination;
  MuxedAccount? _mSourceAccount;

  /// Creates a new AccountMerge builder.
  AccountMergeOperationBuilder(String destinationAccountId) {
    MuxedAccount? dest = MuxedAccount.fromAccountId(destinationAccountId);
    this._destination = checkNotNull(dest, "invalid destination account id");
  }

  /// Creates a new AccountMerge builder for a muxed destination account.
  AccountMergeOperationBuilder.forMuxedDestinationAccount(this._destination);

  /// Set source account of this operation
  AccountMergeOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  AccountMergeOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
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
