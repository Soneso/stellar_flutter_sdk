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
  List<Claimant> _claimants;
  Asset _asset;
  String _amount;

  CreateClaimableBalanceOperation(this._claimants, this._asset, this._amount);

  List<Claimant> get claimants => _claimants;
  Asset get asset => _asset;
  String get amount => _amount;

  @override
  XdrOperationBody toOperationBody() {
    List<XdrClaimant> xdrClaimants = List<XdrClaimant>.empty(growable: true);
    for (int i = 0; i < this.claimants.length; i++) {
      xdrClaimants.add(this.claimants[i].toXdr());
    }

    XdrInt64 amount = XdrInt64();
    amount.int64 = Operation.toXdrAmount(this.amount);

    XdrCreateClaimableBalanceOp op =
        XdrCreateClaimableBalanceOp(this.asset.toXdr(), amount, xdrClaimants);

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.CREATE_CLAIMABLE_BALANCE;
    body.createClaimableBalanceOp = op;
    return body;
  }

  static CreateClaimableBalanceOperationBuilder builder(
      XdrCreateClaimableBalanceOp op) {
    List<Claimant> claimants = List<Claimant>.empty(growable: true);
    for (int i = 0; i < op.claimants.length; i++) {
      claimants.add(Claimant.fromXdr(op.claimants[i]));
    }
    Asset asset = Asset.fromXdr(op.asset);
    String amount = Operation.fromXdrAmount(op.amount.int64!);

    return CreateClaimableBalanceOperationBuilder(claimants, asset, amount);
  }
}

class CreateClaimableBalanceOperationBuilder {
  List<Claimant> _claimants;
  Asset _asset;
  String _amount;
  MuxedAccount? _mSourceAccount;

  CreateClaimableBalanceOperationBuilder(
      this._claimants, this._asset, this._amount);

  /// Sets the source account for this operation represented by [sourceAccountId].
  CreateClaimableBalanceOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  CreateClaimableBalanceOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
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
