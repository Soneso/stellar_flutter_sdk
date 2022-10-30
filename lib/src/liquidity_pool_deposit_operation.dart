// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_other.dart';
import 'price.dart';

class LiquidityPoolDepositOperation extends Operation {
  String liquidityPoolId;
  String maxAmountA;
  String maxAmountB;
  String minPrice;
  String maxPrice;

  LiquidityPoolDepositOperation(
      {required this.liquidityPoolId,
      required this.maxAmountA,
      required this.maxAmountB,
      required this.minPrice,
      required this.maxPrice});

  @override
  XdrOperationBody toOperationBody() {
    XdrHash xLiquidityPoolID = Util.stringIdToXdrHash(liquidityPoolId);
    XdrInt64 amountA = XdrInt64();
    amountA.int64 = Operation.toXdrAmount(this.maxAmountA);

    XdrInt64 amountB = XdrInt64();
    amountB.int64 = Operation.toXdrAmount(this.maxAmountB);

    XdrPrice xMinPrice = Price.fromString(minPrice).toXdr();
    XdrPrice xMaxPrice = Price.fromString(maxPrice).toXdr();

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.LIQUIDITY_POOL_DEPOSIT;
    body.liquidityPoolDepositOp = XdrLiquidityPoolDepositOp(
        xLiquidityPoolID, amountA, amountB, xMinPrice, xMaxPrice);
    return body;
  }

  static LiquidityPoolDepositOperationBuilder builder(
      XdrLiquidityPoolDepositOp op) {
    String lpId = Util.bytesToHex(op.liquidityPoolID.hash!);
    String maxA = Operation.fromXdrAmount(op.maxAmountA.int64!);
    String maxB = Operation.fromXdrAmount(op.maxAmountB.int64!);
    int n = op.minPrice.n!.int32!;
    int d = op.minPrice.d!.int32!;
    String minP = removeTailZero((BigInt.from(n) / BigInt.from(d)).toString());
    n = op.maxPrice.n!.int32!;
    d = op.maxPrice.d!.int32!;
    String maxP = removeTailZero((BigInt.from(n) / BigInt.from(d)).toString());

    return LiquidityPoolDepositOperationBuilder(
        liquidityPoolId: lpId,
        maxAmountA: maxA,
        maxAmountB: maxB,
        minPrice: minP,
        maxPrice: maxP);
  }
}

class LiquidityPoolDepositOperationBuilder {
  String liquidityPoolId;
  String maxAmountA;
  String maxAmountB;
  String minPrice;
  String maxPrice;
  MuxedAccount? _mSourceAccount;

  LiquidityPoolDepositOperationBuilder(
      {required this.liquidityPoolId,
      required this.maxAmountA,
      required this.maxAmountB,
      required this.minPrice,
      required this.maxPrice});

  /// Sets the source account for this operation represented by [sourceAccountId].
  LiquidityPoolDepositOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  LiquidityPoolDepositOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  LiquidityPoolDepositOperation build() {
    LiquidityPoolDepositOperation operation = LiquidityPoolDepositOperation(
        liquidityPoolId: liquidityPoolId,
        maxAmountA: maxAmountA,
        maxAmountB: maxAmountB,
        minPrice: minPrice,
        maxPrice: maxPrice);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
