// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint32.dart';

class XdrConfigSettingContractLedgerCostExtV0 {
  // Maximum number of RO+RW entries in the transaction footprint.
  XdrUint32 _txMaxFootprintEntries;
  XdrUint32 get txMaxFootprintEntries => this._txMaxFootprintEntries;
  set txMaxFootprintEntries(XdrUint32 value) =>
      this._txMaxFootprintEntries = value;

  // Fee per 1 KB of data written to the ledger.
  // Unlike the rent fee, this is a flat fee that is charged for any ledger
  // write, independent of the type of the entry being written.
  XdrInt64 _feeWrite1KB;
  XdrInt64 get feeWrite1KB => this._feeWrite1KB;
  set feeWrite1KB(XdrInt64 value) => this._feeWrite1KB = value;

  XdrConfigSettingContractLedgerCostExtV0(
    this._txMaxFootprintEntries,
    this._feeWrite1KB,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrConfigSettingContractLedgerCostExtV0 encoded,
  ) {
    XdrUint32.encode(stream, encoded.txMaxFootprintEntries);
    XdrInt64.encode(stream, encoded.feeWrite1KB);
  }

  static XdrConfigSettingContractLedgerCostExtV0 decode(
    XdrDataInputStream stream,
  ) {
    final txMaxFootprintEntries = XdrUint32.decode(stream);
    final feeWrite1KB = XdrInt64.decode(stream);
    return XdrConfigSettingContractLedgerCostExtV0(
      txMaxFootprintEntries,
      feeWrite1KB,
    );
  }
}
