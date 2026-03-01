// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_liquidity_pool_constant_product_parameters.dart';
import 'xdr_liquidity_pool_type.dart';

class XdrLiquidityPoolParameters {
  XdrLiquidityPoolType _type;
  XdrLiquidityPoolType get discriminant => this._type;
  set discriminant(XdrLiquidityPoolType value) => this._type = value;

  XdrLiquidityPoolConstantProductParameters? _constantProduct;
  XdrLiquidityPoolConstantProductParameters? get constantProduct =>
      this._constantProduct;
  set constantProduct(XdrLiquidityPoolConstantProductParameters? value) =>
      this._constantProduct = value;

  XdrLiquidityPoolParameters(this._type);

  static void encode(
      XdrDataOutputStream stream, XdrLiquidityPoolParameters encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT:
        XdrLiquidityPoolConstantProductParameters.encode(
            stream, encoded.constantProduct!);
        break;
    }
  }

  static XdrLiquidityPoolParameters decode(XdrDataInputStream stream) {
    XdrLiquidityPoolParameters decoded =
        XdrLiquidityPoolParameters(XdrLiquidityPoolType.decode(stream));
    switch (decoded.discriminant) {
      case XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT:
        decoded.constantProduct =
            XdrLiquidityPoolConstantProductParameters.decode(stream);
        break;
    }
    return decoded;
  }
}
