// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint32.dart';

class XdrConfigSettingContractLedgerCostV0 {

  XdrUint32 _ledgerMaxDiskReadEntries;
  XdrUint32 get ledgerMaxDiskReadEntries => this._ledgerMaxDiskReadEntries;
  set ledgerMaxDiskReadEntries(XdrUint32 value) => this._ledgerMaxDiskReadEntries = value;

  XdrUint32 _ledgerMaxDiskReadBytes;
  XdrUint32 get ledgerMaxDiskReadBytes => this._ledgerMaxDiskReadBytes;
  set ledgerMaxDiskReadBytes(XdrUint32 value) => this._ledgerMaxDiskReadBytes = value;

  XdrUint32 _ledgerMaxWriteLedgerEntries;
  XdrUint32 get ledgerMaxWriteLedgerEntries => this._ledgerMaxWriteLedgerEntries;
  set ledgerMaxWriteLedgerEntries(XdrUint32 value) => this._ledgerMaxWriteLedgerEntries = value;

  XdrUint32 _ledgerMaxWriteBytes;
  XdrUint32 get ledgerMaxWriteBytes => this._ledgerMaxWriteBytes;
  set ledgerMaxWriteBytes(XdrUint32 value) => this._ledgerMaxWriteBytes = value;

  XdrUint32 _txMaxDiskReadEntries;
  XdrUint32 get txMaxDiskReadEntries => this._txMaxDiskReadEntries;
  set txMaxDiskReadEntries(XdrUint32 value) => this._txMaxDiskReadEntries = value;

  XdrUint32 _txMaxDiskReadBytes;
  XdrUint32 get txMaxDiskReadBytes => this._txMaxDiskReadBytes;
  set txMaxDiskReadBytes(XdrUint32 value) => this._txMaxDiskReadBytes = value;

  XdrUint32 _txMaxWriteLedgerEntries;
  XdrUint32 get txMaxWriteLedgerEntries => this._txMaxWriteLedgerEntries;
  set txMaxWriteLedgerEntries(XdrUint32 value) => this._txMaxWriteLedgerEntries = value;

  XdrUint32 _txMaxWriteBytes;
  XdrUint32 get txMaxWriteBytes => this._txMaxWriteBytes;
  set txMaxWriteBytes(XdrUint32 value) => this._txMaxWriteBytes = value;

  XdrInt64 _feeDiskReadLedgerEntry;
  XdrInt64 get feeDiskReadLedgerEntry => this._feeDiskReadLedgerEntry;
  set feeDiskReadLedgerEntry(XdrInt64 value) => this._feeDiskReadLedgerEntry = value;

  XdrInt64 _feeWriteLedgerEntry;
  XdrInt64 get feeWriteLedgerEntry => this._feeWriteLedgerEntry;
  set feeWriteLedgerEntry(XdrInt64 value) => this._feeWriteLedgerEntry = value;

  XdrInt64 _feeDiskRead1KB;
  XdrInt64 get feeDiskRead1KB => this._feeDiskRead1KB;
  set feeDiskRead1KB(XdrInt64 value) => this._feeDiskRead1KB = value;

  XdrInt64 _sorobanStateTargetSizeBytes;
  XdrInt64 get sorobanStateTargetSizeBytes => this._sorobanStateTargetSizeBytes;
  set sorobanStateTargetSizeBytes(XdrInt64 value) => this._sorobanStateTargetSizeBytes = value;

  XdrInt64 _rentFee1KBSorobanStateSizeLow;
  XdrInt64 get rentFee1KBSorobanStateSizeLow => this._rentFee1KBSorobanStateSizeLow;
  set rentFee1KBSorobanStateSizeLow(XdrInt64 value) => this._rentFee1KBSorobanStateSizeLow = value;

  XdrInt64 _rentFee1KBSorobanStateSizeHigh;
  XdrInt64 get rentFee1KBSorobanStateSizeHigh => this._rentFee1KBSorobanStateSizeHigh;
  set rentFee1KBSorobanStateSizeHigh(XdrInt64 value) => this._rentFee1KBSorobanStateSizeHigh = value;

  XdrUint32 _sorobanStateRentFeeGrowthFactor;
  XdrUint32 get sorobanStateRentFeeGrowthFactor => this._sorobanStateRentFeeGrowthFactor;
  set sorobanStateRentFeeGrowthFactor(XdrUint32 value) => this._sorobanStateRentFeeGrowthFactor = value;

  XdrConfigSettingContractLedgerCostV0(this._ledgerMaxDiskReadEntries, this._ledgerMaxDiskReadBytes, this._ledgerMaxWriteLedgerEntries, this._ledgerMaxWriteBytes, this._txMaxDiskReadEntries, this._txMaxDiskReadBytes, this._txMaxWriteLedgerEntries, this._txMaxWriteBytes, this._feeDiskReadLedgerEntry, this._feeWriteLedgerEntry, this._feeDiskRead1KB, this._sorobanStateTargetSizeBytes, this._rentFee1KBSorobanStateSizeLow, this._rentFee1KBSorobanStateSizeHigh, this._sorobanStateRentFeeGrowthFactor);

  static void encode(XdrDataOutputStream stream, XdrConfigSettingContractLedgerCostV0 encodedConfigSettingContractLedgerCostV0) {
    XdrUint32.encode(stream, encodedConfigSettingContractLedgerCostV0.ledgerMaxDiskReadEntries);
    XdrUint32.encode(stream, encodedConfigSettingContractLedgerCostV0.ledgerMaxDiskReadBytes);
    XdrUint32.encode(stream, encodedConfigSettingContractLedgerCostV0.ledgerMaxWriteLedgerEntries);
    XdrUint32.encode(stream, encodedConfigSettingContractLedgerCostV0.ledgerMaxWriteBytes);
    XdrUint32.encode(stream, encodedConfigSettingContractLedgerCostV0.txMaxDiskReadEntries);
    XdrUint32.encode(stream, encodedConfigSettingContractLedgerCostV0.txMaxDiskReadBytes);
    XdrUint32.encode(stream, encodedConfigSettingContractLedgerCostV0.txMaxWriteLedgerEntries);
    XdrUint32.encode(stream, encodedConfigSettingContractLedgerCostV0.txMaxWriteBytes);
    XdrInt64.encode(stream, encodedConfigSettingContractLedgerCostV0.feeDiskReadLedgerEntry);
    XdrInt64.encode(stream, encodedConfigSettingContractLedgerCostV0.feeWriteLedgerEntry);
    XdrInt64.encode(stream, encodedConfigSettingContractLedgerCostV0.feeDiskRead1KB);
    XdrInt64.encode(stream, encodedConfigSettingContractLedgerCostV0.sorobanStateTargetSizeBytes);
    XdrInt64.encode(stream, encodedConfigSettingContractLedgerCostV0.rentFee1KBSorobanStateSizeLow);
    XdrInt64.encode(stream, encodedConfigSettingContractLedgerCostV0.rentFee1KBSorobanStateSizeHigh);
    XdrUint32.encode(stream, encodedConfigSettingContractLedgerCostV0.sorobanStateRentFeeGrowthFactor);
  }

  static XdrConfigSettingContractLedgerCostV0 decode(XdrDataInputStream stream) {
    XdrUint32 ledgerMaxDiskReadEntries = XdrUint32.decode(stream);
    XdrUint32 ledgerMaxDiskReadBytes = XdrUint32.decode(stream);
    XdrUint32 ledgerMaxWriteLedgerEntries = XdrUint32.decode(stream);
    XdrUint32 ledgerMaxWriteBytes = XdrUint32.decode(stream);
    XdrUint32 txMaxDiskReadEntries = XdrUint32.decode(stream);
    XdrUint32 txMaxDiskReadBytes = XdrUint32.decode(stream);
    XdrUint32 txMaxWriteLedgerEntries = XdrUint32.decode(stream);
    XdrUint32 txMaxWriteBytes = XdrUint32.decode(stream);
    XdrInt64 feeDiskReadLedgerEntry = XdrInt64.decode(stream);
    XdrInt64 feeWriteLedgerEntry = XdrInt64.decode(stream);
    XdrInt64 feeDiskRead1KB = XdrInt64.decode(stream);
    XdrInt64 sorobanStateTargetSizeBytes = XdrInt64.decode(stream);
    XdrInt64 rentFee1KBSorobanStateSizeLow = XdrInt64.decode(stream);
    XdrInt64 rentFee1KBSorobanStateSizeHigh = XdrInt64.decode(stream);
    XdrUint32 sorobanStateRentFeeGrowthFactor = XdrUint32.decode(stream);
    return XdrConfigSettingContractLedgerCostV0(ledgerMaxDiskReadEntries, ledgerMaxDiskReadBytes, ledgerMaxWriteLedgerEntries, ledgerMaxWriteBytes, txMaxDiskReadEntries, txMaxDiskReadBytes, txMaxWriteLedgerEntries, txMaxWriteBytes, feeDiskReadLedgerEntry, feeWriteLedgerEntry, feeDiskRead1KB, sorobanStateTargetSizeBytes, rentFee1KBSorobanStateSizeLow, rentFee1KBSorobanStateSizeHigh, sorobanStateRentFeeGrowthFactor);
  }
}
