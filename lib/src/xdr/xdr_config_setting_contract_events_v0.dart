// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint32.dart';

class XdrConfigSettingContractEventsV0 {
  XdrUint32 _txMaxContractEventsSizeBytes;
  XdrUint32 get txMaxContractEventsSizeBytes =>
      this._txMaxContractEventsSizeBytes;
  set txMaxContractEventsSizeBytes(XdrUint32 value) =>
      this._txMaxContractEventsSizeBytes = value;

  XdrInt64 _feeContractEvents1KB;
  XdrInt64 get feeContractEvents1KB => this._feeContractEvents1KB;
  set feeContractEvents1KB(XdrInt64 value) =>
      this._feeContractEvents1KB = value;

  XdrConfigSettingContractEventsV0(
    this._txMaxContractEventsSizeBytes,
    this._feeContractEvents1KB,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrConfigSettingContractEventsV0 encodedConfigSettingContractEventsV0,
  ) {
    XdrUint32.encode(
      stream,
      encodedConfigSettingContractEventsV0.txMaxContractEventsSizeBytes,
    );
    XdrInt64.encode(
      stream,
      encodedConfigSettingContractEventsV0.feeContractEvents1KB,
    );
  }

  static XdrConfigSettingContractEventsV0 decode(XdrDataInputStream stream) {
    XdrUint32 txMaxContractEventsSizeBytes = XdrUint32.decode(stream);
    XdrInt64 feeContractEvents1KB = XdrInt64.decode(stream);
    return XdrConfigSettingContractEventsV0(
      txMaxContractEventsSizeBytes,
      feeContractEvents1KB,
    );
  }
}
