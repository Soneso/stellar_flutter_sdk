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
    var id = liquidityPoolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(
            StrKey.decodeLiquidityPoolId(liquidityPoolId));
      } catch (_) {}
    }
    XdrHash xLiquidityPoolID = Util.stringIdToXdrHash(id);
    var amountA = XdrBigInt64(Util.toXdrBigInt64Amount(this.maxAmountA));
    var amountB = XdrBigInt64(Util.toXdrBigInt64Amount(this.maxAmountB));
    XdrPrice xMinPrice = Price.fromString(minPrice).toXdr();
    XdrPrice xMaxPrice = Price.fromString(maxPrice).toXdr();

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.LIQUIDITY_POOL_DEPOSIT);
    body.liquidityPoolDepositOp = XdrLiquidityPoolDepositOp(
        xLiquidityPoolID, amountA, amountB, xMinPrice, xMaxPrice);
    return body;
  }

  static LiquidityPoolDepositOperationBuilder builder(
      XdrLiquidityPoolDepositOp op) {
    String lpId = Util.bytesToHex(op.liquidityPoolID.hash);
    String maxA = Util.fromXdrBigInt64Amount(op.maxAmountA.bigInt);
    String maxB = Util.fromXdrBigInt64Amount(op.maxAmountB.bigInt);
    int n = op.minPrice.n.int32;
    int d = op.minPrice.d.int32;
    String minP = removeTailZero((BigInt.from(n) / BigInt.from(d)).toString());
    n = op.maxPrice.n.int32;
    d = op.maxPrice.d.int32;
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
