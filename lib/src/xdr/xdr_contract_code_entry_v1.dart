// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_code_cost_inputs.dart';
import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';

class XdrContractCodeEntryV1 {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrContractCodeCostInputs _costInputs;
  XdrContractCodeCostInputs get costInputs => this._costInputs;
  set costInputs(XdrContractCodeCostInputs value) => this._costInputs = value;

  XdrContractCodeEntryV1(this._ext, this._costInputs);

  static void encode(
    XdrDataOutputStream stream,
    XdrContractCodeEntryV1 encodedContractCodeEntryV1,
  ) {
    XdrExtensionPoint.encode(stream, encodedContractCodeEntryV1.ext);
    XdrContractCodeCostInputs.encode(
      stream,
      encodedContractCodeEntryV1.costInputs,
    );
  }

  static XdrContractCodeEntryV1 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrContractCodeCostInputs costInputs = XdrContractCodeCostInputs.decode(
      stream,
    );
    return XdrContractCodeEntryV1(ext, costInputs);
  }
}
