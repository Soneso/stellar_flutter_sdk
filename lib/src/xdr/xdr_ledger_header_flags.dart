// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrLedgerHeaderFlags {
  final _value;
  const XdrLedgerHeaderFlags._internal(this._value);
  toString() => 'LedgerHeaderFlags.$_value';
  XdrLedgerHeaderFlags(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrLedgerHeaderFlags && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const DISABLE_LIQUIDITY_POOL_TRADING_FLAG = const XdrLedgerHeaderFlags._internal(1);
  static const DISABLE_LIQUIDITY_POOL_DEPOSIT_FLAG = const XdrLedgerHeaderFlags._internal(2);
  static const DISABLE_LIQUIDITY_POOL_WITHDRAWAL_FLAG = const XdrLedgerHeaderFlags._internal(4);

  static XdrLedgerHeaderFlags decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return DISABLE_LIQUIDITY_POOL_TRADING_FLAG;
      case 2:
        return DISABLE_LIQUIDITY_POOL_DEPOSIT_FLAG;
      case 4:
        return DISABLE_LIQUIDITY_POOL_WITHDRAWAL_FLAG;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrLedgerHeaderFlags value) {
    stream.writeInt(value.value);
  }
}
