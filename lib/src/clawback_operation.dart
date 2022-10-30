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
  Asset _asset;
  MuxedAccount _from;
  String _amount;

  ClawbackOperation(this._from, this._asset, this._amount);

  // account from which the asset is clawed back
  MuxedAccount get from => _from;

  // asset to be clawed back
  Asset get asset => _asset;

  // asset amount clawed back
  String get amount => _amount;

  @override
  XdrOperationBody toOperationBody() {
    XdrClawbackOp op = XdrClawbackOp();

    op.from = this._from.toXdr();
    op.asset = asset.toXdr();
    XdrInt64 amount = XdrInt64();
    amount.int64 = Operation.toXdrAmount(this.amount);
    op.amount = amount;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.CLAWBACK;
    body.clawbackOp = op;
    return body;
  }

  /// Builds Clawback operation.
  static ClawbackOperationBuilder builder(XdrClawbackOp op) {
    return ClawbackOperationBuilder.forMuxedFromAccount(
        Asset.fromXdr(op.asset!),
        MuxedAccount.fromXdr(op.from!),
        Operation.fromXdrAmount(op.amount!.int64!));
  }
}

class ClawbackOperationBuilder {
  Asset _asset;
  late MuxedAccount _from;
  String _amount;
  MuxedAccount? _mSourceAccount;

  /// Creates a ClawbackOperationBuilder builder.
  /// [asset] Asset to be clawed back.
  /// [fromAccountId] account id from which the asset is clawed back
  /// [amount] Amount to be clawed back.
  ClawbackOperationBuilder(this._asset, String fromAccountId, this._amount) {
    MuxedAccount? fr = MuxedAccount.fromAccountId(fromAccountId);
    this._from = checkNotNull(fr, "invalid fromAccountId");
  }

  /// Creates a ClawbackOperation builder using a MuxedAccount as a from account.
  /// [asset] Aasset to be clawed back.
  /// [fromAccount] MuxedAccount having the accountId of the account from which the asset is clawed back.
  /// [amount] Amount to be clawed back.
  ClawbackOperationBuilder.forMuxedFromAccount(
      this._asset, this._from, this._amount);

  /// Sets the source account for this operation.
  ClawbackOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ClawbackOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds an operation
  ClawbackOperation build() {
    ClawbackOperation operation = ClawbackOperation(_from, _asset, _amount);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
