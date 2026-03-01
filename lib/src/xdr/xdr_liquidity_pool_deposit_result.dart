// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_liquidity_pool_deposit_result_code.dart';

class XdrLiquidityPoolDepositResult {
  XdrLiquidityPoolDepositResultCode _code;

  XdrLiquidityPoolDepositResultCode get discriminant => this._code;

  set discriminant(XdrLiquidityPoolDepositResultCode value) =>
      this._code = value;

  XdrLiquidityPoolDepositResult(this._code);

  static void encode(
    XdrDataOutputStream stream,
    XdrLiquidityPoolDepositResult encoded,
  ) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrLiquidityPoolDepositResult decode(XdrDataInputStream stream) {
    XdrLiquidityPoolDepositResult decoded = XdrLiquidityPoolDepositResult(
      XdrLiquidityPoolDepositResultCode.decode(stream),
    );
    switch (decoded.discriminant) {
      case XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
  }
}
