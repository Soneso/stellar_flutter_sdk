// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_config_setting_contract_bandwidth_v0.dart';
import 'xdr_config_setting_contract_compute_v0.dart';
import 'xdr_config_setting_contract_events_v0.dart';
import 'xdr_config_setting_contract_execution_lanes_v0.dart';
import 'xdr_config_setting_contract_historical_data_v0.dart';
import 'xdr_config_setting_contract_ledger_cost_ext_v0.dart';
import 'xdr_config_setting_contract_ledger_cost_v0.dart';
import 'xdr_config_setting_contract_parallel_compute_v0.dart';
import 'xdr_config_setting_id.dart';
import 'xdr_config_setting_scp_timing.dart';
import 'xdr_contract_cost_params.dart';
import 'xdr_data_io.dart';
import 'xdr_eviction_iterator.dart';
import 'xdr_state_archival_settings.dart';
import 'xdr_uint32.dart';
import 'xdr_uint64.dart';

class XdrConfigSettingEntry {
  XdrConfigSettingID _configSettingID;
  XdrConfigSettingID get configSettingID => this._configSettingID;
  set configSettingID(XdrConfigSettingID value) =>
      this._configSettingID = value;

  XdrUint32? _contractMaxSizeBytes;
  XdrUint32? get contractMaxSizeBytes => this._contractMaxSizeBytes;
  set contractMaxSizeBytes(XdrUint32? value) =>
      this._contractMaxSizeBytes = value;

  XdrConfigSettingContractComputeV0? _contractCompute;
  XdrConfigSettingContractComputeV0? get contractCompute =>
      this._contractCompute;
  set contractCompute(XdrConfigSettingContractComputeV0? value) =>
      this._contractCompute = value;

  XdrConfigSettingContractLedgerCostV0? _contractLedgerCost;
  XdrConfigSettingContractLedgerCostV0? get contractLedgerCost =>
      this._contractLedgerCost;
  set contractLedgerCost(XdrConfigSettingContractLedgerCostV0? value) =>
      this._contractLedgerCost = value;

  XdrConfigSettingContractHistoricalDataV0? _contractHistoricalData;
  XdrConfigSettingContractHistoricalDataV0? get contractHistoricalData =>
      this._contractHistoricalData;
  set contractHistoricalData(XdrConfigSettingContractHistoricalDataV0? value) =>
      this._contractHistoricalData = value;

  XdrConfigSettingContractEventsV0? _contractEvents;
  XdrConfigSettingContractEventsV0? get contractEvents => this._contractEvents;
  set contractEvents(XdrConfigSettingContractEventsV0? value) =>
      this._contractEvents = value;

  XdrConfigSettingContractBandwidthV0? _contractBandwidth;
  XdrConfigSettingContractBandwidthV0? get contractBandwidth =>
      this._contractBandwidth;
  set contractBandwidth(XdrConfigSettingContractBandwidthV0? value) =>
      this._contractBandwidth = value;

  XdrContractCostParams? _contractCostParamsCpuInsns;
  XdrContractCostParams? get contractCostParamsCpuInsns =>
      this._contractCostParamsCpuInsns;
  set contractCostParamsCpuInsns(XdrContractCostParams? value) =>
      this._contractCostParamsCpuInsns = value;

  XdrContractCostParams? _contractCostParamsMemBytes;
  XdrContractCostParams? get contractCostParamsMemBytes =>
      this._contractCostParamsMemBytes;
  set contractCostParamsMemBytes(XdrContractCostParams? value) =>
      this._contractCostParamsMemBytes = value;

  XdrUint32? _contractDataKeySizeBytes;
  XdrUint32? get contractDataKeySizeBytes => this._contractDataKeySizeBytes;
  set contractDataKeySizeBytes(XdrUint32? value) =>
      this._contractDataKeySizeBytes = value;

  XdrUint32? _contractDataEntrySizeBytes;
  XdrUint32? get contractDataEntrySizeBytes => this._contractDataEntrySizeBytes;
  set contractDataEntrySizeBytes(XdrUint32? value) =>
      this._contractDataEntrySizeBytes = value;

  XdrStateArchivalSettings? _stateArchivalSettings;
  XdrStateArchivalSettings? get stateArchivalSettings =>
      this._stateArchivalSettings;
  set stateArchivalSettings(XdrStateArchivalSettings? value) =>
      this._stateArchivalSettings = value;

  XdrConfigSettingContractExecutionLanesV0? _contractExecutionLanes;
  XdrConfigSettingContractExecutionLanesV0? get contractExecutionLanes =>
      this._contractExecutionLanes;
  set contractExecutionLanes(XdrConfigSettingContractExecutionLanesV0? value) =>
      this._contractExecutionLanes = value;

  List<XdrUint64>? _liveSorobanStateSizeWindow;
  List<XdrUint64>? get liveSorobanStateSizeWindow =>
      this._liveSorobanStateSizeWindow;
  set liveSorobanStateSizeWindow(List<XdrUint64>? value) =>
      this._liveSorobanStateSizeWindow = value;

  XdrEvictionIterator? _evictionIterator;
  XdrEvictionIterator? get evictionIterator => this._evictionIterator;
  set evictionIterator(XdrEvictionIterator? value) =>
      this._evictionIterator = value;

  XdrConfigSettingContractParallelComputeV0? _contractParallelCompute;
  XdrConfigSettingContractParallelComputeV0? get contractParallelCompute =>
      this._contractParallelCompute;
  set contractParallelCompute(
    XdrConfigSettingContractParallelComputeV0? value,
  ) => this._contractParallelCompute = value;

  XdrConfigSettingContractLedgerCostExtV0? _contractLedgerCostExt;
  XdrConfigSettingContractLedgerCostExtV0? get contractLedgerCostExt =>
      this._contractLedgerCostExt;
  set contractLedgerCostExt(XdrConfigSettingContractLedgerCostExtV0? value) =>
      this._contractLedgerCostExt = value;

  XdrConfigSettingSCPTiming? _contractSCPTiming;
  XdrConfigSettingSCPTiming? get contractSCPTiming => this._contractSCPTiming;
  set contractSCPTiming(XdrConfigSettingSCPTiming? value) =>
      this._contractSCPTiming = value;

  XdrConfigSettingEntry(this._configSettingID);

  static void encode(
    XdrDataOutputStream stream,
    XdrConfigSettingEntry encoded,
  ) {
    stream.writeInt(encoded.configSettingID.value);
    switch (encoded.configSettingID) {
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES:
        XdrUint32.encode(stream, encoded.contractMaxSizeBytes!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COMPUTE_V0:
        XdrConfigSettingContractComputeV0.encode(
          stream,
          encoded.contractCompute!,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_V0:
        XdrConfigSettingContractLedgerCostV0.encode(
          stream,
          encoded.contractLedgerCost!,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0:
        XdrConfigSettingContractHistoricalDataV0.encode(
          stream,
          encoded.contractHistoricalData!,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EVENTS_V0:
        XdrConfigSettingContractEventsV0.encode(
          stream,
          encoded.contractEvents!,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_BANDWIDTH_V0:
        XdrConfigSettingContractBandwidthV0.encode(
          stream,
          encoded.contractBandwidth!,
        );
        break;
      case XdrConfigSettingID
          .CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS:
        XdrContractCostParams.encode(
          stream,
          encoded.contractCostParamsCpuInsns!,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES:
        XdrContractCostParams.encode(
          stream,
          encoded.contractCostParamsMemBytes!,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES:
        XdrUint32.encode(stream, encoded.contractDataKeySizeBytes!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES:
        XdrUint32.encode(stream, encoded.contractDataEntrySizeBytes!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL:
        XdrStateArchivalSettings.encode(stream, encoded.stateArchivalSettings!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EXECUTION_LANES:
        XdrConfigSettingContractExecutionLanesV0.encode(
          stream,
          encoded.contractExecutionLanes!,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW:
        int pSize = encoded.liveSorobanStateSizeWindow!.length;
        stream.writeInt(pSize);
        for (int i = 0; i < pSize; i++) {
          XdrUint64.encode(stream, encoded.liveSorobanStateSizeWindow![i]);
        }
        break;
      case XdrConfigSettingID.CONFIG_SETTING_EVICTION_ITERATOR:
        XdrEvictionIterator.encode(stream, encoded.evictionIterator!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0:
        XdrConfigSettingContractParallelComputeV0.encode(
          stream,
          encoded.contractParallelCompute!,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0:
        XdrConfigSettingContractLedgerCostExtV0.encode(
          stream,
          encoded.contractLedgerCostExt!,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_SCP_TIMING:
        XdrConfigSettingSCPTiming.encode(stream, encoded.contractSCPTiming!);
        break;
    }
  }

  static XdrConfigSettingEntry decode(XdrDataInputStream stream) {
    XdrConfigSettingEntry decoded = XdrConfigSettingEntry(
      XdrConfigSettingID.decode(stream),
    );
    switch (decoded.configSettingID) {
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES:
        decoded.contractMaxSizeBytes = XdrUint32.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COMPUTE_V0:
        decoded.contractCompute = XdrConfigSettingContractComputeV0.decode(
          stream,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_V0:
        decoded.contractLedgerCost =
            XdrConfigSettingContractLedgerCostV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0:
        decoded.contractHistoricalData =
            XdrConfigSettingContractHistoricalDataV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EVENTS_V0:
        decoded.contractEvents = XdrConfigSettingContractEventsV0.decode(
          stream,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_BANDWIDTH_V0:
        decoded.contractBandwidth = XdrConfigSettingContractBandwidthV0.decode(
          stream,
        );
        break;
      case XdrConfigSettingID
          .CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS:
        decoded.contractCostParamsCpuInsns = XdrContractCostParams.decode(
          stream,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES:
        decoded.contractCostParamsMemBytes = XdrContractCostParams.decode(
          stream,
        );
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES:
        decoded.contractDataKeySizeBytes = XdrUint32.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES:
        decoded.contractDataEntrySizeBytes = XdrUint32.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL:
        decoded.stateArchivalSettings = XdrStateArchivalSettings.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EXECUTION_LANES:
        decoded.contractExecutionLanes =
            XdrConfigSettingContractExecutionLanesV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW:
        int pSize = stream.readInt();
        List<XdrUint64> liveSorobanStateSizeWindow = List<XdrUint64>.empty(
          growable: true,
        );
        for (int i = 0; i < pSize; i++) {
          liveSorobanStateSizeWindow.add(XdrUint64.decode(stream));
        }
        decoded.liveSorobanStateSizeWindow = liveSorobanStateSizeWindow;
        break;
      case XdrConfigSettingID.CONFIG_SETTING_EVICTION_ITERATOR:
        decoded.evictionIterator = XdrEvictionIterator.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0:
        decoded.contractParallelCompute =
            XdrConfigSettingContractParallelComputeV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0:
        decoded.contractLedgerCostExt =
            XdrConfigSettingContractLedgerCostExtV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_SCP_TIMING:
        decoded.contractSCPTiming = XdrConfigSettingSCPTiming.decode(stream);
        break;
    }
    return decoded;
  }
}
