// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int32.dart';
import 'xdr_trust_line_entry_extension_v2_ext.dart';

class TrustLineEntryExtensionV2 {
  TrustLineEntryExtensionV2(this._liquidityPoolUseCount, this._ext);

  XdrInt32 _liquidityPoolUseCount;
  XdrInt32 get liquidityPoolUseCount => this._liquidityPoolUseCount;
  set liquidityPoolUseCount(XdrInt32 value) =>
      this._liquidityPoolUseCount = value;

  TrustLineEntryExtensionV2Ext _ext;
  TrustLineEntryExtensionV2Ext get ext => this._ext;
  set ext(TrustLineEntryExtensionV2Ext value) => this._ext = value;

  static void encode(
    XdrDataOutputStream stream,
    TrustLineEntryExtensionV2 value,
  ) {
    XdrInt32.encode(stream, value.liquidityPoolUseCount);
    TrustLineEntryExtensionV2Ext.encode(stream, value.ext);
  }

  static TrustLineEntryExtensionV2 decode(XdrDataInputStream stream) {
    XdrInt32 liquidityPoolUseCount = XdrInt32.decode(stream);
    TrustLineEntryExtensionV2Ext ext = TrustLineEntryExtensionV2Ext.decode(
      stream,
    );
    return TrustLineEntryExtensionV2(liquidityPoolUseCount, ext);
  }
}
