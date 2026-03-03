// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_liquidity_pool_entry_constant_product.dart';
import 'xdr_liquidity_pool_type.dart';

class XdrLiquidityPoolBody {
  XdrLiquidityPoolType _type;

  XdrLiquidityPoolType get discriminant => this._type;

  set discriminant(XdrLiquidityPoolType value) => this._type = value;

  XdrLiquidityPoolEntryConstantProduct? _constantProduct;

  XdrLiquidityPoolEntryConstantProduct? get constantProduct =>
      this._constantProduct;

  XdrLiquidityPoolBody(this._type);

  set constantProduct(XdrLiquidityPoolEntryConstantProduct? value) =>
      this._constantProduct = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrLiquidityPoolBody encodedLiquidityPoolBody,
  ) {
    stream.writeInt(encodedLiquidityPoolBody.discriminant.value);
    switch (encodedLiquidityPoolBody.discriminant) {
      case XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT:
        XdrLiquidityPoolEntryConstantProduct.encode(
          stream,
          encodedLiquidityPoolBody._constantProduct!,
        );
        break;
      default:
        break;
    }
  }

  static XdrLiquidityPoolBody decode(XdrDataInputStream stream) {
    XdrLiquidityPoolBody decodedLiquidityPoolBody = XdrLiquidityPoolBody(
      XdrLiquidityPoolType.decode(stream),
    );
    switch (decodedLiquidityPoolBody.discriminant) {
      case XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT:
        decodedLiquidityPoolBody._constantProduct =
            XdrLiquidityPoolEntryConstantProduct.decode(stream);
        break;
      default:
        break;
    }
    return decodedLiquidityPoolBody;
  }
}
