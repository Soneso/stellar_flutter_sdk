// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_liquidity_pool_constant_product_parameters.dart';

class XdrLiquidityPoolEntryConstantProduct {
  XdrLiquidityPoolConstantProductParameters _params;
  XdrLiquidityPoolConstantProductParameters get params => this._params;
  set params(XdrLiquidityPoolConstantProductParameters value) =>
      this._params = value;

  XdrInt64 _reserveA;
  XdrInt64 get reserveA => this._reserveA;
  set reserveA(XdrInt64 value) => this._reserveA = value;

  XdrInt64 _reserveB;
  XdrInt64 get reserveB => this._reserveB;
  set reserveB(XdrInt64 value) => this._reserveB = value;

  XdrInt64 _totalPoolShares;
  XdrInt64 get totalPoolShares => this._totalPoolShares;
  set totalPoolShares(XdrInt64 value) => this._totalPoolShares = value;

  XdrInt64 _poolSharesTrustLineCount;
  XdrInt64 get poolSharesTrustLineCount => this._poolSharesTrustLineCount;
  set poolSharesTrustLineCount(XdrInt64 value) =>
      this._poolSharesTrustLineCount = value;

  XdrLiquidityPoolEntryConstantProduct(
    this._params,
    this._reserveA,
    this._reserveB,
    this._totalPoolShares,
    this._poolSharesTrustLineCount,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrLiquidityPoolEntryConstantProduct
    encodedLiquidityPoolEntryConstantProduct,
  ) {
    XdrLiquidityPoolConstantProductParameters.encode(
      stream,
      encodedLiquidityPoolEntryConstantProduct.params,
    );
    XdrInt64.encode(stream, encodedLiquidityPoolEntryConstantProduct.reserveA);
    XdrInt64.encode(stream, encodedLiquidityPoolEntryConstantProduct.reserveB);
    XdrInt64.encode(
      stream,
      encodedLiquidityPoolEntryConstantProduct.totalPoolShares,
    );
    XdrInt64.encode(
      stream,
      encodedLiquidityPoolEntryConstantProduct.poolSharesTrustLineCount,
    );
  }

  static XdrLiquidityPoolEntryConstantProduct decode(
    XdrDataInputStream stream,
  ) {
    XdrLiquidityPoolConstantProductParameters params =
        XdrLiquidityPoolConstantProductParameters.decode(stream);
    XdrInt64 reserveA = XdrInt64.decode(stream);
    XdrInt64 reserveB = XdrInt64.decode(stream);
    XdrInt64 totalPoolShares = XdrInt64.decode(stream);
    XdrInt64 poolSharesTrustLineCount = XdrInt64.decode(stream);
    return XdrLiquidityPoolEntryConstantProduct(
      params,
      reserveA,
      reserveB,
      totalPoolShares,
      poolSharesTrustLineCount,
    );
  }
}
