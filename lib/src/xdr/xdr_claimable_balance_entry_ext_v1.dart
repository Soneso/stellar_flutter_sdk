// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claimable_balance_entry_ext_v1_ext.dart';
import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrClaimableBalanceEntryExtV1 {
  XdrClaimableBalanceEntryExtV1Ext _ext;
  XdrClaimableBalanceEntryExtV1Ext get ext => this._ext;
  set ext(XdrClaimableBalanceEntryExtV1Ext value) => this._ext = value;

  XdrUint32 _flags;
  XdrUint32 get flags => this._flags;
  set flags(XdrUint32 value) => this._flags = value;

  XdrClaimableBalanceEntryExtV1(this._ext, this._flags);

  static void encode(
    XdrDataOutputStream stream,
    XdrClaimableBalanceEntryExtV1 encodedClaimableBalanceEntryExtV1,
  ) {
    XdrClaimableBalanceEntryExtV1Ext.encode(
      stream,
      encodedClaimableBalanceEntryExtV1.ext,
    );
    XdrUint32.encode(stream, encodedClaimableBalanceEntryExtV1.flags);
  }

  static XdrClaimableBalanceEntryExtV1 decode(XdrDataInputStream stream) {
    XdrClaimableBalanceEntryExtV1Ext ext =
        XdrClaimableBalanceEntryExtV1Ext.decode(stream);
    XdrUint32 flags = XdrUint32.decode(stream);
    return XdrClaimableBalanceEntryExtV1(ext, flags);
  }
}
