// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_cost_param_entry.dart';
import 'xdr_data_io.dart';

class XdrContractCostParams {
  List<XdrContractCostParamEntry> _entries;
  List<XdrContractCostParamEntry> get entries => this._entries;
  set entries(List<XdrContractCostParamEntry> value) => this._entries = value;

  XdrContractCostParams(this._entries);

  static void encode(
    XdrDataOutputStream stream,
    XdrContractCostParams encoded,
  ) {
    int pSize = encoded.entries.length;
    stream.writeInt(pSize);
    for (int i = 0; i < pSize; i++) {
      XdrContractCostParamEntry.encode(stream, encoded.entries[i]);
    }
  }

  static XdrContractCostParams decode(XdrDataInputStream stream) {
    int pSize = stream.readInt();
    List<XdrContractCostParamEntry> xEntries =
        List<XdrContractCostParamEntry>.empty(growable: true);
    for (int i = 0; i < pSize; i++) {
      xEntries.add(XdrContractCostParamEntry.decode(stream));
    }
    return XdrContractCostParams(xEntries);
  }
}
