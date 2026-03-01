// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_big_int64.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrLiquidityPoolWithdrawOp {
  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

  XdrBigInt64 _amount;
  XdrBigInt64 get amount => this._amount;
  set amount(XdrBigInt64 value) => this._amount = value;

  XdrBigInt64 _minAmountA;
  XdrBigInt64 get minAmountA => this._minAmountA;
  set minAmountA(XdrBigInt64 value) => this._minAmountA = value;

  XdrBigInt64 _minAmountB;
  XdrBigInt64 get minAmountB => this._minAmountB;
  set minAmountB(XdrBigInt64 value) => this._minAmountB = value;

  XdrLiquidityPoolWithdrawOp(
    this._liquidityPoolID,
    this._amount,
    this._minAmountA,
    this._minAmountB,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrLiquidityPoolWithdrawOp encoded,
  ) {
    XdrHash.encode(stream, encoded.liquidityPoolID);
    XdrBigInt64.encode(stream, encoded.amount);
    XdrBigInt64.encode(stream, encoded.minAmountA);
    XdrBigInt64.encode(stream, encoded.minAmountB);
  }

  static XdrLiquidityPoolWithdrawOp decode(XdrDataInputStream stream) {
    return XdrLiquidityPoolWithdrawOp(
      XdrHash.decode(stream),
      XdrBigInt64.decode(stream),
      XdrBigInt64.decode(stream),
      XdrBigInt64.decode(stream),
    );
  }
}
