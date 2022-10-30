// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';

class LiquidityPoolWithdrawOperation extends Operation {
  String liquidityPoolId;
  String amount;
  String minAmountA;
  String minAmountB;

  LiquidityPoolWithdrawOperation(
      {required this.liquidityPoolId,
      required this.amount,
      required this.minAmountA,
      required this.minAmountB});

  @override
  XdrOperationBody toOperationBody() {
    XdrHash xLiquidityPoolID = Util.stringIdToXdrHash(liquidityPoolId);

    XdrInt64 amountA = XdrInt64();
    amountA.int64 = Operation.toXdrAmount(this.minAmountA);

    XdrInt64 amountB = XdrInt64();
    amountB.int64 = Operation.toXdrAmount(this.minAmountB);

    XdrInt64 a = XdrInt64();
    a.int64 = Operation.toXdrAmount(this.amount);

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.LIQUIDITY_POOL_WITHDRAW;
    body.liquidityPoolWithdrawOp =
        XdrLiquidityPoolWithdrawOp(xLiquidityPoolID, a, amountA, amountB);
    return body;
  }

  static LiquidityPoolWithdrawOperationBuilder builder(
      XdrLiquidityPoolWithdrawOp op) {
    String lpId = Util.bytesToHex(op.liquidityPoolID.hash!);
    String minA = Operation.fromXdrAmount(op.minAmountA.int64!);
    String minB = Operation.fromXdrAmount(op.minAmountB.int64!);
    String a = Operation.fromXdrAmount(op.amount.int64!);

    return LiquidityPoolWithdrawOperationBuilder(
        liquidityPoolId: lpId, amount: a, minAmountA: minA, minAmountB: minB);
  }
}

class LiquidityPoolWithdrawOperationBuilder {
  String liquidityPoolId;
  String minAmountA;
  String minAmountB;
  String amount;
  MuxedAccount? _mSourceAccount;

  LiquidityPoolWithdrawOperationBuilder(
      {required this.liquidityPoolId,
      required this.amount,
      required this.minAmountA,
      required this.minAmountB});

  /// Sets the source account for this operation represented by [sourceAccountId].
  LiquidityPoolWithdrawOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccountId].
  LiquidityPoolWithdrawOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  LiquidityPoolWithdrawOperation build() {
    LiquidityPoolWithdrawOperation operation = LiquidityPoolWithdrawOperation(
        liquidityPoolId: liquidityPoolId,
        amount: amount,
        minAmountA: minAmountA,
        minAmountB: minAmountB);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
