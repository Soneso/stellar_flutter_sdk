// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_liquidity_pool_withdraw_result_code.dart';

class XdrLiquidityPoolWithdrawResult {
  XdrLiquidityPoolWithdrawResultCode _code;

  XdrLiquidityPoolWithdrawResultCode get discriminant => this._code;

  set discriminant(XdrLiquidityPoolWithdrawResultCode value) => this._code = value;

  XdrLiquidityPoolWithdrawResult(this._code);

  static void encode(XdrDataOutputStream stream, XdrLiquidityPoolWithdrawResult encodedLiquidityPoolWithdrawResult) {
    stream.writeInt(encodedLiquidityPoolWithdrawResult.discriminant.value);
    switch (encodedLiquidityPoolWithdrawResult.discriminant) {
      case XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrLiquidityPoolWithdrawResult decode(XdrDataInputStream stream) {
    XdrLiquidityPoolWithdrawResult decodedLiquidityPoolWithdrawResult = XdrLiquidityPoolWithdrawResult(XdrLiquidityPoolWithdrawResultCode.decode(stream));
    switch (decodedLiquidityPoolWithdrawResult.discriminant) {
      case XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_SUCCESS:
        break;
      default:
        break;
    }
    return decodedLiquidityPoolWithdrawResult;
  }
}
