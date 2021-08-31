// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'muxed_account.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_trustline.dart';

class ClawbackOperation extends Operation {
  Asset? _asset;
  MuxedAccount? _from;
  String? _amount;

  ClawbackOperation(Asset? asset, MuxedAccount? from, String? amount) {
    this._from = checkNotNull(from, "from cannot be null");
    this._asset = checkNotNull(asset, "asset cannot be null");
    this._amount = checkNotNull(amount, "amount cannot be null");
  }

  // account from which the asset is clawed back
  MuxedAccount? get from => _from;

  // asset to be clawed back
  Asset? get asset => _asset;

  // asset amount clawed back
  String? get amount => _amount;

  @override
  XdrOperationBody toOperationBody() {
    XdrClawbackOp op = XdrClawbackOp();

    op.from = this._from?.toXdr();
    op.asset = asset?.toXdr();
    XdrInt64 amount = XdrInt64();
    amount.int64 = Operation.toXdrAmount(this.amount!);
    op.amount = amount;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.CLAWBACK;
    body.clawbackOp = op;
    return body;
  }

  /// Builds Clawback operation.
  static ClawbackOperationBuilder builder(XdrClawbackOp op) {
    return ClawbackOperationBuilder.forMuxedFromAccount(Asset.fromXdr(op.asset!),
        MuxedAccount.fromXdr(op.from!), Operation.fromXdrAmount(op.amount!.int64!));
  }
}

class ClawbackOperationBuilder {
  Asset? _asset;
  MuxedAccount? _from;
  String? _amount;
  MuxedAccount? _mSourceAccount;

  /// Creates a ClawbackOperationBuilder builder.
  /// [asset] Asset to be clawed back.
  /// [fromAccountId] account id from which the asset is clawed back
  /// [amount] Amount to be clawed back.
  ClawbackOperationBuilder(Asset asset, String fromAccountId, String amount) {
    this._asset = asset;
    this._from = MuxedAccount(fromAccountId, null);
    this._amount = amount;
  }

  /// Creates a ClawbackOperation builder using a MuxedAccount as a from account.
  /// [asset] Aasset to be clawed back.
  /// [fromAccount] MuxedAccount having the accountId of the account from which the asset is clawed back.
  /// [amount] Amount to be clawed back.
  ClawbackOperationBuilder.forMuxedFromAccount(
      Asset asset, MuxedAccount fromAccount, String amount) {
    this._asset = asset;
    this._from = fromAccount;
    this._amount = amount;
  }

  /// Sets the source account for this operation.
  ClawbackOperationBuilder setSourceAccount(String sourceAccountId) {
    _mSourceAccount = MuxedAccount(sourceAccountId, null);
    return this;
  }

  ClawbackOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds an operation
  ClawbackOperation build() {
    ClawbackOperation operation = ClawbackOperation(_asset, _from, _amount);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
