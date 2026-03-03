// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrLiquidityPoolWithdrawResultCode {
  final _value;
  const XdrLiquidityPoolWithdrawResultCode._internal(this._value);
  toString() => 'LiquidityPoolWithdrawResultCode.$_value';
  XdrLiquidityPoolWithdrawResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrLiquidityPoolWithdrawResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const LIQUIDITY_POOL_WITHDRAW_SUCCESS =
      const XdrLiquidityPoolWithdrawResultCode._internal(0);
  static const LIQUIDITY_POOL_WITHDRAW_MALFORMED =
      const XdrLiquidityPoolWithdrawResultCode._internal(-1);
  static const LIQUIDITY_POOL_WITHDRAW_NO_TRUST =
      const XdrLiquidityPoolWithdrawResultCode._internal(-2);
  static const LIQUIDITY_POOL_WITHDRAW_UNDERFUNDED =
      const XdrLiquidityPoolWithdrawResultCode._internal(-3);
  static const LIQUIDITY_POOL_WITHDRAW_LINE_FULL =
      const XdrLiquidityPoolWithdrawResultCode._internal(-4);
  static const LIQUIDITY_POOL_WITHDRAW_UNDER_MINIMUM =
      const XdrLiquidityPoolWithdrawResultCode._internal(-5);

  static XdrLiquidityPoolWithdrawResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return LIQUIDITY_POOL_WITHDRAW_SUCCESS;
      case -1:
        return LIQUIDITY_POOL_WITHDRAW_MALFORMED;
      case -2:
        return LIQUIDITY_POOL_WITHDRAW_NO_TRUST;
      case -3:
        return LIQUIDITY_POOL_WITHDRAW_UNDERFUNDED;
      case -4:
        return LIQUIDITY_POOL_WITHDRAW_LINE_FULL;
      case -5:
        return LIQUIDITY_POOL_WITHDRAW_UNDER_MINIMUM;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrLiquidityPoolWithdrawResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
