// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_constant_product.dart';
import 'xdr_data_io.dart';
import 'xdr_liquidity_pool_type.dart';

class XdrLiquidityPoolBody {
  XdrLiquidityPoolBody(this._type);

  XdrLiquidityPoolType _type;
  XdrLiquidityPoolType get discriminant => this._type;
  set discriminant(XdrLiquidityPoolType value) => this._type = value;

  XdrConstantProduct? _constantProduct;
  XdrConstantProduct? get constantProduct => this._constantProduct;
  set constantProduct(XdrConstantProduct? value) =>
      this._constantProduct = value;

  static void encode(XdrDataOutputStream stream, XdrLiquidityPoolBody encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT:
        XdrConstantProduct.encode(stream, encoded.constantProduct!);
        break;
    }
  }

  static XdrLiquidityPoolBody decode(XdrDataInputStream stream) {
    XdrLiquidityPoolBody decoded =
        XdrLiquidityPoolBody(XdrLiquidityPoolType.decode(stream));
    switch (decoded.discriminant) {
      case XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT:
        decoded.constantProduct = XdrConstantProduct.decode(stream);
        break;
    }
    return decoded;
  }
}
