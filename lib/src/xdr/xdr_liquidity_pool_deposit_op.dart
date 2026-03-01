// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_big_int64.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_price.dart';

class XdrLiquidityPoolDepositOp {
  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

  XdrBigInt64 _maxAmountA;
  XdrBigInt64 get maxAmountA => this._maxAmountA;
  set maxAmountA(XdrBigInt64 value) => this._maxAmountA = value;

  XdrBigInt64 _maxAmountB;
  XdrBigInt64 get maxAmountB => this._maxAmountB;
  set maxAmountB(XdrBigInt64 value) => this._maxAmountB = value;

  XdrPrice _minPrice;
  XdrPrice get minPrice => this._minPrice;
  set minPrice(XdrPrice value) => this._minPrice = value;

  XdrPrice _maxPrice;
  XdrPrice get maxPrice => this._maxPrice;
  set maxPrice(XdrPrice value) => this._maxPrice = value;

  XdrLiquidityPoolDepositOp(
    this._liquidityPoolID,
    this._maxAmountA,
    this._maxAmountB,
    this._minPrice,
    this._maxPrice,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrLiquidityPoolDepositOp encoded,
  ) {
    XdrHash.encode(stream, encoded.liquidityPoolID);
    XdrBigInt64.encode(stream, encoded.maxAmountA);
    XdrBigInt64.encode(stream, encoded.maxAmountB);
    XdrPrice.encode(stream, encoded.minPrice);
    XdrPrice.encode(stream, encoded.maxPrice);
  }

  static XdrLiquidityPoolDepositOp decode(XdrDataInputStream stream) {
    XdrHash xLiquidityPoolID = XdrHash.decode(stream);
    var xMaxAmountA = XdrBigInt64.decode(stream);
    var xMaxAmountB = XdrBigInt64.decode(stream);
    XdrPrice xMinPrice = XdrPrice.decode(stream);
    XdrPrice xMaxPrice = XdrPrice.decode(stream);
    return XdrLiquidityPoolDepositOp(
      xLiquidityPoolID,
      xMaxAmountA,
      xMaxAmountB,
      xMinPrice,
      xMaxPrice,
    );
  }
}
