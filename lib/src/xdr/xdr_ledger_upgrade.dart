// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_config_upgrade_set_key.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger_upgrade_type.dart';
import 'xdr_uint32.dart';

class XdrLedgerUpgrade {
  XdrLedgerUpgradeType _type;

  XdrLedgerUpgradeType get discriminant => this._type;

  set discriminant(XdrLedgerUpgradeType value) => this._type = value;

  XdrUint32? _newLedgerVersion;

  XdrUint32? get newLedgerVersion => this._newLedgerVersion;

  XdrUint32? _newBaseFee;

  XdrUint32? get newBaseFee => this._newBaseFee;

  XdrUint32? _newMaxTxSetSize;

  XdrUint32? get newMaxTxSetSize => this._newMaxTxSetSize;

  XdrUint32? _newBaseReserve;

  XdrUint32? get newBaseReserve => this._newBaseReserve;

  XdrUint32? _newFlags;

  XdrUint32? get newFlags => this._newFlags;

  XdrConfigUpgradeSetKey? _newConfig;

  XdrConfigUpgradeSetKey? get newConfig => this._newConfig;

  XdrUint32? _newMaxSorobanTxSetSize;

  XdrUint32? get newMaxSorobanTxSetSize => this._newMaxSorobanTxSetSize;

  XdrLedgerUpgrade(this._type);

  set newLedgerVersion(XdrUint32? value) => this._newLedgerVersion = value;

  set newBaseFee(XdrUint32? value) => this._newBaseFee = value;

  set newMaxTxSetSize(XdrUint32? value) => this._newMaxTxSetSize = value;

  set newBaseReserve(XdrUint32? value) => this._newBaseReserve = value;

  set newFlags(XdrUint32? value) => this._newFlags = value;

  set newConfig(XdrConfigUpgradeSetKey? value) => this._newConfig = value;

  set newMaxSorobanTxSetSize(XdrUint32? value) =>
      this._newMaxSorobanTxSetSize = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerUpgrade encodedLedgerUpgrade,
  ) {
    stream.writeInt(encodedLedgerUpgrade.discriminant.value);
    switch (encodedLedgerUpgrade.discriminant) {
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_VERSION:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newLedgerVersion!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_FEE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newBaseFee!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_TX_SET_SIZE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newMaxTxSetSize!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_RESERVE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newBaseReserve!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_FLAGS:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newFlags!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_CONFIG:
        XdrConfigUpgradeSetKey.encode(stream, encodedLedgerUpgrade._newConfig!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newMaxSorobanTxSetSize!);
        break;
      default:
        break;
    }
  }

  static XdrLedgerUpgrade decode(XdrDataInputStream stream) {
    XdrLedgerUpgrade decodedLedgerUpgrade = XdrLedgerUpgrade(
      XdrLedgerUpgradeType.decode(stream),
    );
    switch (decodedLedgerUpgrade.discriminant) {
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_VERSION:
        decodedLedgerUpgrade._newLedgerVersion = XdrUint32.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_FEE:
        decodedLedgerUpgrade._newBaseFee = XdrUint32.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_TX_SET_SIZE:
        decodedLedgerUpgrade._newMaxTxSetSize = XdrUint32.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_RESERVE:
        decodedLedgerUpgrade._newBaseReserve = XdrUint32.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_FLAGS:
        decodedLedgerUpgrade._newFlags = XdrUint32.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_CONFIG:
        decodedLedgerUpgrade._newConfig = XdrConfigUpgradeSetKey.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE:
        decodedLedgerUpgrade._newMaxSorobanTxSetSize = XdrUint32.decode(stream);
        break;
      default:
        break;
    }
    return decodedLedgerUpgrade;
  }
}
