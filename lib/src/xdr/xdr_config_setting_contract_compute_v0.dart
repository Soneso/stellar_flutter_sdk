// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint32.dart';

class XdrConfigSettingContractComputeV0 {
  // Maximum instructions per ledger
  XdrInt64 _ledgerMaxInstructions;
  XdrInt64 get ledgerMaxInstructions => this._ledgerMaxInstructions;
  set ledgerMaxInstructions(XdrInt64 value) =>
      this._ledgerMaxInstructions = value;

  // Maximum instructions per transaction
  XdrInt64 _txMaxInstructions;
  XdrInt64 get txMaxInstructions => this._txMaxInstructions;
  set txMaxInstructions(XdrInt64 value) => this._txMaxInstructions = value;

  // Cost of 10000 instructions
  XdrInt64 _feeRatePerInstructionsIncrement;
  XdrInt64 get feeRatePerInstructionsIncrement =>
      this._feeRatePerInstructionsIncrement;
  set feeRatePerInstructionsIncrement(XdrInt64 value) =>
      this._feeRatePerInstructionsIncrement = value;

  // Memory limit per transaction. Unlike instructions, there is no fee
  // for memory, just the limit.
  XdrUint32 _txMemoryLimit;
  XdrUint32 get txMemoryLimit => this._txMemoryLimit;
  set txMemoryLimit(XdrUint32 value) => this._txMemoryLimit = value;

  XdrConfigSettingContractComputeV0(
      this._ledgerMaxInstructions,
      this._txMaxInstructions,
      this._feeRatePerInstructionsIncrement,
      this._txMemoryLimit);

  static void encode(
      XdrDataOutputStream stream, XdrConfigSettingContractComputeV0 encoded) {
    XdrInt64.encode(stream, encoded.ledgerMaxInstructions);
    XdrInt64.encode(stream, encoded.txMaxInstructions);
    XdrInt64.encode(stream, encoded.feeRatePerInstructionsIncrement);
    XdrUint32.encode(stream, encoded.txMemoryLimit);
  }

  static XdrConfigSettingContractComputeV0 decode(XdrDataInputStream stream) {
    XdrInt64 ledgerMaxInstructions = XdrInt64.decode(stream);
    XdrInt64 txMaxInstructions = XdrInt64.decode(stream);
    XdrInt64 feeRatePerInstructionsIncrement = XdrInt64.decode(stream);
    XdrUint32 txMemoryLimit = XdrUint32.decode(stream);
    return XdrConfigSettingContractComputeV0(ledgerMaxInstructions,
        txMaxInstructions, feeRatePerInstructionsIncrement, txMemoryLimit);
  }
}
