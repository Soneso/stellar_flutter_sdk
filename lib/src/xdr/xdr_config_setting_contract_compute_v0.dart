// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint32.dart';

class XdrConfigSettingContractComputeV0 {

  XdrInt64 _ledgerMaxInstructions;
  XdrInt64 get ledgerMaxInstructions => this._ledgerMaxInstructions;
  set ledgerMaxInstructions(XdrInt64 value) => this._ledgerMaxInstructions = value;

  XdrInt64 _txMaxInstructions;
  XdrInt64 get txMaxInstructions => this._txMaxInstructions;
  set txMaxInstructions(XdrInt64 value) => this._txMaxInstructions = value;

  XdrInt64 _feeRatePerInstructionsIncrement;
  XdrInt64 get feeRatePerInstructionsIncrement => this._feeRatePerInstructionsIncrement;
  set feeRatePerInstructionsIncrement(XdrInt64 value) => this._feeRatePerInstructionsIncrement = value;

  XdrUint32 _txMemoryLimit;
  XdrUint32 get txMemoryLimit => this._txMemoryLimit;
  set txMemoryLimit(XdrUint32 value) => this._txMemoryLimit = value;

  XdrConfigSettingContractComputeV0(this._ledgerMaxInstructions, this._txMaxInstructions, this._feeRatePerInstructionsIncrement, this._txMemoryLimit);

  static void encode(XdrDataOutputStream stream, XdrConfigSettingContractComputeV0 encodedConfigSettingContractComputeV0) {
    XdrInt64.encode(stream, encodedConfigSettingContractComputeV0.ledgerMaxInstructions);
    XdrInt64.encode(stream, encodedConfigSettingContractComputeV0.txMaxInstructions);
    XdrInt64.encode(stream, encodedConfigSettingContractComputeV0.feeRatePerInstructionsIncrement);
    XdrUint32.encode(stream, encodedConfigSettingContractComputeV0.txMemoryLimit);
  }

  static XdrConfigSettingContractComputeV0 decode(XdrDataInputStream stream) {
    XdrInt64 ledgerMaxInstructions = XdrInt64.decode(stream);
    XdrInt64 txMaxInstructions = XdrInt64.decode(stream);
    XdrInt64 feeRatePerInstructionsIncrement = XdrInt64.decode(stream);
    XdrUint32 txMemoryLimit = XdrUint32.decode(stream);
    return XdrConfigSettingContractComputeV0(ledgerMaxInstructions, txMaxInstructions, feeRatePerInstructionsIncrement, txMemoryLimit);
  }
}
