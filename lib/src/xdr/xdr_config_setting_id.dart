// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrConfigSettingID {
  final _value;
  const XdrConfigSettingID._internal(this._value);
  toString() => 'ConfigSettingID..$_value';

  XdrConfigSettingID(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrConfigSettingID && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES =
      const XdrConfigSettingID._internal(0);
  static const CONFIG_SETTING_CONTRACT_COMPUTE_V0 =
      const XdrConfigSettingID._internal(1);
  static const CONFIG_SETTING_CONTRACT_LEDGER_COST_V0 =
      const XdrConfigSettingID._internal(2);
  static const CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0 =
      const XdrConfigSettingID._internal(3);
  static const CONFIG_SETTING_CONTRACT_EVENTS_V0 =
      const XdrConfigSettingID._internal(4);
  static const CONFIG_SETTING_CONTRACT_BANDWIDTH_V0 =
      const XdrConfigSettingID._internal(5);
  static const CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS =
      const XdrConfigSettingID._internal(6);
  static const CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES =
      const XdrConfigSettingID._internal(7);
  static const CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES =
      const XdrConfigSettingID._internal(8);
  static const CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES =
      const XdrConfigSettingID._internal(9);
  static const CONFIG_SETTING_STATE_ARCHIVAL =
      const XdrConfigSettingID._internal(10);
  static const CONFIG_SETTING_CONTRACT_EXECUTION_LANES =
      const XdrConfigSettingID._internal(11);
  static const CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW =
      const XdrConfigSettingID._internal(12);
  static const CONFIG_SETTING_EVICTION_ITERATOR =
      const XdrConfigSettingID._internal(13);
  static const CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0 =
      const XdrConfigSettingID._internal(14);
  static const CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0 =
      const XdrConfigSettingID._internal(15);
  static const CONFIG_SETTING_SCP_TIMING = const XdrConfigSettingID._internal(
    16,
  );

  static XdrConfigSettingID decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES;
      case 1:
        return CONFIG_SETTING_CONTRACT_COMPUTE_V0;
      case 2:
        return CONFIG_SETTING_CONTRACT_LEDGER_COST_V0;
      case 3:
        return CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0;
      case 4:
        return CONFIG_SETTING_CONTRACT_EVENTS_V0;
      case 5:
        return CONFIG_SETTING_CONTRACT_BANDWIDTH_V0;
      case 6:
        return CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS;
      case 7:
        return CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES;
      case 8:
        return CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES;
      case 9:
        return CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES;
      case 10:
        return CONFIG_SETTING_STATE_ARCHIVAL;
      case 11:
        return CONFIG_SETTING_CONTRACT_EXECUTION_LANES;
      case 12:
        return CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW;
      case 13:
        return CONFIG_SETTING_EVICTION_ITERATOR;
      case 14:
        return CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0;
      case 15:
        return CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0;
      case 16:
        return CONFIG_SETTING_SCP_TIMING;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrConfigSettingID value) {
    stream.writeInt(value.value);
  }
}
