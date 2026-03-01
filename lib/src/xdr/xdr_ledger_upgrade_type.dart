// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrLedgerUpgradeType {
  final _value;

  const XdrLedgerUpgradeType._internal(this._value);

  toString() => 'LedgerUpgradeType.$_value';

  XdrLedgerUpgradeType(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrLedgerUpgradeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const LEDGER_UPGRADE_VERSION = const XdrLedgerUpgradeType._internal(1);
  static const LEDGER_UPGRADE_BASE_FEE =
      const XdrLedgerUpgradeType._internal(2);
  static const LEDGER_UPGRADE_MAX_TX_SET_SIZE =
      const XdrLedgerUpgradeType._internal(3);
  static const LEDGER_UPGRADE_BASE_RESERVE =
      const XdrLedgerUpgradeType._internal(4);
  static const LEDGER_UPGRADE_FLAGS = const XdrLedgerUpgradeType._internal(5);
  static const LEDGER_UPGRADE_CONFIG = const XdrLedgerUpgradeType._internal(6);
  static const LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE =
      const XdrLedgerUpgradeType._internal(7);

  static XdrLedgerUpgradeType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return LEDGER_UPGRADE_VERSION;
      case 2:
        return LEDGER_UPGRADE_BASE_FEE;
      case 3:
        return LEDGER_UPGRADE_MAX_TX_SET_SIZE;
      case 4:
        return LEDGER_UPGRADE_BASE_RESERVE;
      case 5:
        return LEDGER_UPGRADE_FLAGS;
      case 6:
        return LEDGER_UPGRADE_CONFIG;
      case 7:
        return LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrLedgerUpgradeType value) {
    stream.writeInt(value.value);
  }
}
