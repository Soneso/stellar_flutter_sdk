// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class TrustLineEntryExtensionV2Ext {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  TrustLineEntryExtensionV2Ext(this._v);

  static void encode(
    XdrDataOutputStream stream,
    TrustLineEntryExtensionV2Ext encodedTrustLineEntryExtensionV2Ext,
  ) {
    stream.writeInt(encodedTrustLineEntryExtensionV2Ext.discriminant);
    switch (encodedTrustLineEntryExtensionV2Ext.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static TrustLineEntryExtensionV2Ext decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    TrustLineEntryExtensionV2Ext decodedTrustLineEntryExtensionV2Ext =
        TrustLineEntryExtensionV2Ext(discriminant);
    switch (decodedTrustLineEntryExtensionV2Ext.discriminant) {
      case 0:
        break;
      default:
        break;
    }
    return decodedTrustLineEntryExtensionV2Ext;
  }
}
