// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/key_pair.dart';

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
    var id = liquidityPoolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(
            StrKey.decodeLiquidityPoolId(liquidityPoolId));
      } catch (_) {}
    }
    XdrHash xLiquidityPoolID = Util.stringIdToXdrHash(id);
    XdrBigInt64 amountA = XdrBigInt64(Util.toXdrBigInt64Amount(this.minAmountA));
    XdrBigInt64 amountB = XdrBigInt64(Util.toXdrBigInt64Amount(this.minAmountB));
    XdrBigInt64 a = XdrBigInt64(Util.toXdrBigInt64Amount(this.amount));

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.LIQUIDITY_POOL_WITHDRAW);
    body.liquidityPoolWithdrawOp =
        XdrLiquidityPoolWithdrawOp(xLiquidityPoolID, a, amountA, amountB);
    return body;
  }

  static LiquidityPoolWithdrawOperationBuilder builder(
      XdrLiquidityPoolWithdrawOp op) {
    String lpId = Util.bytesToHex(op.liquidityPoolID.hash);
    String minA = Util.fromXdrBigInt64Amount(op.minAmountA.bigInt);
    String minB = Util.fromXdrBigInt64Amount(op.minAmountB.bigInt);
    String amount = Util.fromXdrBigInt64Amount(op.amount.bigInt);

    return LiquidityPoolWithdrawOperationBuilder(
        liquidityPoolId: lpId, amount: amount, minAmountA: minA, minAmountB: minB);
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
