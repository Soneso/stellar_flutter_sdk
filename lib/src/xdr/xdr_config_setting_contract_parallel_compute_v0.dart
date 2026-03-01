// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrConfigSettingContractParallelComputeV0 {
  // Maximum number of clusters with dependent transactions allowed in a
  // stage of parallel tx set component.
  // This effectively sets the lower bound on the number of physical threads
  // necessary to effectively apply transaction sets in parallel.
  XdrUint32 _ledgerMaxDependentTxClusters;
  XdrUint32 get ledgerMaxDependentTxClusters =>
      this._ledgerMaxDependentTxClusters;
  set ledgerMaxDependentTxClusters(XdrUint32 value) =>
      this._ledgerMaxDependentTxClusters = value;

  XdrConfigSettingContractParallelComputeV0(this._ledgerMaxDependentTxClusters);

  static void encode(
    XdrDataOutputStream stream,
    XdrConfigSettingContractParallelComputeV0 encoded,
  ) {
    XdrUint32.encode(stream, encoded.ledgerMaxDependentTxClusters);
  }

  static XdrConfigSettingContractParallelComputeV0 decode(
    XdrDataInputStream stream,
  ) {
    XdrUint32 ledgerMaxDependentTxClusters = XdrUint32.decode(stream);
    return XdrConfigSettingContractParallelComputeV0(
      ledgerMaxDependentTxClusters,
    );
  }
}
