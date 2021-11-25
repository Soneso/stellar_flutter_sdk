// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_ledger.dart';

import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';
import 'claimant.dart';
import 'assets.dart';

class CreateClaimableBalanceOperation extends Operation {
  List<Claimant?>? _claimants;
  Asset? _asset;
  String? _amount;

  CreateClaimableBalanceOperation(List<Claimant?>? claimants, Asset? asset, String? amount) {
    this._claimants = checkNotNull(claimants, "claimants cannot be null");
    this._asset = checkNotNull(asset, "asset cannot be null");
    this._amount = checkNotNull(amount, "amount cannot be null");
  }

  List<Claimant?>? get claimants => _claimants;
  Asset? get asset => _asset;
  String? get amount => _amount;

  @override
  XdrOperationBody toOperationBody() {
    XdrCreateClaimableBalanceOp op = XdrCreateClaimableBalanceOp();

    // List<XdrClaimant> xdrClaimants = List<XdrClaimant>(this.claimants.length);
    List<XdrClaimant?> xdrClaimants = []..length = this.claimants!.length;
    for (int i = 0; i < this.claimants!.length; i++) {
      xdrClaimants[i] = this.claimants![i]?.toXdr();
    }
    op.claimants = xdrClaimants;

    op.asset = this.asset?.toXdr();

    XdrInt64 amount = XdrInt64();
    amount.int64 = Operation.toXdrAmount(this.amount!);
    op.amount = amount;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.CREATE_CLAIMABLE_BALANCE;
    body.createClaimableBalanceOp = op;
    return body;
  }

  static CreateClaimableBalanceOperationBuilder builder(XdrCreateClaimableBalanceOp op) {
    // List<Claimant> claimants = List<Claimant>(op.claimants.length);
    List<Claimant?> claimants = []..length = op.claimants!.length;
    for (int i = 0; i < op.claimants!.length; i++) {
      claimants[i] = Claimant.fromXdr(op.claimants![i]!);
    }
    Asset asset = Asset.fromXdr(op.asset!);
    String amount = Operation.fromXdrAmount(op.amount!.int64!);

    return CreateClaimableBalanceOperationBuilder(claimants, asset, amount);
  }
}

class CreateClaimableBalanceOperationBuilder {
  List<Claimant?>? _claimants;
  Asset? _asset;
  String? _amount;
  MuxedAccount? _mSourceAccount;

  CreateClaimableBalanceOperationBuilder(this._claimants, this._asset, this._amount);

  /// Sets the source account for this operation represented by [sourceAccount].
  CreateClaimableBalanceOperationBuilder setSourceAccount(String sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = MuxedAccount(sourceAccount, null);
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccountId].
  CreateClaimableBalanceOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = checkNotNull(sourceAccount, "sourceAccount cannot be null");
    return this;
  }

  ///Builds an operation
  CreateClaimableBalanceOperation build() {
    CreateClaimableBalanceOperation operation =
        CreateClaimableBalanceOperation(_claimants, _asset, _amount);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
