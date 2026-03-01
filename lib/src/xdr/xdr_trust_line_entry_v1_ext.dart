// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_trust_line_entry_extension_v2.dart';

class XdrTrustLineEntryV1Ext {
  XdrTrustLineEntryV1Ext(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  TrustLineEntryExtensionV2? _ext;

  TrustLineEntryExtensionV2? get ext => this._ext;

  set ext(TrustLineEntryExtensionV2? value) => this._ext = value;

  static void encode(XdrDataOutputStream stream, XdrTrustLineEntryV1Ext value) {
    stream.writeInt(value.discriminant);
    switch (value.discriminant) {
      case 0:
        break;
      case 2:
        TrustLineEntryExtensionV2.encode(stream, value.ext!);
        break;
    }
  }

  static XdrTrustLineEntryV1Ext decode(XdrDataInputStream stream) {
    XdrTrustLineEntryV1Ext decodedTrustLineEntryV1Ext =
        XdrTrustLineEntryV1Ext(stream.readInt());
    switch (decodedTrustLineEntryV1Ext.discriminant) {
      case 0:
        break;
      case 2:
        decodedTrustLineEntryV1Ext.ext =
            TrustLineEntryExtensionV2.decode(stream);
        break;
    }
    return decodedTrustLineEntryV1Ext;
  }
}
